// Copyright 2026 Cii
//
// This file is part of Rasen.
//
// Rasen is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Rasen is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Rasen.  If not, see <http://www.gnu.org/licenses/>.

import struct Foundation.UUID
import Dispatch

@MainActor protocol Action {
    func updateNode()
}
extension Action {
    func updateNode() {}
}

protocol PinchEventAction: Action {
    func flow(with event: PinchEvent)
}
protocol RotateEventAction: Action {
    func flow(with event: RotateEvent)
}
protocol ScrollEventAction: Action {
    func flow(with event: ScrollEvent)
}
protocol SwipeEventAction: Action {
    func flow(with event: SwipeEvent)
}
protocol DragEventAction: Action {
    func flow(with event: DragEvent)
}
protocol InputKeyEventAction: Action {
    func flow(with event: InputKeyEvent)
}
protocol InputTextEventAction: Action {
    func flow(with event: InputTextEvent)
}

final class RootAction: Action {
    var rootView: RootView
    
    init(_ rootView: RootView) {
        self.rootView = rootView
        
        rootView.updateNodeNotifications.append { [weak self] _ in
            self?.updateActionNode()
        }
    }
    
    func cancelTasks() {
        runActions.forEach { $0.cancel() }
        
        textAction.cancelTasks()
        
        rootView.cancelTasks()
    }
    
    func containsAllTimelines(with event: any Event) -> Bool {
        let sp = rootView.screenPointFromMenu ?? event.screenPoint
        let p = rootView.convertScreenToWorld(sp)
        guard let sheetView = rootView.sheetView(at: p) else { return false }
        let sheetP = sheetView.convertFromWorld(p)
        let timelineP = sheetView.animationView.timelineNode.convertFromWorld(p)
        return sheetView.animationView.containsTimeline(timelineP,
                                                        scale: rootView.screenToWorldScale)
        || sheetView.containsOtherTimeline(sheetP, scale: rootView.screenToWorldScale)
    }
    func isPlaying(with event: any Event) -> Bool {
        for (_, v) in rootView.sheetViewValues {
            if v.sheetView?.isPlaying ?? false {
                return true
            }
        }
        return false
    }
    
    var modifierKeys = ModifierKeys()
    
    func indicate(with event: DragEvent) {
        if !rootView.isUpdateWithCursorPosition {
            rootView.isUpdateWithCursorPosition = true
        }
        rootView.cursorPoint = event.screenPoint
        textAction.isMovedCursor = true
        textAction.moveEndInputKey(isStopFromMarkedText: true)
    }
    
    private(set) var oldPinchEvent: PinchEvent?, zoomAction: ZoomAction?
    func pinch(with event: PinchEvent) {
        switch event.phase {
        case .began:
            zoomAction = ZoomAction(self)
            zoomAction?.flow(with: event)
            oldPinchEvent = event
        case .changed:
            zoomAction?.flow(with: event)
            oldPinchEvent = event
        case .ended:
            oldPinchEvent = nil
            zoomAction?.flow(with: event)
            zoomAction = nil
        }
    }
    
    private(set) var oldScrollEvent: ScrollEvent?, scrollAction: ScrollAction?
    func scroll(with event: ScrollEvent) {
        textAction.moveEndInputKey()
        switch event.phase {
        case .began:
            scrollAction = ScrollAction(self)
            scrollAction?.flow(with: event)
            oldScrollEvent = event
        case .changed:
            scrollAction?.flow(with: event)
            oldScrollEvent = event
        case .ended:
            oldScrollEvent = nil
            scrollAction?.flow(with: event)
            scrollAction = nil
        }
    }
    
    private(set) var oldSwipeEvent: SwipeEvent?, swipeAction: SelectTimeAction?
    func swipe(with event: SwipeEvent) {
        textAction.moveEndInputKey()
        if !(dragAction is DrawLineAction || dragAction is DrawStraightLineAction) {
            stopDragEvent()
        }
        switch event.phase {
        case .began:
            stopInputTextEvent()
            updateLastEditedSheetPosition(from: event)
            swipeAction = SelectTimeAction(self)
            swipeAction?.flow(with: event)
            oldSwipeEvent = event
        case .changed:
            swipeAction?.flow(with: event)
            oldSwipeEvent = event
        case .ended:
            oldSwipeEvent = nil
            swipeAction?.flow(with: event)
            swipeAction = nil
        }
    }
    
    private(set) var oldRotateEvent: RotateEvent?, rotateAction: RotateAction?
    func rotate(with event: RotateEvent) {
        switch event.phase {
        case .began:
            rotateAction = RotateAction(self)
            rotateAction?.flow(with: event)
            oldRotateEvent = event
        case .changed:
            rotateAction?.flow(with: event)
            oldRotateEvent = event
        case .ended:
            oldRotateEvent = nil
            rotateAction?.flow(with: event)
            rotateAction = nil
        }
    }
    
    func strongDrag(with event: DragEvent) {}
    
    private func subDragAction(with quasimode: Quasimode) -> (any DragEventAction)? {
        switch quasimode {
        case .selectByRange: SelectByRangeAction(self)
        case .unselectByRange: UnselectByRangeAction(self)
        default: nil
        }
    }
    private(set) var oldSubDragEvent: DragEvent?, subDragEventAction: (any DragEventAction)?
    func subDrag(with event: DragEvent) {
        switch event.phase {
        case .began:
            updateLastEditedSheetPosition(from: event)
            stopInputTextEvent()
            let quasimode = Quasimode(modifier: modifierKeys, .subDrag)
            subDragEventAction = self.subDragAction(with: quasimode)
            subDragEventAction?.flow(with: event)
            oldSubDragEvent = event
            rootView.textCursorNode.isHidden = true
            rootView.textMaxTypelineWidthNode.isHidden = true
        case .changed:
            subDragEventAction?.flow(with: event)
            oldSubDragEvent = event
        case .ended:
            oldSubDragEvent = nil
            subDragEventAction?.flow(with: event)
            subDragEventAction = nil
            rootView.cursorPoint = event.screenPoint
        }
    }
    
    private(set) var oldMiddleDragEvent: DragEvent?, middleDragEventAction: (any DragEventAction)?
    func middleDrag(with event: DragEvent) {
        switch event.phase {
        case .began:
            updateLastEditedSheetPosition(from: event)
            stopInputTextEvent()
            middleDragEventAction = LassoCutAction(self)
            middleDragEventAction?.flow(with: event)
            oldMiddleDragEvent = event
            rootView.textCursorNode.isHidden = true
            rootView.textMaxTypelineWidthNode.isHidden = true
        case .changed:
            middleDragEventAction?.flow(with: event)
            oldMiddleDragEvent = event
        case .ended:
            oldMiddleDragEvent = nil
            middleDragEventAction?.flow(with: event)
            middleDragEventAction = nil
            rootView.cursorPoint = event.screenPoint
        }
    }
    
    private func dragAction(with quasimode: Quasimode) -> (any DragEventAction)? {
        switch quasimode {
        case .drawLine: DrawLineAction(self)
        case .drawStraightLine: DrawStraightLineAction(self)
        case .lassoCut: LassoCutAction(self)
        case .selectByRange: SelectByRangeAction(self)
        case .unselectByRange: UnselectByRangeAction(self)
        case .changeLightness: ChangeLightnessAction(self)
        case .changeTint: ChangeTintAction(self)
        case .keySelectTime: SelectTimeAction(self)
        case .selectVersion: SelectVersionAction(self)
        case .move: MoveAction(self)
        case .moveZ: MoveZAction(self)
        default: nil
        }
    }
    private(set) var oldDragEvent: DragEvent?, dragAction: (any DragEventAction)?
    func drag(with event: DragEvent) {
        switch event.phase {
        case .began:
            updateLastEditedSheetPosition(from: event)
            stopInputTextEvent()
            let quasimode = Quasimode(modifier: modifierKeys, .drag)
            if quasimode != .selectTime {
                stopInputKeyEvent()
            }
            dragAction = self.dragAction(with: quasimode)
            dragAction?.flow(with: event)
            oldDragEvent = event
            rootView.textCursorNode.isHidden = true
            rootView.textMaxTypelineWidthNode.isHidden = true
            
            rootView.isUpdateWithCursorPosition = false
            rootView.cursorPoint = event.screenPoint
        case .changed:
            dragAction?.flow(with: event)
            oldDragEvent = event
            
            rootView.cursorPoint = event.screenPoint
        case .ended:
            oldDragEvent = nil
            dragAction?.flow(with: event)
            dragAction = nil
            
            rootView.isUpdateWithCursorPosition = true
            rootView.cursorPoint = event.screenPoint
        }
    }
    
    private(set) var oldInputTextKeys = Set<InputKeyType>()
    lazy private(set) var textAction: TextAction = { TextAction(self) } ()
    func inputText(with event: InputTextEvent) {
        switch event.phase {
        case .began:
            updateLastEditedSheetPosition(from: event)
            oldInputTextKeys.insert(event.inputKeyType)
            textAction.flow(with: event)
        case .changed:
            textAction.flow(with: event)
        case .ended:
            oldInputTextKeys.remove(event.inputKeyType)
            textAction.flow(with: event)
        }
    }
    
    var runActions = Set<RunAction>() {
        didSet {
            rootView.updateRunningNodes(fromWorldPrintOrigins: runActions.map { $0.worldPrintOrigin })
        }
    }
    
    private func inputKeyAction(with quasimode: Quasimode) -> (any InputKeyEventAction)? {
        switch quasimode {
        case .undo: UndoAction(self)
        case .redo: RedoAction(self)
        case .cut: CutAction(self)
        case .copy: CopyAction(self)
        case .paste: PasteAction(self)
        case .insert: InsertAction(self)
        case .find: FindAction(self)
        case .changeToDraft: ChangeToDraftAction(self)
        case .cutDraft: CutDraftAction(self)
        case .makeFaces: MakeFacesAction(self)
        case .cutFaces: CutFacesAction(self)
        case .justFit: JustFitAction(self)
        case .interpolate: InterpolateAction(self)
        case .disconnect: DisconnectAction(self)
        case .changeToVerticalText: ChangeToVerticalTextAction(self)
        case .changeToHorizontalText: ChangeToHorizontalTextAction(self)
        case .changeToSuperscript: ChangeToSuperscriptAction(self)
        case .changeToSubscript: ChangeToSubscriptAction(self)
        case .addTime: AddTimeAction(self)
        case .addScore: AddScoreAction(self)
        case .lookUp, .keyLookUp: LookUpAction(self)
        case .runOrClose: RunAction(self)
        case .keyPlay: PlayAction(self)
        case .goPrevious: GoPreviousAction(self)
        case .goNext: GoNextAction(self)
        case .stop: StopAction(self)
        case .changeABC: ChangeLanguageAction(self)
        case .changeAIU: ChangeLanguageAction(self)
        default: nil
        }
    }
    private(set) var oldInputKeyEvent: InputKeyEvent?
    private(set) var inputKeyAction: (any InputKeyEventAction)?
    func inputKey(with event: InputKeyEvent) {
        switch event.phase {
        case .began:
            updateLastEditedSheetPosition(from: event)
            guard inputKeyAction == nil else { return }
            let quasimode = Quasimode(modifier: modifierKeys,
                                      event.inputKeyType)
            if rootView.editingTextView != nil
                && quasimode != .changeToSuperscript
                && quasimode != .changeToSubscript
                && quasimode != .changeToHorizontalText
                && quasimode != .changeToVerticalText
                && quasimode != .cut
                && quasimode != .paste
                && quasimode != .changeABC && quasimode != .changeAIU {
                
                stopInputTextEvent(isEndEdit: quasimode != .undo && quasimode != .redo)
            }
            if quasimode == .runOrClose {
                textAction.moveEndInputKey()
            }
            stopDragEvent()
            inputKeyAction = self.inputKeyAction(with: quasimode)
            inputKeyAction?.flow(with: event)
            oldInputKeyEvent = event
        case .changed:
            inputKeyAction?.flow(with: event)
            oldInputKeyEvent = event
        case .ended:
            oldInputKeyEvent = nil
            inputKeyAction?.flow(with: event)
            inputKeyAction = nil
        }
    }
    
    func updateLastEditedSheetPosition(from event: any Event) {
        rootView.updateLastEditedSheetPosition(fromScreen: event.screenPoint)
    }
    
    func keepOut(with event: any Event) {
        switch event.phase {
        case .began:
            rootView.cursor = .block
        case .changed:
            break
        case .ended:
            rootView.cursor = rootView.defaultCursor
        }
    }
    func stopPlaying(with event: any Event) {
        switch event.phase {
        case .began:
            rootView.cursor = .stop
            
            for (_, v) in rootView.sheetViewValues {
                v.sheetView?.stop()
            }
            rootView.showSelected()
        case .changed:
            break
        case .ended:
            rootView.cursor = rootView.defaultCursor
        }
    }
    
    func stopAllEvents(isEnableText: Bool = true) {
        stopPinchEvent()
        stopScrollEvent()
        stopSwipeEvent()
        stopDragEvent()
        if isEnableText {
            stopInputTextEvent()
        }
        stopInputKeyEvent()
        if isEnableText {
            textAction.moveEndInputKey()
        }
        modifierKeys = []
    }
    func stopPinchEvent() {
        if var event = oldPinchEvent, let zoomAction {
            event.phase = .ended
            self.zoomAction = nil
            oldPinchEvent = nil
            zoomAction.flow(with: event)
        }
    }
    func stopScrollEvent() {
        if var event = oldScrollEvent, let scrollAction {
            event.phase = .ended
            self.scrollAction = nil
            oldScrollEvent = nil
            scrollAction.flow(with: event)
        }
    }
    func stopSwipeEvent() {
        if var event = oldSwipeEvent, let swipeAction {
            event.phase = .ended
            self.swipeAction = nil
            oldSwipeEvent = nil
            swipeAction.flow(with: event)
        }
    }
    func stopDragEvent() {
        if var event = oldDragEvent, let dragAction {
            event.phase = .ended
            self.dragAction = nil
            oldDragEvent = nil
            dragAction.flow(with: event)
        }
    }
    func stopInputTextEvent(isEndEdit: Bool = true) {
        oldInputTextKeys.removeAll()
        textAction.stopInputKey(isEndEdit: isEndEdit)
    }
    func stopInputKeyEvent() {
        if var event = oldInputKeyEvent, let inputKeyAction {
            event.phase = .ended
            self.inputKeyAction = nil
            oldInputKeyEvent = nil
            inputKeyAction.flow(with: event)
        }
    }
    func updateActionNode() {
        zoomAction?.updateNode()
        scrollAction?.updateNode()
        swipeAction?.updateNode()
        dragAction?.updateNode()
        inputKeyAction?.updateNode()
    }
}

final class ZoomAction: PinchEventAction {
    let rootAction: RootAction, rootView: RootView
    
    init(_ rootAction: RootAction) {
        self.rootAction = rootAction
        rootView = rootAction.rootView
    }
    
    let correction = 3.25
    func flow(with event: PinchEvent) {
        guard event.magnification != 0 else { return }
        let oldIsEditingSheet = rootView.isEditingSheet
        
        var transform = rootView.pov.transform
        let p = event.screenPoint * rootView.screenToWorldTransform
        let log2Scale = transform.log2Scale
        let newLog2Scale = (log2Scale - (event.magnification * correction))
            .clipped(min: RootView.minPOVLog2Scale,
                     max: RootView.maxPOVLog2Scale) - log2Scale
        transform.translate(by: -p)
        transform.scale(byLog2Scale: newLog2Scale)
        transform.translate(by: p)
        rootView.pov = RootView.clippedPOV(from: .init(transform))
        
        if oldIsEditingSheet != rootView.isEditingSheet {
            rootAction.textAction.moveEndInputKey()
            rootView.updateTextCursor()
        }
        
        rootView.updateSelectedNodesWithScale()
        rootView.updateFindingNodes()
    }
}

final class RotateAction: RotateEventAction {
    let rootAction: RootAction, rootView: RootView
    
    init(_ rootAction: RootAction) {
        self.rootAction = rootAction
        rootView = rootAction.rootView
    }
    
    private var cursorTimer: (any DispatchSourceTimer)?
    private var oldRotation = 0.0
    
    let correction = .pi / 50.0, clipD = .pi / 8.0
    var isClipped = false, worldCenterP = Point()
    func flow(with event: RotateEvent) {
        switch event.phase {
        case .began:
            isClipped = false
            worldCenterP = event.screenPoint * rootView.screenToWorldTransform
            oldRotation = rootView.pov.rotation
        default: break
        }
        
        if !isClipped && event.rotationQuantity != 0 {
            var transform = rootView.pov.transform
            let p = worldCenterP
            let r = transform.angle
            let rotation = r - event.rotationQuantity * correction
            let nr: Double
            if (rotation < clipD && rotation >= 0 && r < 0)
                || (rotation > -clipD && rotation <= 0 && r > 0) {
                
                nr = 0
                Feedback.performAlignment()
                isClipped = true
            } else {
                nr = rotation.loopedRotation
            }
            transform.translate(by: -p)
            transform.rotate(by: nr - r)
            transform.translate(by: p)
            var pov = RootView.clippedPOV(from: .init(transform))
            if isClipped {
                pov.rotation = 0
                rootView.pov = pov
            } else {
                rootView.pov = pov
            }
        }
        
        switch event.phase {
        case .began:
            cursorTimer = DispatchSource.scheduledTimer(withTimeInterval: 1 / 60) { [weak self] in
                DispatchQueue.main.async { [weak self] in
                    guard let self, !(self.cursorTimer?.isCancelled ?? true) else { return }
                    let rootView = self.rootView
                    guard rootView.pov.rotation != self.oldRotation else { return }
                    self.oldRotation = rootView.pov.rotation
                    if rootView.pov.rotation != 0 {
                        rootView.defaultCursor = Cursor.rotate(rotation: -rootView.pov.rotation + .pi / 2)
                        rootView.cursor = rootView.defaultCursor
                    } else {
                        rootView.defaultCursor = .drawLine
                        rootView.cursor = rootView.defaultCursor
                    }
                }
            }
        case .changed: break
        case .ended:
            cursorTimer?.cancel()
            
            if rootView.pov.rotation != 0 {
                rootView.defaultCursor = Cursor.rotate(rotation: -rootView.pov.rotation + .pi / 2)
                rootView.cursor = rootView.defaultCursor
            } else {
                rootView.defaultCursor = .drawLine
                rootView.cursor = rootView.defaultCursor
            }
        }
    }
}

final class ScrollAction: ScrollEventAction {
    let rootAction: RootAction, rootView: RootView
    
    init(_ rootAction: RootAction) {
        self.rootAction = rootAction
        rootView = rootAction.rootView
    }
    
    enum SnapType {
        case began, none, x, y
    }
    private let correction = 1.0
    private let updateSpeed = 1000.0
    private var isHighSpeed = false, oldTime = 0.0, oldDeltaPoint = Point()
    private var oldSpeedTime = 0.0, oldSpeedDistance = 0.0, oldSpeed = 0.0
    func flow(with event: ScrollEvent) {
        switch event.phase {
        case .began:
            oldTime = event.time
            oldSpeedTime = oldTime
            oldDeltaPoint = Point()
            oldSpeedDistance = 0.0
            oldSpeed = 0.0
        case .changed:
            guard !event.scrollDeltaPoint.isEmpty else { return }
            let dt = event.time - oldTime
            var dp = event.scrollDeltaPoint.mid(oldDeltaPoint)
            if rootView.pov.rotation != 0 {
                dp = dp * Transform(rotation: rootView.pov.rotation)
            }
            
            oldDeltaPoint = event.scrollDeltaPoint
            
            let length = dp.length()
            let lengthDt = length / dt
            
            var transform = rootView.pov.transform
            let newPoint = dp * correction * transform.absXScale
            
            let oldPosition = transform.position
            let newP = RootView.clippedPOVPosition(from: oldPosition - newPoint) - oldPosition
            
            transform.translate(by: newP)
            rootView.pov = .init(transform)
            
            rootView.isUpdateWithCursorPosition = lengthDt < updateSpeed / 2
            rootView.updateWithCursorPosition()
            if !rootView.isUpdateWithCursorPosition {
                rootView.textCursorNode.isHidden = true
                rootView.textMaxTypelineWidthNode.isHidden = true
            }
            
            oldTime = event.time
        case .ended:
            if !rootView.isUpdateWithCursorPosition {
                rootView.isUpdateWithCursorPosition = true
                rootView.updateWithCursorPosition()
            }
            break
        }
    }
}

final class SelectByRangeAction: DragEventAction {
    let action: SelectAction
    
    init(_ rootAction: RootAction) {
        action = SelectAction(rootAction)
    }
    
    func flow(with event: DragEvent) {
        action.select(with: event, isUnselect: false)
    }
    func updateNode() {
        action.updateNode()
    }
}
final class UnselectByRangeAction: DragEventAction {
    let action: SelectAction
    
    init(_ rootAction: RootAction) {
        action = SelectAction(rootAction)
    }
    
    func flow(with event: DragEvent) {
        action.select(with: event, isUnselect: true)
    }
    func updateNode() {
        action.updateNode()
    }
}
final class SelectAction: Action {
    let rootAction: RootAction, rootView: RootView
    let isEditingSheet: Bool
    
    init(_ rootAction: RootAction) {
        self.rootAction = rootAction
        rootView = rootAction.rootView
        isEditingSheet = rootView.isEditingSheet
    }
    
    struct Capture {
        var selectedLineIs: [Int]
        var selectedPlaneIs: [Int]
        var selectedContentIs: [Int]
        var selectedNotePitSprolIs: [Int : [Int : Set<Int>]]
        var selectedTextRanegs: [Int: [Range<String.Index>]]
    }
    
    private var firstP = Point(), selectKeyframeAction: SelectKeyframeAction?,
                captures = [SheetView: Capture](), firstSelectedSheetIDs = [UUID](),
                firstSheetView: SheetView?, firstTextI: Int?
    private let node = Node(lineType: .color(.selected), fillType: .color(.subSelected))
    let snappedDistance = 3.5
    
    func select(with event: DragEvent, isUnselect: Bool) {
        let p = rootView.convertScreenToWorld(event.screenPoint)
        switch event.phase {
        case .began:
            if let sheetView = rootView.sheetView(at: p),
               sheetView.animationView.containsTimeline(sheetView.animationView.timelineNode.convertFromWorld(p),
                                                        scale: rootView.screenToWorldScale) {
                
                selectKeyframeAction = .init(rootAction)
                selectKeyframeAction?.select(with: event, isUnselect: isUnselect)
                return
            }
            
            node.lineType = .color(!isUnselect ? .selected : .diselected)
            node.fillType = .color(!isUnselect ? .subSelected : .subDiselected)
            
            rootView.cursor = .arrow
            firstP = p
            node.lineWidth = rootView.worldLineWidth
            node.path = .init(.init(p, distance: 0))
            rootView.node.append(child: node)
            
            if !isEditingSheet {
                firstSelectedSheetIDs = rootView.world.selectedSheetIDs
            } else if let sheetView = rootView.sheetView(at: p),
                      let ti = sheetView.textIndex(at: sheetView.convertFromWorld(p),
                                                   scale: rootView.screenToWorldScale) {
                firstSheetView = sheetView
                firstTextI = ti
                node.isHidden = true
            }
        case .changed:
            if let selectKeyframeAction {
                selectKeyframeAction.select(with: event, isUnselect: isUnselect)
                return
            }
            
            let rect = AABB(firstP, p).rect
            node.path = .init(rect)
            
            if rootView.isEditingSheet, let sheetView = firstSheetView,
                let ti = firstTextI, ti < sheetView.model.texts.count {
                
                let capture: Capture
                if let aCapture = captures[sheetView] {
                    capture = aCapture
                } else {
                    let aCapture = Capture(selectedLineIs: sheetView.keyframeView.selectedLineIs,
                          selectedPlaneIs: sheetView.keyframeView.selectedPlaneIs,
                          selectedContentIs: sheetView.selectedContentIs,
                          selectedNotePitSprolIs: sheetView.scoreView.selectedNotePitSprolIs,
                          selectedTextRanegs: sheetView.textsView.elementViews.enumerated().reduce(into: .init()) { $0[$1.offset] = $1.element.selectedRanges })
                    captures[sheetView] = aCapture
                    capture = aCapture
                }
                
                let textView = sheetView.textsView.elementViews[ti]
                guard let oRanges = capture.selectedTextRanegs[ti] else { return }
                let nRect = textView.convertFromWorld(rect)
                guard textView.intersectsHalf(nRect) else { return }
                let tfp = textView.convertFromWorld(firstP)
                let tlp = textView.convertFromWorld(p)
                
                guard let fi = textView.characterIndexWithOutOfBounds(for: tfp),
                      let li = textView.characterIndexWithOutOfBounds(for: tlp) else { return }
                let range = fi < li ? fi ..< li : li ..< fi
                
                var nRanges = oRanges
                if isUnselect {
                    Range.subtracting(range, in: &nRanges)
                } else {
                    Range.union(range, in: &nRanges)
                }
                textView.selectedRanges = nRanges
            } else if rootView.isEditingSheet {
                for v in rootView.sheetViewValues {
                    guard rootView.sheetFrame(with: v.key).intersects(rect),
                          let sheetView = v.value.sheetView else { continue }
                    
                    let capture: Capture
                    if let aCapture = captures[sheetView] {
                        capture = aCapture
                    } else {
                        let aCapture = Capture(selectedLineIs: sheetView.keyframeView.selectedLineIs,
                              selectedPlaneIs: sheetView.keyframeView.selectedPlaneIs,
                              selectedContentIs: sheetView.selectedContentIs,
                              selectedNotePitSprolIs: sheetView.scoreView.selectedNotePitSprolIs,
                              selectedTextRanegs: sheetView.textsView.elementViews.enumerated().reduce(into: .init()) { $0[$1.offset] = $1.element.selectedRanges })
                        captures[sheetView] = aCapture
                        capture = aCapture
                    }
                    
                    let sheetRect = sheetView.convertFromWorld(rect)
                    
                    let scoreView = sheetView.scoreView
                    if scoreView.model.enabled {
                        let score = sheetView.scoreView.model
                        let scoreP = scoreView.convertFromWorld(firstP)
                        let scoreRect = scoreView.convertFromWorld(rect)
                        
                        let nNotePitSprolIs: [Int : [Int : Set<Int>]]
                        if let noteI = scoreView.noteIInTone(at: scoreP),
                           scoreView.isEditTone(from: score.notes[noteI]) {
                            let note = score.notes[noteI]
                            let toneFrames = scoreView.toneFrames(from: note)
                            nNotePitSprolIs = [noteI: toneFrames.reduce(into: .init()) { (v, tf) in
                                tf.pitIs.forEach { pitI in
                                    let pit = note.pits[pitI]
                                    for sprolI in pit.tone.spectlope.sprols.count.range {
                                        if scoreRect.contains(scoreView.sprolPosition(atSprol: sprolI, atPit: pitI, at: noteI, atY: tf.frame.minY)) {
                                            if v[pitI] != nil {
                                                v[pitI]?.insert(sprolI)
                                            } else {
                                                v[pitI] = [sprolI]
                                            }
                                        }
                                    }
                                }
                            }]
                        } else {
                            let noteIs = (0 ..< scoreView.model.notes.count).filter {
                                scoreView.intersectsNote(scoreRect, at: $0)
                            }
                            nNotePitSprolIs = noteIs.reduce(into: .init()) {
                                let note = score.notes[$1]
                                $0[$1] = note.pits.count == 1 ?
                                [0: []] :
                                note.pits.count.range.filter {
                                    scoreRect.contains(scoreView.pitPosition(atPit: $0, from: note))
                                }.reduce(into: .init()) { $0[$1] = [] }
                            }
                        }
                        
                        if isUnselect {
                            let oNotePitSprolIs = capture.selectedNotePitSprolIs
                            sheetView.scoreView.selectedNotePitSprolIs
                            = oNotePitSprolIs.merging(nNotePitSprolIs) { v0, v1 in
                                v0.merging(v1) { w0, w1 in w0.subtracting(w1) }
                            }
                        } else {
                            let oNotePitSprolIs = capture.selectedNotePitSprolIs
                            sheetView.scoreView.selectedNotePitSprolIs
                            = oNotePitSprolIs.merging(nNotePitSprolIs) { v0, v1 in
                                v0.merging(v1) { w0, w1 in w0.union(w1) }
                            }
                        }
                    }
                    
                    let oSelectedLineIs = Set(capture.selectedLineIs)
                    let nSelectedLineIs = sheetView.linesView.elementViews.enumerated().compactMap {
                        $0.element.intersects(sheetRect) ? $0.offset : nil
                    }
                    sheetView.keyframeView.selectedLineIs
                    = (isUnselect ? oSelectedLineIs.subtracting(nSelectedLineIs) :
                        oSelectedLineIs.union(nSelectedLineIs)).sorted()
                    
                    let sheetRectPath = Path(sheetRect)
                    let oSelectedPlaneIs = Set(capture.selectedPlaneIs)
                    let nSelectedPlaneIs = sheetView.planesView.elementViews.enumerated().compactMap {
                        sheetRectPath.contains($0.element.node.path) ? $0.offset : nil
                    }
                    sheetView.keyframeView.selectedPlaneIs
                    = (isUnselect ? oSelectedPlaneIs.subtracting(nSelectedPlaneIs) :
                        oSelectedPlaneIs.union(nSelectedPlaneIs)).sorted()
                    
                    let oSelectedContentIs = Set(capture.selectedContentIs)
                    let nSelectedContentIs = sheetView.contentsView.elementViews.enumerated().compactMap { (ci, contentView) in
                        if let b = contentView.transformedBounds,
                           sheetRectPath.intersects(b) { ci } else { nil }
                    }
                    sheetView.selectedContentIs
                    = (isUnselect ? oSelectedContentIs.subtracting(nSelectedContentIs) :
                        oSelectedContentIs.union(nSelectedContentIs)).sorted()
                    
                    for (ti, textView) in sheetView.textsView.elementViews.enumerated() {
                         guard let oRanges = capture.selectedTextRanegs[ti] else { continue }
                        let nRect = textView.convertFromWorld(rect)
                        guard textView.intersectsHalf(nRect) else { continue }
                        let tfp = textView.convertFromWorld(firstP)
                        let tlp = textView.convertFromWorld(p)
                        
                        guard let fi = textView.characterIndexWithOutOfBounds(for: tfp),
                              let li = textView.characterIndexWithOutOfBounds(for: tlp) else { continue }
                        let range = fi < li ? fi ..< li : li ..< fi
                        
                        var nRanges = oRanges
                        if isUnselect {
                            Range.subtracting(range, in: &nRanges)
                        } else {
                            Range.union(range, in: &nRanges)
                        }
                        textView.selectedRanges = nRanges
                    }
                    
                    rootView.updateSelectedFrame()
                }
            } else {
                let oSIDs = Set(firstSelectedSheetIDs)
                let nSIDs = rootView.world.sheetIDs.filter {
                    rect.intersects(rootView.sheetFrame(with: $0.key))
                }.map { $0.value }
                rootView.world.selectedSheetIDs
                = (isUnselect ? oSIDs.subtracting(nSIDs) : oSIDs.union(nSIDs)).sorted()
                rootView.updateSelected()
            }
            
        case .ended:
            if let selectKeyframeAction {
                selectKeyframeAction.select(with: event, isUnselect: isUnselect)
                return
            }
            
            node.removeFromParent()
            
            if firstSelectedSheetIDs != rootView.world.selectedSheetIDs {
                rootView.newUndoGroup()
                rootView.capture(rootView.world.selectedSheetIDs, old: firstSelectedSheetIDs)
            }
            
            rootView.cursor = rootView.defaultCursor
        }
    }
}
final class SelectKeyframeAction: Action {
    let rootAction: RootAction, rootView: RootView
    let isEditingSheet: Bool
    
    init(_ rootAction: RootAction) {
        self.rootAction = rootAction
        rootView = rootAction.rootView
        isEditingSheet = rootView.isEditingSheet
    }
    
    private var sheetView: SheetView?
    private var beganRootBeatPosition = Animation.RootBeatPosition(),
                movedBeganRootBeatPosition = Animation.RootBeatPosition(),
                beganSelectedRootBeat = Rational(0),
                beganSelectedFrameIndexes = [Int]()
    private var lastRootBeats = [(sec: Double, rootBeat: Rational)](capacity: 128)
    private var minLastSec = 1 / 12.0
    
    private let progressWidth = {
        let text = Text(string: "00.00", size: Font.defaultSize)
        return text.frame?.width ?? 40
    } ()
    
    private func updateSelected(fromRootBeeat nRootBeat: Rational,
                                in animationView: AnimationView, isUnselect: Bool) {
        var isSelects = [Bool](repeating: false, count: animationView.model.keyframes.count)
        beganSelectedFrameIndexes.forEach { isSelects[$0] = true }
        let beganRootIndex = animationView.model.nearestRootIndex(atRootBeat: beganSelectedRootBeat)
        let ni = animationView.model.rootIndex(atRootBeat: nRootBeat)
        let range = beganRootIndex <= ni ? beganRootIndex ... ni : ni ... beganRootIndex
        for i in range {
            let ki = animationView.model.index(atRoot: i)
            isSelects[ki] = !isUnselect
        }
        
        let fis = isSelects.enumerated().compactMap { $0.element ? $0.offset : nil }
        animationView.selectedIs = fis
    }
    
    func select(with event: DragEvent, isUnselect: Bool) {
        guard isEditingSheet else {
            rootAction.keepOut(with: event)
            return
        }
        if rootAction.isPlaying(with: event) {
            rootAction.stopPlaying(with: event)
        }
        
        let p = rootView.convertScreenToWorld(event.screenPoint)
        switch event.phase {
        case .began:
            rootView.cursor = .arrow
            if let sheetView = rootView.sheetView(at: p),
               sheetView.animationView.containsTimeline(sheetView.animationView.timelineNode.convertFromWorld(p),
                                                        scale: rootView.screenToWorldScale) {
                self.sheetView = sheetView
                let animationView = sheetView.animationView
                beganRootBeatPosition = sheetView.rootBeatPosition
                
                var rbp = movedBeganRootBeatPosition
                rbp.beat = animationView.beat(atX: sheetView.convertFromWorld(p).x)
                - animationView.model.beatRange.start
                let nRootBeat = animationView.model.rootBeat(at: rbp)
                if animationView.rootBeat != nRootBeat {
                    sheetView.rootBeat = nRootBeat
                    rootAction.updateActionNode()
                    rootView.updateSelectedFrame()
                }
                animationView.shownInterTypeKeyframeIndex = animationView.model.index
                
                movedBeganRootBeatPosition = sheetView.rootBeatPosition
                beganSelectedFrameIndexes = animationView.selectedIs
                beganSelectedRootBeat = nRootBeat
                lastRootBeats.append((event.time, beganSelectedRootBeat))
                var isSelects = [Bool](repeating: false, count: animationView.model.keyframes.count)
                let beganRootIndex = animationView.model.nearestRootIndex(atRootBeat: beganSelectedRootBeat)
                let ni = animationView.model.nearestRootIndex(atRootBeat: nRootBeat)
                let range = beganRootIndex <= ni ? beganRootIndex ... ni : ni ... beganRootIndex
                
                for i in range {
                    let ki = animationView.model.index(atRoot: i)
                    isSelects[ki] = true
                }
                beganSelectedFrameIndexes.forEach { isSelects[$0] = true }
                let fis = isSelects.enumerated().compactMap { $0.element ? $0.offset : nil }
                animationView.selectedIs = fis
                
                self.rootView.cursor = self.rootView.cursor(from: sheetView.currentKeyframeString(),
                                                  progress: sheetView.currentTimeProgress(),
                                                  progressWidth: self.progressWidth)
            } else {
                rootView.cursor = rootView.cursor(from: Animation.timeString(fromTime: 0, frameRate: 0))
            }
        case .changed:
            if let sheetView {
                let animationView = sheetView.animationView
                let oldKI = animationView.model.index
                var bp = movedBeganRootBeatPosition
                bp.beat = animationView.beat(atX: sheetView.convertFromWorld(p).x)
                - animationView.model.beatRange.start
                let nRootBeat = animationView.model.rootBeat(at: bp)
                
                if sheetView.rootBeat != nRootBeat {
                    sheetView.rootBeat = nRootBeat
                    rootAction.updateActionNode()
                    rootView.updateSelectedFrame()
                    
                    if oldKI != animationView.model.index {
                        lastRootBeats.append((event.time, nRootBeat))
                        for (i, v) in lastRootBeats.enumerated().reversed() {
                            if event.time - v.sec > minLastSec {
                                if i > 0 {
                                    lastRootBeats.removeFirst(i - 1)
                                }
                                break
                            }
                        }
                        
                        animationView.shownInterTypeKeyframeIndex = animationView.model.index
                        
                        updateSelected(fromRootBeeat: nRootBeat, in: animationView,
                                       isUnselect: isUnselect)
                        
                        self.rootView.cursor = self.rootView.cursor(from: sheetView.currentKeyframeString(),
                                                          progress: sheetView.currentTimeProgress(),
                                                          progressWidth: self.progressWidth)
                    }
                }
            }
        case .ended:
            if let sheetView {
                let animationView = sheetView.animationView
                animationView.shownInterTypeKeyframeIndex = nil
                
                sheetView.rootBeatPosition = beganRootBeatPosition
                
                for (sec, rootBeat) in lastRootBeats.reversed() {
                    if event.time - sec > minLastSec {
                        let animationView = sheetView.animationView
                        updateSelected(fromRootBeeat: rootBeat, in: animationView,
                                       isUnselect: isUnselect)
                        break
                    }
                }
            }
            
            rootView.cursor = rootView.defaultCursor
        }
    }
}
final class UnselectAllAction: InputKeyEventAction {
    let rootAction: RootAction, rootView: RootView
    
    init(_ rootAction: RootAction) {
        self.rootAction = rootAction
        rootView = rootAction.rootView
    }
    
    func flow(with event: InputKeyEvent) {
        switch event.phase {
        case .began:
            rootView.cursor = .arrow
            
            rootView.closeLookingUp()
            rootView.unselect(at: rootView.convertScreenToWorld(event.screenPoint))
        case .changed:
            break
        case .ended:
            rootView.cursor = rootView.defaultCursor
        }
    }
}

final class ChangeToDraftAction: InputKeyEventAction {
    let action: DraftAction
    
    init(_ rootAction: RootAction) {
        action = DraftAction(rootAction)
    }
    
    func flow(with event: InputKeyEvent) {
        action.changeToDraft(with: event)
    }
    func updateNode() {
        action.updateNode()
    }
}
final class CutDraftAction: InputKeyEventAction {
    let action: DraftAction
    
    init(_ rootAction: RootAction) {
        action = DraftAction(rootAction)
    }
    
    func flow(with event: InputKeyEvent) {
        action.cutDraft(with: event)
    }
    func updateNode() {
        action.updateNode()
    }
}
final class DraftAction: Action {
    let rootAction: RootAction, rootView: RootView
    let isEditingSheet: Bool
    
    init(_ rootAction: RootAction) {
        self.rootAction = rootAction
        rootView = rootAction.rootView
        isEditingSheet = rootView.isEditingSheet
    }
    
    func changeToDraft(with event: InputKeyEvent) {
        guard isEditingSheet else {
            rootAction.keepOut(with: event)
            return
        }
        if rootAction.isPlaying(with: event) {
            rootAction.stopPlaying(with: event)
        }
        let sp = rootView.screenPointFromMenu ?? event.screenPoint
        let p = rootView.convertScreenToWorld(sp)
        switch event.phase {
        case .began:
            rootView.cursor = .arrow
            
            var isChanged = false
            if let sheetView = rootView.sheetViewWithSelectedNote(at: p) {
                let nis = sheetView.scoreView.selectedNotePitSprolIs.map { $0.key }.sorted()
                if !nis.isEmpty {
                    sheetView.newUndoGroup()
                    sheetView.changeToDraft(withNoteInexes: nis)
                    rootView.updateSelectedFrame()
                    isChanged = true
                }
            } else if let sheetView = rootView.sheetViewWithSelectedLine(at: p)
                        ?? rootView.sheetViewWithSelectedPlane(at: p) {
                let lis = sheetView.keyframeView.selectedLineIs
                let pis = sheetView.keyframeView.selectedPlaneIs
                if !lis.isEmpty {
                    sheetView.newUndoGroup()
                    sheetView.changeToDraft(withLineInexes: lis,
                                            planeInexes: pis)
                    rootView.updateSelectedFrame()
                    isChanged = true
                }
            } else {
                if let sheetView = rootView.sheetView(at: p) {
                    if sheetView.model.score.enabled {
                        let nis = if let i = sheetView.scoreView.noteIndex(at: sheetView.scoreView.convertFromWorld(p), scale: rootView.screenToWorldScale) {
                            [i]
                        } else {
                            (0 ..< sheetView.model.score.notes.count).map { $0 }
                        }
                        if !nis.isEmpty {
                            sheetView.newUndoGroup()
                            sheetView.changeToDraft(withNoteInexes: nis)
                            isChanged = true
                        }
                    } else {
                        isChanged = sheetView.changeToDraft(with: nil)
                    }
                }
            }
            if !isChanged {
                rootView.cursor = .arrowWith(string: "Empty".localized)
            }
        case .changed:
            break
        case .ended:
            rootView.cursor = rootView.defaultCursor
        }
    }
    
    func cutDraft(with event: InputKeyEvent) {
        guard isEditingSheet else {
            rootAction.keepOut(with: event)
            return
        }
        if rootAction.isPlaying(with: event) {
            rootAction.stopPlaying(with: event)
        }
        let sp = rootView.screenPointFromMenu ?? event.screenPoint
        let p = rootView.convertScreenToWorld(sp)
        switch event.phase {
        case .began:
            rootView.cursor = .arrow
            
            var isChanged = false
            if let sheetView = rootView.sheetView(at: p) {
                if sheetView.model.score.enabled {
                    let nis = (0 ..< sheetView.model.score.draftNotes.count).map { $0 }
                    if !nis.isEmpty {
                        let scoreView = sheetView.scoreView
                        let scoreP = scoreView.convertFromWorld(p)
                        let pitchInterval = rootView.currentPitchInterval
                        let pitch = scoreView.pitch(atY: scoreP.y, interval: pitchInterval)
                        let beatInterval = rootView.currentBeatInterval
                        let beat = scoreView.beat(atX: scoreP.x, interval: beatInterval)
                        let notes: [Note] = sheetView.model.score.draftNotes.map {
                            var note = $0
                            note.pitch -= pitch
                            note.beatRange.start -= beat
                            return note
                        }
                        
                        sheetView.newUndoGroup()
                        sheetView.removeDraftNotes(at: nis)
                        
                        Pasteboard.shared.copiedObjects = [.notesValue(.init(notes: notes, deltaPitch: pitch))]//
                        
                        isChanged = true
                    }
                } else {
                    if !sheetView.animationView.selectedIs.isEmpty {
                        sheetView.newUndoGroup()
                        let sfis = sheetView.animationView.selectedIs.sorted()
                        sheetView.removeDraftKeyLines(sfis.compactMap {
                            let lines = sheetView.model.animation.keyframes[$0].draftPicture.lines
                            return lines.isEmpty ?
                            nil :
                            IndexValue(value: Array(0 ..< lines.count), index: $0)
                        })
                        sheetView.removeDraftKeyPlanes(sfis.compactMap {
                            let planes = sheetView.model.animation.keyframes[$0].draftPicture.planes
                            return planes.isEmpty ?
                                nil :
                            IndexValue(value: Array(0 ..< planes.count), index: $0)
                        })
                        
                        isChanged = true
                    } else {
                        let object = PastableObject.picture(sheetView.model.draftPicture)
                        if !sheetView.model.draftPicture.isEmpty {
                            sheetView.newUndoGroup()
                            sheetView.removeDraft()
                            Pasteboard.shared.copiedObjects = [object]
                            
                            isChanged = true
                        }
                    }
                }
            }
            if !isChanged {
                rootView.cursor = .arrowWith(string: "Empty".localized)
            }
        case .changed:
            break
        case .ended:
            rootView.cursor = rootView.defaultCursor
        }
    }
}

final class MakeFacesAction: InputKeyEventAction {
    let action: FaceAction
    
    init(_ rootAction: RootAction) {
        action = FaceAction(rootAction)
    }
    
    func flow(with event: InputKeyEvent) {
        action.makeFaces(with: event)
    }
    func updateNode() {
        action.updateNode()
    }
}
final class CutFacesAction: InputKeyEventAction {
    let action: FaceAction
    
    init(_ rootAction: RootAction) {
        action = FaceAction(rootAction)
    }
    
    func flow(with event: InputKeyEvent) {
        action.cutFaces(with: event)
    }
    func updateNode() {
        action.updateNode()
    }
}
final class FaceAction: Action {
    let rootAction: RootAction, rootView: RootView
    let isEditingSheet: Bool
    
    init(_ rootAction: RootAction) {
        self.rootAction = rootAction
        rootView = rootAction.rootView
        isEditingSheet = rootView.isEditingSheet
    }
    
    func makeFaces(with event: InputKeyEvent) {
        guard isEditingSheet else {
            rootAction.keepOut(with: event)
            return
        }
        if rootAction.isPlaying(with: event) {
            rootAction.stopPlaying(with: event)
        }
        let sp = rootView.screenPointFromMenu ?? event.screenPoint
        let p = rootView.convertScreenToWorld(sp)
        switch event.phase {
        case .began:
            rootView.cursor = .arrow
            
            if let sheetView = rootView.sheetView(at: p), sheetView.model.score.enabled {
                let score = sheetView.scoreView.model
                let scoreP = sheetView.scoreView.convertFromWorld(p)
                let ois = sheetView.scoreView.noteIs(at: scoreP, scale: rootView.screenToWorldScale)
                let nis = ois.isEmpty ? Array(score.notes.count.range) : ois
                let nnis = nis.filter { score.notes[$0].isDefaultTone }.sorted()
                if !nnis.isEmpty {
                    var tones = [UUID: Tone]()
                    var nivs = [IndexValue<Note>]()
                    for ni in nnis {
                        var note = score.notes[ni]
                        if note.isSimpleLyric {
                            note = note.withRendable(tempo: score.tempo)
                        } else {
                            for (pi, pit) in note.pits.enumerated() {
                                if let tone = tones[pit.tone.id] {
                                    note.pits[pi].tone = tone
                                } else if pit.tone.isDefault {
                                    let tone = Tone(spectlope: .random())
                                    tones[pit.tone.id] = tone
                                    note.pits[pi].tone = tone
                                }
                            }
                        }
                        nivs.append(.init(value: note, index: ni))
                    }
                    
                    sheetView.newUndoGroup()
                    sheetView.replace(nivs)
                }
                return
            }
            
            var isChanged = false
            if let sheetView = rootView.sheetViewWithSelectedFrame(at: p)
                ?? rootView.sheetViewWithSelectedSheetValue(at: p),
               let rect = sheetView.selectedFrame {
                
                isChanged = sheetView.makeFaces(withClipping: rect,
                                                selectedKeyframeIs: [], isOutClip: true)
            } else if let sheetView = rootView.sheetViewWithSelectedKeyframe(at: p) {
                let kis = sheetView.animationView.selectedIs.sorted()
                let (frame, isAll) = rootView.frame(at: p, with: sheetView)
                if isAll {
                    isChanged = sheetView.makeFaces(withClipping: nil,
                                                    selectedKeyframeIs: kis, isOutClip: false)
                } else {
                    let f = sheetView.convertFromWorld(frame)
                    isChanged = sheetView.makeFaces(withClipping: f,
                                                    selectedKeyframeIs: kis, isOutClip: false)
                }
            } else {
                let (_, sheetView, frame, isAll) = rootView.sheetViewAndFrame(at: p)
                if let sheetView {
                    if isAll {
                        isChanged = sheetView.makeFaces(withClipping: nil,
                                                        selectedKeyframeIs: [], isOutClip: false)
                    } else {
                        let f = sheetView.convertFromWorld(frame)
                        isChanged = sheetView.makeFaces(withClipping: f,
                                                        selectedKeyframeIs: [], isOutClip: false)
                    }
                } else if let sheetView = rootView.madeSheetView(at: p) {
                    isChanged = sheetView.makeFacesFromKeyframeIndex(withClipping: nil,
                                                                     isOutClip: false,
                                                                     isNewUndoGroup: true)
                }
            }
            if !isChanged {
                rootView.cursor = .arrowWith(string: "No Update".localized)
                Sleep.start(atTime: 0.2)
            }
        case .changed:
            break
        case .ended:
            rootView.cursor = rootView.defaultCursor
        }
    }
    func cutFaces(with event: InputKeyEvent) {
        guard isEditingSheet else {
            rootAction.keepOut(with: event)
            return
        }
        if rootAction.isPlaying(with: event) {
            rootAction.stopPlaying(with: event)
        }
        let sp = rootView.screenPointFromMenu ?? event.screenPoint
        let p = rootView.convertScreenToWorld(sp)
        switch event.phase {
        case .began:
            rootView.cursor = .arrow
            
            var isChanged = false
            if let sheetView = rootView.sheetView(at: p), sheetView.model.score.enabled {
                let score = sheetView.scoreView.model
                let scoreP = sheetView.scoreView.convertFromWorld(p)
                let ois = sheetView.scoreView.noteIs(at: scoreP, scale: rootView.screenToWorldScale)
                let nis = ois.isEmpty ? Array(score.notes.count.range) : ois
                let nnis = nis
                    .filter { !score.notes[$0].isOneOvertone && !score.notes[$0].isFullNoise }
                    .sorted()
                if !nnis.isEmpty {
                    var nivs = [IndexValue<Note>]()
                    for ni in nnis {
                        var note = score.notes[ni]
                        if note.isRendableFromLyric {
                            note = note.withSimpleLyric
                        } else {
                            for (pi, pit) in note.pits.enumerated() {
                                if !pit.tone.overtone.isOne && !pit.tone.spectlope.isFullNoise {
                                    note.pits[pi].tone = .init()
                                }
                            }
                        }
                        nivs.append(.init(value: note, index: ni))
                    }
                    
                    sheetView.newUndoGroup()
                    sheetView.replace(nivs)
                    
                    isChanged = true
                }
            } else if let sheetView = rootView.sheetViewWithSelectedPlane(at: p) {
                sheetView.newUndoGroup()
                let planes = sheetView.keyframeView.selectedPlaneIs
                    .map { sheetView.model.picture.planes[$0] }
                let t = Transform(translation: -sheetView.convertFromWorld(p))
                sheetView.removePlanes(at: sheetView.keyframeView.selectedPlaneIs)
                let value = SheetValue(lines: [], planes: planes, texts: []) * t
                Pasteboard.shared.copiedObjects = [.sheetValue(value)]
                
                isChanged = true
            } else if let sheetView = rootView.sheetViewWithSelectedKeyframe(at: p) {
                let vs = sheetView.animationView.selectedIs.sorted().compactMap {
                    let planes = sheetView.model.animation.keyframes[$0].picture.planes
                    return planes.isEmpty ?
                        nil :
                    IndexValue(value: Array(0 ..< planes.count), index: $0)
                }
                if !vs.isEmpty {
                    sheetView.newUndoGroup()
                    sheetView.removeKeyPlanes(vs)
                    
                    isChanged = true
                }
            } else {
                let (_, sheetView, frame, isAll) = rootView.sheetViewAndFrame(at: p)
                if let sheetView = sheetView {
                    if isAll {
                        isChanged = sheetView.cutFaces(with: nil)
                    } else {
                        let f = sheetView.convertFromWorld(frame).inset(by: 1)
                        isChanged = sheetView.cutFaces(with: Path(f))
                    }
                }
            }
            
            if !isChanged {
                rootView.cursor = .arrowWith(string: "Empty".localized)
            }
        case .changed:
            break
        case .ended:
            rootView.cursor = rootView.defaultCursor
        }
    }
}

final class AddTimeAction: InputKeyEventAction {
    let rootAction: RootAction, rootView: RootView
    let isEditingSheet: Bool
    
    init(_ rootAction: RootAction) {
        self.rootAction = rootAction
        rootView = rootAction.rootView
        isEditingSheet = rootView.isEditingSheet
    }
    
    func flow(with event: InputKeyEvent) {
        guard isEditingSheet else {
            rootAction.keepOut(with: event)
            return
        }
        if rootAction.isPlaying(with: event) {
            rootAction.stopPlaying(with: event)
        }
        let sp = rootView.screenPointFromMenu ?? event.screenPoint
        let p = rootView.convertScreenToWorld(sp)
        switch event.phase {
        case .began:
            rootView.cursor = .arrow
            
            if let sheetView = rootView.madeSheetView(at: p) {
                let sheetP = sheetView.convertFromWorld(p)
                
                if let ci = sheetView.contentIndex(at: sheetP,
                                                   scale: rootView.screenToWorldScale) {
                   let contentView = sheetView.contentsView.elementViews[ci]
                   if contentView.model.timeOption == nil {
                       var content = contentView.model
                       let startBeat: Rational = sheetView.animationView.beat(atX: content.origin.x)
                       let tempo = sheetView.nearestTempo(at: sheetP) ?? rootView.nearestAroundTempo(at: p)
                       content.timeOption = .init(beatRange: startBeat ..< (4 + startBeat),
                                                  tempo: tempo)
                       
                       sheetView.newUndoGroup()
                       sheetView.replace(IndexValue(value: content, index: ci))
                       
                       sheetView.updatePlaying()
                   } else {
                       rootView.cursor = .arrowWith(string: "Added".localized)
                   }
               } else if let ti = sheetView.textIndex(at: sheetP,
                                                      scale: rootView.screenToWorldScale) {
                   let textView = sheetView.textsView.elementViews[ti]
                   if textView.model.timeOption == nil {
                       var text = textView.model
                       let startBeat: Rational = sheetView.animationView.beat(atX: text.origin.x)
                       let tempo = sheetView.nearestTempo(at: sheetP) ?? rootView.nearestAroundTempo(at: p)
                       text.timeOption = .init(beatRange: startBeat ..< (4 + startBeat),
                                               tempo: tempo)
                       
                       sheetView.newUndoGroup()
                       sheetView.replace([IndexValue(value: text, index: ti)])
                       
                       sheetView.updatePlaying()
                   } else {
                       rootView.cursor = .arrowWith(string: "Added".localized)
                   }
               } else if !sheetView.model.enabledAnimation {
                   if sheetView.model.score.enabled {
                       rootView.cursor = .block
                   } else {
                       sheetView.newUndoGroup(enabledKeyframeIndex: false)
                       sheetView.set(beat: 0, at: 0)
                       var option = sheetView.model.animation.option
                       option.tempo = sheetView.nearestTempo(at: sheetP) ?? rootView.nearestAroundTempo(at: p)
                       option.timelineY = sheetP.y.clipped(min: Sheet.timelineY,
                                                           max: Sheet.height - Sheet.timelineY)
                       option.enabled = true
                       sheetView.set(option)
                       
                       rootAction.updateActionNode()
                   }
               } else {
                   rootView.cursor = .arrowWith(string: "Added".localized)
               }
            } else {
                rootView.cursor = .arrowWith(string: "Added".localized)
            }
        case .changed:
            break
        case .ended:
            rootView.cursor = rootView.defaultCursor
        }
    }
}

final class AddScoreAction: InputKeyEventAction {
    let rootAction: RootAction, rootView: RootView
    let isEditingSheet: Bool
    
    init(_ rootAction: RootAction) {
        self.rootAction = rootAction
        rootView = rootAction.rootView
        isEditingSheet = rootView.isEditingSheet
    }
    
    func flow(with event: InputKeyEvent) {
        guard isEditingSheet else {
            rootAction.keepOut(with: event)
            return
        }
        if rootAction.isPlaying(with: event) {
            rootAction.stopPlaying(with: event)
        }
        let sp = rootView.screenPointFromMenu ?? event.screenPoint
        let p = rootView.convertScreenToWorld(sp)
        switch event.phase {
        case .began:
            rootView.cursor = .arrow
            
            if let sheetView = rootView.madeSheetView(at: p), !sheetView.model.score.enabled {
                if sheetView.model.animation.enabled {
                    rootView.cursor = .block
                } else {
                    let inP = sheetView.convertFromWorld(p)
                    let tempo = sheetView.nearestTempo(at: inP) ?? rootView.nearestAroundTempo(at: p)
                    let option = ScoreOption(tempo: tempo, timelineY: Sheet.timelineY, enabled: true)
                    
                    sheetView.newUndoGroup()
                    sheetView.set(option)
                    
                    rootAction.updateActionNode()
                }
            } else {
                rootView.cursor = .arrowWith(string: "Added".localized)
            }
        case .changed:
            break
        case .ended:
            rootView.cursor = rootView.defaultCursor
        }
    }
}

final class JustFitAction: InputKeyEventAction {
    let rootAction: RootAction, rootView: RootView
    let isEditingSheet: Bool
    
    init(_ rootAction: RootAction) {
        self.rootAction = rootAction
        rootView = rootAction.rootView
        isEditingSheet = rootView.isEditingSheet
    }
    
    func flow(with event: InputKeyEvent) {
        guard isEditingSheet else {
            rootAction.keepOut(with: event)
            return
        }
        if rootAction.isPlaying(with: event) {
            rootAction.stopPlaying(with: event)
        }
        let sp = rootView.screenPointFromMenu ?? event.screenPoint
        let p = rootView.convertScreenToWorld(sp)
        switch event.phase {
        case .began:
            rootView.cursor = .arrow
            
            var isChanged = false
            if let sheetView = rootView.sheetView(at: p), sheetView.model.score.enabled {
                let scoreView = sheetView.scoreView
                let score = scoreView.model
                
                let scoreP = scoreView.convertFromWorld(p)
                if let noteI = scoreView.noteIndex(at: scoreP,
                                                   scale: rootView.screenToWorldScale) {
                    let beat: Double = scoreView.beat(atX: scoreP.x)
                    let result = score.notes[noteI].pitResult(atBeat: beat - Double(score.notes[noteI].beatRange.start))
                    let pitch = (result.pitch.rationalValue(intervalScale: rootView.currentPitchInterval) + result.notePitch).rounded()
                    var nivs = [IndexValue<Note>]()
                    
                    let nis: [Int]
                    if scoreView.selectedNotePitSprolIs.isEmpty {
                        let beat: Rational = scoreView.beat(atX: scoreP.x)
                        nis = scoreView.model.notes.enumerated()
                            .filter { $0.element.beatRange.contains(beat) }.map { $0.offset }
                    } else {
                        nis = scoreView.selectedNotePitSprolIs.map { $0.key }.sorted()
                    }
                    
                    for ni in nis {
                        var note = score.notes[ni]
                        let oldNote = note
                        if note.pits.count > 1 {
                            let result = note.pitResult(atBeat: beat - Double(note.beatRange.start))
                            if result.isStraight {
                                note.pitch.round()
                                let nPitch = Chord.approximationJustIntonation(pitch: note.pits[result.pitI].pitch + note.pitch - pitch) + pitch - note.pitch
                                note.pits[result.pitI].pitch = nPitch
                                if result.pitI + 1 < note.pits.count {
                                    note.pits[result.pitI + 1].pitch = nPitch
                                }
                                if oldNote.pits[result.pitI].pitch != nPitch {
                                    nivs.append(.init(value: note, index: ni))
                                }
                            }
                        } else {
                            note.pits[0].pitch.round()
                            note.pitch = Chord.approximationJustIntonation(pitch: note.firstPitch - pitch) + pitch - note.pits[0].pitch
                            if oldNote.pitch != note.pitch {
                                nivs.append(.init(value: note, index: ni))
                            }
                        }
                    }
                    if !nivs.isEmpty {
                        sheetView.newUndoGroup()
                        sheetView.replace(nivs)
                        
                        isChanged = true
                    }
                }
            }
            
            if !isChanged {
                rootView.cursor = .arrowWith(string: "Empty".localized)
            }
        case .changed:
            break
        case .ended:
            rootView.cursor = rootView.defaultCursor
        }
    }
}
