// Copyright 2026 Cii
//
// This file is part of Shikisen.
//
// Shikisen is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Shikisen is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Shikisen.  If not, see <http://www.gnu.org/licenses/>.

import Dispatch
import struct Foundation.UUID

final class LineView<T: BinderProtocol>: BindableView, @unchecked Sendable {
    typealias Model = Line
    typealias Binder = T
    let binder: Binder
    var keyPath: BinderKeyPath
    let node: Node, pointNode = Node(isHidden: true, isEnabledCloneChildren: false)
    fileprivate var captureColor: Color?
    
    init(binder: Binder, keyPath: BinderKeyPath) {
        self.binder = binder
        self.keyPath = keyPath
        
        node = Node(children: [pointNode],
                    path: Path(binder[keyPath: keyPath]),
                    lineWidth: binder[keyPath: keyPath].size,
                    lineType: .color(binder[keyPath: keyPath].uuColor.value))
        pointNode.children = pointNodes()
    }
    
    func updateWithModel() {
        updateColor()
        updatePath()
        node.lineWidth = model.size
    }
    var isSelected = false {
        didSet {
            guard isSelected != oldValue else { return }
            updateColor()
        }
    }
    var isHiddenSelected = false {
        didSet {
            guard isHiddenSelected != oldValue else { return }
            updateColor()
        }
    }
    var isHiddenPoints = true {
        didSet {
            guard isHiddenPoints != oldValue else { return }
            pointNode.isHidden = isHiddenPoints
        }
    }
    
    func pointNodes() -> [Node] {
        if case .line(let line) = node.path.pathlines.first?.elements.first,
           case .color(let color) = node.lineType {
            let pointColor: Color = color.lightness < 30 ? .lightPoint : .darkPoint
            return line.mainControlSequence.map {
                let pointNode = Node.point.clone
                pointNode.pose.position = $0.point
                pointNode.fillType = .color(pointColor)
                return pointNode
            }
        } else {
            return []
        }
    }
    
    func updateColor() {
        let uuColor = model.uuColor
        node.lineType = .color(isSelected && !isHiddenSelected ?
                               (uuColor == Line.defaultUUColor ?
                                .selected :
                                    .linear(.selected, uuColor.value,
                                            t: uuColor.value.lightness / 100 * 0.5)) :
                                uuColor.value)
        
        if case .color(let color) = node.lineType {
            let pointColor: Color = color.lightness < 30 ? .lightPoint : .darkPoint
            pointNode.children.forEach { $0.fillType = .color(pointColor) }
        }
    }
    func updatePath() {
        node.path = Path(model)
        
        pointNode.children = pointNodes()
    }
    var uuColor: UUColor {
        get { model.uuColor }
        set {
            unupdateModel.uuColor = newValue
            updateColor()
        }
    }
    func intersects(_ otherRect: Rect) -> Bool {
        guard let b = node.bounds else { return false }
        guard b.intersects(otherRect) else {
            return false
        }
        if otherRect.contains(b) {
            return true
        }
        let line = model
        if otherRect.contains(line.firstPoint) {
            return true
        } else {
            let x0y0 = otherRect.origin
            let x1y0 = Point(otherRect.maxX, otherRect.minY)
            let x0y1 = Point(otherRect.minX, otherRect.maxY)
            let x1y1 = Point(otherRect.maxX, otherRect.maxY)
            func intersects(_ edge: Edge) -> Bool {
                for b in line.bezierSequence {
                    if b.intersects(edge) {
                        return true
                    }
                }
                return false
            }
            return intersects(Edge(x0y0, x1y0))
                || intersects(Edge(x1y0, x1y1))
                || intersects(Edge(x1y1, x0y1))
                || intersects(Edge(x0y1, x0y0))
        }
    }
}
typealias SheetLineView = LineView<SheetBinder>

final class PlaneView<T: BinderProtocol>: BindableView, @unchecked Sendable {
    typealias Model = Plane
    typealias Binder = T
    let binder: Binder
    var keyPath: BinderKeyPath
    let node: Node
    
    init(binder: Binder, keyPath: BinderKeyPath) {
        self.binder = binder
        self.keyPath = keyPath
        
        node = Node(path: binder[keyPath: keyPath].path,
                    fillType: .color(binder[keyPath: keyPath].uuColor.value))
        node.isCPUFillAntialias = false
    }
    
    func updateWithModel() {
        updateColor()
        updatePath()
    }
    var isSelected = false {
        didSet {
            guard isSelected != oldValue else { return }
            updateColor()
        }
    }
    var isHiddenSelected = false {
        didSet {
            guard isHiddenSelected != oldValue else { return }
            updateColor()
        }
    }
    func updateColor() {
        node.fillType = .color(isSelected && !isHiddenSelected ? .selected + model.uuColor.value :  model.uuColor.value)
    }
    func updatePath() {
        node.path = model.path
    }
    var uuColor: UUColor {
        get { model.uuColor }
        set {
            unupdateModel.uuColor = newValue
            updateColor()
        }
    }
}
typealias SheetPlaneView = PlaneView<SheetBinder>

typealias SheetTextView = TextView<SheetBinder>
typealias SheetContentView = ContentView<SheetBinder>

final class BorderView<T: BinderProtocol>: BindableView, @unchecked Sendable {
    typealias Model = Border
    typealias Binder = T
    let binder: Binder
    var keyPath: BinderKeyPath
    let node: Node
    
    var bounds = Sheet.defaultBounds {
        didSet {
            guard bounds != oldValue else { return }
            updateWithModel()
        }
    }
    
    init(binder: Binder, keyPath: BinderKeyPath) {
        self.binder = binder
        self.keyPath = keyPath
        
        node = Node(path: binder[keyPath: keyPath].path(with: bounds),
                    lineWidth: 1, lineType: .color(.subBorder))
    }
    
    var screenToWorldScale = 1.0 {
        didSet {
            guard screenToWorldScale != oldValue else { return }
            if screenToWorldScale < 0.5 {
                node.lineWidth = screenToWorldScale * 2
            } else if node.lineWidth != 1 {
                node.lineWidth = 1
            }
        }
    }
    func updateWithModel() {
        node.path = model.path(with: bounds)
    }
}
typealias SheetBorderView = BorderView<SheetBinder>

final class KeyframeView: BindableView, @unchecked Sendable {
    typealias Model = Keyframe
    typealias Binder = SheetBinder
    let binder: Binder
    var keyPath: BinderKeyPath {
        didSet {
            linesView.keyPath = keyPath.appending(path: \Model.picture.lines)
            planesView.keyPath = keyPath.appending(path: \Model.picture.planes)
            draftLinesView.keyPath = keyPath.appending(path: \Model.draftPicture.lines)
            draftPlanesView.keyPath = keyPath.appending(path: \Model.draftPicture.planes)
        }
    }
    let node: Node
    
    let linesView: ArrayView<SheetLineView>
    let planesView: ArrayView<SheetPlaneView>
    let draftLinesView: ArrayView<SheetLineView>
    let draftPlanesView: ArrayView<SheetPlaneView>
    
    var isSelected = false
    
    var selectedLineIs: [Int] {
        get {
            linesView.elementViews.count.range.filter { linesView.elementViews[$0].isSelected }
        }
        set {
            let value = Set(newValue)
            linesView.elementViews.enumerated().forEach {
                $0.element.isSelected = value.contains($0.offset)
            }
        }
    }
    var selectedPlaneIs: [Int] {
        get {
            planesView.elementViews.count.range.filter { planesView.elementViews[$0].isSelected }
        }
        set {
            let value = Set(newValue)
            planesView.elementViews.enumerated().forEach {
                $0.element.isSelected = value.contains($0.offset)
            }
        }
    }
    
    func showSelected() {
        linesView.elementViews.forEach { $0.isHiddenSelected = false }
        planesView.elementViews.forEach { $0.isHiddenSelected = false }
    }
    func hideSelected() {
        linesView.elementViews.forEach { $0.isHiddenSelected = true }
        planesView.elementViews.forEach { $0.isHiddenSelected = true }
    }
    
    init(binder: Binder, keyPath: BinderKeyPath) {
        self.binder = binder
        self.keyPath = keyPath
        
        linesView = ArrayView(binder: binder,
                              keyPath: keyPath.appending(path: \Model.picture.lines))
        planesView = ArrayView(binder: binder,
                               keyPath: keyPath.appending(path: \Model.picture.planes))
        draftLinesView = ArrayView(binder: binder,
                                   keyPath: keyPath.appending(path: \Model.draftPicture.lines))
        draftPlanesView = ArrayView(binder: binder,
                                    keyPath: keyPath.appending(path: \Model.draftPicture.planes))
        
        draftLinesView.node.isClippingChildrenLines = true
        draftLinesView.node.path = .init(Sheet.defaultBounds)
        draftLinesView.node.fillType = .color(.draftLine)
        
        node = Node(children: [draftPlanesView.node, draftLinesView.node,
                               planesView.node, linesView.node])
        
        updateDraft()
    }
    
    func updateWithModel() {
        linesView.updateWithModel()
        planesView.updateWithModel()
        draftLinesView.updateWithModel()
        draftPlanesView.updateWithModel()
        
        updateDraft()
    }
    func updateDraft() {
        draftLinesView.elementViews.forEach {
            $0.node.lineType = .color(.background)
        }
        if !draftPlanesView.model.isEmpty {
            draftPlanesView.elementViews.forEach {
                $0.node.fillType = .color($0.model.uuColor.value.with(opacity: $0.model.uuColor.value.opacity * 0.075))
            }
        }
    }
}

extension TimelineView {
    static func beatLineWidth(atBeat cBeat: Rational,
                          beatR0: Rational = .init(1, 2),
                          beatR1: Rational = EditGrid.beatInterval,
                          beatR2: Rational = EditGrid.secondBeatInterval,
                          beat0:Rational = 1) -> Double {
        return if cBeat % beat0 == 0 {
            0.5
        } else if cBeat % beatR0 == 0 {
            0.25
        } else if cBeat % beatR1 == 0 {
            0.125
        } else if cBeat % beatR2 == 0 {
            0.0625
        } else {
            0.03125
        }
    }
    func makeBeatPathlines(in beatRange: Range<Rational>,
                           sy: Double, ey: Double, subBorderBeats: Set<Rational> = [],
                           isEnabledBeatExtension: Bool = true,
                           subBorderPathlines: inout [Pathline],
                           fullEditBorderPathlines: inout [Pathline],
                           secondEditBorderPathlines: inout [Pathline],
                           borderPathlines: inout [Pathline]) {
        let roundedSBeat = beatRange.start.rounded(.down)
        let deltaBeat = Rational(1, 128)
        var cBeat = roundedSBeat
        while cBeat <= beatRange.end {
            if cBeat >= beatRange.start {
                let lw = Self.beatLineWidth(atBeat: cBeat)
                let beatX = x(atBeat: cBeat)
                
                let dlh = isEnabledBeatExtension && lw == 0.5 ? 3.0 : 0.0
                let rect = Rect(x: beatX - lw / 2, y: sy - dlh,
                                width: lw, height: ey - sy + dlh * 2)
                if subBorderBeats.contains(cBeat) {
                    subBorderPathlines.append(.init(rect))
                } else if lw == 0.0625 || lw == 0.03125 {
                    if lw == 0.0625 {
                        secondEditBorderPathlines.append(.init(rect))
                    }
                    fullEditBorderPathlines.append(.init(rect))
                } else {
                    borderPathlines.append(.init(rect))
                }
            }
            cBeat += deltaBeat
        }
        
        subBorderBeats.sorted().forEach {
            if $0 % deltaBeat != 0 {
                let beatX = x(atBeat: $0)
                let lw = 0.0625
                let rect = Rect(x: beatX - lw / 2, y: sy,
                                width: lw, height: ey - sy)
                subBorderPathlines.append(.init(rect))
            }
        }
    }
}

final class AnimationView: TimelineView, @unchecked Sendable {
    typealias Binder = KeyframeView.Binder
    typealias Model = Animation
    let binder: Binder
    var keyPath: BinderKeyPath
    let node = Node()
    let previousNextNode = Node()
    let captionNode = Node()
    let timelineNode = Node()
    let clippingNode = Node(isHidden: true, lineWidth: 4, lineType: .color(.warning))
    
    var isPlaying = false
    var bounds = Sheet.defaultBounds {
        didSet {
            guard bounds != oldValue else { return }
            updateTimeline()
        }
    }
    var frameRate = Keyframe.defaultFrameRate {
        didSet { updateTimeline() }
    }
    var timelineY: Double {
        get { model.timelineY }
        set {
            unupdateModel.timelineY = newValue
            timelineNode.pose.position.y = newValue
        }
    }
    
    var tempo: Rational {
        get { model.tempo }
        set {
            unupdateModel.tempo = newValue
            updateTimeline()
        }
    }
    
    var selectedIs: [Int] {
        get {
            elementViews.count.range.filter { elementViews[$0].isSelected }
        }
        set {
            guard newValue != selectedIs else { return }
            let value = Set(newValue)
            elementViews.enumerated().forEach {
                $0.element.isSelected = value.contains($0.offset)
            }
            updateTimeline()
        }
    }
    
    var keyframeView: KeyframeView {
        elementViews[model.index]
    }
    
    typealias ElementView = KeyframeView
    typealias ModelElement = KeyframeView.Model
    private(set) var elementViews: [ElementView]
    
    init(binder: Binder, keyPath: BinderKeyPath) {
        self.binder = binder
        self.keyPath = keyPath
        
        elementViews = AnimationView.elementViewsWith(model: binder[keyPath: keyPath],
                                                      binder: binder,
                                                      keyPath: keyPath)
        updateTimeline()
        updateWithKeyframeIndex()
        timelineNode.pose.position.y = binder[keyPath: keyPath].timelineY
    }
    
    func updateWithModel() {
        updateElementViews()
    }
    func updateElementViews() {
        elementViews = AnimationView.elementViewsWith(model: model,
                                                      binder: binder,
                                                      keyPath: keyPath)
    }
    private static func elementViewsWith(model: Model,
                                         binder: Binder,
                                         keyPath: BinderKeyPath) -> [ElementView] {
        return model.keyframes.enumerated().map { (i, _) in
            ElementView(binder: binder,
                        keyPath: keyPath.appending(path: \Model.keyframes[i]))
        }
    }
    
    @discardableResult
    func append(_ modelElement: ModelElement) -> ElementView {
        unupdateModel.keyframes.append(modelElement)
        let elementView
            = ElementView(binder: binder,
                          keyPath: keyPath
                            .appending(path: \Model.keyframes[model.keyframes.count - 1]))
        elementViews.append(elementView)
        return elementView
    }
    @discardableResult
    func insert(_ modelElement: ModelElement, at index: Int) -> ElementView {
        unupdateModel.keyframes.insert(modelElement, at: index)
        let elementView
            = ElementView(binder: binder,
                          keyPath: keyPath.appending(path: \Model.keyframes[index]))
        elementViews.insert(elementView, at: index)
        
        elementViews[(index + 1)...].enumerated().forEach { (i, aElementView) in
            aElementView.keyPath = keyPath.appending(path: \Model.keyframes[index + 1 + i])
        }
        return elementView
    }
    func insert(_ elementView: ElementView, _ modelElement: ModelElement,
                at index: Int) {
        unupdateModel.keyframes.insert(modelElement, at: index)
        elementViews.insert(elementView, at: index)
        
        elementViews[(index + 1)...].enumerated().forEach { (i, aElementView) in
            aElementView.keyPath = keyPath.appending(path: \Model.keyframes[index + 1 + i])
        }
    }
    func remove(at index: Int) {
        unupdateModel.keyframes.remove(at: index)
        elementViews.remove(at: index)
        
        elementViews[index...].enumerated().forEach { (i, elementView) in
            elementView.keyPath = keyPath.appending(path: \Model.keyframes[index + i])
        }
    }
    func append(_ modelElements: [ModelElement]) {
        unupdateModel.keyframes += modelElements
        
        for i in 0 ..< modelElements.count {
            let j = model.keyframes.count - modelElements.count + i
            let elementView
                = ElementView(binder: binder,
                              keyPath: keyPath.appending(path: \Model.keyframes[j]))
            elementViews.append(elementView)
        }
    }
    func insert(_ ivs: [IndexValue<ModelElement>]) {
        var model = self.model
        for iv in ivs {
            model.keyframes.insert(iv.value, at: iv.index)
        }
        unupdateModel = model
        
        let nElementViews: [ElementView] = ivs.map { iv in
            ElementView(binder: binder,
                        keyPath: keyPath.appending(path: \Model.keyframes[iv.index]))
        }
        for (i, elementView) in nElementViews.enumerated() {
            let iv = ivs[i]
            elementViews.insert(elementView, at: iv.index)
        }
        
        elementViews.enumerated().forEach { (i, elementView) in
            elementView.keyPath = keyPath.appending(path: \Model.keyframes[i])
        }
    }
    func insert(_ ivs: [IndexValue<ElementView>]) {
        var model = self.model
        for iv in ivs {
            model.keyframes.insert(iv.value.model, at: iv.index)
        }
        unupdateModel = model
        
        for iv in ivs {
            elementViews.insert(iv.value, at: iv.index)
        }
        
        elementViews.enumerated().forEach { (i, elementView) in
            elementView.keyPath = keyPath.appending(path: \Model.keyframes[i])
        }
    }
    func append(_ elementViews: [ElementView], _ modelElements: [ModelElement]) {
        unupdateModel.keyframes += modelElements
        self.elementViews += elementViews
    }
    func removeLasts(count: Int) {
        unupdateModel.keyframes.removeLast(count)
        elementViews.removeLast(count)
    }
    func remove(at indexes: [Int]) {
        var model = self.model
        for index in indexes.reversed() {
            model.keyframes.remove(at: index)
            elementViews.remove(at: index)
        }
        unupdateModel = model
        
        elementViews.enumerated().forEach { (i, elementView) in
            elementView.keyPath = keyPath.appending(path: \Model.keyframes[i])
        }
    }
    
    var rootBeat: Rational {
        get { model.rootBeat }
        set {
            unupdateModel.rootBeat = newValue
            updateWithKeyframeIndex()
            updateTimeline()
        }
    }
    var rootBeatIndex: Animation.RootBeatIndex {
        get { model.rootBeatIndex }
        set {
            unupdateModel.rootBeatIndex = newValue
            updateWithKeyframeIndex()
            updateTimeline()
        }
    }
    var rootBeatPosition: Animation.RootBeatPosition {
        get { model.rootBeatPosition }
        set {
            unupdateModel.rootBeatPosition = newValue
            updateWithKeyframeIndex()
            updateTimeline()
        }
    }
    var rootKeyframeIndex: Int {
        get { model.rootIndex }
        set {
            unupdateModel.rootIndex = newValue
            updateWithKeyframeIndex()
            updateTimeline()
        }
    }
    func goNext(isKey: Bool) {
        if isKey {
            unupdateModel.rootInterIndex
            = model.rootInterIndex.addingReportingOverflow(1).partialValue
        } else {
            unupdateModel.goNext()
        }
        updateWithKeyframeIndex()
        updateTimeline()
    }
    func goPrevious(isKey: Bool) {
        if isKey {
            unupdateModel.rootInterIndex
            = model.rootInterIndex.subtractingReportingOverflow(1).partialValue
        } else {
            unupdateModel.goPrevious()
        }
        updateWithKeyframeIndex()
        updateTimeline()
    }
    
    var currentKeyframe: Keyframe {
        get { model.currentKeyframe }
        set {
            unupdateModel.currentKeyframe = newValue
            updateWithKeyframeIndex()
        }
    }
    
    func updateWithKeyframeIndex() {
        updatePreviousNext()
        
        node.children = [keyframeView.node]
    }
    
    func previousNextDistance(_ p: Point, scale: Double) -> Double {
        previousNextFrame.distanceSquared(p).squareRoot()
    }
    var previousNextFrame: Rect {
        let beatRange = model.beatRange
        let sBeat = max(beatRange.start, -10000)
        let sx = x(atBeat: sBeat)
        let ey = Sheet.timelineHalfHeight
        let pnW = 14.0, pnnH = 12.0, spnW = 3.0, pnY = ey + 12
        return Rect(x: sx, y: pnY - pnnH / 2, width: pnW * 3 + spnW, height: pnnH)
    }
    var paddingPreviousNextFrame: Rect {
        previousNextFrame.outset(by: Sheet.timelinePadding)
    }
    var transformedPreviousNextFrame: Rect {
        var f = previousNextFrame
        f.origin.y += timelineY
        return f
    }
    func containsPreviousNext(_ p: Point, scale: Double) -> Bool {
        previousNextDistance(p, scale: scale) < 3 + scale * 5
    }
    func previousNext(at p: Point) -> PreviousNext {
        let beatRange = model.beatRange
        let sBeat = max(beatRange.start, -10000)
        let sx = x(atBeat: sBeat)
        let pnW = 14.0
        return if p.x < sx + pnW * 0.5 {
            .none
        } else if p.x < sx + pnW * 1.5 {
            .previous
        } else if p.x < sx + pnW * 2.5 {
            .next
        } else {
            .previousAndNext
        }
    }
    
    func containsTimeline(_ p: Point, scale: Double) -> Bool {
        model.isEnabled ?
        ((paddingTimelineBounds?.contains(p) ?? false)
         || containsPreviousNext(p, scale: scale)) : false
    }
    var transformedPaddingTimelineBounds: Rect? {
        guard var b = paddingTimelineBounds else { return nil }
        b.origin.y += model.timelineY
        return b
    }
    func transformedKeyframeBounds(at i: Int) -> Rect? {
        let knobW = Sheet.knobWidth, knobH = Sheet.knobHeight
        let iKnobW = width(atDurBeat: Rational(1, frameRate)),
            iKnobH = Sheet.interpolatedKnobHeight
        let centerY = 0.0
        
        let kfBeat = model.beatRange.start + model.localBeat(at: i)
        let keyframe = model.keyframes[i]
        let kx = x(atBeat: kfBeat)
        
        let nKnobH = keyframe.isKey ? knobH : iKnobH
        
        return keyframe.isKey ?
            Rect(x: kx - knobW / 2,
                 y: centerY - nKnobH / 2 + model.timelineY,
                 width: knobW, height: nKnobH) :
            Rect(x: kx - iKnobW / 2,
                 y: centerY - nKnobH / 2 + model.timelineY,
                 width: iKnobW, height: nKnobH)
    }
    private(set) var timelineBounds: Rect?
    var paddingTimelineBounds: Rect? {
        timelineBounds?.outset(by: Sheet.timelinePadding)
    }
    
    func keyBeatRect(fromBeat beat: Rational) -> Rect {
        let x = x(atBeat: beat)
        let centerY = 0.0
        let sy = centerY - Sheet.timelineHalfHeight - 3
        let ey = centerY + Sheet.timelineHalfHeight + 3
        let lw = ScoreView.beatLineWidth(atBeat: beat)
        return .init(x: x - lw / 2, y: sy, width: lw, height: ey - sy)
    }
    func keyBeatKnobRect(fromBeat beat: Rational) -> Rect {
        let nx = x(atBeat: beat)
        let knobW = Sheet.knobWidth, knobH = Sheet.knobHeight
        let nKnobW = beat % EditGrid.beatInterval == 0 ? knobW : knobW / 2
        return Rect(x: nx - nKnobW / 2, y: timelineCenterY - knobH / 2,
                    width: nKnobW, height: knobH)
    }
    
    var editGrid = EditGrid.main {
        didSet {
            guard editGrid != oldValue else { return }
            if let node = timelineNode.children.first(where: { $0.name == "fullGrid" }) {
                node.isHidden = editGrid != .full
            }
            if let node = timelineNode.children.first(where: { $0.name == "secondGrid" }) {
                node.isHidden = editGrid != .second
            }
            
            elementViews.forEach {
                $0.linesView.elementViews.forEach {
                    $0.isHiddenPoints = editGrid != .full
                }
            }
        }
    }
    
    enum OptionHitResult {
        case keyBeat(beatI: Int)
    }
    func hitTestOption(_ p: Point, scale: Double) -> OptionHitResult? {
        let maxD = Sheet.knobEditDistance * scale
        let maxDSq = maxD * maxD
        let score = model
        
        var result: OptionHitResult?, minDSq = Double.infinity
        for (ki, keyBeat) in score.keyBeats.enumerated() {
            let x = x(atBeat: keyBeat)
            let dSq = p.x.distanceSquared(x)
            if dSq < minDSq && dSq < maxDSq {
                minDSq = dSq
                result = .keyBeat(beatI: ki)
            }
        }
        return result
    }
    
    func updateTimeline() {
        if model.isEnabled {
            let btsx = x(atBeat: model.beatRange.lowerBound)
            let btex = x(atBeat: model.endLoopDurBeat)
            let timelineBounds = Rect(x: btsx, y: -Sheet.timelineHalfHeight,
                                      width: btex - btsx,
                                      height: Sheet.timelineHalfHeight * 2)
            self.timelineBounds = timelineBounds
            let af = timelineBounds.outset(by: Sheet.timelinePadding),
                bf = previousNextFrame.outset(by: Sheet.timelinePadding)
            timelineNode.children = timelineNodes() + [clippingNode]
            timelineNode.path = .init([Point(bf.minX, bf.maxY), Point(af.minX, af.minY),
                                       Point(af.maxX, af.minY), Point(af.maxX, af.maxY),
                                       Point(bf.maxX, af.maxY), Point(bf.maxX, bf.maxY)])
            timelineNode.fillType = .color(.subRemoving)
            timelineNode.pose.position.y = model.timelineY
            
            updateClippingNode()
        } else {
            timelineNode.children = []
            timelineNode.path = .init()
            timelineNode.fillType = nil
            timelineBounds = nil
            timelineNode.pose.position = .init()
            updateClippingNode()
        }
    }
    func updateTimeline(atKeyframe ki: Int) {
        updateTimeline()//
    }
    func updateTimelineAtCurrentKeyframe() {
        updateTimeline(atKeyframe: model.index)
    }
    func timelineNodes() -> [Node] {
        let beatRange = model.beatRange, loopDurBeat = model.loopDurBeat
        let sBeat = max(beatRange.start, -10000),
            eBeat = min(beatRange.end, 10000)
        let sx = x(atBeat: sBeat), ex = x(atBeat: eBeat)
        let lw = 1.0
        let fpbD = 0.5
        let knobW = Sheet.knobWidth, knobH = Sheet.knobHeight
        let rulerH = Sheet.rulerHeight
        let iKnobW = knobW, iKnobH = Sheet.interpolatedKnobHeight
        let centerY = 0.0
        let sy = centerY - Sheet.timelineHalfHeight
        let ey = centerY + Sheet.timelineHalfHeight
        let w = ex - sx
        
        let iSet = Set(selectedIs)
        
        var contentPathlines = [Pathline](), backgroundPathlines = [Pathline](),
            borderPathlines = [Pathline](), subBorderPathlines = [Pathline]()
        var fullEditBorderPathlines = [Pathline](), secondEditBorderPathlines = [Pathline]()
        var selectedPathlines = [Pathline]()
        
        contentPathlines.append(.init(Rect(x: sx, y: centerY - lw / 2,
                                           width: w, height: lw)))
        
        makeBeatPathlines(in: beatRange.start ..< beatRange.end + loopDurBeat, sy: sy, ey: ey,
                          subBorderBeats: Set(model.keyBeats),
                          subBorderPathlines: &subBorderPathlines,
                          fullEditBorderPathlines: &fullEditBorderPathlines,
                          secondEditBorderPathlines: &secondEditBorderPathlines,
                          borderPathlines: &borderPathlines)
        
        let mainBeatX = x(atBeat: model.mainBeat)
        
        let fpb = Sheet.fpb(fromTempo: model.tempo)
        var selectedFrame: Rect?
        for (i, keyframe) in model.keyframes.enumerated() {
            let beat = keyframe.beat + beatRange.start
            let kx = x(atBeat: beat)
            
            let nKnobH = keyframe.isKey ? knobH : iKnobH
            let nKnobW = beat % EditGrid.beatInterval == 0 ?
            knobW :
            (beat % EditGrid.secondBeatInterval == 0 ? knobW / 2 : knobW / 4)
            let topD: Double
            if !keyframe.draftPicture.isEmpty {
                let pathline = Pathline(Rect(x: kx - nKnobW / 2,
                                             y: centerY + nKnobH / 2 - knobW,
                                             width: nKnobW, height: knobW))
                if iSet.contains(i) {
                    selectedPathlines.append(pathline)
                }
                contentPathlines.append(pathline)
                
                topD = knobW * 2
            } else {
                topD = 0
            }
            
            let bottomD = 0.0
            
            let niKnobW = (keyframe.beat + beatRange.start) % EditGrid.beatInterval == 0 ? iKnobW : iKnobW / 2
            let pathline = keyframe.isKey ?
            Pathline(Rect(x: kx - nKnobW / 2,
                          y: centerY - nKnobH / 2 + bottomD,
                          width: nKnobW, height: nKnobH - bottomD - topD)) :
            Pathline(Rect(x: kx - niKnobW / 2,
                          y: centerY - nKnobH / 2 + bottomD,
                          width: niKnobW, height: nKnobH - bottomD - topD))
            if iSet.contains(i) {
                let y = centerY - knobH / 2 + bottomD - 4
                selectedFrame += Rect(x: kx, y: y)
                selectedPathlines.append(.init(Rect(x: kx - 0.25, y: y,
                                                    width: 0.5, height: pathline.bounds.minY - y)))
                selectedPathlines.append(pathline)
            }
            if fpb == nil || !(Rational(fpb!) * beat).isInteger {
                backgroundPathlines.append(Pathline(Rect(x: kx - fpbD,
                                                         y: centerY - fpbD,
                                                         width: fpbD * 2, height: fpbD * 2)))
            }
            contentPathlines.append(pathline)
        }
        let kx = ex
        let nKnobW = eBeat % EditGrid.beatInterval == 0 ? knobW : knobW / 2
        let eKnobMinY = centerY - knobH / 2 - 1
        let lkb = Rect(x: kx - nKnobW / 2, y: eKnobMinY,
                       width: nKnobW, height: knobH + 2)
        if fpb == nil || !(Rational(fpb!) * eBeat).isInteger {
            backgroundPathlines.append(.init(Rect(x: kx - fpbD, y: centerY - fpbD,
                                                  width: fpbD * 2, height: fpbD * 2)))
        }
        contentPathlines.append(.init(lkb))
        
        let loopKnobH = 4.0
        let neBeat = eBeat + loopDurBeat
        let lkx = x(atBeat: neBeat)
        if loopDurBeat > 0 {
            contentPathlines.append(.init(Rect(x: ex, y: ey - lw / 2,
                                               width: lkx - ex, height: lw)))
            contentPathlines.append(.init(Rect(x: ex, y: centerY - lw / 2,
                                               width: lkx - ex, height: lw)))
            var beat = eBeat
            loop: while beat < neBeat {
                for keyframe in model.keyframes {
                    let nBeat = keyframe.beat + beat
                    guard nBeat < neBeat else { break loop }
                    let kx = x(atBeat: nBeat)
                    contentPathlines.append(.init(Rect(x: kx - 0.5,
                                                       y: centerY - 2,
                                                       width: 1, height: 4)))
                }
                beat += beatRange.length
            }
        }
        let llkb = Rect(x: lkx - nKnobW / 2, y: ey - loopKnobH / 2,
                        width: nKnobW, height: loopKnobH)
        if let fpb, !(Rational(fpb) * neBeat).isInteger {
            backgroundPathlines.append(.init(Rect(x: lkx - fpbD, y: ey - fpbD,
                                                  width: fpbD * 2, height: fpbD * 2)))
        }
        contentPathlines.append(.init(llkb))
        
        let d = knobH / 2
        let kkx = x(atBeat: model.currentKeyframe.beat + beatRange.start)
        let kd = model.currentKeyframe.isKey ? knobH / 2 : iKnobH / 2
        contentPathlines.append(.init(Rect(x: kkx - lw / 2,
                                           y: sy,
                                           width: lw,
                                           height: (centerY - kd - knobW / 2) - sy)))
        contentPathlines.append(.init(Rect(x: kkx - lw / 2,
                                           y: centerY + kd + knobW / 2,
                                           width: lw,
                                           height: ey - (centerY + kd + knobW / 2))))
        
        contentPathlines.append(.init(Rect(x: mainBeatX - lw / 2,
                                           y: sy,
                                           width: lw,
                                           height: (centerY - d - knobW / 2) - sy)))
        contentPathlines.append(.init(Rect(x: mainBeatX - lw * 2,
                                           y: sy,
                                           width: lw * 4,
                                           height: lw)))
        contentPathlines.append(.init(Rect(x: mainBeatX - lw / 2,
                                           y: centerY + d + knobW / 2,
                                           width: lw,
                                           height: ey - (centerY + d + knobW / 2))))
        contentPathlines.append(.init(Rect(x: mainBeatX - lw * 2,
                                           y: ey - lw,
                                           width: lw * 4,
                                           height: lw)))
        
        
        let secRange = model.secRange
        for sec in Int(secRange.start.rounded(.up)) ..< Int((secRange.end + model.loopDurSec).rounded(.up)) {
            let sec = Rational(sec)
            let secX = x(atSec: sec)
            contentPathlines.append(.init(Rect(x: secX - knobW / 2, y: sy - rulerH,
                                               width: knobW, height: rulerH)))
        }
        
        let pnW = 14.0, pnH = 6.0, spnW = 2.5, spnH = 3.0, pnnH = Sheet.knobHeight,
            pnY = ey + Sheet.timelineMargin / 2
        contentPathlines.append(.init(Rect(x: sx,
                                           y: pnY - lw / 2,
                                           width: pnW * 3 + spnW, height: lw)))
        
        contentPathlines.append(.init(Rect(x: sx - lw / 2,
                                           y: pnY - pnH / 2,
                                           width: lw, height: pnH)))
        
        contentPathlines.append(.init(Rect(x: sx + pnW - spnW - lw / 2,
                                           y: pnY - spnH / 2,
                                           width: lw, height: spnH)))
        contentPathlines.append(.init(Rect(x: sx + pnW - lw / 2,
                                           y: pnY - pnH / 2,
                                           width: lw, height: pnH)))
        
        contentPathlines.append(.init(Rect(x: sx + pnW * 2 - lw / 2,
                                           y: pnY - pnH / 2,
                                           width: lw, height: pnH)))
        contentPathlines.append(.init(Rect(x: sx + pnW * 2 + spnW - lw / 2,
                                           y: pnY - spnH / 2,
                                           width: lw, height: spnH)))
        
        contentPathlines.append(.init(Rect(x: sx + pnW * 3 - spnW - lw / 2,
                                           y: pnY - spnH / 2,
                                           width: lw, height: spnH)))
        contentPathlines.append(.init(Rect(x: sx + pnW * 3 - lw / 2,
                                           y: pnY - pnH / 2,
                                           width: lw, height: pnH)))
        contentPathlines.append(.init(Rect(x: sx + pnW * 3 + spnW - lw / 2,
                                           y: pnY - spnH / 2,
                                           width: lw, height: spnH)))
        let pnX = switch model.previousNext {
        case .none: pnW * 0
        case .previous: pnW * 1
        case .next: pnW * 2
        case .previousAndNext: pnW * 3
        }
        contentPathlines.append(.init(Rect(x: pnX + sx - knobW / 2,
                                           y: pnY - pnnH / 2,
                                           width: knobW, height: pnnH)))
        
        
        if let b = selectedFrame {
            selectedPathlines.append(.init(Rect(x: b.minX, y: b.minY,
                                                width: b.width, height: 0.5)))
        }
        
        var nodes = [Node]()
        
        if !fullEditBorderPathlines.isEmpty {
            nodes.append(Node(name: "fullGrid",
                              isHidden: editGrid != .full,
                              path: Path(fullEditBorderPathlines),
                              fillType: .color(.border)))
        }
        if !secondEditBorderPathlines.isEmpty {
            nodes.append(Node(name: "secondGrid",
                              isHidden: editGrid != .second,
                              path: Path(secondEditBorderPathlines),
                              fillType: .color(.border)))
        }
        if !borderPathlines.isEmpty {
            nodes.append(Node(path: Path(borderPathlines),
                              fillType: .color(.border)))
        }
        if !subBorderPathlines.isEmpty {
            nodes.append(Node(path: Path(subBorderPathlines),
                              fillType: .color(.subBorder)))
        }
        if !contentPathlines.isEmpty {
            nodes.append(Node(path: Path(contentPathlines),
                              fillType: .color(.content)))
        }
        if !backgroundPathlines.isEmpty {
            nodes.append(Node(path: Path(backgroundPathlines),
                              fillType: .color(.background)))
        }
        if !selectedPathlines.isEmpty {
            nodes.append(Node(name: "selected", isHidden: isHiddenSelected,
                              path: Path(selectedPathlines),
                              fillType: .color(.selected)))
        }
        return nodes
    }
    var isHiddenSelected = false {
        didSet {
            guard isHiddenSelected != oldValue else { return }
            timelineNode.children.forEach {
                if $0.name == "selected" {
                    $0.isHidden = isHiddenSelected
                }
            }
        }
    }
    func updatePreviousNext() {
        guard !isPlaying else { return }
        
        func otherNode(color: Color, _ previousNext: PreviousNext, atRootInter i :Int) -> Node {
            let i = model.index(atRootInter: i)
            let keyframeView = elementViews[i]
            let nodes = keyframeView.linesView.elementViews.map {
                let node = $0.node.clone
                node.lineType = .color(.background)
                return node
            }
            return Node(children: nodes, isClippingChildrenLines: true,
                        path: .init(bounds), fillType: .color(color))
        }
        
        if model.keyframes.count <= 1 {
            if !previousNextNode.children.isEmpty {
                previousNextNode.children.forEach {
                    $0.lineType = .color(.content)
                }
                previousNextNode.children = []
            }
            return
        }
        switch model.previousNext {
        case .none:
            if !previousNextNode.children.isEmpty {
                previousNextNode.children.forEach {
                    $0.lineType = .color(.content)
                }
                previousNextNode.children = []
            }
        case .previous:
            previousNextNode.children = [otherNode(color: .previous, .previous,
                                                   atRootInter: model.rootInterIndex - 1)]
        case .next:
            previousNextNode.children = [otherNode(color: .next, .next,
                                                   atRootInter: model.rootInterIndex + 1)]
        case .previousAndNext:
            previousNextNode.children = [otherNode(color: .previous, .previous,
                                                   atRootInter: model.rootInterIndex - 1),
                                         otherNode(color: .next, .next,
                                                   atRootInter: model.rootInterIndex + 1)]
        }
    }
    
    func updateClippingNode() {
        var parent: Node?
        timelineNode.allParents { node, stop in
            if node.bounds != nil {
                parent = node
                stop = true
            }
        }
        if let parent,
            let pb = parent.bounds, let b = transformedPaddingTimelineBounds {
            let edges = timelineNode.convert(pb, from: parent).intersectionEdges(b)
            
            if !edges.isEmpty {
                clippingNode.isHidden = false
                clippingNode.path = .init(edges)
                clippingNode.pose.position = -timelineNode.pose.position
            } else {
                clippingNode.isHidden = true
            }
        } else {
            clippingNode.isHidden = true
        }
    }
    
    func slidableKeyframeIndex(atRootBeat: Rational, maxDistance: Double) -> (i: Int, distance: Double)? {
        slidableKeyframeIndex(at: Point(x(atBeat: model.localBeat(atRootBeat: atRootBeat)), 0),
                              maxDistance: maxDistance)
    }
    func slidableKeyframeIndex(at timelineP: Point, maxDistance: Double) -> (i: Int, distance: Double)? {
        guard abs(timelineP.y) < Sheet.timelineHalfHeight else { return nil }
        let animation = model
        let beatRange = animation.beatRange
        
        var minD = maxDistance, minI: Int?
        for (i, keyframe) in animation.keyframes.enumerated() {
            let x = x(atBeat: keyframe.beat + beatRange.start)
            let d = abs(timelineP.x - x)
            if d < minD {
                minD = d
                minI = i
            }
        }
        
        if let minI, minI + 2 < animation.keyframes.count,
           animation.keyframes[minI].beat == animation.keyframes[minI + 1].beat {
            
            for i in minI + 1 ..< animation.keyframes.count - 1 {
                if animation.keyframes[i + 1].beat - animation.keyframes[i].beat > 0 {
                    return (i, minD)
                }
            }
            return (animation.keyframes.count - 1, minD)
        }
        
        return if let minI { (minI, minD) } else { nil }
    }
    func keyframeIndex(at timelineP: Point, scale: Double, isEnabledCount: Bool = false) -> Int? {
        guard abs(timelineP.y) < Sheet.timelineHalfHeight else { return nil }
        let animation = model
        let count = animation.keyframes.count
        let maxD = Sheet.keyframeEditDistance * scale
        var minD = Double.infinity, minI: Int?
        let beatRange = animation.beatRange
        for (i, keyframe) in animation.keyframes.enumerated() {
            let x = x(atBeat: keyframe.beat + beatRange.start)
            let d = abs(timelineP.x - x)
            if d < minD && d < maxD {
                minD = d
                minI = i
            }
        }
        if isEnabledCount {
            let x = x(atBeat: beatRange.end)
            let d = abs(timelineP.x - x)
            if d < minD && d < maxD {
                minD = d
                minI = count
            }
        }
        
        if let minI {
            return minI
        } else {
            return nil
        }
    }
    
    func isInterpolated(atLineI li: Int, atKeyframeI fki: Int) -> Bool {
        guard model.keyframes.count >= 2 else { return false }
        let id = model.keyframes[fki].picture.lines[li].interID
        return model.keyframes.enumerated().contains(where: { (ki, kf) in
            guard ki != fki else { return false }
            return kf.picture.lines.enumerated().contains(where: {
                $0.element.interID == id
            })
        })
    }
    func isEnabledFirstOrLastInterpolated(atLineI li: Int,
                                        atRootKI: Int, fromRootKI: Int) -> Bool {
        guard model.keyframes.count >= 2 else { return false }
        let ki = model.index(atRoot: atRootKI)
        let id = model.keyframes[ki].picture.lines[li].interID
        func isID(at ki: Int) -> Bool {
            model.keyframes[ki].picture.lines.contains { $0.interID == id }
        }
        return if fromRootKI <= atRootKI {
            !(fromRootKI ..< atRootKI).contains(where: { isID(at: model.index(atRoot: $0)) })
        } else {
            !(atRootKI + 1 ... fromRootKI).contains(where: { isID(at: model.index(atRoot: $0)) })
        }
    }
    var shownInterTypeKeyframeIndex: Int? {
        didSet {
            guard shownInterTypeKeyframeIndex != oldValue else { return }
            if let oldValue = oldValue, oldValue < elementViews.count {
                elementViews[oldValue].linesView.elementViews.forEach {
                    $0.node.lineType = .color($0.captureColor ?? $0.model.uuColor.value)
                    $0.captureColor = nil
                }
            }
            if let i = shownInterTypeKeyframeIndex, i < elementViews.count {
                elementViews[i].linesView.elementViews.forEach {
                    let nColor: Color
                    if case .color(let color) = $0.node.lineType {
                        $0.captureColor = color
                        nColor = color
                    } else {
                        $0.captureColor = nil
                        nColor = $0.model.uuColor.value
                    }
                    
                    $0.node.lineType = switch $0.model.interType {
                    case .interpolated: .color(nColor.lightness < 80 ? .init(lightness: min(nColor.lightness + 40, 80)) : .init(lightness: nColor.lightness - 20))
                    case .key, .none: .color(nColor)
                    }
                }
            }
        }
    }
    func interpolationNodes(from ids: [UUID], scale: Double,
                            removeLineIndex: Int? = nil,
                            oldRootKeyframeIndex orki: Int? = nil,
                            newRootKeyframeIndex nrki: Int? = nil,
                            isConvertToWorld: Bool = true) -> [Node] {
        guard !ids.isEmpty else { return [] }
        let idSet = Set(ids)
        let ki = model.index, lw = Line.defaultLineWidth
        
        let boldKISet: Set<Int> = if let orki, let nrki {
            Set((orki < nrki ? (orki ... nrki) : (nrki ... orki)).map { model.index(atRoot: $0) })
        } else {
            []
        }
        
        let nlw = max(lw * 0.5, lw * scale), blw = lw * 4, nblw = lw * 2
        let color: Color = removeLineIndex != nil ?
            .removing : .subSelected
        var nodes = [Node]()
        var lineNodeDic = [[Line.Control]: Node]()
        for (i, kf) in model.keyframes.enumerated() {
            for (li, line) in kf.picture.lines.enumerated() {
                var isAppend = true
                if let nli = removeLineIndex {
                    if i == ki && nli == li {
                        isAppend = false
                    }
                }
                if isAppend, idSet.contains(line.interID) {
                    if let node = lineNodeDic[line.controls] {
                        node.lineWidth = blw
                    } else {
                        let nLine = isConvertToWorld ? convertToWorld(line) : line
                        let node = Node(path: Path(nLine),
                                        lineWidth: boldKISet.contains(i) ? nblw : nlw,
                                        lineType: .color(color))
                        nodes.append(node)
                        lineNodeDic[line.controls] = node
                    }
                }
            }
        }
        
        return nodes
    }
    func interporatedTimelineNodes(from ids: [UUID]) -> [Node] {
        guard !ids.isEmpty else { return [] }
        let idSet = Set(ids)
        
        let knobW = Sheet.knobWidth, knobH = Sheet.knobHeight
        let iKnobW = width(atDurBeat: Rational(1, frameRate)),
            iKnobH = Sheet.interpolatedKnobHeight
        
        var selectedPathlines = [Pathline]()
        
        let beatRange = model.beatRange
        for keyframe in model.keyframes {
            let nLines = keyframe.picture.lines.filter { idSet.contains($0.interID) }
            guard !nLines.isEmpty else { continue }
            let kx = x(atBeat: keyframe.beat + beatRange.start)
            
            let pathline = nLines.contains(where: { $0.interType == .key }) ?
                Pathline(Rect(x: kx - knobW / 2,
                              y: -knobH / 2,
                              width: knobW, height: knobH)) :
                Pathline(Rect(x: kx - iKnobW / 2,
                              y: -iKnobH / 2,
                              width: iKnobW, height: iKnobH))
            selectedPathlines.append(pathline)
            
            if !keyframe.draftPicture.isEmpty {
                let pathline = Pathline(Rect(x: kx - knobW / 2,
                                             y: knobH / 2 + knobW,
                                             width: knobW, height: knobW))
                 selectedPathlines.append(pathline)
            }
        }
        
        return [Node(path: timelineNode.convertToWorld(Path(selectedPathlines)),
                     fillType: .color(.selected))]
    }
    func interporatedKeyLineIs(from ids: [UUID]) -> [Int] {
        guard !ids.isEmpty else { return [] }
        let idSet = Set(ids)
        return model.keyframes.enumerated().compactMap { (ki, keyframe) in
            keyframe.picture.lines.contains(where: { idSet.contains($0.interID) }) ? ki : nil
        }
    }
    func interporatedTimelineNodes(fromColor ids: [UUID]) -> [Node] {
        guard !ids.isEmpty else { return [] }
        let idSet = Set(ids)
        
        let knobW = Sheet.knobWidth, knobH = Sheet.knobHeight
        let iKnobW = width(atDurBeat: Rational(1, frameRate)),
            iKnobH = Sheet.interpolatedKnobHeight
        let nb = bounds.insetBy(dx: Sheet.textPadding.width, dy: 0)
        let kfY = nb.minY + timelineY
        
        var selectedPathlines = [Pathline]()
        
        let beatRange = model.beatRange
        for keyframe in model.keyframes {
            let nPlanes = keyframe.picture.planes.filter { idSet.contains($0.uuColor.id) }
            guard !nPlanes.isEmpty else { continue }
            let kx = x(atBeat: keyframe.beat + beatRange.start)
            
            let pathline = Pathline(Rect(x: kx - iKnobW / 2,
                                         y: kfY - iKnobH / 2,
                                         width: iKnobW, height: iKnobH))
            selectedPathlines.append(pathline)
            
            if !keyframe.draftPicture.isEmpty {
                let pathline = Pathline(Rect(x: kx - knobW / 2,
                                             y: kfY + knobH / 2 + knobW,
                                             width: knobW, height: knobW))
                 selectedPathlines.append(pathline)
            }
        }
        
        return [Node(path: convertToWorld(Path(selectedPathlines)),
                     fillType: .color(.selected))]
    }
    
    var origin: Point { .init(0, timelineY) }
    var timelineCenterY: Double { 0 }
    var beatRange: Range<Rational>? {
        get { model.beatRange }
        set {
            guard let newValue else { return }
            unupdateModel.beatRange = newValue
            updateTimeline()
        }
    }
    var loopDurBeat: Rational? { model.loopDurBeat }
    var localBeatRange: Range<Rational>? {
        model.localBeatRange
    }
    
    var endLoopDurBeat: Rational? {
        get { model.endLoopDurBeat }
        set {
            guard let newValue else { return }
            unupdateModel.endLoopDurBeat = newValue
            updateTimeline()
        }
    }
    
    var previousNext: PreviousNext {
        get { model.previousNext }
        set {
            guard newValue != previousNext else { return }
            unupdateModel.previousNext = newValue
            updatePreviousNext()
            updateTimeline()
        }
    }
    
    enum HitResult {
        case key(i: Int)
        case previousNext(PreviousNext)
        case startBeat
        case endBeat
        case loopDurBeat
        case all
    }
    func hitTest(_ p: Point, scale: Double) -> HitResult {
        var minD = Double.infinity, minResult = HitResult.all
        let pnD = previousNextDistance(p, scale: scale)
        
        if pnD < minD && pnD < 3 + scale * 5 {
            minD = pnD
            minResult = .previousNext(previousNext(at: p))
        }
        
        if p.y > Sheet.timelineHalfHeight - 3 {
            let ld = abs(p.x - x(atBeat: model.endLoopDurBeat))
            if ld < minD && ld < 10.0 * scale {
                minD = ld
                minResult = .loopDurBeat
            }
        }
        
        let isEnabledStartBeat = model.keyframes[0].beat == 0
        let sd = abs(p.x - x(atBeat: model.beatRange.start))
        if sd < minD && sd < 10.0 * scale && isEnabledStartBeat {
            minD = sd
            minResult = .startBeat
        }
        
        let ed = abs(p.x - x(atBeat: model.beatRange.end))
        if ed < minD && ed < 10.0 * scale {
            minD = ed
            minResult = .endBeat
        }
        
        let md = Sheet.keyframeEditDistance * scale
        if let (minI, d) = slidableKeyframeIndex(at: p, maxDistance: md) {
            if isEnabledStartBeat ? minI != 0 : true, d < minD {
                minD = d
                minResult = .key(i: minI)
            }
        }
        
        return minResult
    }
    
    func tempoPositionBeat(_ p: Point, scale: Double) -> Rational? {
        let tempoBeat = model.beatRange.start.rounded(.down) + 1
        if tempoBeat < model.beatRange.end {
            let sy = model.timelineY - Sheet.timelineHalfHeight
            let np = Point(x(atBeat: tempoBeat), sy)
            return np.distance(p) < 15 * scale ? tempoBeat : nil
        } else {
            return nil
        }
    }
}

typealias SheetBinder = RecordBinder<Sheet>
final class SheetView: View, @unchecked Sendable {
    typealias Model = Sheet
    typealias Binder = SheetBinder
    typealias BinderKeyPath = ReferenceWritableKeyPath<Binder, Model>
    let binder: Binder
    var keyPath: BinderKeyPath
    
    weak var selectedTextView: SheetTextView?
    
    var model: Model {
        get { binder.value }
        set {
            binder.value = newValue
            updateWithModel()
        }
    }
    var unupdateModel: Model {
        get { binder.value }
        set { binder.value = newValue }
    }
    
    var history = SheetHistory() { didSet { binder.record.isWillwrite = true } }
    var id = UUID()
    
    let node: Node
    var otherIAndNodes = [WeakElement<SheetView>: (i: Int, isBottom: Bool, node: Node)]()
    let opacityNode = Node(), otherBottomNode = Node(), otherTopNode = Node()
    let animationView: AnimationView
    var keyframeView: KeyframeView {
        animationView.elementViews[model.animation.index]
    }
    var linesView: ArrayView<SheetLineView> {
        keyframeView.linesView
    }
    var planesView: ArrayView<SheetPlaneView> {
        keyframeView.planesView
    }
    var draftLinesView: ArrayView<SheetLineView> {
        keyframeView.draftLinesView
    }
    var draftPlanesView: ArrayView<SheetPlaneView> {
        keyframeView.draftPlanesView
    }
    let scoreView: ScoreView
    let contentsView: ArrayView<SheetContentView>
    let textsView: ArrayView<SheetTextView>
    let bordersView: ArrayView<SheetBorderView>
    
    let mainFrameNode = Node()
    let keyframePoseNode = Node()
    
    var notePlayer: NotePlayer?
    let tempoNode = Node()
    
    var selectedTextIs: [Int] {
        textsView.elementViews.enumerated()
            .compactMap { !$0.element.selectedRanges.isEmpty ? $0.offset : nil }
    }
    var selectedContentIs: [Int] {
        get {
            contentsView.elementViews.count.range.filter { contentsView.elementViews[$0].isSelected }
        }
        set {
            let value = Set(newValue)
            contentsView.elementViews.enumerated().forEach {
                $0.element.isSelected = value.contains($0.offset)
            }
        }
    }
    
    var selectedFrameNode: Node?
    func updateSelectedFrame() {
        let scale = screenToWorldScale
        guard let selectedFrame = selectedFrame(scale: scale) else {
            selectedFrameNode?.removeFromParent()
            selectedFrameNode = nil
            return
        }
        let rect = convertToWorld(selectedFrame)
        let lastP: Point? = if let p = model.selection.lastPosition { convertToWorld(p) } else { nil }
        selectedFrameNode = Node(children: Self.selectedFrameNodes(fom: rect, lastP: lastP,
                                                                   isKnob: !model.score.isEnabled,
                                                                   scale: scale))
    }
    static func selectedFrameNodes(fom rect: Rect, lastP: Point?, isKnob: Bool,
                                   scale: Double) -> [Node] {
        var frameNodes = [Node(path: isKnob ? .init(rect) :
                .init(rect, cornerRadius: min(rect.width / 2, rect.height / 2, 2 * scale)),
                               lineWidth: scale,
                               lineType: .color(.selected))]
        if let lastP {
            let ps = rect.minPoints(at: lastP)
            if !ps.isEmpty {
                frameNodes.append(.init(path: .init(ps),
                                        lineWidth: scale, lineType: .color(.selected)))
            }
        }
        if !isKnob {
            return frameNodes
        }
        let cp = rect.centerPoint
        let knobNodes = [rect.minXMinYPoint, rect.minXMidYPoint, rect.minXMaxYPoint,
                         rect.midXMinYPoint, rect.midXMaxYPoint,
                         rect.maxXMinYPoint, rect.maxXMidYPoint, rect.maxXMaxYPoint].map {
            Node(name: "knob",
                 pose: .init(position: $0, scale: .init(square: scale)),
                 path: Path(circleRadius: 3),
                 fillType: .color(.selected))
        } + [rect.minXMinYPoint.mid(rect.midXMinYPoint),
             rect.midXMinYPoint.mid(rect.maxXMinYPoint),
             rect.maxXMinYPoint.mid(rect.maxXMidYPoint),
             rect.maxXMidYPoint.mid(rect.maxXMaxYPoint),
             rect.maxXMaxYPoint.mid(rect.midXMaxYPoint),
             rect.midXMaxYPoint.mid(rect.minXMaxYPoint),
             rect.minXMaxYPoint.mid(rect.minXMidYPoint),
             rect.minXMidYPoint.mid(rect.minXMinYPoint)].map {
            Node(name: "knob",
                 pose: .init(position: $0, scale: .init(square: scale), rotation: cp.angle($0)),
                 path: Path(Rect(x: -2.5, y: -0.75, width: 5, height: 1.5)),
                 fillType: .color(.selected))
        }
        
        return knobNodes + frameNodes
    }
    
    init(binder: Binder, keyPath: BinderKeyPath, history: SheetHistory) {
        self.binder = binder
        self.keyPath = keyPath
        self.history = history
        
        animationView = AnimationView(binder: binder,
                                      keyPath: keyPath.appending(path: \Model.animation))
        scoreView =  ScoreView(binder: binder,
                               keyPath: keyPath.appending(path: \Model.score))
        contentsView = ArrayView(binder: binder,
                                 keyPath: keyPath.appending(path: \Model.contents))
        textsView = ArrayView(binder: binder,
                              keyPath: keyPath.appending(path: \Model.texts))
        bordersView = ArrayView(binder: binder,
                                keyPath: keyPath.appending(path: \Model.borders))
        
        node = Node(children: [opacityNode, otherBottomNode,
                               animationView.node,
                               otherTopNode,
                               animationView.previousNextNode,
                               mainFrameNode,
                               contentsView.node,
                               scoreView.node,
                               textsView.node,
                               bordersView.node,
                               animationView.timelineNode,
                               animationView.captionNode,
                               keyframePoseNode])
        
        updateBackground()
        updateWithKeyframeIndex()
        updateTimeline()
        updateMainFrame()
        
        updateNode(from: model.selection, old: nil)
        
        for textView in textsView.elementViews {
            textView.selectedRangesNotification = { [weak self] textView, ranges in
                self?.updateSelection(from: ranges, textView)
            }
        }
        
        if !model.keyframePose.isIdentity {
            update(keyframePose: model.keyframePose)
        }
    }
    
    var keyframePose: Pose {
        get { model.keyframePose }
        set {
            guard keyframePose != newValue else { return }
            unupdateModel.keyframePose = newValue
            update(keyframePose: newValue)
        }
    }
    func update(keyframePose: Pose) {
        otherBottomNode.pose = keyframePose
        animationView.node.pose = keyframePose
        otherTopNode.pose = keyframePose
        animationView.previousNextNode.pose = keyframePose
        mainFrameNode.pose = keyframePose
        if keyframePose.isIdentity {
            keyframePoseNode.path = .init()
        } else {
            let typesetter = Text(string: "x: \(keyframePose.position.x.string(digitsCount: 2)), y: \(keyframePose.position.y.string(digitsCount: 2)), scale: \(keyframePose.log2Scale.string(digitsCount: 2))").typesetter
            keyframePoseNode.path = .init(typesetter, isPolygon: false)
            keyframePoseNode.pose = .init(position: .init(bounds.width - typesetter.width - 5, bounds.height - typesetter.height / 2 - 5))
            keyframePoseNode.fillType = .color(.content)
        }
        updateSelectedFrame()
    }
    func containsKeyframePose(_ p: Point) -> Bool {
        keyframePoseNode.bounds?.outset(by: 5)
            .contains(keyframePoseNode.convert(p, from: node)) ?? false
    }
    
    func updateSelection(from ranges: [Range<String.Index>], _ textView: SheetTextView) {
        if let ti = textsView.elementViews.firstIndex(of: textView) {
            unupdateModel.selection.textSelections[ti]
            = ranges.isEmpty ?
            nil : .init(ranges: ranges.map { textView.model.string.intRange(from: $0) })
        }
    }
    
    func cancelTasks() {
        playingTimer?.cancel()
        playingTimer = nil
        isPlaying = false
        
        if sequencer != nil {
            sequencer?.beginPause()
            audioPauseTask = Task { @MainActor in
                try Task.checkCancellation()
                try await Task.sleep(sec: Waveclip.default.releaseSec + 0.01)
                try Task.checkCancellation()
                sequencer?.pause()
            }
        }
    }
    
    func updateWithModel() {
        linesView.updateWithModel()
        planesView.updateWithModel()
        draftLinesView.updateWithModel()
        draftPlanesView.updateWithModel()
        scoreView.updateWithModel()
        contentsView.updateWithModel()
        textsView.updateWithModel()
        bordersView.updateWithModel()
        
        updateBackground()
        updateTimeline()
        updateMainFrame()
    }
    func updateWithKeyframeIndex() {
        updatePreviousNext()
        animationView.node.children = [keyframeView.node]
    }
    func updatePreviousNext() {
        animationView.updatePreviousNext()
    }
    func updateTimeline() {
        animationView.updateTimeline()
    }
    
    var screenToWorldScale = 1.0 {
        didSet {
            bordersView.elementViews.forEach {
                $0.screenToWorldScale = screenToWorldScale
            }
        }
    }
    
    var bounds: Rect {
        get { node.bounds ?? Sheet.defaultBounds }
        set {
            node.path = .init(newValue)
            animationView.bounds = newValue
            scoreView.bounds = newValue
            contentsView.elementViews.forEach { $0.updateClippingNode() }
            textsView.elementViews.forEach { $0.updateClippingNode() }
            bordersView.elementViews.forEach { $0.bounds = newValue }
        }
    }
    var backgroundUUColor: UUColor {
        get { model.backgroundUUColor }
        set {
            unupdateModel.backgroundUUColor = newValue
            
            updateBackground()
        }
    }
    private func updateBackground() {
        let backgroundUUColor = backgroundUUColor
        if backgroundUUColor != Sheet.defalutBackgroundUUColor {
            if backgroundUUColor.value.opacity != 1 {
                let color0 = Color(white: 1), color1 = Color(white: 0.975)
                opacityNode.path = .init([Rect].checkerboard(with: .init(square: 8), in: bounds)
                    .map { Pathline($0) })
                opacityNode.fillType = .color(color0.alphaBlend(backgroundUUColor.value))
                node.fillType = .color(color1.alphaBlend(backgroundUUColor.value))
            } else {
                opacityNode.path = .init()
                node.fillType = .color(backgroundUUColor.value)
            }
        } else {
            opacityNode.path = .init()
            node.fillType = nil
        }
    }
    var mainFrame: Rect {
        get { model.option.mainFrame }
        set {
            if newValue != self.mainFrame {
                unupdateModel.option.mainFrame = newValue
                updateMainFrame()
            }
        }
    }
    private func updateMainFrame() {
        let f = mainFrame
        if f == Sheet.defaultBounds {
            if !mainFrameNode.children.isEmpty {
                mainFrameNode.children = []
            }
        } else if isPlaying {
            let lw = Sheet.mainFrameLineWidth
            let b = bounds
            let bf = f.outset(by: lw)
            let bNode = Node(path: .init([.init(Rect(x: bf.minX, y: bf.maxY,
                                                     width: bf.width, height: b.maxY - bf.maxY)),
                                          .init(Rect(x: bf.maxX, y: b.minY,
                                                     width: b.maxX - bf.maxX, height: b.height)),
                                          .init(Rect(x: bf.minX, y: b.minY,
                                                     width: bf.width, height: bf.minY - b.minY)),
                                          .init(Rect(x: b.minX, y: b.minY,
                                                     width: bf.minX - b.minX, height: b.height))]),
                             fillType: .color(model.backgroundUUColor.value.with(opacity: 0.75)))
            let node = Node(path: .init([.init(Rect(x: f.minX, y: f.maxY,
                                                    width: f.width, height: lw)),
                                         .init(Rect(x: f.maxX, y: f.minY - lw,
                                                    width: lw, height: f.height + lw * 2)),
                                         .init(Rect(x: f.minX, y: f.minY - lw,
                                                    width: f.width, height: lw)),
                                         .init(Rect(x: f.minX - lw, y: f.minY - lw,
                                                    width: lw, height: f.height + lw * 2))]),
                            fillType: .color(.mainFrame))
            mainFrameNode.children = [bNode, node]
        } else {
            mainFrameNode.children = Self.mainFrameNodes(fromMainFrame: f)
        }
    }
    static func mainFrameNodes(fromMainFrame f: Rect) -> [Node] {
        let lw = Sheet.mainFrameLineWidth, hlw = lw / 2, tlw = hlw / 2
        let node = Node(path: .init([.init(Rect(x: f.minX, y: f.maxY,
                                                width: f.width, height: lw)),
                                     .init(Rect(x: f.maxX, y: f.minY - lw,
                                                width: lw, height: f.height + lw * 2)),
                                     .init(Rect(x: f.minX, y: f.minY - lw,
                                                width: f.width, height: lw)),
                                     .init(Rect(x: f.minX - lw, y: f.minY - lw,
                                                width: lw, height: f.height + lw * 2))]),
                        fillType: .color(.mainFrame))
        let tNode = Node(path: .init([.init(Rect(x: f.minX + f.width / 3 - tlw / 2,
                                                 y: f.maxY + lw - hlw,
                                                 width: tlw, height: hlw)),
                                      .init(Rect(x: f.minX + f.width * 2 / 3.0 - tlw / 2,
                                                 y: f.maxY + lw - hlw,
                                                 width: tlw, height: hlw)),
                                      .init(Rect(x: f.minX + f.width / 3 - tlw / 2,
                                                 y: f.minY - lw,
                                                 width: tlw, height: hlw)),
                                      .init(Rect(x: f.minX + f.width * 2 / 3.0 - tlw / 2,
                                                 y: f.minY - lw,
                                                 width: tlw, height: hlw)),
                                      .init(Rect(x: f.minX - lw,
                                                 y: f.minY + f.height / 3 - tlw / 2,
                                                 width: hlw, height: tlw)),
                                      .init(Rect(x: f.minX - lw,
                                                 y: f.minY + f.height * 2 / 3.0 - tlw / 2,
                                                 width: hlw, height: tlw)),
                                      .init(Rect(x: f.maxX + lw - hlw,
                                                 y: f.minY + f.height / 3 - tlw / 2,
                                                 width: hlw, height: tlw)),
                                      .init(Rect(x: f.maxX + lw - hlw,
                                                 y: f.minY + f.height * 2 / 3.0 - tlw / 2,
                                                 width: hlw, height: tlw))]),
                         fillType: .color(.subBorder))
        return [node, tNode]
    }
    
    func selectedFrame(scale: Double) -> Rect? {
        var rect: Rect?
        keyframeView.selectedLineIs.forEach {
            rect += keyframeView.linesView.elementViews[$0].node.bounds
        }
        keyframeView.selectedPlaneIs.forEach {
            rect += keyframeView.planesView.elementViews[$0].node.bounds
        }
        if keyframePose != .init(), let nRect = rect {
            rect = animationView.convert(nRect, to: node)
        }
        
        selectedTextIs.forEach {
            let textView = textsView.elementViews[$0], text = textView.model
            if textView.selectedRanges.count == 1 &&
                text.string.intRange(from: textView.selectedRanges[0])
                == text.string.intRange(from: text.string.allRange) {
                rect += textsView.elementViews[$0].transformedBounds
            }
        }
        selectedContentIs.forEach {
            rect += contentsView.elementViews[$0].transformedBounds
        }
        if model.score.isEnabled, let selectedFrame = scoreView.selectedFrame {
            rect += convert(selectedFrame, from: scoreView.node)
        }
        return rect?.outset(by: 10 * scale)
    }
    func updateSelectedColor(isMain: Bool) {
        animationView.timelineNode.children.forEach {
            if $0.name == "selected" {
                $0.fillType = .color(.selected)
            }
        }
        animationView.elementViews.forEach {
            $0.linesView.elementViews.forEach { if $0.isSelected { $0.updateColor() } }
            $0.planesView.elementViews.forEach { if $0.isSelected { $0.updateColor() } }
        }
        textsView.elementViews.forEach {
            $0.selectedNode.fillType = .color(.subSelected)
            $0.selectedNode.lineType = .color(.selected)
        }
        scoreView.updateWithSelected(old: [:])
        contentsView.elementViews.forEach {
            $0.selectedNode.fillType = .color(.subSelected)
            $0.selectedNode.lineType = .color(.selected)
        }
    }
    func containsSelected(_ p: Point, scale: Double) -> Bool {
        containsSelectedNote(p, scale: scale) || containsSelectedSheetValue(p, scale: scale)
    }
    
    func selectedSheetValue() -> SheetValue? {
        let sheet = model
        
        let texts: [Text] = textsView.elementViews.enumerated().compactMap { (ti, textView) in
            let ranges = textView.selectedRanges
            guard !ranges.isEmpty else { return nil }
            var text = textView.model
            if ranges.count == 1
                && text.string.intRange(from: ranges[0])
                == text.string.intRange(from: text.string.allRange) {
                
                return text
            }
            var minP = textView.typesetter
                .characterPosition(at: textView.model.string.startIndex)
            var minI = textView.model.string.endIndex
            for range in ranges {
                let i = range.lowerBound
                if i < minI {
                    minI = i
                    minP = textView.typesetter.characterPosition(at: i)
                }
            }
            var removedText = text
            removedText.string = ""
            for range in ranges {
                removedText.string += text.string[range]
            }
            for range in ranges.reversed() {
                text.string.removeSubrange(range)
            }
            removedText.origin += minP
            return removedText
        }
        
        let ssValue = SheetValue(lines: keyframeView.selectedLineIs.map { animationView.convert(sheet.picture.lines[$0], to: node) },
                                 planes: keyframeView.selectedPlaneIs.map { animationView.convert(sheet.picture.planes[$0], to: node) },
                                 texts: texts,
                                 contents: selectedContentIs.map { sheet.contents[$0] },
                                 id: id, rootKeyframeIndex: model.animation.rootIndex,
                                 keyframes: [], keyframeBeganIndex: 0, isSelected: true)
        return ssValue.isEmpty ? nil : ssValue
    }
    func containsSelectedSheetValue(_ p: Point, scale: Double) -> Bool {
        containsSelectedLine(p, scale: scale)
        || containsSelectedPlane(p)
        || containsSelectedText(p, scale: scale)
        || containsSelectedContent(p, scale: scale)
        || containsSelectedLastLine(p, scale: scale)
    }
    func containsSelectedFrame(_ p: Point, scale: Double) -> Bool {
        guard let frame = selectedFrame(scale: scale) else { return false }
        if model.score.isEnabled {
            let edSq = (Sheet.moveKnobEditDistance / 2 * scale).squared
            return frame.edges.contains { $0.distanceSquared(from: p) < edSq }
        } else {
            let dSq = (Sheet.moveKnobEditDistance * scale).squared
            let edSq = (Sheet.moveKnobEditDistance / 2 * scale).squared
            return frame.allPoints.contains { $0.distanceSquared(p) < dSq }
            || frame.edges.contains { $0.distanceSquared(from: p) < edSq }
        }
    }
    func selectedFrameDistanceSquared(_ p: Point, scale: Double) -> Double? {
        guard let frame = selectedFrame(scale: scale) else { return nil }
        let maxDSq = (Sheet.moveKnobEditDistance * scale).squared
        let maxEDSq = (Sheet.moveKnobEditDistance / 2 * scale).squared
        var minDSq = Double.infinity
        if !model.score.isEnabled {
            frame.allPoints.forEach {
                let dSq = $0.distanceSquared(p)
                if dSq < minDSq && dSq < maxDSq {
                    minDSq = dSq
                }
            }
        }
        frame.edges.forEach {
            let dSq = $0.distanceSquared(from: p)
            if dSq < minDSq && dSq < maxEDSq {
                minDSq = dSq
            }
        }
        if let lp = model.selection.lastPosition {
            let ps = frame.minPoints(at: lp)
            let edges = Edge.edges(from: ps)
            for edge in edges {
                let dSq = edge.distanceSquared(from: p)
                if dSq < minDSq && dSq < maxDSq {
                    minDSq = dSq
                }
            }
        }
        return minDSq.isInfinite ? nil : minDSq
    }
    func containsSelectedLastLine(_ p: Point, scale: Double) -> Bool {
        guard let frame = selectedFrame(scale: scale) else { return false }
        let maxDSq = (Sheet.moveKnobEditDistance * scale).squared
        if let lp = model.selection.lastPosition {
            let ps = frame.minPoints(at: lp)
            let edges = Edge.edges(from: ps)
            for edge in edges {
                let dSq = edge.distanceSquared(from: p)
                if dSq < maxDSq {
                    return true
                }
            }
        }
        return false
    }
    func containsSelectedLineOrPlane(_ p: Point, scale: Double) -> Bool {
        containsSelectedLine(p, scale: scale) || containsSelectedPlane(p)
    }
    func containsSelectedLine(_ p: Point, scale: Double) -> Bool {
        !keyframeView.selectedLineIs.isEmpty
        && lineTuple(at: p, isSelectedOnly: true, scale: scale) != nil
    }
    func containsSelectedPlane(_ p: Point) -> Bool {
        let p = animationView.convert(p, from: node)
        return !keyframeView.selectedPlaneIs.isEmpty
        && keyframeView.selectedPlaneIs.contains { keyframeView.planesView.elementViews[$0].node.path.contains(p) }
    }
    func containsSelectedText(_ p: Point, scale: Double) -> Bool {
        selectedTextIs.contains {
            let textView = textsView.elementViews[$0]
            let p = textView.convert(p, from: node)
            return if let ci = textView.characterIndex(for: p) {
                textView.selectedRanges.contains { $0.contains(ci) }
            } else {
                false
            }
        }
    }
    func containsSelectedContent(_ p: Point, scale: Double) -> Bool {
        selectedContentIs.contains {
            let view = contentsView.elementViews[$0]
            return view.contains(view.convert(p, from: node), scale: scale)
        }
    }
    func containsSelectedKeyframe(_ p: Point, scale: Double) -> Bool {
        if animationView.containsTimeline(animationView.timelineNode.convert(p, from: node),
                                          scale: scale),
           let ki = animationView
            .keyframeIndex(at: animationView.timelineNode.convert(p, from: node),
                           scale: scale) {
            animationView.selectedIs.contains(ki)
        } else {
            false
        }
    }
    
    func containsSelectedNote(_ p: Point, scale: Double) -> Bool {
        guard model.score.isEnabled,
                let v = scoreView.hitTestPoint(scoreView.convert(p, from: node),
                                               scale: scale) else { return false }
        return switch v.result {
        case .note, .startBeat, .endBeat, .f0, .spectlopeHeight: scoreView.selectedNoteIs.contains(v.noteI)
        case .pit(let pitI): scoreView.selectedNotePitIs[v.noteI]?.contains(pitI) ?? false
        case .lyric(let pitI): scoreView.selectedNotePitIs[v.noteI]?.contains(pitI) ?? false
        case .even(let pitI): scoreView.selectedNotePitIs[v.noteI]?.contains(pitI) ?? false
        case .sprol(let pitI, let sprolI, _): scoreView.selectedNotePitSprolIs[v.noteI]?[pitI]?.contains(sprolI) ?? false
        case .allSprol: scoreView.selectedNoteIs.contains(v.noteI)
        }
    }
    
    var selectedTextFrames: [Rect] {
        textsView.elementViews.flatMap { $0.transformedSelectedRects }
    }
    
    private(set) var selectedLinesNode: Node?, selectedLineNodes = [Line: Node]()
    private(set) var selectedNotesNode: Node?, selectedPointsNode: Node?,
                     selectedNoteNodes = [Pointline: Node]()
    
    func sec(at p: Point, scale: Double, interval: Rational) -> Rational {
        if let (_, view) = contentIndexAndView(at: p, scale: scale) {
            view.sec(atX: p.x, interval: interval)
        } else if scoreView.contains(p, scale: scale) {
            scoreView.sec(atX: p.x, interval: interval)
        } else {
            animationView.sec(atX: p.x, interval: interval)
        }
    }
    
    func interporatedTimelineNodes(from ids: [UUID]) -> [Node] {
        animationView.interporatedTimelineNodes(from: ids)
    }
    func interporatedTimelineNodes(fromColor ids: [UUID]) -> [Node] {
        animationView.interporatedTimelineNodes(fromColor: ids)
    }
    
    func containsScoreNoder(from ids: Set<UUID>) -> Bool {
        if let scoreTrackItem = scoreView.scoreTrackItem {
            ids.contains(scoreTrackItem.id)
        } else {
            false
        }
    }
    func containsPCMTrackItem(from ids: Set<UUID>, in contentView: SheetContentView) -> Bool {
        if let pcmTrackItem = contentView.pcmTrackItem {
            ids.contains(pcmTrackItem.id)
        } else {
            false
        }
    }
    
    func currentKeyframeString() -> String {
        Animation.timeString(fromTime: model.animation.currentKeyframe.beat + model.animation.beatRange.start,
                             frameRate: Rational(frameRate))
        + (model.animation.currentKeyframe.isKey ? "" : "i")
    }
    func timeString(fromBeat beat: Rational) -> String {
        Animation.timeString(fromTime: beat, frameRate: Rational(frameRate))
    }
    func timeString(fromSec sec: Rational, frameRate: Rational) -> String {
        Animation.timeString(fromTime: sec, frameRate: frameRate)
    }
    func currentTimeString() -> String {
        Animation.timeString(fromTime: model.animation.localBeat,
                             frameRate: Rational(frameRate))
    }
    func currentTimeProgress() -> Double? {
        model.animation.localDurBeat != 0 && model.isEnabledAnimation ?
            .init(model.animation.localBeat / model.animation.localDurBeat) : nil
    }
    func timeProgress(fromBeat beat: Rational) -> Double? {
        model.animation.localDurBeat != 0 && model.isEnabledAnimation ?
            .init(beat / model.animation.localDurBeat) : nil
    }
    func currentTimeNodes() -> [Node] {
        Self.timeNodes(duration: model.animation.currentDurBeat,
                       time: model.animation.localBeat,
                       isKey: model.animation.currentKeyframe.isKey,
                       frameRate: Rational(frameRate))
    }
    static func timeNodes(duration: Rational,
                          time: Rational,
                          isKey: Bool,
                          frameRate: Rational) -> [Node] {
        let u = Animation.timeString(fromTime: time, frameRate: frameRate) + (isKey ? "" : "i")
        let size = Font.largeSize
        let text = Text(string: u, size: size)
        let b = text.frame ?? Rect()
        let tp = Point(-b.width / 2, -b.height / 2 - 9)
        let path = Text(string: u, size: size).typesetter.path()
        return [Node(pose: Pose(position: tp),
                     path: path,
                     lineWidth: 4, lineType: .color(.background)),
                Node(pose: Pose(position: tp),
                     path: path,
                     fillType: .color(.content))]
    }
    
    func containsTempo(_ p: Point, scale: Double) -> Bool {
        if animationView.model.isEnabled, animationView.containsTempo(p, scale: scale) {
            return true
        }
        if scoreView.model.isEnabled, scoreView.containsTempo(p, scale: scale) {
            return true
        }
        for textView in textsView.elementViews {
            if textView.model.timeOption != nil, textView.containsTempo(p, scale: scale) {
                return true
            }
        }
        for contentView in contentsView.elementViews {
            if contentView.model.timeOption != nil, contentView.containsTempo(p, scale: scale) {
                return true
            }
        }
        return false
    }
    func tempo(at p: Point, scale: Double) -> Rational? {
        if animationView.model.isEnabled, animationView.containsTempo(p, scale: scale) {
            return animationView.tempo
        }
        if scoreView.model.isEnabled, scoreView.containsTempo(p, scale: scale) {
            return scoreView.tempo
        }
        for textView in textsView.elementViews {
            if textView.model.timeOption != nil, textView.containsTempo(p, scale: scale) {
                return textView.tempo
            }
        }
        for contentView in contentsView.elementViews {
            if contentView.model.timeOption != nil, contentView.containsTempo(p, scale: scale) {
                return contentView.tempo
            }
        }
        return nil
    }
    
    func containsOtherTimeline(_ p: Point, scale: Double) -> Bool {
        if scoreView.containsMainFrame(scoreView.convert(p, from: node), scale: scale)
            || scoreView.containsTimeline(scoreView.convert(p, from: node), scale: scale) {
            return true
        }
        for view in contentsView.elementViews {
            if view.containsTimeline(view.convert(p, from: node), scale: scale) {
                return true
            }
        }
        for view in textsView.elementViews {
            if view.containsTimeline(view.convert(p, from: node), scale: scale) {
                return true
            }
        }
        return false
    }
    
    func contentIndex(at p: Point, scale: Double) -> Int? {
        for (i, view) in contentsView.elementViews.enumerated().reversed() {
            if view.contains(view.convert(p, from: node), scale: scale) {
                return i
            }
        }
        return nil
    }
    func contentIndexAndView(at p: Point, scale: Double) -> (Int, SheetContentView)? {
        if let ci = contentIndex(at: p, scale: scale) {
            (ci, contentsView.elementViews[ci])
        } else {
            nil
        }
    }
    func textIndex(at p: Point, scale: Double) -> Int? {
        if let i = textTuple(at: p, scale: scale)?.textIndex {
            return i
        }
        for (i, view) in textsView.elementViews.enumerated().reversed() {
            if view.containsTimeline(view.convert(p, from: node), scale: scale) {
                return i
            }
        }
        return nil
    }
    func textIndexAndView(at p: Point, scale: Double) -> (Int, SheetTextView)? {
        if let ti = textIndex(at: p, scale: scale) {
            (ti, textsView.elementViews[ti])
        } else {
            nil
        }
    }
    
    func slidableKeyframeIndex(at timelineP: Point,
                               maxDistance: Double) -> Int? {
        animationView.slidableKeyframeIndex(at: timelineP,
                                            maxDistance: maxDistance)?.i
    }
    func keyframeIndex(at timelineP: Point, scale: Double, isEnabledCount: Bool = false) -> Int? {
        animationView.keyframeIndex(at: timelineP, scale: scale, isEnabledCount: isEnabledCount)
    }
    
    var rootKeyframeIndex: Int {
        get { animationView.rootKeyframeIndex }
        set { animationView.rootKeyframeIndex = newValue }
    }
    var rootBeatIndex: Animation.RootBeatIndex {
        get { animationView.rootBeatIndex }
        set { animationView.rootBeatIndex = newValue }
    }
    var rootBeatPosition: Animation.RootBeatPosition {
        get { animationView.rootBeatPosition }
        set { animationView.rootBeatPosition = newValue }
    }
    var rootBeat: Rational {
        get { animationView.rootBeat }
        set {
            if rootBeat != newValue {
                animationView.rootBeat = newValue
                updateAllTopAndBottomWithMainSec()
            }
        }
    }
    private func setNoUpdateTopAndBottom(mainSec: Rational) {
        guard model.animation.isEnabled,
              model.animation.allSecRange.contains(mainSec)
                else { return }
        
        let localSec = mainSec - model.animation.secRange.start
        var bp = model.animation.rootBeatPosition
        bp.beat = model.animation.beat(fromSec: localSec)
        animationView.rootBeat = model.animation.rootBeat(at: bp)
    }
    
    var currentKeyframe: Keyframe {
        get { animationView.currentKeyframe }
        set { animationView.currentKeyframe = newValue }
    }
    
    func goNext(isKey: Bool) {
        stop()
        animationView.goNext(isKey: isKey)
        updateAllTopAndBottomWithMainSec()
    }
    func goPrevious(isKey: Bool) {
        stop()
        animationView.goPrevious(isKey: isKey)
        updateAllTopAndBottomWithMainSec()
    }
    func goNextFrame() {
        stop()
        let deltaTime = Rational(1, animationView.frameRate)
        self.rootBeat = Rational.saftyAdd(rootBeat, deltaTime)
        updateAllTopAndBottomWithMainSec()
    }
    func goPreviousFrame() {
        stop()
        let deltaTime = Rational(-1, animationView.frameRate)
        self.rootBeat = Rational.saftyAdd(rootBeat, deltaTime)
        updateAllTopAndBottomWithMainSec()
    }
    
    func showSelected() {
        selectedFrameNode?.isHidden = false
        scoreView.isHiddenSelected = false
        textsView.elementViews.forEach { $0.isHiddenSelected = false }
        contentsView.elementViews.forEach { $0.isHiddenSelected = false }
        keyframeView.showSelected()
        animationView.isHiddenSelected = false
    }
    func hideSelected() {
        selectedFrameNode?.isHidden = true
        scoreView.isHiddenSelected = true
        textsView.elementViews.forEach { $0.isHiddenSelected = true }
        contentsView.elementViews.forEach { $0.isHiddenSelected = true }
        keyframeView.hideSelected()
        animationView.isHiddenSelected = true
    }
    
    weak var left, right, top, bottom: SheetView?
    func updateScoreViewFromAround() {
        let nBeatRange = self.scoreView.model.beatRange
        var nNotes = [Note]()
        if let scoreView = left?.scoreView, scoreView.model.isEnabled {
            let beatRange = scoreView.model.beatRange
            nNotes += scoreView.model.notes.filter { $0.beatRange.end > beatRange.end }.map {
                var n = $0
                n.beatRange.start -= beatRange.end
                return n
            }
        }
        if let scoreView = right?.scoreView, scoreView.model.isEnabled {
            let startBeat = scoreView.model.beatRange.start
            nNotes += scoreView.model.notes.filter { $0.beatRange.start < startBeat }.map {
                var n = $0
                n.beatRange.start += nBeatRange.end
                return n
            }
        }
        self.scoreView.otherNotes = nNotes
    }
    func updateScoreViewFromOtherAround() {
        if let left {
            left.updateScoreViewFromAround()
        }
        if let right {
            right.updateScoreViewFromAround()
        }
        if let top {
            top.updateScoreViewFromAround()
        }
        if let bottom {
            bottom.updateScoreViewFromAround()
        }
    }
    
    func updateAllTopAndBottomWithMainSec() {
        updateTopAndBottom()
        let mainSec = animationView.model.mainSec
        topSheetViews.forEach {
            $0.element?.setNoUpdateTopAndBottom(mainSec: mainSec)
            $0.element?.updateTopAndBottom()
        }
        bottomSheetViews.forEach {
            $0.element?.setNoUpdateTopAndBottom(mainSec: mainSec)
            $0.element?.updateTopAndBottom()
        }
    }
    func updateAllTopAndBottom() {
        updateTopAndBottom()
        topSheetViews.forEach { $0.element?.updateTopAndBottom() }
        bottomSheetViews.forEach { $0.element?.updateTopAndBottom() }
    }
    func updateTopAndBottom() {
        guard model.isEnabledAnimation else { return }
        let allSec = animationView.model.mainSec, bounds = bounds
        var otherBottomChildren = [Node](), otherTopChildren = [Node]()
        
        func update(_ oSheetView: SheetView, isBottom: Bool) {
            if oSheetView.model.isEnabledAnimation, oSheetView.model.animation.allSecRange.contains(allSec) {
                
                let weakElement = WeakElement(element: oSheetView)
                let ki = oSheetView.animationView.model.index(atSec: allSec)
                if otherIAndNodes[weakElement] == nil || otherIAndNodes[weakElement]?.i != ki {
                    let keyframeView = oSheetView.animationView.elementViews[ki]
                    let nodes = keyframeView.linesView.elementViews.map {
                        let node = $0.node.clone
                        node.lineType = .color(.background)
                        return node
                    }
                    let planeNodes = keyframeView.planesView.elementViews.map {
                        let node = $0.node.clone
                        node.fillType = .color($0.uuColor.value.with(multiplyOpacity: 0.5))
                        return node
                    }
                    let dNodes = keyframeView.draftLinesView.elementViews.map {
                        let node = $0.node.clone
                        node.lineType = .color(.background)
                        return node
                    }
                    let dPlaneNodes = keyframeView.draftPlanesView.elementViews.map {
                        let node = $0.node.clone
                        node.fillType = .color($0.uuColor.value.with(multiplyOpacity: 0.125))
                        return node
                    }
                    let opacity = !planeNodes.isEmpty ? 0.5 : 0.125
                    let node = Node(children: dPlaneNodes + [Node(children: dNodes, isClippingChildrenLines: true,
                                                    path: .init(bounds), fillType: .color(.draft.with(opacity: opacity)))] + planeNodes +
                                               
                                               [Node(children: nodes, isClippingChildrenLines: true,
                                                           path: .init(bounds), fillType: .color(Color(white: 0, opacity: opacity)))])
                    
                    if isBottom {
                        otherBottomChildren.append(node)
                    } else {
                        otherTopChildren.append(node)
                    }
                    
                    otherIAndNodes[weakElement] = (ki, isBottom, node)
                } else if let (_, isBottom, node) = otherIAndNodes[weakElement] {
                    if isBottom {
                        otherBottomChildren.append(node)
                    } else {
                        otherTopChildren.append(node)
                    }
                }
            }
        }
        topSheetViews.forEach {
            if let sheetView = $0.element {
                update(sheetView, isBottom: false)
            }
        }
        bottomSheetViews.forEach {
            if let sheetView = $0.element {
                update(sheetView, isBottom: true)
            }
        }
        
        if !otherBottomChildren.isEmpty {
            otherBottomNode.children = otherBottomChildren
        } else if !otherBottomNode.children.isEmpty {
            otherBottomNode.children = []
        }
        if !otherTopChildren.isEmpty {
            otherTopNode.children = otherTopChildren
        } else if !otherTopNode.children.isEmpty {
            otherTopNode.children = []
        }
    }
    
    func seqTrack(sampleRate: Double) -> Sequencer.Track {
        var seqTrack = sequencerTrack
        bottomSheetViews.forEach {
            if let aSeqTrack = $0.element?.sequencerTrack {
                seqTrack += aSeqTrack
            }
        }
        topSheetViews.forEach {
            if let aSeqTrack = $0.element?.sequencerTrack {
                seqTrack += aSeqTrack
            }
        }
        let bottomEndSec = bottomSheetViews.reduce(Rational(0)) {
            max($0, $1.element?.model.allEndSec ?? 0)
        }
        let topEndSec = topSheetViews.reduce(Rational(0)) {
            max($0, $1.element?.model.allEndSec ?? 0)
        }
        let mainDurSec = max(model.allEndSec, bottomEndSec, topEndSec,
                             seqTrack.durSec)
        seqTrack.scoreTrackItems.append(.init(rendnoteManagers: [],
                                              sampleRate: sampleRate,
                                              startSec: 0,
                                              durSec: mainDurSec))
        return seqTrack
    }
    
    func mainFrameWithBottomAndTop() -> Rect {
        if model.mainFrame != Sheet.defaultBounds {
            return model.mainFrame
        }
        for sheetView in bottomSheetViews {
            if let f = sheetView.element?.model.mainFrame, f != Sheet.defaultBounds {
                return f
            }
        }
        return bounds
    }
    
    private var playingTimer: (any DispatchSourceTimer)?,
                playingOldKeyframeIndex: Int?
    private var playingCaptions = [Caption](), playingCaptionNodes = [Node]()
    private var playingSheetIndex = 0
    var previousSheetViews = [WeakElement<SheetView>]()
    var nextSheetViews = [WeakElement<SheetView>]()
    var bottomSheetViews = [WeakElement<SheetView>]()
    var topSheetViews = [WeakElement<SheetView>]()
    private var bottomNodes = [Node](), centerNode: Node?, topNodes = [Node]()
    private var timeNode: Node?, volumeNode: Node?, musicBackgroundNode: Node?
    private var volumeColor = Color.background
    private(set) var sequencer: Sequencer?
    private var firstSec: Rational?
    private var willPlaySec: Rational?, playingOtherTimelineIDs = Set<UUID>()
    private var playingFrameRate: Rational = 24, firstDeltaSec: Rational = 0
    private var beganPlaySec: SuspendingClock.Instant?
    private var audioPauseTask: Task<(), any Error>?
    private var mainDurSec: Rational = 0
    private(set) var clonePlayNode: Node?
    let frameRate = Keyframe.defaultFrameRate
    var isPlaying = false {
        didSet {
            guard isPlaying != oldValue else { return }
            updateWithIsPlaying()
        }
    }
    private func updateWithIsPlaying() {
        audioPauseTask?.cancel()
        playingTimer?.cancel()
        playingTimer = nil
        if isPlaying {
            clonePlayNode = node.clone
        }
        animationView.isPlaying = isPlaying
        animationView.previousNextNode.isHidden = isPlaying
        otherBottomNode.isHidden = isPlaying
        otherTopNode.isHidden = isPlaying
        if isPlaying {
            let playingSec = firstSec ?? model.animation.sec(fromBeat: model.animation.mainBeat)
            self.playingSec = playingSec
            
            playingOldKeyframeIndex = nil
            bottomSheetViews.forEach { $0.element?.playingOldKeyframeIndex = nil }
            topSheetViews.forEach { $0.element?.playingOldKeyframeIndex = nil }
            bottomNodes = bottomSheetViews.count.range.map { _ in Node() }
            centerNode = nil
            topNodes = topSheetViews.count.range.map { _ in Node() }
            playingSheetIndex = 0
            playingCaptions = []
            
            updateCaption()
            setupTimeNodes()
            
            updateMainFrame()
            
            var seqTracks = [Sequencer.Track]()
            var deltaSec: Rational = 0
            
            let sampleRate = Audio.defaultSampleRate
            
            for weakElement in previousSheetViews {
                guard let sheetView = weakElement.element else { continue }
                let seqTrack = sheetView.seqTrack(sampleRate: sampleRate)
                sheetView.mainDurSec = seqTrack.durSec
                seqTracks.append(seqTrack)
                deltaSec += seqTrack.durSec
            }
            firstDeltaSec = deltaSec
            
            let seqTrack = seqTrack(sampleRate: sampleRate)
            self.mainDurSec = seqTrack.durSec
            seqTracks.append(seqTrack)
            
            if model.isEnabledAudio {
                musicBackgroundNode = Node(path: .init(bounds), fillType: .color(.musicBacground))
            }
            
            deltaSec += playingSec
            willPlaySec = playingSec
            
            for weakElement in nextSheetViews {
                guard let sheetView = weakElement.element else { continue }
                let seqTrack = sheetView.seqTrack(sampleRate: sampleRate)
                sheetView.mainDurSec = seqTrack.durSec
                seqTracks.append(seqTrack)
            }
            
            if !playingOtherTimelineIDs.isEmpty {
                for i in 0 ..< seqTracks.count {
                    seqTracks[i].scoreTrackItems.removeAll {
                        !playingOtherTimelineIDs.contains($0.id)
                    }
                    seqTracks[i].pcmTrackItems.removeAll {
                        !playingOtherTimelineIDs.contains($0.id)
                    }
                }
            }
            
            allSampless = [[Double]](repeating: .init(repeating: 0, count: Self.tapSampleCount),
                                     count: 2)
            
            if seqTracks.contains(where: { !$0.isEmpty }) {
                if sequencer != nil {
                    sequencer?.update(seqTracks)
                } else {
                    let sequencer = Sequencer(tracks: seqTracks, type: .loop) { [weak self] (sampless, sampleRate) in
                        DispatchQueue.main.async { [weak self] in
                            guard let self, self.isPlaying else { return }
                            self.updateTimeNodes(from: sampless, sampleRate: sampleRate)
                        }
                    }
                    self.sequencer = sequencer
                }
            } else {
                sequencer = nil
            }
            
            sequencer?.startSec = Double(deltaSec)
            sequencer?.play()
            
            playingFrameRate = Rational(60)
            beganPlaySec = .now
            let timeInterval = Double(1 / playingFrameRate)
            playingTimer = DispatchSource.scheduledTimer(withTimeInterval: timeInterval) { [weak self] in
                DispatchQueue.main.async { [weak self] in
                    guard !(self?.playingTimer?.isCancelled ?? true) else { return }
                    self?.loopPlay()
                }
            }
            
            hideSelected()
        } else {
            playingSheetIndex = 0
            playingSec = nil
            playingOldKeyframeIndex = nil
            bottomSheetViews.forEach { $0.element?.playingOldKeyframeIndex = nil }
            topSheetViews.forEach { $0.element?.playingOldKeyframeIndex = nil }
            bottomNodes = []
            centerNode = nil
            topNodes = []
            musicBackgroundNode = nil
            
            updateWithKeyframeIndex()
            updateMainFrame()
            
            animationView.captionNode.children = []
            playingCaptions = []
            playingCaptionNodes = []
            
            playingSecRange = nil
            firstSec = nil
            
            endTimeNodes()
            
            allSampless = []
            
            contentsView.elementViews.forEach {
                if $0.model.type == .movie, let sec = $0.model.rootSec {
                    $0.updateMovie(atSec: sec)
                }
            }
            
            updatePreviousNext()
        
            if sequencer != nil {
                sequencer?.beginPause()
                audioPauseTask = Task { @MainActor in
                    try Task.checkCancellation()
                    try await Task.sleep(sec: Waveclip.default.releaseSec + 0.01)
                    try Task.checkCancellation()
                    sequencer?.pause()
                }
            }
//            sequencer?.endEngine()
//            sequencer = nil
            
            showSelected()
            
            clonePlayNode = nil
        }
    }
    var playingSec: Rational? {
        didSet {
            guard playingSec != oldValue, let playingSec else { return }
            let sheetView = playingSheetView
            
            var children = [Node]()
            
            if !sheetView.bottomSheetViews.isEmpty {
                for (si, bottomSheetViewE) in sheetView.bottomSheetViews.enumerated() {
                    guard let bottomSheetView = bottomSheetViewE.element,
                          bottomSheetView.model.isEnabledAnimation else { continue }
                    let i = bottomSheetView.model.animation.indexInBeatRange(atSec: playingSec)
                    if let i {
                        if bottomSheetView.playingOldKeyframeIndex != i {
                            if si < bottomNodes.count {
                                bottomSheetView.animationView.elementViews[i].hideSelected()
                                bottomNodes[si]
                                = bottomSheetView.animationView.elementViews[i].node.clone
                                bottomSheetView.animationView.elementViews[i].showSelected()
                            }
                            bottomSheetView.playingOldKeyframeIndex = i
                        }
                    } else if si < bottomNodes.count {
                        bottomNodes[si] = .init()
                        bottomSheetView.playingOldKeyframeIndex = nil
                    }
                }
                children += bottomNodes
            } else {
                bottomNodes = []
            }
            
            let i = sheetView.model.animation.indexInBeatRange(atSec: playingSec)
            if let i {
                if playingOldKeyframeIndex != i {
                    let node = sheetView.animationView.elementViews[i].node
                    sheetView.animationView.elementViews[i].hideSelected()
                    centerNode = node.clone
                    sheetView.animationView.elementViews[i].showSelected()
                    playingOldKeyframeIndex = i
                }
            } else {
                centerNode = nil
                playingOldKeyframeIndex = nil
            }
            if let centerNode {
                children.append(centerNode)
            }
            
            if !sheetView.topSheetViews.isEmpty {
                for (si, topSheetViewE) in sheetView.topSheetViews.enumerated() {
                    guard let topSheetView = topSheetViewE.element,
                          topSheetView.model.isEnabledAnimation else { continue }
                    let i = topSheetView.model.animation.indexInBeatRange(atSec: playingSec)
                    if let i {
                        if topSheetView.playingOldKeyframeIndex != i {
                            if si < topNodes.count {
                                topSheetView.animationView.elementViews[i].hideSelected()
                                topNodes[si]
                                = topSheetView.animationView.elementViews[i].node.clone
                                topSheetView.animationView.elementViews[i].showSelected()
                            }
                            topSheetView.playingOldKeyframeIndex = i
                        }
                    } else if si < topNodes.count {
                        topNodes[si] = .init()
                        topSheetView.playingOldKeyframeIndex = nil
                    }
                }
                children += topNodes
            } else {
                topNodes = []
            }
            
            if let musicBackgroundNode {
                children += [musicBackgroundNode]
            }
            
            if !children.isEmpty {
                animationView.node.children = children
            }
            
            updateCaption()
            updateTimeNodes()
            
            sheetView.contentsView.elementViews.forEach {
                if $0.model.type == .movie, let timeOption = $0.model.timeOption {
                    $0.updateMovie(atSec: playingSec - timeOption.secRange.start - timeOption.localStartBeat)
                }
            }
        }
    }
    func setupTimeNodes() {
        endTimeNodes()
        if let parentNode = node.parent {
            let timeNode = Node()
            parentNode.append(child: timeNode)
            self.timeNode = timeNode
            
            let volumeNode = Node()
            parentNode.append(child: volumeNode)
            self.volumeNode = volumeNode
            
            volumeColor = .background
            updateTimeNodes()
        }
    }
    func endTimeNodes() {
        timeNode?.removeFromParent()
        volumeNode?.removeFromParent()
        timeNode?.children = []
        volumeNode?.children = []
    }
    func updateTimeNodes() {
        if let playingSec {
            updateTimeNodes(fromSec: playingSec)
        }
    }
    func updateTimeNodesWithMainSec() {
        updateTimeNodes(fromSec: animationView.model.mainSec)
    }
    func updateTimeNodes(fromSec playingSec: Rational) {
        let sheetView = playingSheetView
        if let parentNode = sheetView.node.parent {
            var timeRects0 = [Rect](), timeRects1 = [Rect](), volumeRects1 = [Rect]()
            func update(from sheetView: SheetView) {
                let d = volumeColor == .warning ? 2.0 : 1.0
                let knobW = (isPlaying ? 3.0 : 1.0) * d, volmW = (isPlaying ? 2.0 : 0) * d
                if !(!isPlaying && sheetView == self), sheetView.model.isEnabledAnimation && sheetView.animationView.model.allSecRange.contains(playingSec) {
                    
                    let btx = sheetView.animationView.x(atSec: playingSec)
                    let knobH = sheetView.animationView.timelineBounds?.height ?? 0
                    let tlY = sheetView.animationView.transformedPaddingTimelineBounds?.midY ?? 0
                    timeRects0.append(parentNode.convert(Rect(x: btx - knobW / 2, y: tlY - knobH / 2,
                                                              width: knobW, height: knobH),
                                                         from: sheetView.node))
                }
                timeRects0 += sheetView.textsView.elementViews.compactMap {
                    guard $0.timeOption?.secRange.contains(playingSec) ?? false,
                          let f = $0.transformedTimelineFrame else { return nil }
                    let btx = $0.x(atSec: playingSec) + $0.origin.x
                    return .init(x: btx - knobW / 2, y: f.minY, width: knobW, height: f.height)
                }.map { parentNode.convert($0, from: sheetView.node) }
                
                var oTimeRects1 = [Rect]()
                let scoreView = sheetView.scoreView
                if scoreView.option.isEnabled {
                    if scoreView.model.allSecRange.contains(playingSec) {
                        let btx = scoreView.x(atSec: playingSec) + scoreView.origin.x
                        let h = scoreView.mainFrame.maxY - scoreView.timelineFrame.minY
                        oTimeRects1.append(Rect(x: btx - knobW / 2,
                                                y: scoreView.timelineY - scoreView.timelineFrame.height / 2,
                                                width: knobW, height: h))
                    }
                }
                oTimeRects1 += sheetView.contentsView.elementViews.compactMap {
                    guard $0.timeOption?.secRange.contains(playingSec) ?? false,
                          let f = $0.transformedTimelineFrame else { return nil }
                    let h = $0.isShownSpectrogram ?
                    f.height + SheetContentView.spectrogramHeight + Sheet.timelineMargin : f.height
                    let btx = $0.x(atSec: playingSec) + $0.origin.x
                    return .init(x: btx - knobW / 2, y: f.minY, width: knobW, height: h)
                }
                
                timeRects1 += oTimeRects1.map { parentNode.convert($0, from: sheetView.node) }
                volumeRects1 += oTimeRects1.map { $0.inset(by: (knobW - volmW) / 2) }
                    .map { parentNode.convert($0, from: sheetView.node) }
            }
            update(from: sheetView)
            sheetView.bottomSheetViews.forEach {
                guard let sheetView = $0.element else { return }
                update(from: sheetView)
            }
            sheetView.topSheetViews.forEach {
                guard let sheetView = $0.element else { return }
                update(from: sheetView)
            }
            
            let rects0 = isPlaying ? [parentNode.convert(allTimeSliderRect(atSec: playingSec,
                                                                           at: playingSheetIndex),
                                                         from: node)] : []
            timeNode?.children
            = rects0.map { Node(path: Path($0), fillType: .color(.content)) }
            + timeRects0.map { Node(path: Path($0), fillType: .color(.content)) }
            + timeRects1.map { Node(path: Path($0), fillType: .color(.content)) }
            volumeNode?.children = volumeRects1.map { Node(path: Path($0), fillType: .color(volumeColor)) }
        } else {
            timeNode?.children = []
            volumeNode?.children = []
        }
    }
    
    static let tapSampleCount = 20480
    private var allSampless = [[Double]](repeating: .init(repeating: 0, count: tapSampleCount),
                                         count: 2),
                loudness = Loudness(sampleRate: Audio.defaultSampleRate)
    private func updateTimeNodes(from sampless: [[Double]]?, sampleRate: Double) {
        guard let sampless else {
            volumeColor = .background
            return
        }
        
        for ci in 0 ..< min(sampless.count, allSampless.count) {
            if allSampless[ci].count < sampless[ci].count {
                allSampless[ci] = Array(sampless[ci][(sampless[ci].count - allSampless[ci].count)...])
            } else {
                let di = allSampless[ci].count - sampless[ci].count
                for i in 0 ..< di {
                    allSampless[ci][i] = allSampless[ci][i + sampless[ci].count]
                }
                for i in di ..< allSampless[ci].count {
                    allSampless[ci][i] = sampless[ci][i - di]
                }
            }
        }
        
        if loudness.sampleRate != sampleRate {
            loudness = .init(sampleRate: sampleRate)
        }
        let lufs = (try? loudness.lufs(from: allSampless)) ?? -.infinity
        let peakAmp = PCMBuffer.peakAmp(sampless: sampless)
        let isPeak = peakAmp > Audio.headroomAmp
        
        volumeColor = if isPeak {
            .warning
        } else if lufs > Audio.limitLufs {
            .linear(.content, .loudnessWarning,
                    t: lufs.clipped(min: Audio.limitLufs, max: Audio.limitLufs + 6, newMin: 0.25, newMax: 1))
        } else {
            Color(white: lufs.clipped(min: Audio.limitLufs - 6, max: Audio.limitLufs, newMin: 1, newMax: 0))
        }
    }
    private func allTimeSliderRect(atSec sec: Rational, at index: Int) -> Rect {
        if index == 0 {
            let beat = model.animation.beat(fromSec: sec)
            let btx = animationView.x(atBeat: beat)
            let knobW = 2.0, knobH = 6.0
            return Rect(x: btx - knobW / 2, y: 0,
                        width: knobW, height: knobH)
        } else if index < 0 {
            let allDurSec = model.allEndSec
            let bt = allDurSec == 0 ? 0 : Double(sec / allDurSec).clipped(min: 0, max: 1)
            let knobW = 2.0, knobH = 6.0
            return Rect(x: bounds.width / 2 * bt,
                        y: 0,
                        width: knobW, height: knobH)
        } else {
            let allDurSec = model.allEndSec
            let bt = allDurSec == 0 ? 0 : Double(sec / allDurSec).clipped(min: 0, max: 1)
            let knobW = 2.0, knobH = 6.0
            return Rect(x: bounds.midX + bounds.width / 2 * bt,
                        y: 0,
                        width: knobW, height: knobH)
        }
    }
    
    var playingSheetView: SheetView {
        if playingSheetIndex < 0, -playingSheetIndex <= previousSheetViews.count,
            let sheetView = previousSheetViews[previousSheetViews.count - (-playingSheetIndex - 1) - 1].element {
            return sheetView
        } else if playingSheetIndex > 0, playingSheetIndex <= nextSheetViews.count,
            let sheetView = nextSheetViews[playingSheetIndex - 1].element {
            
            return sheetView
        } else {
            return self
        }
    }
    private func loopPlay() {
        guard let willPlaySec else { return }
        if sequencer != nil, let beganPlaySec {
            let ddSec = beganPlaySec.duration(to: .now).sec
            let dSec = Rational(ddSec, intervalScale: .init(1, 60))
            let preDurSecs = previousSheetViews.map { $0.element?.mainDurSec ?? 0 }
            let preDurSec = preDurSecs.sum()
            guard mainDurSec > 0 else { return }
            let nextDurSecs = nextSheetViews.map { $0.element?.mainDurSec ?? 0 }
            let nexrDurSec = nextDurSecs.sum()
            let oldPlayingSheetIndex = playingSheetIndex
            if preDurSec == 0 && nexrDurSec == 0 {
                playingSheetIndex = 0
                playingSec = (dSec + willPlaySec) % mainDurSec
            } else {
                let nSec = dSec + willPlaySec
                var i = 0, nPlayingSec: Rational = 0, sec: Rational = 0
                while true {
                    let oldSec = sec
                    if i == 0 {
                        sec += mainDurSec
                        if nSec < sec {
                            nPlayingSec = (nSec - oldSec) % mainDurSec
                            break
                        }
                    } else if i < 0 {
                        let durSec = preDurSecs[preDurSecs.count - (-i - 1) - 1]
                        sec += durSec
                        if nSec < sec && durSec > 0 {
                            nPlayingSec = (nSec - oldSec) % durSec
                            break
                        }
                    } else {
                        let durSec = nextDurSecs[i - 1]
                        sec += durSec
                        if nSec < sec && durSec > 0 {
                            nPlayingSec = (nSec - oldSec) % durSec
                            break
                        }
                    }
                    
                    i += 1
                    if i > nextSheetViews.count {
                        i = -previousSheetViews.count
                    }
                }
                playingSheetIndex = i
                playingSec = nPlayingSec
            }
            
            if playingSheetIndex != oldPlayingSheetIndex {
                playingOldKeyframeIndex = nil
                bottomSheetViews.forEach { $0.element?.playingOldKeyframeIndex = nil }
                topSheetViews.forEach { $0.element?.playingOldKeyframeIndex = nil }
                bottomNodes = bottomSheetViews.count.range.map { _ in Node() }
                topNodes = topSheetViews.count.range.map { _ in Node() }
                
                let nSheetView = playingSheetView
                nSheetView.bottomSheetViews.forEach { $0.element?.playingOldKeyframeIndex = nil }
                nSheetView.topSheetViews.forEach { $0.element?.playingOldKeyframeIndex = nil }
                bottomNodes = nSheetView.bottomSheetViews.count.range.map { _ in Node() }
                topNodes = nSheetView.topSheetViews.count.range.map { _ in Node() }
            }
            
            return
        }
        
        let nSec = willPlaySec + 1 / playingFrameRate
        
        let sheetView = playingSheetView
        let maxSec = playingSecRange != nil ? playingSecRange!.end : sheetView.mainDurSec
        if nSec >= maxSec {
            let oldPlayingSheetIndex = playingSheetIndex
            
            playingSheetIndex += 1
            if playingSheetIndex > nextSheetViews.count {
                playingSheetIndex = -previousSheetViews.count
            }
            if playingSecRange != nil {
                playingSheetIndex = 0
            }
            
            if playingSheetIndex != oldPlayingSheetIndex {
                playingOldKeyframeIndex = nil
                bottomSheetViews.forEach { $0.element?.playingOldKeyframeIndex = nil }
                topSheetViews.forEach { $0.element?.playingOldKeyframeIndex = nil }
                bottomNodes = bottomSheetViews.count.range.map { _ in Node() }
                topNodes = topSheetViews.count.range.map { _ in Node() }
                
                let nSheetView = playingSheetView
                nSheetView.bottomSheetViews.forEach { $0.element?.playingOldKeyframeIndex = nil }
                nSheetView.topSheetViews.forEach { $0.element?.playingOldKeyframeIndex = nil }
                bottomNodes = nSheetView.bottomSheetViews.count.range.map { _ in Node() }
                topNodes = nSheetView.topSheetViews.count.range.map { _ in Node() }
            }
            
            if playingSecRange != nil || playingSheetIndex <= 0 {
                let sSec = playingSecRange?.start ?? 0
                self.willPlaySec = sSec
                playingSec = sSec
            } else {
                self.willPlaySec = nSec - maxSec
                playingSec = nSec - maxSec
            }
        } else {
            self.willPlaySec = nSec
            playingSec = nSec
        }
    }
    var playingSecRange: Range<Rational>?
    func play(atSec sec: Rational? = nil,
              inSec playingSecRange: Range<Rational>? = nil,
              otherTimelineIDs: Set<UUID> = []) {
        if isPlaying {
            isPlaying = false
            Sleep.start(atTime: Waveclip.default.releaseSec + 0.01)
        }
        if let sec {
            firstSec = sec
        }
        self.playingSecRange = playingSecRange
        self.playingOtherTimelineIDs = otherTimelineIDs
        isPlaying = true
    }
    var stopNotifications = [((SheetView) -> ())]()
    func stop() {
        if isPlaying {
            playingSecRange = nil
            playingOtherTimelineIDs = []
            isPlaying = false
            stopNotifications.forEach { $0(self) }
        }
    }
    func updatePlaying() {
        if isPlaying {
            let sec = playingSec
            let secRange = playingSecRange
            isPlaying = false
            firstSec = sec
            playingSecRange = secRange
            isPlaying = true
        }
    }
    
    func endSeqencer() {
        guard !(sequencer?.isPlaying ?? true) else { return }
        sequencer = nil
    }
    
    func updateCaption() {
        guard isPlaying, let playingSec else { return }
        
        let sheetView = playingSheetView
        let captions = sheetView.model.captions(atSec: playingSec)
        + sheetView.bottomSheetViews.flatMap { $0.element?.model.captions(atSec: playingSec) ?? [] }
        + sheetView.topSheetViews.flatMap { $0.element?.model.captions(atSec: playingSec) ?? [] }
        if captions != playingCaptions {
            playingCaptions = captions
            if !captions.isEmpty {
                let nodes = Caption.nodes(in: sheetView.mainFrameWithBottomAndTop(),
                                          from: captions)
                playingCaptionNodes = nodes
                animationView.captionNode.children = nodes
            } else {
                playingCaptionNodes = []
                animationView.captionNode.children = playingCaptionNodes
            }
        } else {
            animationView.captionNode.children = playingCaptionNodes
        }
    }
    
    var sequencerTrack: Sequencer.Track {
        scoreView.scoreTrackItem?.updateNotewaveDic()
        return .init(scoreTrackItems: scoreView.scoreTrackItem != nil ? [scoreView.scoreTrackItem!] : [],
                     pcmTrackItems: contentsView.elementViews.compactMap { $0.pcmTrackItem })
    }
    
    func spectrogramNode(at p: Point) -> (node: Node, contentView: SheetContentView)? {
        for contentView in contentsView.elementViews {
            if let nNode = contentView.spectrogramNode(at: contentView.convert(p, from: node)) {
                return (nNode, contentView)
            }
        }
        return nil
    }
    
    func nearestTempo(at p: Point) -> Rational? {
        var minTempo: Rational?, minDS = Double.infinity
        
        if scoreView.model.isEnabled {
            let ds = scoreView.transformedTimelineFrame?.distanceSquared(p) ?? 0
            if ds < minDS {
                minTempo = scoreView.model.tempo
                minDS = ds
            }
        }
        
        for contentView in contentsView.elementViews {
            guard let tempo = contentView.model.timeOption?.tempo else { continue }
            let ds = contentView.transformedTimelineFrame?.distanceSquared(p) ?? 0
            if ds < minDS {
                minTempo = tempo
                minDS = ds
            }
        }
        for textView in textsView.elementViews {
            guard let tempo = textView.model.timeOption?.tempo else { continue }
            let ds = textView.transformedTimelineFrame?.distanceSquared(p) ?? 0
            if ds < minDS {
                minTempo = tempo
                minDS = ds
            }
        }
        if animationView.model.isEnabled {
            let ds = animationView.transformedPaddingTimelineBounds?.distanceSquared(p) ?? 0
            if ds < minDS {
                minTempo = animationView.model.tempo
                minDS = ds
            }
        }
        return minTempo
    }
    
    func clearHistory() {
        history.reset()
        binder.enableWrite()
    }
    
    func worldColorPathValue(with colorValue: ColorValue,
                             toColor: Color?,
                             color: Color, subColor: Color) -> ColorPathValue {
        if !colorValue.planeIndexes.isEmpty {
            var paths = colorValue.planeIndexes.map {
                animationView.convertToWorld(planesView.elementViews[$0].node.path)
            }
            if colorValue.isBackground, let b = node.bounds {
                let path = Path([Pathline(b)]) * node.localTransform
                paths.append(path)
            }
            if let toColor = toColor {
                return ColorPathValue(paths: paths,
                                      lineType: .color(color),
                                      fillType: .color(subColor + toColor))
            } else {
                return ColorPathValue(paths: paths,
                                      lineType: .color(color),
                                      fillType: .color(subColor))
            }
        } else if !colorValue.planeAnimationIndexes.isEmpty {
            var paths = [Path]()
            for v in colorValue.planeAnimationIndexes {
                if v.index == model.animation.index {
                    let planes = model.animation.keyframes[v.index].picture.planes
                    for i in v.value {
                        paths.append(animationView.convertToWorld(planes[i].node.path))
                    }
                }
            }
            if colorValue.isBackground, let b = node.bounds {
                let path = Path([Pathline(b)]) * node.localTransform
                paths.append(path)
            }
            if let toColor = toColor {
                return ColorPathValue(paths: paths,
                                      lineType: .color(color),
                                      fillType: .color(subColor + toColor))
            } else {
                return ColorPathValue(paths: paths,
                                      lineType: .color(color),
                                      fillType: .color(subColor))
            }
        } else if colorValue.isBackground, let b = node.bounds {
            let path = Path([Pathline(b)]) * node.localTransform
            if let toColor = toColor {
                return ColorPathValue(paths: [path],
                                      lineType: .color(color),
                                      fillType: .color(subColor + toColor))
            } else {
                return ColorPathValue(paths: [path],
                                      lineType: .color(color),
                                      fillType: .color(subColor))
            }
        } else {
            return ColorPathValue(paths: [], lineType: nil, fillType: nil)
        }
    }
    
    func removeAll() {
        guard !model.picture.isEmpty
                || !model.draftPicture.isEmpty
                || !model.texts.isEmpty
                || !model.contents.isEmpty
                || !model.score.notes.isEmpty else { return }
        newUndoGroup()
        if !model.picture.isEmpty {
            set(Picture())
        }
        if !model.draftPicture.isEmpty {
            removeDraft()
        }
        if !model.texts.isEmpty {
            removeTexts(at: Array(0 ..< model.texts.count))
        }
        if !model.contents.isEmpty {
            removeContents(at: Array(0 ..< model.contents.count))
        }
        if !model.score.notes.isEmpty {
            removeNotes(at: Array(0 ..< model.score.notes.count))
        }
    }
    
    func unselect() {
        if !model.selection.isEmpty {
            set(SheetSelection.empty)
        }
    }
    func unselectAndNewUndoGroupIfNeeded() {
        if !model.selection.isEmpty {
            newUndoGroup()
            set(SheetSelection.empty)
        }
    }
    func unselectAndNewUndoGroupIfNeeded(withoutText textI: Int) {
        var selection = model.selection
        selection.textSelections[textI] = nil
        if !selection.isEmpty {
            newUndoGroup()
            set(SheetSelection.empty)
        }
    }
    func unselect(isNewUndoGroup: inout Bool) {
        if !model.selection.isEmpty {
            if isNewUndoGroup {
                newUndoGroup()
                isNewUndoGroup = false
            }
            set(SheetSelection.empty)
        }
    }
    
    func plane(at p: Point) -> Plane? {
        if let pi = planesView.firstIndex(at: p) {
            return model.picture.planes[pi]
        } else {
            return nil
        }
    }
    func planeTuple(at p: Point) -> (pi: Int, plane: Plane)? {
        if let pi = planesView.firstIndex(at: p) {
            return (pi, model.picture.planes[pi])
        } else {
            return nil
        }
    }
    func sheetColorOwner(at p: Point,
                         isEnabledLine: Bool = true, isEnabledLinePlane: Bool = true,
                         isEnabledAlwaysAnimation: Bool = false,
                         removingUUColor: UUColor? = Line.defaultUUColor,
                         scale: Double) -> (isLine: Bool, value: SheetColorOwner) {
        if isEnabledLine,
           let (lineView, li) = lineTuple(at: p,
                                          isEnabledPlane: isEnabledLinePlane,
                                          removingUUColor: removingUUColor,
                                          scale: scale) {
            let uuColor = lineView.model.uuColor
            
            if model.isEnabledAnimation {
                if containsSelectedKeyframe(p, scale: scale) {
                    return (true, sheetColorOwnerFromAnimation(with: uuColor, isLine: true))
                } else {
                    let cv = ColorValue(uuColor: uuColor,
                                        lineAnimationIndexes: [IndexValue(value: [li],
                                                               index: model.animation.index)])
                    return (true, SheetColorOwner(sheetView: self, colorValue: cv))
                }
            } else {
                let cv = ColorValue(uuColor: uuColor, lineIndexes: [li])
                return (true, SheetColorOwner(sheetView: self, colorValue: cv))
            }
        } else {
            return (false, sheetColorOwnerFromPlane(at: p, isEnabledAlwaysAnimation: isEnabledAlwaysAnimation, scale: scale))
        }
    }
    func sheetColorOwnerFromAnimation(with uuColor: UUColor,
                                      isLine: Bool = false) -> SheetColorOwner {
        let planeValue: [IndexValue<[Int]>] = animationView.model.keyframes.count.range.compactMap {
            let pis = animationView.elementViews[$0].planesView.elementViews.enumerated().filter { $0.element.model.uuColor == uuColor }
                .map { $0.offset }
            if pis.isEmpty {
                return nil
            } else {
                return IndexValue(value: pis, index: $0)
            }
        }
        let lineValue: [IndexValue<[Int]>] = !isLine ? [] :
        animationView.model.keyframes.count.range.compactMap {
            let lis = animationView.elementViews[$0].linesView.elementViews.enumerated().filter { $0.element.model.uuColor == uuColor }
                .map { $0.offset }
            if lis.isEmpty {
                return nil
            } else {
                return IndexValue(value: lis, index: $0)
            }
        }
        let cv = ColorValue(uuColor: uuColor,
                            planeAnimationIndexes: planeValue,
                            lineAnimationIndexes: lineValue)
        return SheetColorOwner(sheetView: self, colorValue: cv)
    }
    func sheetColorOwnerFromPlane(at p: Point,
                                  isEnabledAlwaysAnimation: Bool = false,
                                  scale: Double) -> SheetColorOwner {
        if let pi = planesView.firstIndex(at: animationView.convert(p, from: node)) {
            if model.isEnabledAnimation {
                if containsSelectedKeyframe(p, scale: scale) || isEnabledAlwaysAnimation {
                    let uuColor = model.picture.planes[pi].uuColor
                    return sheetColorOwnerFromAnimation(with: uuColor)
                } else {
                    let cv = ColorValue(uuColor: model.picture.planes[pi].uuColor,
                                        planeAnimationIndexes: [IndexValue(value: [pi],
                                                           index: model.animation.index)])
                    return SheetColorOwner(sheetView: self, colorValue: cv)
                }
            } else {
                let cv = ColorValue(uuColor: model.picture.planes[pi].uuColor,
                                    planeIndexes: [pi])
                return SheetColorOwner(sheetView: self, colorValue: cv)
            }
        } else {
            let cv = ColorValue(uuColor: model.backgroundUUColor, isBackground: true)
            return SheetColorOwner(sheetView: self, colorValue: cv)
        }
    }
    func sheetColorOwnerWithSelection(isLine: Bool = false) -> [SheetColorOwner] {
        if isLine {
            let liDic = keyframeView.selectedLineIs.reduce(into: [UUColor: [Int]]()) {
                let uuColor = model.picture.lines[$1].uuColor
                if $0[uuColor] != nil {
                    $0[uuColor]?.append($1)
                } else {
                    $0[uuColor] = [$1]
                }
            }
            return liDic.map {
                if model.isEnabledAnimation {
                    let cv = ColorValue(uuColor: $0.key,
                                        lineAnimationIndexes: [IndexValue(value: $0.value,
                                                           index: model.animation.index)])
                    return SheetColorOwner(sheetView: self, colorValue: cv)
                } else {
                    let cv = ColorValue(uuColor: $0.key, lineIndexes: $0.value)
                    return SheetColorOwner(sheetView: self, colorValue: cv)
                }
            }
        } else {
            let piDic = keyframeView.selectedPlaneIs.reduce(into: [UUColor: [Int]]()) {
                let uuColor = model.picture.planes[$1].uuColor
                if $0[uuColor] != nil {
                    $0[uuColor]?.append($1)
                } else {
                    $0[uuColor] = [$1]
                }
            }
            return piDic.map {
                if model.isEnabledAnimation {
                    let cv = ColorValue(uuColor: $0.key,
                                        planeAnimationIndexes: [IndexValue(value: $0.value,
                                                           index: model.animation.index)])
                    return SheetColorOwner(sheetView: self, colorValue: cv)
                } else {
                    let cv = ColorValue(uuColor: $0.key, planeIndexes: $0.value)
                    return SheetColorOwner(sheetView: self, colorValue: cv)
                }
            }
        }
    }
    func sheetColorOwner(with uuColor: UUColor) -> SheetColorOwner? {
        if model.isEnabledAnimation {
            let iivs: [IndexValue<[Int]>] = model.animation.keyframes.enumerated().compactMap { (i, kf) in
                let planeIndexes = kf.picture.planes.enumerated().compactMap {
                    $0.element.uuColor == uuColor ? $0.offset : nil
                }
                if planeIndexes.isEmpty {
                    return nil
                } else {
                    return IndexValue(value: planeIndexes, index: i)
                }
            }
            let liivs: [IndexValue<[Int]>] = model.animation.keyframes.enumerated().compactMap { (i, kf) in
                let lineIndexes = kf.picture.lines.enumerated().compactMap {
                    $0.element.uuColor == uuColor ? $0.offset : nil
                }
                if lineIndexes.isEmpty {
                    return nil
                } else {
                    return IndexValue(value: lineIndexes, index: i)
                }
            }
            let isBackground = model.backgroundUUColor == uuColor
            guard !iivs.isEmpty || !liivs.isEmpty || isBackground else {
                return nil
            }
            let cv = ColorValue(uuColor: uuColor,
                                isBackground: isBackground,
                                planeAnimationIndexes: iivs, lineAnimationIndexes: liivs)
            return SheetColorOwner(sheetView: self, colorValue: cv)
        } else {
            let planeIndexes = model.picture.planes.enumerated().compactMap {
                $0.element.uuColor == uuColor ? $0.offset : nil
            }
            let lineIndexes = model.picture.lines.enumerated().compactMap {
                $0.element.uuColor == uuColor ? $0.offset : nil
            }
            let isBackground = model.backgroundUUColor == uuColor
            guard !planeIndexes.isEmpty || !lineIndexes.isEmpty || isBackground else {
                return nil
            }
            let cv = ColorValue(uuColor: uuColor,
                                planeIndexes: planeIndexes,
                                lineIndexes: lineIndexes,
                                isBackground: isBackground)
            return SheetColorOwner(sheetView: self, colorValue: cv)
        }
    }
    
    func newUndoGroup() {
        history.newUndoGroup()
    }
    
    private func cap(undo undoItem: SheetUndoItem) {
        if model.animation.isEnabled {
            history.set(first: .setRootKeyframeI(model.animation.rootIndex))
        }
        history.append(undo: undoItem, redo: model.reversed(undoItem))
    }
    private func set(_ redoItem: SheetUndoItem) {
        if model.animation.isEnabled {
            history.set(first: .setRootKeyframeI(model.animation.rootIndex))
        }
        history.append(undo: model.reversed(redoItem), redo: redoItem)
        update(redoItem)
    }
    private func set(_ redoItem: SheetUndoItem, rootKI: Int) {
        history.set(first: .setRootKeyframeI(rootKI))
        history.append(undo: model.reversed(redoItem), redo: redoItem)
        update(redoItem)
    }
    @discardableResult
    func undo(to toTopIndex: Int,
              isMakeRect: Bool = true,
              isSleep: Bool = true) throws -> (rect: Rect?, nodes: [Node]) {
        var rect = Rect?.none, nodes = [Node]()
        let results = history.undoResults(to: toTopIndex)
        for result in results {
            let (aRect, aNodes) = update(try history.undoItem(with: result, model),
                                      isMakeRect: isMakeRect, isSleep: isSleep)
            rect += aRect
            nodes += aNodes
        }
        return (rect, nodes)
    }
    @discardableResult
    func update(_ item: SheetUndoItem,
                isMakeRect: Bool = false,
                isSleep: Bool = false) -> (rect: Rect?, nodes: [Node]) {
        selectedTextView = nil
        stop()
        
        func rect(local b: Rect?) -> Rect? {
            b != nil ? animationView.convert(b!, to: node) : nil
        }
        switch item {
        case .appendLine(let line):
            let lineView = appendNode(line)
            if isMakeRect {
                return (rect(local: lineView.node.bounds), [])
            }
        case .removeLastLine:
            if isMakeRect {
                let rect = rect(local: linesView.elementViews.last!.node.bounds)
                removeLastLinesNode(count: 1)
                return (rect, [])
            } else {
                removeLastLinesNode(count: 1)
            }
        case .appendKeyLine(let kv):
            let lineView = appendNode(kv.value, atKeyframe: kv.index)
            if isMakeRect {
                return (rect(local: lineView.node.bounds), [])
            }
        case .removeKeyLastLine(let ki):
            if isMakeRect {
                let rect = rect(local: animationView.elementViews[ki]
                    .linesView.elementViews.last!.node.bounds)
                removeLastLinesNode(count: 1, atKeyframe: ki)
                return (rect, [])
            } else {
                removeLastLinesNode(count: 1, atKeyframe: ki)
            }
        case .appendLines(let lines):
            appendNode(lines)
            for lineView in linesView.elementViews[(linesView.elementViews.count - lines.count)...] {
                lineView.isHiddenPoints = animationView.editGrid != .full
            }
            animationView.updateTimelineAtCurrentKeyframe()
            
            if isMakeRect {
                let rect = linesView.elementViews[(linesView.elementViews.count - lines.count)...]
                    .reduce(into: Rect?.none) { $0 += rect(local: $1.node.bounds) }
                return (rect, [])
            }
        case .insertLines(let livs):
            insertNode(livs)
            for liv in livs {
                let lineView = linesView.elementViews[liv.index]
                lineView.isHiddenPoints = animationView.editGrid != .full
            }
            animationView.updateTimelineAtCurrentKeyframe()
            
            if isMakeRect {
                let rect = livs.reduce(into: Rect?.none) {
                    $0 += rect(local: linesView.elementViews[$1.index].node.bounds)
                }
                return (rect, [])
            }
        case .removeLastLines(let count):
            if isMakeRect {
                let rect = linesView.elementViews[(linesView.elementViews.count - count)...]
                    .reduce(into: Rect?.none) { $0 += rect(local: $1.node.bounds) }
                removeLastLinesNode(count: count)
                return (rect, [])
            } else {
                removeLastLinesNode(count: count)
            }
        case .appendKeyLines(let kv):
            appendNode(kv.value, atKeyframe: kv.index)
            for lineView in animationView.elementViews[kv.index]
                .linesView.elementViews.suffix(kv.value.count) {
                lineView.isHiddenPoints = animationView.editGrid != .full
            }
            animationView.updateTimelineAtCurrentKeyframe()
            
            if isMakeRect {
                let rect = animationView.elementViews[kv.index]
                    .linesView.elementViews.suffix(kv.value.count)
                    .reduce(into: Rect?.none) { $0 += rect(local: $1.node.bounds) }
                return (rect, [])
            }
        case .removeKeyLastLines(let countKV):
            if isMakeRect {
                let rect = animationView.elementViews[countKV.index]
                    .linesView.elementViews.suffix(countKV.value)
                    .reduce(into: Rect?.none) { $0 += rect(local: $1.node.bounds) }
                removeLastLinesNode(count: countKV.value, atKeyframe: countKV.index)
                return (rect, [])
            } else {
                removeLastLinesNode(count: countKV.value, atKeyframe: countKV.index)
            }
        case .removeLines(let lis):
            if isMakeRect {
                let rect = lis.reduce(into: Rect?.none) {
                    $0 += rect(local: linesView.elementViews[$1].node.bounds)
                }
                removeLinesNode(at: lis)
                return (rect, [])
            } else {
                removeLinesNode(at: lis)
            }
            
        case .appendPlanes(let planes):
            appendNode(planes)
            if isMakeRect {
                let rect = planesView.elementViews[(planesView.elementViews.count - planes.count)...]
                    .reduce(into: Rect?.none) {
                        if let b = $1.node.bounds {
                            $0 += animationView.convert(b, to: node)
                        }
                    }
                return (rect, [])
            }
        case .removeLastPlanes(let count):
            if isMakeRect {
                let rect = planesView.elementViews[(planesView.elementViews.count - count)...]
                    .reduce(into: Rect?.none) {
                        if let b = $1.node.bounds {
                            $0 += animationView.convert(b, to: node)
                        }
                    }
                removeLastsPlaneNode(count: count)
                return (rect, [])
            } else {
                removeLastsPlaneNode(count: count)
            }
        case .insertPlanes(let pivs):
            insertNode(pivs)
            if isMakeRect {
                let rect = pivs.reduce(into: Rect?.none) {
                    if let b = planesView.elementViews[$1.index].node.bounds {
                        $0 += animationView.convert(b, to: node)
                    }
                }
                return (rect, [])
            }
        case .replaceLines(let livs):
            if isMakeRect {
                var rect: Rect?
                for liv in livs {
                    unupdateModel.picture.lines[liv.index] = liv.value
                    linesView.elementViews[liv.index].updateWithModel()
                    if let b = linesView.elementViews[liv.index].node.bounds {
                        rect += animationView.convert(b, to: node)
                    }
                }
                return (rect, [])
            } else {
                for liv in livs {
                    unupdateModel.picture.lines[liv.index] = liv.value
                    linesView.elementViews[liv.index].updateWithModel()
                }
            }
        case .replacePlanes(let pivs):
            if isMakeRect {
                var rect: Rect?
                for piv in pivs {
                    unupdateModel.picture.planes[piv.index] = piv.value
                    planesView.elementViews[piv.index].updateWithModel()
                    if let b = planesView.elementViews[piv.index].node.bounds {
                        rect += animationView.convert(b, to: node)
                    }
                }
                return (rect, [])
            } else {
                for piv in pivs {
                    unupdateModel.picture.planes[piv.index] = piv.value
                    planesView.elementViews[piv.index].updateWithModel()
                }
            }
        case .removePlanes(let planeIndexes):
            if isMakeRect {
                let rect = planeIndexes.reduce(into: Rect?.none) {
                    if let b = planesView.elementViews[$1].node.bounds {
                        $0 += animationView.convert(b, to: node)
                    }
                }
                removePlanesNode(at: planeIndexes)
                return (rect, [])
            } else {
                removePlanesNode(at: planeIndexes)
            }
        case .setPlaneValue(let planeValue):
            let planeIndexes = planeValue.moveIndexValues.map {
                IndexValue(value: planesView.elementViews[$0.value].model, index: $0.index)
            }
            setNode(planeValue.planes)
            if isMakeRect {
                let rect = planesView.elementViews
                    .reduce(into: Rect?.none) {
                        if let b = $1.node.bounds {
                            $0 += animationView.convert(b, to: node)
                        }
                    }
                insertNode(planeIndexes)
                return (rect, [])
            } else {
                insertNode(planeIndexes)
            }
        case .setKeyPlaneValues(let kvs):
            var rect: Rect?, nodes = [Node]()
            for kv in kvs {
                let planeValue = kv.value, ki = kv.index
                let planeIVs = planeValue.moveIndexValues.map {
                    IndexValue(value: animationView.elementViews[ki]
                        .planesView.elementViews[$0.value].model,
                               index: $0.index)
                }
                animationView.elementViews[ki].planesView.model = planeValue.planes
                if isMakeRect {
                    animationView.elementViews[kv.index].planesView.insert(planeIVs)
                    
                    rect += planeIVs.reduce(into: Rect?.none) {
                        let planeNode = animationView.elementViews[kv.index].planesView
                            .elementViews[$1.index].node.clone
                        planeNode.fillType = .color(.selected)
                        if let b = planeNode.bounds {
                            $0 += animationView.convert(b, to: node)
                        }
                        nodes.append(planeNode)
                    }
                    
                } else {
                    animationView.elementViews[kv.index].planesView.insert(planeIVs)
                }
            }
            if isMakeRect {
                return (rect, nodes)
            }
        case .changeToDraft(let isReverse):
            if isReverse {
                if linesView.model.isEmpty && planesView.model.isEmpty {
                    setNode(draftLinesView.model)
                    linesView.elementViews.forEach {
                        $0.isHiddenPoints = animationView.editGrid != .full
                    }
                    setDraftNode([Line]())
                    setNode(draftPlanesView.model)
                    setDraftNode([Plane]())
                }
            } else {
                if draftLinesView.model.isEmpty && draftPlanesView.model.isEmpty {
                    setDraftNode(linesView.model)
                    setNode([Line]())
                    setDraftNode(planesView.model)
                    setNode([Plane]())
                }
            }
            updateTimeline()
            if isMakeRect {
                return (node.bounds, [])
            }
        case .setPicture(let picture):
            setNode(picture.lines)
            setNode(picture.planes)
            animationView.updateTimelineAtCurrentKeyframe()
            if isMakeRect {
                return (node.bounds, [])
            }
        case .insertDraftLines(let livs):
            insertDraftNode(livs)
            updateTimeline()
            if isMakeRect {
                let rect = livs.reduce(into: Rect?.none) {
                    if let b = draftLinesView.elementViews[$1.index].node.bounds {
                        $0 += animationView.convert(b, to: node)
                    }
                }
                return (rect, [])
            }
        case .insertDraftPlanes(let pivs):
            insertDraftNode(pivs)
            updateTimeline()
            if isMakeRect {
                let rect = pivs.reduce(into: Rect?.none) {
                    if let b = draftPlanesView.elementViews[$1.index].node.bounds {
                        $0 += animationView.convert(b, to: node)
                    }
                }
                return (rect, [])
            }
        case .removeDraftLines(let lineIndexes):
            if isMakeRect {
                let rect = lineIndexes.reduce(into: Rect?.none) {
                    if let b = draftLinesView.elementViews[$1].node.bounds {
                        $0 += animationView.convert(b, to: node)
                    }
                }
                removeDraftLinesNode(at: lineIndexes)
                updateTimeline()
                return (rect, [])
            } else {
                removeDraftLinesNode(at: lineIndexes)
                updateTimeline()
            }
        case .removeDraftPlanes(let planeIndexes):
            if isMakeRect {
                let rect = planeIndexes.reduce(into: Rect?.none) {
                    if let b = draftPlanesView.elementViews[$1].node.bounds {
                        $0 += animationView.convert(b, to: node)
                    }
                }
                removeDraftPlanesNode(at: planeIndexes)
                updateTimeline()
                return (rect, [])
            } else {
                removeDraftPlanesNode(at: planeIndexes)
                updateTimeline()
            }
        case .setDraftPicture(let picture):
            setDraftNode(picture.lines)
            setDraftNode(picture.planes)
            updateTimeline()
            if isMakeRect {
                return (node.bounds, [])
            }
            
        case .changedColors(let colorValue):
            changeColorsNode(colorValue)
            
            if isMakeRect {
                let rect = colorValue.planeIndexes.reduce(into: Rect?.none) {
                    if let b = planesView.elementViews[$1].node.bounds {
                        $0 += animationView.convert(b, to: node)
                    }
                } + colorValue.lineIndexes.reduce(into: Rect?.none) {
                    if let b = linesView.elementViews[$1].node.bounds {
                        $0 += animationView.convert(b, to: node)
                    }
                }
                return (rect, [])
            }
            
        case .insertTexts(let tivs):
            insertNode(tivs)
            
            if isPlaying ? tivs.contains(where: { $0.value.timeOption != nil }) : false {
                updateCaption()
            }
            
            tivs.forEach { textsView.elementViews[$0.index].updateClippingNode() }
            
            if isMakeRect {
                let rect = tivs.reduce(into: Rect?.none) {
                    $0 += textsView.elementViews[$1.index].transformedBounds
                }
                return (rect, [])
            }
        case .replaceTexts(let tivs):
            if isMakeRect {
                var rect: Rect?
                for tiv in tivs {
                    unupdateModel.texts[tiv.index] = tiv.value
                    textsView.elementViews[tiv.index].updateWithModel()
                    rect += textsView.elementViews[tiv.index].node.transformedBounds
                }
                
                tivs.forEach { textsView.elementViews[$0.index].updateClippingNode() }
                
                return (rect, [])
            } else {
                for tiv in tivs {
                    unupdateModel.texts[tiv.index] = tiv.value
                    textsView.elementViews[tiv.index].updateWithModel()
                }
                
                tivs.forEach { textsView.elementViews[$0.index].updateClippingNode() }
            }
        case .removeTexts(let textIndexes):
            let isUpdateCaption = isPlaying ?
            textIndexes.contains(where: { textsView.elementViews[$0].model.timeOption != nil }) : false
            
            if isMakeRect {
                let rect = textIndexes.reduce(into: Rect?.none) {
                    $0 += textsView.elementViews[$1].transformedBounds
                }
                removeTextsNode(at: textIndexes)
                
                if isUpdateCaption {
                    updateCaption()
                }
                
                return (rect, [])
            } else {
                removeTextsNode(at: textIndexes)
                
                if isUpdateCaption {
                    updateCaption()
                }
            }
        case .replaceString(let ituv):
            if isMakeRect {
                let textView = textsView.elementViews[ituv.index]
                let firstRect: Rect?
                if ituv.value.origin != nil || ituv.value.size != nil {
                    firstRect = textView.transformedBounds
                } else {
                    let fRange = textView.model.string
                        .range(fromInt: ituv.value.replacedRange)
                    firstRect = textView
                        .transformedTypoBounds(with: fRange)
                }
                setNode(ituv)
                let lastRect: Rect?
                if ituv.value.origin != nil || ituv.value.size != nil {
                    lastRect = textView.transformedBounds
                } else {
                    let nRange = textView.model.string
                        .range(fromInt: ituv.value.newRange)
                    lastRect = textView
                        .transformedTypoBounds(with: nRange)
                }
                selectedTextView = textView
                
                if isPlaying ? textView.model.timeOption != nil : false {
                    updateCaption()
                }
                
                return (firstRect + lastRect, [])
            } else {
                setNode(ituv)
                
                let textView = textsView.elementViews[ituv.index]
                if isPlaying ? textView.model.timeOption != nil : false {
                    updateCaption()
                }
                
                selectedTextView = textsView.elementViews[ituv.index]
            }
            
        case .insertBorders(let bivs):
            insertNode(bivs)
            if isMakeRect {
                let rect = bivs.reduce(into: Rect?.none) {
                    let borderView = bordersView.elementViews[$1.index]
                    $0 += borderView.node.bounds?.inset(by: -borderView.node.lineWidth)
                }
                return (rect, [])
            }
        case .removeBorders(let borderIndexes):
            if isMakeRect {
                let rect = borderIndexes.reduce(into: Rect?.none) {
                    let borderView = bordersView.elementViews[$1]
                    $0 += borderView.node.bounds?.inset(by: -borderView.node.lineWidth)
                }
                removeBordersNode(at: borderIndexes)
                return (rect, [])
            } else {
                removeBordersNode(at: borderIndexes)
            }
            
        case .insertKeyframes(let kivs):
            if !kivs.isEmpty {
                animationView.insert(kivs)
                
                unupdateModel.animation.rootIndex = kivs.last?.index ?? 0
                
                updateWithKeyframeIndex()
                updateTimeline()
                if isMakeRect {
                    let rect = kivs.reduce(into: Rect?.none) {
                        $0 += animationView.transformedKeyframeBounds(at: $1.index)
                    }
                    return (rect, [])
                }
            }
        case .removeKeyframes(let indexes):
            if !indexes.isEmpty {
                let rect = isMakeRect ? indexes.reduce(into: Rect?.none) {
                    $0 += animationView.transformedKeyframeBounds(at: $1)
                } : Rect?.none
                
                animationView.remove(at: indexes)
                
                unupdateModel.animation
                    .rootIndex = (indexes.first ?? 0) - 1
                
                updateWithKeyframeIndex()
                updateTimeline()
                if isMakeRect {
                    return (rect, [])
                }
            }
        case .setKeyframeOptions(let koivs):
            let rootBI = model.animation.rootBeatIndex
            
            unupdateModel.animation.set(koivs)
            
            if model.animation.rootBeatIndex != rootBI {
                unupdateModel.animation.rootBeatIndex = rootBI
            }
            
            updateTimeline()
            updatePreviousNext()
            
            if isMakeRect {
                let rect = koivs.reduce(into: Rect?.none) {
                    $0 += animationView.transformedKeyframeBounds(at: $1.index)
                }
                return (rect, [])
            }
            
        case .insertKeyLines(let kvs):
            if isMakeRect {
                var rect: Rect?, nodes = [Node]()
                for kv in kvs {
                    animationView.elementViews[kv.index].linesView.insert(kv.value)
                    for k in kv.value {
                        let lineView = animationView.elementViews[kv.index].linesView
                            .elementViews[k.index]
                        lineView.isHiddenPoints = animationView.editGrid != .full
                    }
                    
                    rect += kv.value.reduce(into: Rect?.none) {
                        let lineNode = animationView.elementViews[kv.index].linesView
                            .elementViews[$1.index].node.clone
                        lineNode.lineType = .color(.selected)
                        if let b = lineNode.bounds {
                            $0 += animationView.convert(b, to: node)
                        }
                        nodes.append(lineNode)
                    }
                }
                updateWithKeyframeIndex()
                updateTimeline()
                return (rect, nodes)
            } else {
                for kv in kvs {
                    animationView.elementViews[kv.index].linesView.insert(kv.value)
                }
                updateWithKeyframeIndex()
                updateTimeline()
            }
        case .replaceKeyLines(let kvs):
            if isMakeRect {
                var rect: Rect?, nodes = [Node]()
                for kv in kvs {
                    for liv in kv.value {
                        unupdateModel.animation.keyframes[kv.index]
                            .picture.lines[liv.index] = liv.value
                        animationView.elementViews[kv.index].linesView.elementViews[liv.index].updateWithModel()
                    }
                    
                    rect += kv.value.reduce(into: Rect?.none) {
                        let lineNode = animationView.elementViews[kv.index].linesView
                            .elementViews[$1.index].node.clone
                        lineNode.lineType = .color(.selected)
                        if let b = lineNode.bounds {
                            $0 += animationView.convert(b, to: node)
                        }
                        nodes.append(lineNode)
                    }
                }
                updateWithKeyframeIndex()
                updateTimeline()
                return (rect, nodes)
            } else {
                for kv in kvs {
                    for liv in kv.value {
                        unupdateModel.animation.keyframes[kv.index]
                            .picture.lines[liv.index] = liv.value
                        animationView.elementViews[kv.index].linesView.elementViews[liv.index].updateWithModel()
                    }
                }
                updateWithKeyframeIndex()
                updateTimeline()
            }
        case .removeKeyLines(let iivs):
            if isMakeRect {
                var rect: Rect?, nodes = [Node]()
                for iv in iivs {
                    rect += iv.value.reduce(into: Rect?.none) {
                        let lineNode = animationView.elementViews[iv.index].linesView
                            .elementViews[$1].node.clone
                        lineNode.lineType = .color(.removing)
                        if let b = lineNode.bounds {
                            $0 += animationView.convert(b, to: node)
                        }
                        nodes.append(lineNode)
                    }
                    
                    animationView.elementViews[iv.index].linesView.remove(at: iv.value)
                }
                updateWithKeyframeIndex()
                updateTimeline()
                
                return (rect, nodes)
            } else {
                for iv in iivs {
                    animationView.elementViews[iv.index].linesView.remove(at: iv.value)
                }
                updateWithKeyframeIndex()
                updateTimeline()
            }
            
        case .insertKeyPlanes(let kvs):
            if isMakeRect {
                var rect: Rect?, nodes = [Node]()
                for kv in kvs {
                    animationView.elementViews[kv.index].planesView.insert(kv.value)
                    
                    rect += kv.value.reduce(into: Rect?.none) {
                        let planeNode = animationView.elementViews[kv.index].planesView
                            .elementViews[$1.index].node.clone
                        planeNode.fillType = .color(.selected)
                        if let b = planeNode.bounds {
                            $0 += animationView.convert(b, to: node)
                        }
                        nodes.append(planeNode)
                    }
                }
                updateWithKeyframeIndex()
                return (rect, nodes)
            } else {
                for kv in kvs {
                    animationView.elementViews[kv.index].planesView.insert(kv.value)
                }
                updateWithKeyframeIndex()
            }
        case .replaceKeyPlanes(let kvs):
            if isMakeRect {
                var rect: Rect?, nodes = [Node]()
                for kv in kvs {
                    for liv in kv.value {
                        unupdateModel.animation.keyframes[kv.index]
                            .picture.planes[liv.index] = liv.value
                        animationView.elementViews[kv.index].planesView.elementViews[liv.index].updateWithModel()
                    }
                    
                    rect += kv.value.reduce(into: Rect?.none) {
                        let planeNode = animationView.elementViews[kv.index].planesView
                            .elementViews[$1.index].node.clone
                        planeNode.fillType = .color(.selected)
                        if let b = planeNode.bounds {
                            $0 += animationView.convert(b, to: node)
                        }
                        nodes.append(planeNode)
                    }
                }
                updateWithKeyframeIndex()
                updateTimeline()
                return (rect, nodes)
            } else {
                for kv in kvs {
                    for piv in kv.value {
                        unupdateModel.animation.keyframes[kv.index]
                            .picture.planes[piv.index] = piv.value
                        animationView.elementViews[kv.index].planesView.elementViews[piv.index].updateWithModel()
                    }
                }
                updateWithKeyframeIndex()
                updateTimeline()
            }
        case .removeKeyPlanes(let iivs):
            if isMakeRect {
                var rect: Rect?, nodes = [Node]()
                for iv in iivs {
                    rect += iv.value.reduce(into: Rect?.none) {
                        let planeNode = animationView.elementViews[iv.index].planesView
                            .elementViews[$1].node.clone
                        planeNode.fillType = .color(.removing)
                        if let b = planeNode.bounds {
                            $0 += animationView.convert(b, to: node)
                        }
                        nodes.append(planeNode)
                    }
                    
                    animationView.elementViews[iv.index].planesView.remove(at: iv.value)
                }
                updateWithKeyframeIndex()
                
                return (rect, nodes)
            } else {
                for iv in iivs {
                    animationView.elementViews[iv.index].planesView.remove(at: iv.value)
                }
                updateWithKeyframeIndex()
            }
            
        case .insertDraftKeyLines(let kvs):
            if isMakeRect {
                var rect: Rect?, nodes = [Node]()
                for kv in kvs {
                    animationView.elementViews[kv.index].draftLinesView.insert(kv.value)
                    updateDraftLines(from: kv.value.map { $0.index },
                                     atKeyframeIndex: kv.index)
                    
                    rect += kv.value.reduce(into: Rect?.none) {
                        let lineNode = animationView.elementViews[kv.index].draftLinesView
                            .elementViews[$1.index].node.clone
                        lineNode.lineType = .color(.selected)
                        if let b = lineNode.bounds {
                            $0 += animationView.convert(b, to: node)
                        }
                    }
                }
                updateWithKeyframeIndex()
                updateTimeline()
                return (rect, nodes)
            } else {
                for kv in kvs {
                    animationView.elementViews[kv.index].draftLinesView.insert(kv.value)
                    updateDraftLines(from: kv.value.map { $0.index },
                                     atKeyframeIndex: kv.index)
                }
                updateWithKeyframeIndex()
                updateTimeline()
            }
        case .removeDraftKeyLines(let iivs):
            if isMakeRect {
                var rect: Rect?, nodes = [Node]()
                for iv in iivs {
                    rect += iv.value.reduce(into: Rect?.none) {
                        let lineNode = animationView.elementViews[iv.index].draftLinesView
                            .elementViews[$1].node.clone
                        lineNode.lineType = .color(.removing)
                        if let b = lineNode.bounds {
                            $0 += animationView.convert(b, to: node)
                        }
                        nodes.append(lineNode)
                    }
                    
                    animationView.elementViews[iv.index].draftLinesView.remove(at: iv.value)
                }
                updateWithKeyframeIndex()
                updateTimeline()
                
                return (rect, nodes)
            } else {
                for iv in iivs {
                    animationView.elementViews[iv.index].draftLinesView.remove(at: iv.value)
                }
                updateWithKeyframeIndex()
                updateTimeline()
            }
        case .insertDraftKeyPlanes(let kvs):
            if isMakeRect {
                var rect: Rect?, nodes = [Node]()
                for kv in kvs {
                    animationView.elementViews[kv.index].draftPlanesView.insert(kv.value)
                    updateDraftPlanes(from: kv.value.map { $0.index },
                                      atKeyframeIndex: kv.index)
                    
                    rect += kv.value.reduce(into: Rect?.none) {
                        let planeNode = animationView.elementViews[kv.index].draftPlanesView
                            .elementViews[$1.index].node.clone
                        planeNode.fillType = .color(.selected)
                        if let b = planeNode.bounds {
                            $0 += animationView.convert(b, to: node)
                        }
                        nodes.append(planeNode)
                    }
                }
                updateWithKeyframeIndex()
                updateTimeline()
                return (rect, nodes)
            } else {
                for kv in kvs {
                    animationView.elementViews[kv.index].draftPlanesView.insert(kv.value)
                    updateDraftPlanes(from: kv.value.map { $0.index },
                                      atKeyframeIndex: kv.index)
                }
                updateWithKeyframeIndex()
                updateTimeline()
            }
        case .removeDraftKeyPlanes(let iivs):
            if isMakeRect {
                var rect: Rect?, nodes = [Node]()
                for iv in iivs {
                    rect += iv.value.reduce(into: Rect?.none) {
                        let planeNode = animationView.elementViews[iv.index].draftPlanesView
                            .elementViews[$1].node.clone
                        planeNode.fillType = .color(.removing)
                        if let b = planeNode.bounds {
                            $0 += animationView.convert(b, to: node)
                        }
                        nodes.append(planeNode)
                    }
                    
                    animationView.elementViews[iv.index].draftPlanesView.remove(at: iv.value)
                }
                updateWithKeyframeIndex()
                updateTimeline()
                
                return (rect, nodes)
            } else {
                for iv in iivs {
                    animationView.elementViews[iv.index].draftPlanesView.remove(at: iv.value)
                }
                updateWithKeyframeIndex()
                updateTimeline()
            }
            
        case .setLineIDs(let kvs):
            if isMakeRect {
                for kv in kvs {
                    for iov in kv.value {
                        unupdateModel.animation.keyframes[kv.index]
                            .picture.lines[iov.index].interOption = iov.value
                    }
                }
                
                let idSet = Set(kvs.flatMap { $0.value.map { $0.value.id } })
                var nodes = [Node]()
                let rect = model.animation.keyframes.enumerated().reduce(into: Rect?.none) { (n, v) in
                    n += v.element.picture.lines.enumerated().reduce(into: Rect?.none) {
                        if idSet.contains($1.element.interID) {
                            let lineNode = animationView.elementViews[v.offset].linesView
                                .elementViews[$1.offset].node.clone
                            lineNode.lineType = .color(.selected)
                            if let b = lineNode.bounds {
                                $0 += animationView.convert(b, to: node)
                            }
                            nodes.append(lineNode)
                        }
                    }
                }
                
                updateTimeline()
                
                return (rect, nodes)
            } else {
                for kv in kvs {
                    for iov in kv.value {
                        unupdateModel.animation.keyframes[kv.index]
                            .picture.lines[iov.index].interOption = iov.value
                    }
                }
            }
            
        case .setRootKeyframeI(let rootKI):
            if model.animation.rootIndex != rootKI {
                let i = model.animation.index
                unupdateModel.animation.rootIndex = rootKI
                if i != model.animation.index {
                    updateWithKeyframeIndex()
                    updateTimeline()
                    node.draw()
                    if isSleep {
                        Sleep.start(atTime: 0.04)
                    }
                }
            }
            
        case .setAnimationOption(let option):
            unupdateModel.animation.option = option
            updateTimeline()
            updatePreviousNext()
            if isMakeRect {
                return (animationView.transformedPaddingTimelineBounds ?? node.bounds, [])
            }
            
        case .insertNotes(let nivs):
            insertNode(nivs)
            if isMakeRect {
                let rect = nivs.reduce(into: Rect?.none) {
                    $0 += scoreView.transformedNoteFrame(at: $1.index)
                }
                return (rect, [])
            }
        case .replaceNotes(let nivs):
            if isMakeRect {
                var rect: Rect?
                for niv in nivs {
                    rect += scoreView.transformedNoteFrame(at: niv.index)
                }
                replaceNode(nivs)
                for niv in nivs {
                    rect += scoreView.transformedNoteFrame(at: niv.index)
                }
                return (rect, [])
            } else {
                replaceNode(nivs)
            }
        case .removeNotes(noteIndexes: let noteIndexes):
            if isMakeRect {
                let rect = noteIndexes.reduce(into: Rect?.none) {
                    $0 += scoreView.transformedNoteFrame(at: $1)
                }
                removeNotesNode(at: noteIndexes)
                return (rect, [])
            } else {
                removeNotesNode(at: noteIndexes)
            }
            
        case .insertDraftNotes(let nivs):
            insertDraftNode(nivs)
            if isMakeRect {
                let rect = nivs.reduce(into: Rect?.none) {
                    $0 += scoreView.transformedDraftNoteFrame(at: $1.index)
                }
                return (rect, [])
            }
        case .removeDraftNotes(noteIndexes: let noteIndexes):
            if isMakeRect {
                let rect = noteIndexes.reduce(into: Rect?.none) {
                    $0 += scoreView.transformedDraftNoteFrame(at: $1)
                }
                removeDraftNotesNode(at: noteIndexes)
                return (rect, [])
            } else {
                removeDraftNotesNode(at: noteIndexes)
            }
            
        case .insertContents(let civs):
            insertNode(civs)
            
            civs.forEach { contentsView.elementViews[$0.index].updateClippingNode() }
            
            if isMakeRect {
                let rect = civs.reduce(into: Rect?.none) {
                    let contentView = contentsView.elementViews[$1.index]
                    $0 += contentView.node.transformedBounds
                }
                return (rect, [])
            }
        case .replaceContents(let civs):
            if isMakeRect {
                var rect: Rect?
                for civ in civs {
                    unupdateModel.contents[civ.index] = civ.value
                    contentsView.elementViews[civ.index].updateWithModel()
                    rect += contentsView.elementViews[civ.index].node.transformedBounds
                }
                
                civs.forEach { contentsView.elementViews[$0.index].updateClippingNode() }
                
                return (rect, [])
            } else {
                for civ in civs {
                    unupdateModel.contents[civ.index] = civ.value
                    contentsView.elementViews[civ.index].updateWithModel()
                }
                
                civs.forEach { contentsView.elementViews[$0.index].updateClippingNode() }
            }
        case .removeContents(contentIndexes: let contentIndexes):
            if isMakeRect {
                let rect = contentIndexes.reduce(into: Rect?.none) {
                    let contentView = contentsView.elementViews[$1]
                    $0 += contentView.node.transformedBounds
                }
                removeContentsNode(at: contentIndexes)
                return (rect, [])
            } else {
                removeContentsNode(at: contentIndexes)
            }
            
        case .setScoreOption(let option):
            scoreView.option = option
            if isMakeRect {
                return (scoreView.transformedMainFrame, [])
            }
        case .setSheetOption(let option):
            unupdateModel.option = option
            updateMainFrame()
            
            if isMakeRect {
                return (option.mainFrame, [])
            }
        case .setSelection(let selection):
            let oldSelection = model.selection
            unupdateModel.selection = selection
            let rect = updateNode(from: selection, old: oldSelection)
            
            if isMakeRect {
                return (rect, [])
            }
        }
        return (nil, [])
    }
    @discardableResult
    private func appendNode(_ line: Line) -> SheetLineView {
        let lineView = linesView.append(line)
        lineView.isHiddenPoints = animationView.editGrid != .full
        animationView.updateTimelineAtCurrentKeyframe()
        return lineView
    }
    private func appendNode(_ line: Line, atKeyframe ki: Int) -> SheetLineView {
        let lineView = animationView.elementViews[ki].linesView.append(line)
        lineView.isHiddenPoints = animationView.editGrid != .full
        animationView.updateTimeline(atKeyframe: ki)
        return lineView
    }
    private func appendNode(_ lines: [Line]) {
        linesView.append(lines)
    }
    private func appendNode(_ lines: [Line], atKeyframe ki: Int) {
        animationView.elementViews[ki].linesView.append(lines)
    }
    private func removeLastLinesNode(count: Int) {
        linesView.removeLasts(count: count)
        animationView.updateTimelineAtCurrentKeyframe()
    }
    private func removeLastLinesNode(count: Int, atKeyframe ki: Int) {
        animationView.elementViews[ki].linesView.removeLasts(count: count)
        animationView.updateTimelineAtCurrentKeyframe()
    }
    private func removeLinesNode(at lineIndexes: [Int]) {
        linesView.remove(at: lineIndexes)
        animationView.updateTimelineAtCurrentKeyframe()
    }
    
    private func appendNode(_ planes: [Plane]) {
        planesView.append(planes)
    }
    private func removeLastsPlaneNode(count: Int) {
        planesView.removeLasts(count: count)
    }
    private func insertNode(_ livs: [IndexValue<Line>]) {
        linesView.insert(livs)
    }
    private func insertNode(_ pivs: [IndexValue<Plane>]) {
        planesView.insert(pivs)
    }
    private func removePlanesNode(at planeIndexes: [Int]) {
        planesView.remove(at: planeIndexes)
    }
    private func setNode(_ lines: [Line]) {
        linesView.model = lines
    }
    private func setNode(_ planes: [Plane]) {
        planesView.model = planes
    }
    private func setDraftNode(_ lines: [Line]) {
        draftLinesView.model = lines
        
        if !lines.isEmpty {
            draftLinesView.elementViews.forEach {
                $0.node.lineType = .color(.background)
            }
        }
    }
    private func setDraftNode(_ planes: [Plane]) {
        draftPlanesView.model = planes
        
        if !planes.isEmpty {
            draftPlanesView.elementViews.forEach {
                $0.node.fillType = .color($0.model.uuColor.value.with(opacity: $0.model.uuColor.value.opacity * 0.075))
            }
        }
    }
    private func updateDraftLines(from livs: [Int],
                                  atKeyframeIndex ki: Int) {
        if !livs.isEmpty {
            let draftLinesView = animationView.elementViews[ki].draftLinesView
            livs.forEach {
                draftLinesView.elementViews[$0].node.lineType = .color(.background)
            }
        }
    }
    private func updateDraftPlanes(from pivs: [Int],
                                  atKeyframeIndex ki: Int) {
        if !pivs.isEmpty {
            let draftPlanesView = animationView.elementViews[ki].draftPlanesView
            pivs.forEach {
                let planeView = draftPlanesView.elementViews[$0]
                planeView.node.fillType = .color(planeView.model.uuColor.value.with(opacity: planeView.model.uuColor.value.opacity * 0.075))
            }
        }
    }
    private func insertDraftNode(_ livs: [IndexValue<Line>]) {
        draftLinesView.insert(livs)
        updateDraftLines(from: livs.map { $0.index },
                         atKeyframeIndex: model.animation.index)
    }
    private func insertDraftNode(_ pivs: [IndexValue<Plane>]) {
        draftPlanesView.insert(pivs)
        updateDraftPlanes(from: pivs.map { $0.index },
                          atKeyframeIndex: model.animation.index)
    }
    private func removeDraftLinesNode(at lineIndexes: [Int]) {
        draftLinesView.remove(at: lineIndexes)
    }
    private func removeDraftPlanesNode(at planeIndexes: [Int]) {
        draftPlanesView.remove(at: planeIndexes)
    }
    private func insertNode(_ tivs: [IndexValue<Text>]) {
        textsView.insert(tivs)
        for tiv in tivs {
            textsView.elementViews[tiv.index].selectedRangesNotification = { [weak self] textView, ranges in
                self?.updateSelection(from: ranges, textView)
            }
        }
    }
    private func removeTextsNode(at textIndexes: [Int]) {
        textsView.remove(at: textIndexes)
    }
    private func setNode(_ ituv: IndexValue<TextValue>) {
        textsView.elementViews[ituv.index].set(ituv.value)
    }
    
    var selection: SheetSelection {
        get { model.selection }
        set {
            let oldSelection = selection
            unupdateModel.selection = newValue
            updateNode(from: newValue, old: oldSelection)
        }
    }
    var changeSelectedFrameNotifications = [((SheetView, SheetSelection) -> ())]()
    @discardableResult
    func updateNode(from selection: SheetSelection, old oldSelection: SheetSelection?) -> Rect? {
        var rect: Rect?
        var isChangedTimeline = false
        animationView.elementViews.enumerated().forEach {
            let nKeyframeSelection = selection.keyframeSelections[$0.offset]
            
            $0.element.linesView.elementViews.enumerated().forEach {
                let nIsSelected = nKeyframeSelection?.lineIs.contains($0.offset) ?? false
                if nIsSelected != $0.element.isSelected {
                    $0.element.isSelected = nIsSelected
                    rect += $0.element.node.transformedBounds
                }
            }
            $0.element.planesView.elementViews.enumerated().forEach {
                let nIsSelected = nKeyframeSelection?.planeIs.contains($0.offset) ?? false
                if nIsSelected != $0.element.isSelected {
                    $0.element.isSelected = nIsSelected
                    rect += $0.element.node.transformedBounds
                }
            }
            
            let nIsSelected = nKeyframeSelection != nil
            if nIsSelected != $0.element.isSelected {
                $0.element.isSelected = nIsSelected
                isChangedTimeline = true
            }
        }
        if isChangedTimeline {
            animationView.updateTimeline()
        }
        
        scoreView.selectedNotePitSprolIs = selection.notePitSprolIs
        
        textsView.elementViews.enumerated().forEach {
            let nTextSelection = selection.textSelections[$0.offset]
            let text = $0.element.model
            let nSelectedRanges = nTextSelection?.ranges.map { text.string.range(fromInt: $0) } ?? []
            if nSelectedRanges != $0.element.selectedRanges {
                $0.element.selectedRanges = nSelectedRanges
                rect += $0.element.node.transformedBounds
            }
        }
        
        contentsView.elementViews.enumerated().forEach {
            let nIsSelected = selection.contentIs.contains($0.offset)
            if nIsSelected != $0.element.isSelected {
                $0.element.isSelected = nIsSelected
                rect += $0.element.node.transformedBounds
            }
        }
        
        if oldSelection == nil || selection.isChangeSelectedFrame(old: oldSelection!) {
            updateSelectedFrame()
            changeSelectedFrameNotifications.forEach { $0(self, selection) }
        }
        
        return rect
    }
    
    private func changeColorsNode(_ colorValue: ColorValue) {
        if !colorValue.planeIndexes.isEmpty {
            colorValue.planeIndexes.forEach {
                planesView.elementViews[$0].uuColor = colorValue.uuColor
            }
        } else if !colorValue.planeAnimationIndexes.isEmpty {
            if colorValue.animationColors.count == colorValue.planeAnimationIndexes.count {
                for (ki, v) in colorValue.planeAnimationIndexes.enumerated() {
                    let uuColor = UUColor(colorValue.animationColors[ki],
                                          id: colorValue.uuColor.id)
                    for i in v.value {
                        animationView.elementViews[v.index].planesView.elementViews[i]
                            .uuColor = uuColor
                    }
                }
            } else {
                for v in colorValue.planeAnimationIndexes {
                    for i in v.value {
                        animationView.elementViews[v.index].planesView.elementViews[i].uuColor = colorValue.uuColor
                    }
                }
            }
        }
        
        if !colorValue.lineIndexes.isEmpty {
            colorValue.lineIndexes.forEach {
                linesView.elementViews[$0].uuColor = colorValue.uuColor
            }
        } else if !colorValue.lineAnimationIndexes.isEmpty {
            if colorValue.animationColors.count == colorValue.lineAnimationIndexes.count {
                for (ki, v) in colorValue.lineAnimationIndexes.enumerated() {
                    let uuColor = UUColor(colorValue.animationColors[ki],
                                          id: colorValue.uuColor.id)
                    for i in v.value {
                        animationView.elementViews[v.index].linesView.elementViews[i]
                            .uuColor = uuColor
                    }
                }
            } else {
                for v in colorValue.lineAnimationIndexes {
                    for i in v.value {
                        animationView.elementViews[v.index].linesView.elementViews[i].uuColor = colorValue.uuColor
                    }
                }
            }
        }
        
        if colorValue.isBackground {
            backgroundUUColor = colorValue.uuColor
        }
    }
    func update(_ colorValue: ColorValue) {
        if !colorValue.planeIndexes.isEmpty {
            var picture = model.picture
            for pi in colorValue.planeIndexes {
                picture.planes[pi].uuColor = colorValue.uuColor
            }
            unupdateModel.picture = picture
            for pi in colorValue.planeIndexes {
                planesView.elementViews[pi].updateColor()
            }
        } else if !colorValue.planeAnimationIndexes.isEmpty {
            var keyframes = model.animation.keyframes
            if colorValue.animationColors.count == colorValue.planeAnimationIndexes.count {
                for (ki, v) in colorValue.planeAnimationIndexes.enumerated() {
                    let uuColor = UUColor(colorValue.animationColors[ki],
                                          id: colorValue.uuColor.id)
                    for i in v.value {
                        keyframes[v.index].picture.planes[i].uuColor = uuColor
                    }
                }
            } else {
                for v in colorValue.planeAnimationIndexes {
                    for i in v.value {
                        keyframes[v.index].picture.planes[i].uuColor = colorValue.uuColor
                    }
                }
            }
            unupdateModel.animation.keyframes = keyframes
            for v in colorValue.planeAnimationIndexes {
                for i in v.value {
                    animationView.elementViews[v.index].planesView.elementViews[i].updateColor()
                }
            }
        }
        
        if !colorValue.lineIndexes.isEmpty {
            var picture = model.picture
            for li in colorValue.lineIndexes {
                picture.lines[li].uuColor = colorValue.uuColor
            }
            unupdateModel.picture = picture
            for li in colorValue.lineIndexes {
                linesView.elementViews[li].updateColor()
            }
        } else if !colorValue.lineAnimationIndexes.isEmpty {
            var keyframes = model.animation.keyframes
            if colorValue.animationColors.count == colorValue.lineAnimationIndexes.count {
                for (ki, v) in colorValue.lineAnimationIndexes.enumerated() {
                    let uuColor = UUColor(colorValue.animationColors[ki],
                                          id: colorValue.uuColor.id)
                    for i in v.value {
                        keyframes[v.index].picture.lines[i].uuColor = uuColor
                    }
                }
            } else {
                for v in colorValue.lineAnimationIndexes {
                    for i in v.value {
                        keyframes[v.index].picture.lines[i].uuColor = colorValue.uuColor
                    }
                }
            }
            unupdateModel.animation.keyframes = keyframes
            for v in colorValue.lineAnimationIndexes {
                for i in v.value {
                    animationView.elementViews[v.index].linesView.elementViews[i].updateColor()
                }
            }
        }
        
        if colorValue.isBackground {
            backgroundUUColor = colorValue.uuColor
        }
    }
    
    private func insertNode(_ nivs: [IndexValue<Note>]) {
        scoreView.insert(nivs)
        updateScoreViewFromOtherAround()
    }
    private func replaceNode(_ nivs: [IndexValue<Note>]) {
        scoreView.replace(nivs)
        updateScoreViewFromOtherAround()
    }
    private func removeNotesNode(at noteIndexes: [Int]) {
        scoreView.remove(at: noteIndexes)
        updateScoreViewFromOtherAround()
    }
    
    private func insertDraftNode(_ nivs: [IndexValue<Note>]) {
        scoreView.insertDraft(nivs)
    }
    private func removeDraftNotesNode(at noteIndexes: [Int]) {
        scoreView.removeDraft(at: noteIndexes)
    }
    
    private func insertNode(_ civs: [IndexValue<Content>]) {
        contentsView.insert(civs)
    }
    private func removeContentsNode(at contentIndexes: [Int]) {
        contentsView.remove(at: contentIndexes)
    }
    
    private func insertNode(_ bivs: [IndexValue<Border>]) {
        bordersView.insert(bivs)
        let bounds = self.bounds
        bivs.forEach {
            bordersView.elementViews[$0.index].bounds = bounds
            bordersView.elementViews[$0.index].screenToWorldScale = screenToWorldScale
        }
    }
    private func removeBordersNode(at borderIndexes: [Int]) {
        bordersView.remove(at: borderIndexes)
    }
    
    func append(_ line: Line) {
        set(.appendLine(line))
    }
    func append(_ line: Line, atRoot rootKI: Int) {
        set(.appendKeyLine(.init(value: line,
                                       index: model.animation.index(atRoot: rootKI))),
            rootKI: rootKI)
    }
    func append(_ lines: [Line]) {
        if lines.count == 1 {
            append(lines[0])
        } else {
            set(.appendLines(lines))
        }
    }
    func append(_ kvs: [IndexValue<[Line]>]) {
        let vs = kvs.map { kv in
            let lines = model.animation.keyframes[kv.index].picture.lines
            let livs = kv.value.enumerated().map {
                IndexValue(value: $0.element, index: lines.count + $0.offset)
            }
            return IndexValue(value: livs, index: kv.index)
        }
        insertKeyLines(vs)
    }
    func insert(_ livs: [IndexValue<Line>]) {
        set(.insertLines(livs))
    }
    func insertKeyLines(_ kvs: [IndexValue<[IndexValue<Line>]>]) {
        if kvs.count == 1 && kvs[0].index == model.animation.index {
            insert(kvs[0].value)
        } else {
            set(.insertKeyLines(kvs))
        }
    }
    func replace(_ line: Line, at i: Int) {
        replace(IndexValue(value: line, index: i))
    }
    func replace(_ liv: IndexValue<Line>) {
        set(.replaceLines([liv]))
    }
    func replace(_ livs: [IndexValue<Line>]) {
        set(.replaceLines(livs))
    }
    func replaceKeyLines(_ kvs: [IndexValue<[IndexValue<Line>]>]) {
        if kvs.count == 1 && kvs[0].index == model.animation.index {
            replace(kvs[0].value)
        } else {
            set(.replaceKeyLines(kvs))
        }
    }
    func capture(old oldLine: Line, at i: Int) {
        capture(old: IndexValue(value: oldLine, index: i))
    }
    func capture(old oldLIV: IndexValue<Line>) {
        cap(undo: .replaceLines([oldLIV]))
    }
    func capture(old oldLIVs: [IndexValue<Line>]) {
        cap(undo: .replaceLines(oldLIVs))
    }
    func removeLines(at lis: [Int]) {
        set(.removeLines(lineIndexes: lis))
    }
    func removeKeyLines(_ kvs: [IndexValue<[Int]>]) {
        if kvs.count == 1 && kvs[0].index == model.animation.index {
            removeLines(at: kvs[0].value)
        } else {
            set(.removeKeyLines(kvs))
        }
    }
    
    func append(_ planes: [Plane]) {
        set(.appendPlanes(planes))
    }
    func append(_ kvs: [IndexValue<[Plane]>]) {
        let vs = kvs.map { kv in
            let planes = model.animation.keyframes[kv.index].picture.planes
            let pivs = kv.value.enumerated().map {
                IndexValue(value: $0.element, index: planes.count + $0.offset)
            }
            return IndexValue(value: pivs, index: kv.index)
        }
        insertKeyPlanes(vs)
    }
    func insert(_ pivs: [IndexValue<Plane>]) {
        set(.insertPlanes(pivs))
    }
    func insertKeyPlanes(_ kvs: [IndexValue<[IndexValue<Plane>]>]) {
        if kvs.count == 1 && kvs[0].index == model.animation.index {
            insert(kvs[0].value)
        } else {
            set(.insertKeyPlanes(kvs))
        }
    }
    func replace(_ plane: Plane, at i: Int) {
        replace(IndexValue(value: plane, index: i))
    }
    func replace(_ piv: IndexValue<Plane>) {
        set(.replacePlanes([piv]))
    }
    func replace(_ pivs: [IndexValue<Plane>]) {
        set(.replacePlanes(pivs))
    }
    func replaceKeyPlanes(_ kvs: [IndexValue<[IndexValue<Plane>]>]) {
        if kvs.count == 1 && kvs[0].index == model.animation.index {
            replace(kvs[0].value)
        } else {
            set(.replaceKeyPlanes(kvs))
        }
    }
    func capture(old oldPlane: Plane, at i: Int) {
        capture(old: IndexValue(value: oldPlane, index: i))
    }
    func capture(old oldPIV: IndexValue<Plane>) {
        cap(undo: .replacePlanes([oldPIV]))
    }
    func capture(old oldPIVs: [IndexValue<Plane>]) {
        cap(undo: .replacePlanes(oldPIVs))
    }
    func removePlanes(at pis: [Int]) {
        set(.removePlanes(planeIndexes: pis))
    }
    func removeKeyPlanes(_ kvs: [IndexValue<[Int]>]) {
        if kvs.count == 1 && kvs[0].index == model.animation.index {
            removePlanes(at: kvs[0].value)
        } else {
            set(.removeKeyPlanes(kvs))
        }
    }
    
    func set(_ planeValue: PlaneValue) {
        set(.setPlaneValue(planeValue))
    }
    func set(_ pvkvs: [IndexValue<PlaneValue>]) {
        set(.setKeyPlaneValues(pvkvs))
    }
    
    func appendDraftKeyLines(_ kvs: [IndexValue<[Line]>]) {
        let nkvs = kvs.map { kv in
            let lines = model.animation.keyframes[kv.index].draftPicture.lines
            let livs = kv.value.enumerated().map {
                IndexValue(value: $0.element, index: lines.count + $0.offset)
            }
            return IndexValue(value: livs, index: kv.index)
        }
        insertDraftKeyLines(nkvs)
    }
    func insertDraft(_ livs: [IndexValue<Line>]) {
        set(.insertDraftLines(livs))
    }
    func insertDraftKeyLines(_ kvs: [IndexValue<[IndexValue<Line>]>]) {
        set(.insertDraftKeyLines(kvs))
    }
    func set(_ kvs: [IndexValue<[IndexValue<InterOption>]>]) {
        set(.setLineIDs(kvs))
    }
    func removeDraftLines(at lis: [Int]) {
        set(.removeDraftLines(lineIndexes: lis))
    }
    func removeDraftKeyLines(_ kvs: [IndexValue<[Int]>]) {
        set(.removeDraftKeyLines(kvs))
    }
    
    func appendDraftKeyPlanes(_ kvs: [IndexValue<[Plane]>]) {
        let nkvs = kvs.map { kv in
            let planes = model.animation.keyframes[kv.index].draftPicture.planes
            let pivs = kv.value.enumerated().map {
                IndexValue(value: $0.element, index: planes.count + $0.offset)
            }
            return IndexValue(value: pivs, index: kv.index)
        }
        insertKeyPlanes(nkvs)
    }
    func insertDraft(_ pivs: [IndexValue<Plane>]) {
        set(.insertDraftPlanes(pivs))
    }
    func insertDraftKeyPlanes(_ values: [IndexValue<[IndexValue<Plane>]>]) {
        set(.insertDraftKeyPlanes(values))
    }
    func removeDraftPlanes(at pis: [Int]) {
        set(.removeDraftPlanes(planeIndexes: pis))
    }
    func removeDraftKeyPlanes(_ kvs: [IndexValue<[Int]>]) {
        set(.removeDraftKeyPlanes(kvs))
    }
    
    func set(_ picture: Picture) {
        set(.setPicture(picture))
    }
    func removeDraft() {
        setDraft(Picture())
    }
    func setDraft(_ draftPicture: Picture) {
        set(.setDraftPicture(draftPicture))
    }
    func changeToDraft() {
        if !model.draftPicture.isEmpty {
            removeDraft()
        }
        set(.changeToDraft(isReverse: false))
    }
    
    func set(_ cv: ColorValue, oldColorValue: ColorValue) {//
        set(.changedColors(cv))
    }
    func set(_ cv: ColorValue) {
        set(.changedColors(cv))
    }
    func capture(_ cv: ColorValue, old oldCV: ColorValue) {
        cap(undo: .changedColors(oldCV))
    }
    
    func insert(_ kivs: [IndexValue<Keyframe>]) {
        set(.insertKeyframes(kivs))
    }
    func set(_ koivs: [IndexValue<KeyframeOption>]) {
        set(.setKeyframeOptions(koivs))
    }
    func set(keyframeBeat beat: Rational, at ki: Int) {
        let ko = model.animation.keyframes[ki].option
        set(.setKeyframeOptions([IndexValue(value: ko.with(beat: beat), index: ki)]))
    }
    func capture(keyframeBeat beat: Rational, oldBeat: Rational, at ki: Int) {
        let ko = model.animation.keyframes[ki].option
        cap(undo: .setKeyframeOptions([IndexValue(value: ko.with(beat: oldBeat), index: ki)]))
    }
    func capture(old okoivs: [IndexValue<KeyframeOption>]) {
        cap(undo: .setKeyframeOptions(okoivs))
    }
    func removeKeyframes(at kis: [Int]) {
        set(.removeKeyframes(kis))
    }
    
    func set(_ option: AnimationOption) {
        set(.setAnimationOption(option))
    }
    func capture(old oldOption: AnimationOption) {
        cap(undo: .setAnimationOption(oldOption))
    }
    
    func append(_ text: Text) {
        set(.insertTexts([.init(value: text, index: model.texts.count)]))
    }
    func append(_ texts: [Text]) {
        set(.insertTexts(texts.enumerated().map { IndexValue(value: $0.element, index: model.texts.count + $0.offset) }))
    }
    func insert(_ tivs: [IndexValue<Text>]) {
        set(.insertTexts(tivs))
    }
    func replace(_ text: Text, at i: Int) {
        replace(IndexValue(value: text, index: i))
    }
    func replace(_ tiv: IndexValue<Text>) {
        set(.replaceTexts([tiv]))
    }
    func replace(_ tivs: [IndexValue<Text>]) {
        set(.replaceTexts(tivs))
    }
    func capture(old oldText: Text, at i: Int) {
        capture(old: IndexValue(value: oldText, index: i))
    }
    func capture(old oldTIV: IndexValue<Text>) {
        cap(undo: .replaceTexts([oldTIV]))
    }
    func capture(old oldTIVs: [IndexValue<Text>]) {
        cap(undo: .replaceTexts(oldTIVs))
    }
    func removeText(at ti: Int) {
        set(.removeTexts([ti]))
    }
    func removeTexts(at tis: [Int]) {
        set(.removeTexts(tis))
    }
    
    func capture(_ ituv: IndexValue<TextValue>, old oituv: IndexValue<TextValue>) {
        cap(undo: .replaceString(oituv))
    }
    func replace(_ tviv: IndexValue<TextValue>) {
        set(.replaceString(tviv))
    }
    
    func append(_ note: Note) {
        append([note])
    }
    func append(_ notes: [Note]) {
        set(.insertNotes(notes.enumerated().map {
            IndexValue(value: $0.element, index: model.score.notes.count + $0.offset)
        }))
    }
    func captureAppend(_ note: Note) {
        captureAppend([note])
    }
    func captureAppend(_ notes: [Note]) {
        cap(undo: .removeNotes(noteIndexes: Array((model.score.notes.count - notes.count) ..< (model.score.notes.count))))
    }
    func insert(_ nivs: [IndexValue<Note>]) {
        set(.insertNotes(nivs))
    }
    func capture(_ note: Note, old oldNote: Note, at ni: Int) {
        capture([.init(value: note, index: ni)], old: [.init(value: oldNote, index: ni)])
    }
    func capture(_ values: [IndexValue<Note>], old oldValues: [IndexValue<Note>]) {
        cap(undo: .replaceNotes(oldValues))
    }
    func replace(_ note: Note, at ni: Int) {
        replace([.init(value: note, index: ni)])
    }
    func replace(_ values: [IndexValue<Note>]) {
        set(.replaceNotes(values))
    }
    func removeNote(at i: Int) {
        set(.removeNotes(noteIndexes: [i]))
    }
    func removeNotes(at noteIndexes: [Int]) {
        set(.removeNotes(noteIndexes: noteIndexes))
    }
    
    func insertDraft(_ nivs: [IndexValue<Note>]) {
        set(.insertDraftNotes(nivs))
    }
    func removeDraftNotes(at nis: [Int]) {
        set(.removeDraftNotes(noteIndexes: nis))
    }
    
    func set(_ option: ScoreOption) {
        set(.setScoreOption(option))
    }
    func capture(old oldOption: ScoreOption) {
        cap(undo: .setScoreOption(oldOption))
    }
    
    func append(_ content: Content) {
        set(.insertContents([IndexValue(value: content, index: model.contents.count)]))
    }
    func replace(_ content: Content, at i: Int) {
        replace(IndexValue(value: content, index: i))
    }
    func replace(_ civ: IndexValue<Content>) {
        set(.replaceContents([civ]))
    }
    func replace(_ civs: [IndexValue<Content>]) {
        set(.replaceContents(civs))
    }
    func capture(old oldContent: Content, at i: Int) {
        cap(undo: .replaceContents([IndexValue(value: oldContent, index: i)]))
    }
    func capture(old oldCIVs: [IndexValue<Content>]) {
        cap(undo: .replaceContents(oldCIVs))
    }
    func removeContent(at i: Int) {
        set(.removeContents(contentIndexes: [i]))
    }
    func removeContents(at cis: [Int]) {
        set(.removeContents(contentIndexes: cis))
    }
    
    func removeBorder(at i: Int) {
        set(.removeBorders(borderIndexes: [i]))
    }
    func capture(_ border: Border, old oldBorder: Border, at i: Int) {
        cap(undo: .insertBorders([IndexValue(value: oldBorder, index: i)]))
        cap(undo: .removeBorders(borderIndexes: [i]))
    }
    
    func set(_ option: SheetOption) {
        set(.setSheetOption(option))
    }
    func capture(old oldOption: SheetOption) {
        cap(undo: .setSheetOption(oldOption))
    }
    
    func set(_ selection: SheetSelection) {
        set(.setSelection(selection))
    }
    func capture(old oldSelection: SheetSelection) {
        cap(undo: .setSelection(oldSelection))
    }
    
    func textTuple(at p: Point, scale: Double) -> (textView: SheetTextView,
                                                   textIndex: Int,
                                                   stringIndex: String.Index,
                                                   cursorIndex: String.Index)? {
        var n: (textView: SheetTextView,
                textIndex: Int,
                stringIndex: String.Index,
                cursorIndex: String.Index)?
        var minD = Double.infinity
        for (ti, textView) in textsView.elementViews.enumerated() {
            if textView.transformedBounds?.contains(p) ?? false {
                let textP = textView.convert(p, from: node)
                if let i = textView.characterIndex(for: textP),
                   let cr = textView.characterRatio(for: textP) {
                    
                    let sri = cr > 0.5 ?
                        textView.typesetter.index(after: i) : i
                    
                    let np = textView.typesetter.characterPosition(at: sri)
                    let d = p.distanceSquared(textView.convert(np, to: node))
                    if d < minD {
                        minD = d
                        n = (textView, ti, i, sri)
                    }
                }
            }
        }
        return n
    }
    
    func isDefaultPlaneColor(at p: Point, scale: Double) -> Bool {
        let uuColor = sheetColorOwnerFromPlane(at: p, scale: scale).uuColor
        return uuColor == Sheet.defalutBackgroundUUColor
        || (uuColor.id == .two && uuColor.value.opacity == 0)
    }
    func lineTuple(at p: Point, isEnabledPlane: Bool = false,
                   isSelectedOnly: Bool = false,
                   removingUUColor: UUColor? = nil,
                   scale: Double) -> (lineView: SheetLineView, lineIndex: Int)? {
        let isNoneDefaultColorPlane = isEnabledPlane
        && !model.picture.planes.isEmpty
        && !isDefaultPlaneColor(at: p, scale: scale)
        let ds = if isNoneDefaultColorPlane {
            0.0
        } else if textTuple(at: p, scale: scale) != nil {
            animationView.convertFromWorldScale(4 * scale)
        } else {
            animationView.convertFromWorldScale(40 * scale)
        }
        
        let p = animationView.convert(p, from: node)
        var minI: Int?, minDSq = Double.infinity
        for (i, line) in model.picture.lines.enumerated().reversed() {
            guard !isSelectedOnly || keyframeView.linesView.elementViews[i].isSelected else { continue }
            guard line.uuColor != removingUUColor else { continue }
            if line.uuColor != Line.defaultUUColor && isNoneDefaultColorPlane {
                if line.containsPressure(at: p) {
                    return (linesView.elementViews[i], i)
                }
            } else {
                let (dSq, pressure) = line.minDistanceSquaredAndPressure(at: p)
                let nd = line.size / (isNoneDefaultColorPlane ? 4 : 2) * pressure + ds
                let ldSq = nd * nd
                if dSq < minDSq && dSq < ldSq {
                    minDSq = dSq
                    minI = i
                }
            }
        }
        return if let minI { (linesView.elementViews[minI], minI) } else { nil }
    }
    
    func capture(intRange: Range<Int>, subString: String,
                 captureString: String, captureOrigin: Point?,
                 captureSize: Double?, captureWidthCount: Double?,
                 at i: Int, in textView: SheetTextView) {
        let oldIntRange = intRange.lowerBound ..< (intRange.lowerBound + subString.count)
        let range = captureString.range(fromInt: intRange)
        
        let newOrigin, oldOrigin: Point?
        if let captureOrigin = captureOrigin,
           captureOrigin != textView.model.origin {
            newOrigin = textView.model.origin
            oldOrigin = captureOrigin
        } else {
            newOrigin = nil
            oldOrigin = nil
        }
        
        let newSize, oldSize: Double?
        if let captureSize = captureSize,
           captureSize != textView.model.size {
            newSize = textView.model.size
            oldSize = captureSize
        } else {
            newSize = nil
            oldSize = nil
        }
        
        let newWidthCount, oldWidthCount: Double?
        if let captureWidthCount = captureWidthCount,
           captureWidthCount != textView.model.widthCount {
            newWidthCount = textView.model.widthCount
            oldWidthCount = captureWidthCount
        } else {
            newWidthCount = nil
            oldWidthCount = nil
        }
        
        let otv = TextValue(string: String(captureString[range]),
                            replacedRange: oldIntRange,
                            origin: oldOrigin, size: oldSize,
                            widthCount: oldWidthCount)
        let tv = TextValue(string: subString,
                           replacedRange: intRange,
                           origin: newOrigin, size: newSize,
                           widthCount: newWidthCount)
        capture(IndexValue(value: tv, index: i),
                old: IndexValue(value: otv, index: i))
    }
    func capture(captureOrigin: Point,
                 at i: Int, in textView: SheetTextView) {
        let newOrigin = textView.model.origin
        guard newOrigin != captureOrigin else { return }
        let oldOrigin = captureOrigin
        
        let otv = TextValue(string: "", replacedRange: 0 ..< 0,
                            origin: oldOrigin, size: nil, widthCount: nil)
        let tv = TextValue(string: "", replacedRange: 0 ..< 0,
                           origin: newOrigin, size: nil, widthCount: nil)
        capture(IndexValue(value: tv, index: i),
                old: IndexValue(value: otv, index: i))
    }
    
    func lassoErase(with lasso: Lasso,
                    isRemove: Bool,
                    isEnabledLine: Bool = true,
                    isEnabledPlane: Bool = true,
                    isEnabledText: Bool = true,
                    isEnabledContent: Bool = true,
                    isDraft: Bool = false,
                    isUpdatedNewUndoGroup: Bool = false,
                    distance d: Double = 0) -> SheetValue? {
        guard let nlb = lasso.bounds else { return nil }
        
        var isUpdatedNewUndoGroup = isUpdatedNewUndoGroup
        func updateUndoGroup() {
            if !isUpdatedNewUndoGroup {
                newUndoGroup()
                if !model.selection.isEmpty {
                    set(SheetSelection.empty)
                }
                isUpdatedNewUndoGroup = true
            }
        }
        
        var ssValue = SheetValue(id: id, rootKeyframeIndex: model.animation.rootIndex,
                                 isSelected: true)
        
        let nPath = lasso.line.path(isClosed: true, isPolygon: false)
        
        if isEnabledLine {
            let linesView = isDraft ? self.draftLinesView : self.linesView
            var removeLines = [Line](), splitedLines = [Line]()
            var removeLineIndexes = [Int]()
            let nSplitLines: [Line], nd: Double
            if d > 0 {
                let snlb = nlb.outset(by: d + 0.0001)
                let splitLines = linesView.model.filter {
                    $0.bounds?.outset(by: $0.size / 2).intersects(snlb) ?? false
                }
                if splitLines.count < 50 {
                    let count = splitLines.reduce(0) {
                        lasso.intersects($1) ? $0 + 1 : $0
                    }
                    nd = count <= 3 ? d * 2 : d
                    nSplitLines = splitLines
                } else {
                    nd = d
                    nSplitLines = []
                }
            } else {
                nd = d
                nSplitLines = []
            }
            for (i, aLine) in linesView.model.enumerated() {
                if let splitedLine = lasso
                    .splitedLine(with: aLine,
                                 splitLines: nSplitLines,
                                 distance: nd) {
                    switch splitedLine {
                    case .around(let line):
                        removeLineIndexes.append(i)
                        removeLines.append(line)
                    case .split((let aRemoveLines, var aSplitLines)):
                        removeLineIndexes.append(i)
                        removeLines += aRemoveLines
                        if !aSplitLines.isEmpty {
                            let idI: Int
                            if aSplitLines.count == 1 {
                                idI = 0
                            } else {
                                var maxD = 0.0, j = 0
                                for (k, l) in aSplitLines.enumerated() {
                                    let d = l.length()
                                    if d > maxD {
                                        j = k
                                        maxD = d
                                    }
                                }
                                idI = j
                            }
                            for i in aSplitLines.count.range {
                                if i == idI {
                                    aSplitLines[idI].interID = aLine.interID
                                    aSplitLines[idI].interType = aLine.interType
                                } else {
                                    aSplitLines[i].interID = .init()
                                }
                            }
                            
                            splitedLines += aSplitLines
                        }
                    }
                }
            }
            if isRemove && (!removeLineIndexes.isEmpty || !splitedLines.isEmpty) {
                updateUndoGroup()
                if !removeLineIndexes.isEmpty {
                    if isDraft {
                        self.removeDraftLines(at: removeLineIndexes)
                    } else {
                        self.removeLines(at: removeLineIndexes)
                    }
                }
                if isDraft {
                    insertDraft(splitedLines.enumerated().map {
                        IndexValue(value: $0.element, index: $0.offset)
                    })
                } else {
                    append(splitedLines)
                }
            }
            ssValue.lines = removeLines
        }
        
        if isEnabledPlane {
            let planesView = isDraft ? self.draftPlanesView : self.planesView
            let indexValues = planesView.elementViews.enumerated().compactMap { (pi, planeView) in
                nPath.contains(planeView.node.path) ?
                IndexValue(value: planeView.model, index: pi) : nil
            }
            if !indexValues.isEmpty {
                if isRemove {
                    updateUndoGroup()
                    if isDraft {
                        removeDraftPlanes(at: indexValues.map { $0.index })
                    } else {
                        removePlanes(at: indexValues.map { $0.index })
                    }
                }
                ssValue.planes += indexValues.map { $0.value }
            }
            if isRemove {
                let iSet = Set(indexValues.map { $0.index })
                var repPlanes = [IndexValue<Plane>]()
                for (i, planeView) in planesView.elementViews.enumerated() {
                    guard !iSet.contains(i) else { continue }
                    var plane = planeView.model
                    if !plane.topolygon.holePolygons.isEmpty {
                        var nHolePolygons = plane.topolygon.holePolygons, isRemove = false
                        for (j, holePolygon) in plane.topolygon.holePolygons.enumerated().reversed() {
                            if nPath.contains(Path(holePolygon)) {
                                nHolePolygons.remove(at: j)
                                isRemove = true
                            }
                        }
                        if isRemove {
                            plane.topolygon.holePolygons = nHolePolygons
                            repPlanes.append(IndexValue(value: plane, index: i))
                        }
                    }
                }
                if !repPlanes.isEmpty {
                    updateUndoGroup()
                    removePlanes(at: repPlanes.map { $0.index })
                    insert(repPlanes)
                }
            }
        }
        
        if isEnabledText {
            for (ti, textView) in textsView.elementViews.enumerated().reversed() {
                
                guard textView.transformedBounds.intersects(nlb) else { continue }
                var ranges = [Range<String.Index>]()
                for typeline in textView.typesetter.typelines {
                    let tlRange = typeline.range
                    var oldI: String.Index?
                    var isRemoveAll = true
                    
                    let range: Range<String.Index>
                    if !typeline.isReturnEnd {
                        range = tlRange
                    } else if tlRange.lowerBound < tlRange.upperBound {
                        range = tlRange.lowerBound ..< tlRange.upperBound
                    } else { continue }
                    
                    for i in textView.model.string[range].indices {
                        let tb = textView.typesetter
                            .characterBounds(at: i)!
                            .outset(by: textView.lassoPadding)
                            + textView.model.origin
                        if nPath.intersects(tb) {
                            if oldI == nil {
                                oldI = i
                            }
                        } else {
                            isRemoveAll = false
                            if let oldI = oldI {
                                ranges.append(oldI ..< i)
                            }
                            oldI = nil
                        }
                    }
                    if isRemoveAll {
                        ranges.append(tlRange)
                    } else if let oldI = oldI, oldI < range.upperBound {
                        ranges.append(oldI ..< range.upperBound)
                    }
                    oldI = nil
                }
                
                guard !ranges.isEmpty else { continue }
                
                var minP = textView.typesetter
                    .characterPosition(at: textView.model.string.startIndex)
                var minI = textView.model.string.endIndex
                for range in ranges {
                    let i = range.lowerBound
                    if i < minI {
                        minI = i
                        minP = textView.typesetter
                            .characterPosition(at: i)
                    }
                }
                let oldText = textView.model
                var text = textView.model
                var removedText = text
                removedText.string = ""
                for range in ranges {
                    removedText.string += text.string[range]
                }
                for range in ranges.reversed() {
                    text.string.removeSubrange(range)
                }
                removedText.origin += minP
                
                if isRemove {
                    if text.string.isEmpty {
                        updateUndoGroup()
                        removeText(at: ti)
                    } else {
                        let os = oldText.string
                        let range = os
                            .intRange(from: os.startIndex ..< os.endIndex)
                        
                        let sb = bounds.inset(by: Sheet.textPadding)
                        let origin: Point?
                        if let textFrame = text.frame,
                           !sb.contains(textFrame) {
                           
                            let nFrame = sb.clipped(textFrame)
                            origin = text.origin + nFrame.origin - textFrame.origin
                        } else {
                            origin = nil
                        }
                        
                        let tuv = TextValue(string: text.string,
                                            replacedRange: range,
                                            origin: origin, size: nil,
                                            widthCount: nil)
                        updateUndoGroup()
                        replace(IndexValue(value: tuv, index: ti))
                    }
                }
                
                ssValue.texts.append(removedText)
            }
        }
        
        if isEnabledContent {
            let indexValues = contentsView.elementViews.enumerated().compactMap { (ci, contentView) in
                if let f = contentView.imageFrame, nPath.intersects(f) {
                    IndexValue(value: contentView.model, index: ci)
                } else { nil }
            }
            if !indexValues.isEmpty {
                if isRemove {
                    updateUndoGroup()
                    removeContents(at: indexValues.map { $0.index })
                }
                ssValue.contents += indexValues.map { $0.value }
            }
        }
        
        return ssValue.isEmpty ? nil : ssValue
    }
    
    @MainActor
    func fillAll(withClipping cb: Rect?, selectedKeyframeIs: [Int], isOutClip: Bool) -> Bool {
        if selectedKeyframeIs.isEmpty || !model.isEnabledAnimation {
            return fillAllFromKeyframeIndex(withClipping: cb, isOutClip: isOutClip)
        }
        
        let b = bounds, borders = model.borders
        let pictures = model.animation.keyframes[selectedKeyframeIs].map { $0.picture }
        
        let progressPanel = ProgressPanel(message: "Making Faces".localized)
        node.root.show(progressPanel)
        let task = Task.detached {
            let progress = ActorProgress(total: selectedKeyframeIs.count)
            let nPolyss = try? await withThrowingTaskGroup(of: (i: Int, polys: [Topolygon]).self,
                                                          returning: [[Topolygon]]?.self) { group in
                for i in selectedKeyframeIs.count.range {
                    group.addTask(priority: .high) {
                        try Task.checkCancellation()
                        let v = pictures[i].makePolygons(in: b, clippingBounds: cb,
                                                         borders: borders, isOutClip: isOutClip)
                        await progress.addCount()
                        Task(priority: .high) { @MainActor in
                            progressPanel.progress = await progress.fractionCompleted
                        }
                        return (i, v)
                    }
                }
                
                return try await group.reduce(into: .init(repeating: [], count: selectedKeyframeIs.count)) {
                    $0[$1.i] = $1.polys
                }
            }
            Task { @MainActor in
                defer { progressPanel.closePanel() }
                guard let nPolyss, nPolyss.count == selectedKeyframeIs.count else { return }
                self.fillAll(withClipping: cb, isOutClip: isOutClip,
                             at: selectedKeyframeIs, with: nPolyss)
            }
        }
        progressPanel.cancelHandler = { task.cancel() }
        return true
    }
    func fillAllFromKeyframeIndex(withClipping cb: Rect?, isOutClip: Bool,
                                    isNewUndoGroup: Bool = true) -> Bool {
        let topolygons = model.picture.makePolygons(in: bounds,
                                                    clippingBounds: cb,
                                                    borders: model.borders,
                                                    isOutClip: isOutClip)
        return fillAllFromKeyframeIndex(withClipping: cb,
                                          topolygons: topolygons,
                                          isOutClip: isOutClip,
                                          isNewUndoGroup: isNewUndoGroup)
    }
    private func fillAllEnabledPlanes(at otherKI: Int) -> [Plane]? {
        let planes = model.animation.keyframes[otherKI].picture.planes
        return planes.isEmpty ? nil : planes
    }
    private func fillAllOtherPlanes(at ki: Int) -> [Plane]? {
        guard model.animation.keyframes[ki].picture.planes.isEmpty else { return nil }
        let preKI = ki - 1 >= 0 ?ki - 1 : model.animation.keyframes.count - 1
        let nextKI = ki + 1 < model.animation.keyframes.count ?ki + 1 : 0
        return ki == 0 ?
        fillAllEnabledPlanes(at: nextKI) ?? fillAllEnabledPlanes(at: preKI) :
        fillAllEnabledPlanes(at: preKI) ?? fillAllEnabledPlanes(at: nextKI)
    }
    func fillAll(withClipping cb: Rect?, isOutClip: Bool,
                 at kis: [Int], with topolygonss: [[Topolygon]]) {
        var appendPKVs = [IndexValue<[Plane]>]()
        var pvKVs = [IndexValue<PlaneValue>]()
        var removePKVs = [IndexValue<[Int]>]()
        var backgroundUUColor: UUColor?
        for (j, ki) in kis.enumerated() {
            let result = Picture.autoFill(fromOther: fillAllOtherPlanes(at: ki),
                                          from: topolygonss[j],
                                          from: model.animation.keyframes[ki].picture.planes,
                                          in: bounds,
                                          clippingBounds: cb, borders: model.borders,
                                          isOutClip: isOutClip)
            switch result {
            case .planes(let planes):
                appendPKVs.append(.init(value: planes, index: ki))
            case .planeValue(let planeValue):
                pvKVs.append(.init(value: planeValue, index: ki))
            case .none: break
            case .background(let uuColor):
                if model.backgroundUUColor == Sheet.defalutBackgroundUUColor {
                    let planes = model.animation.keyframes[ki].picture.planes
                    if !planes.isEmpty {
                        removePKVs.append(.init(value: .init(planes.count.range), index: ki))
                    }
                    backgroundUUColor = uuColor
                }
            }
        }
        if !appendPKVs.isEmpty || !pvKVs.isEmpty || !removePKVs.isEmpty
            || backgroundUUColor != nil {
            newUndoGroup()
            unselect()
            if !appendPKVs.isEmpty {
                append(appendPKVs)
            }
            if !pvKVs.isEmpty {
                set(pvKVs)
            }
            if !removePKVs.isEmpty {
                removeKeyPlanes(removePKVs)
            }
            if let backgroundUUColor {
                set(ColorValue(uuColor: backgroundUUColor, isBackground: true))
            }
        }
    }
    func fillAllFromKeyframeIndex(withClipping cb: Rect?, topolygons: [Topolygon],
                                  isOutClip: Bool, isNewUndoGroup: Bool = true) -> Bool {
        let result = if model.isEnabledAnimation {
            Picture.autoFill(fromOther: fillAllOtherPlanes(at: model.animation.index),
                             from: topolygons,
                             from: model.picture.planes,
                             in: bounds,
                             clippingBounds: cb, borders: model.borders,
                             isOutClip: isOutClip)
        } else {
            Picture.autoFill(from: topolygons,
                             from: model.picture.planes,
                             in: bounds,
                             clippingBounds: cb, borders: model.borders,
                             isOutClip: isOutClip)
        }
        switch result {
        case .planes(let planes):
            if isNewUndoGroup {
                newUndoGroup()
            }
            unselect()
            append(planes)
            return true
        case .planeValue(let planeValue):
            if isNewUndoGroup {
                newUndoGroup()
            }
            unselect()
            set(planeValue)
            return true
        case .none:
            return false
        case .background(let uuColor):
            if model.backgroundUUColor == Sheet.defalutBackgroundUUColor {
                if isNewUndoGroup {
                    newUndoGroup()
                }
                unselect()
                if !model.picture.planes.isEmpty {
                    removePlanes(at: .init(model.picture.planes.count.range))
                }
                set(ColorValue(uuColor: uuColor, isBackground: true))
                return true
            } else {
                return false
            }
        }
    }
    
    func cutColorsAll(with path: Path?) -> Bool {
        var removePlaneValues = Array(planesView.elementViews.enumerated())
        if let path = path {
            removePlaneValues = removePlaneValues.filter {
                path.intersects($0.element.node.path)
            }
        }
        let isRemoveBackground
            = model.backgroundUUColor != Sheet.defalutBackgroundUUColor
            && path == nil
        
        if isRemoveBackground || !removePlaneValues.isEmpty {
            newUndoGroup()
            unselect()
            if !removePlaneValues.isEmpty {
                let planes = removePlaneValues.map { $0.element.model }
                Pasteboard.shared.copiedObjects
                    = [.planesValue(PlanesValue(planes: planes))]
                removePlanes(at: removePlaneValues.map { $0.offset })
            }
            if isRemoveBackground {
                let ocv = ColorValue(uuColor: model.backgroundUUColor,
                                     isBackground: true)
                let ncv = ColorValue(uuColor: Sheet.defalutBackgroundUUColor,
                                     isBackground: true)
                backgroundUUColor = ncv.uuColor
                capture(ncv, old: ocv)
            }
            return true
        }
        return false
    }
}

final class SheetColorOwner {
    let sheetView: SheetView
    private(set) var colorValue: ColorValue
    let oldColorValue: ColorValue
    var uuColor: UUColor {
        get { colorValue.uuColor }
        set {
            colorValue.uuColor = newValue
            sheetView.update(colorValue)
        }
    }
    var oldUUColor: UUColor {
        oldColorValue.uuColor
    }
    
    func showSelected() {
        sheetView.showSelected()
    }
    func hideSelected() {
        sheetView.hideSelected()
    }
    
    init(sheetView: SheetView, colorValue: ColorValue) {
        self.sheetView = sheetView
        self.colorValue = colorValue
        oldColorValue = colorValue
    }
    
    func captureUUColor() {
        sheetView.capture(colorValue, old: oldColorValue)
    }
    func captureUUColor(isNewUndoGroup: Bool) {
        if isNewUndoGroup {
            sheetView.newUndoGroup()
        }
        sheetView.capture(colorValue, old: oldColorValue)
    }
    func colorPathValue(toColor: Color?,
                        color: Color, subColor: Color) -> ColorPathValue {
        sheetView.worldColorPathValue(with: colorValue,
                                      toColor: toColor,
                                      color: color, subColor: subColor)
    }
    
    func moveLine(with uuColor: UUColor, old oldUUColor: UUColor) {
        if oldUUColor == Line.defaultUUColor && uuColor != Line.defaultUUColor {
            if colorValue.lineAnimationIndexes.count >= 1 {
                var removeKeyLines = [IndexValue<[Int]>]()
                var insertKeyLines = [IndexValue<[IndexValue<Line>]>]()
                for kiv in colorValue.lineAnimationIndexes {
                    let lis = kiv.value.filter { $0 != 0 }
                    if !lis.isEmpty {
                        let livs = sheetView.model.animation.keyframes[kiv.index].picture.lines[lis].enumerated()
                            .map { IndexValue(value: $0.element, index: $0.offset) }
                        removeKeyLines.append(.init(value: lis, index: kiv.index))
                        insertKeyLines.append(.init(value: livs, index: kiv.index))
                    }
                }
                if !removeKeyLines.isEmpty || !insertKeyLines.isEmpty {
                    //
                    sheetView.set(SheetSelection.empty)
                    
                    sheetView.removeKeyLines(removeKeyLines)
                    sheetView.insertKeyLines(insertKeyLines)
                }
            } else {
                let lis = colorValue.lineIndexes.filter { $0 != 0 }
                if !lis.isEmpty {
                    //
                    sheetView.set(SheetSelection.empty)
                    
                    let livs = sheetView.model.picture.lines[lis].enumerated()
                        .map { IndexValue(value: $0.element, index: $0.offset) }
                    sheetView.removeLines(at: lis)
                    sheetView.insert(livs)
                }
            }
        }
    }
}
