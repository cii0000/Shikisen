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

import struct Foundation.UUID
import struct Foundation.URL

final class RunAction: InputKeyEventAction {
    let rootAction: RootAction, rootView: RootView
    let isEditingSheet: Bool
    
    private(set) var worldPrintOrigin = Point()
    
    private let maxSheetByte = 100 * 1024 * 1024
    
    private var runText = Text(), runTypobute = Typobute()
    
    private(set) var calculatingString = ""
    private var calculatingNode = Node(fillType: .color(.content))
    private var calculatingTimer: Task<(), any Error>?
    
    private var task: Task<(o: O, id: ID?), Never>?
    private var firstErrorNode: Node?
    
    private var isStopPlaying = false
    
    init(_ rootAction: RootAction) {
        self.rootAction = rootAction
        rootView = rootAction.rootView
        isEditingSheet = rootView.isEditingSheet
    }
    
    func flow(with event: InputKeyEvent) {
        if isStopPlaying || rootAction.isPlaying(with: event) {
            rootAction.stopPlaying(with: event)
            isStopPlaying = true
            return
        }
        
        let p = rootView.convertScreenToWorld(event.screenPoint)
        switch event.phase {
        case .began:
            rootView.cursor = .arrow
            rootView.closeAllPanels(at: p)
            
            rootView.unselectAllAndNewUndoGroupIfNeeded()
            
            let shp = rootView.sheetPosition(at: p)
            guard isEditingSheet, let sheetView = rootView.sheetView(at: shp) else { break }
            let sheetP = sheetView.convertFromWorld(p)
            if let (textView, ti, _, _) = sheetView.textTuple(at: sheetP, scale: rootView.screenToWorldScale) {
                let text = textView.model
                
                if text.string.hasPrefix("http"), URL(string: text.string)?.openInBrowser() ?? false { return }
                
                if text.string == "drawWaveform =" {
                    var view: SheetContentView?, minD = Double.infinity
                    for contentView in sheetView.contentsView.elementViews {
                        if contentView.model.timeOption != nil {
                            let d = contentView.mainLineDistance(contentView.convertFromWorld(p))
                            if d < min(minD, 500) {
                                view = contentView
                                minD = d
                            }
                        }
                    }
                    
                    if let view, let pcmBuffer = view.pcmBuffer {
                        let allW = sheetView.bounds.width - Sheet.textPadding.width * 2
                        let tW = view.width(atDurBeat: view.localBeatRange?.length ?? 0)
                        let dx = text.origin.x
                        let wx = Sheet.textPadding.width - dx
                        
                        let fx = view.x(atBeat: (view.beatRange?.start ?? 0) + (view.localBeatRange?.start ?? 0))
                        let pw = sheetP.x - fx
                        let firstX = -wx + pw
                        
                        let maxCount = 10000
                        let xi = Int(Double(pcmBuffer.sampleCount) * pw / tW)
                        var pathlines = [Pathline](), y = 100.0
                        for ci in 0 ..< pcmBuffer.channelCount {
                            let minX = min(xi, pcmBuffer.sampleCount)
                            let maxX = min(xi + maxCount, pcmBuffer.sampleCount)
                            let ps = (minX ..< maxX).map { i in
                                Point(-wx + allW * Double(i - minX) / Double(maxX - minX),
                                      y + Double(pcmBuffer[ci, i]) * 50)
                            }
                            if !ps.isEmpty {
                                pathlines.append(.init(ps, isClosed: false))
                            }
                            y += 100
                        }
                        
                        let rangeY = 10.0, edgeH = 3.0
                        let endX = firstX + allW * Double(maxCount) / Double(pcmBuffer.sampleCount)
                        pathlines.append(.init(Edge(Point(firstX, rangeY),
                                                    Point(endX, rangeY))))
                        pathlines.append(.init(Edge(Point(firstX, rangeY - edgeH),
                                                    Point(firstX, rangeY + edgeH))))
                        pathlines.append(.init(Edge(Point(endX, rangeY - edgeH),
                                                    Point(endX, rangeY + edgeH))))
                        pathlines.append(.init(Edge(Point(firstX, rangeY),
                                                    Point(-wx, rangeY * 2))))
                        pathlines.append(.init(Edge(Point(endX, rangeY),
                                                    Point(-wx + allW, rangeY * 2))))
                        pathlines.append(.init(Edge(Point(-wx, rangeY * 2),
                                                    Point(-wx + allW, rangeY * 2))))
                        let path = Path(pathlines)
                        
                        let wy = view.spectrgramY + 0.5
                        let sNode = Node(name: "spectrogram",
                                         attitude: .init(position: .init(wx, wy)),
                                         path: path,
                                         lineWidth: 0.5,
                                         lineType: .color(.content))
                        view.node.children
                            .filter { $0.name == sNode.name }
                            .forEach { $0.removeFromParent() }
                        view.node.append(child: sNode)
                        return
                    }
                } else if text.string == "exportIconImages =" {
                    Task { @MainActor in
                        let result = await URL.export(message: "message",
                                                      name: "icons",
                                                      fileType: Image.FileType.pngs,
                                                      fileSizeHandler: { nil })
                        switch result {
                        case .complete(let ioResult):
                            rootView.syncSave()
                            
                            var oSheet = sheetView.model
                            oSheet.texts = oSheet.texts.filter { $0.string != "exportIconImages =" }
                            let sheet = oSheet
                            
                            let bounds = sheetView.model.boundsTuple(at: sheetView.convertFromWorld(p),
                                                                     in: rootView.sheetFrame(with: shp).bounds).bounds.integral
                            
                            let sizes = [16, 32, 64, 128, 256, 512, 1024]
                            
                            let progressPanel = ProgressPanel(message: "Exporting Images".localized)
                            rootView.node.show(progressPanel)
                            do {
                                try ioResult.remove()
                                try ioResult.makeDirectory()
                                
                                @Sendable func export(progressHandler: (Double, inout Bool) -> ()) throws {
                                    var isStop = false
                                    for (j, size) in sizes.enumerated() {
                                        let node = sheet.node(isBorder: false, in: bounds)
                                        let image = node.image(in: bounds, to: Size(square: size), .sRGB)
                                        let subIOResult = ioResult.sub(name: "\(size).png")
                                        try image?.write(.png, to: subIOResult.url)
                                        try subIOResult.setAttributes()
                                        progressHandler(Double(j + 1) / Double(sizes.count), &isStop)
                                        if isStop { break }
                                    }
                                }
                                
                                let task = Task.detached(priority: .high) {
                                    do {
                                        try export { (progress, isStop) in
                                            if Task.isCancelled {
                                                isStop = true
                                                return
                                            }
                                            Task { @MainActor in
                                                progressPanel.progress = progress
                                            }
                                        }
                                        Task { @MainActor in
                                            progressPanel.closePanel()
                                        }
                                    } catch {
                                        Task { @MainActor in
                                            self.rootView.node.show(error)
                                            progressPanel.closePanel()
                                        }
                                    }
                                }
                                progressPanel.cancelHandler = { task.cancel() }
                            } catch {
                                self.rootView.node.show(error)
                                progressPanel.closePanel()
                            }
                        case .cancel: break
                        }
                    }
                    return
                }
                
                if text.string.last == "=" {
                    send(sheetP, from: text, ti: ti, shp, sheetView)
                }
            }
        case .changed:
            break
        case .ended:
            rootView.cursor = rootView.defaultCursor
        }
    }
}
extension RunAction: Hashable {
    nonisolated static func == (lhs: RunAction, rhs: RunAction) -> Bool {
        lhs === rhs
    }
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
extension RunAction {
    func send(_ currentP: Point,
              from text: Text, ti: Int,
              _ shp: IntPoint, _ sheetView: SheetView) {
        runText = text
        runTypobute = text.typobute
        let sf = rootView.sheetFrame(with: shp)
        let shpp = sf.origin
        var ssDic = [O: O](), tsss = [([Text], IntPoint, Sheet)]()
        var shps = Set<IntPoint>(), shpStack = Stack<IntPoint>()
        shps.insert(shp)
        shpStack.push(shp)
        while let nshp = shpStack.pop() {
            guard let sid = rootView.sheetID(at: nshp) else { continue }
            guard let sheet = rootView.readSheet(at: sid) else { continue }
            let sheetBounds = rootView.sheetFrame(with: nshp).bounds
            let dshp = nshp - shp
            ssDic[O(dshp)] = O(sheet)
            
            let texts = sheet.texts
            var nTexts = [Text]()
            nTexts.reserveCapacity(texts.count)
            for t in texts {
                func shpFromPlus(at t: Text) -> IntPoint? {
                    guard t.string == "+", let f = t.frame else { return nil }
                    let s = max(f.width, f.height), p = f.centerPoint
                    guard !sheetBounds.inset(by: s).contains(p),
                        let lrtb = sheetBounds.lrtb(at: p) else { return nil }
                    return switch lrtb {
                    case .left: .init(nshp.x - 1, nshp.y)
                    case .right: .init(nshp.x + 1, nshp.y)
                    case .top: .init(nshp.x, nshp.y + 1)
                    case .bottom: .init(nshp.x, nshp.y - 1)
                    }
                }
                if let nnshp = shpFromPlus(at: t) {
                    if !shps.contains(nnshp) {
                        shps.insert(nnshp)
                        shpStack.push(nnshp)
                    }
                } else {
                    nTexts.append(t)
                }
            }
            tsss.append((nTexts, nshp, sheet))
        }
        
        let printOrigin = nodePoint(from: text)
        self.worldPrintOrigin = sheetView.convertToWorld(printOrigin)
        
        
        var oDic = O.defaultDictionary(with: sheetView.model,
                                       bounds: sf.bounds,
                                       ssDic: ssDic,
                                       cursorP: currentP, printP: printOrigin)
        
        for (nTexts, nshp, _) in tsss {
            for (i, t) in nTexts.enumerated() {
                guard !(shp == nshp && i == ti) && !t.isEmpty else { continue }
                var nText = t
                nText.origin += shpp
                let o = O(nText, isDictionary: true, &oDic)
                switch o {
                case .f(let f):
                    for (key, _) in f.definitions {
                        oDic[key] = O()
                    }
                default: break
                }
            }
        }
        for (nTexts, nshp, _) in tsss {
            for (i, t) in nTexts.enumerated() {
                guard !(shp == nshp && i == ti) && !t.isEmpty else { continue }
                var nText = t
                nText.origin += shpp
                let o = O(nText, isDictionary: true, &oDic)
                switch o {
                case .f(let f):
                    for (key, value) in f.definitions {
                        oDic[key] = O(value)
                    }
                default: break
                }
            }
        }
        let oText = sheetView.model.texts[ti]
        var nText = oText
        nText.string.removeLast()
        nText.origin += rootView.sheetFrame(with: shp).origin
        let xo = O(nText, &oDic)
        
        calculatingNode.attitude.position = nodePoint(from: nText)
        rootView.node.append(child: calculatingNode)
        
        calculatingTimer = Task.timer(interval: .seconds(1)) { dur in
            await self.showCalculating(sec: dur.sec.rounded())
        }
        
        rootAction.runActions.insert(self)
        
        let xoDic = oDic
        Task { @MainActor in
            let clock = SuspendingClock.now
            let task = Task.detached(priority: .high) {
                Calculator.calculate(xo, xoDic) { _,_ in !Task.isCancelled }
            }
            self.task = task
            let (no, id) = await task.value
            self.task = nil
            
            calculatingTimer?.cancel()
            calculatingTimer = nil
            
            rootAction.runActions.remove(self)
            
            calculatingNode.removeFromParent()
            
            if no != .stopped {
                let time = clock.duration(to: .now).sec
                if let sheetView = rootView.madeReadSheetView(at: worldPrintOrigin) {
                    let shp = rootView.sheetPosition(at: worldPrintOrigin)
                    draw(no, id, from: text, time: time, in: sheetView, shp)
                }
            }
            rootView.updateTextCursor()
        }
    }
    
    func cancel() {
        calculatingTimer?.cancel()
        calculatingTimer = nil
        
        task?.cancel()
        task = nil
    }
    
    func containsCalculating(_ p: Point) -> Bool {
        calculatingNode.path.bounds?.contains(calculatingNode.convertFromWorld(p)) ?? false
    }
    func nodePoint(from text: Text) -> Point {
        let size = text.typesetter.typoBounds?.size ?? Size()
        let padding = runTypobute.font.size * 2 * 2 / 3.0
        return Point(text.origin.x + padding + size.width, text.origin.y)
    }
    
    func showCalculating(sec: Double) {
        calculatingString = "Calculating".localized + "\n" + "\(Int(sec.rounded())) s"
        calculatingNode.path = Typesetter(string: calculatingString, typobute: runTypobute).path()
    }
    
    func draw(_ o: O, _ id: ID?, from text: Text, time: Double,
              in sheetView: SheetView, _ shp: IntPoint) {
        switch o {
        case .dic(let a):
            if let sheet = Sheet(o) {
                draw(sheet, from: text, at: shp)
            } else {
                var ssDic = [IntPoint: Sheet]()
                for (key, value) in a {
                    if case .array(let idxs) = key, idxs.count == 2,
                       case .int(let x) = idxs[0], case .int(let y) = idxs[1],
                       case .sheet(let sheet) = value {
                        
                        let nshp = IntPoint(x, y) + shp
                        ssDic[nshp] = sheet
                    }
                }
                if !ssDic.isEmpty {
                    for (key, value) in ssDic {
                        draw(value, from: text, at: key)
                    }
                } else {
                    draw(o.description, at: nodePoint(from: text), in: sheetView)
                }
            }
        case .sheet(let a):
            draw(a, from: text, at: shp)
        default:
            draw(o.description, at: nodePoint(from: text), in: sheetView)
        }
        if let id {
            draw(id, in: sheetView)
        }
        if time > 10 {
            drawTime(time, from: text, in: sheetView, shp)
        }
    }
    func draw(_ nSheet: Sheet, from text: Text, at shp: IntPoint) {
        guard let sheetView = rootView.readSheetView(at: shp) else { return }
        
        func lineCount(_ line: Line) -> Int {
            line.controls.count * MemoryLayout<Point>.size
        }
        func planeCount(_ plane: Plane) -> Int {
            (plane.topolygon.holePolygons.sum { $0.points.count } + plane.topolygon.polygon.points.count) * MemoryLayout<Point>.size
        }
        func pictureCount(_ picture: Picture) -> Int {
            picture.lines.sum { lineCount($0) } + picture.planes.sum { planeCount($0) }
        }
        func keyframeCount(_ keyframe: Keyframe) -> Int {
            pictureCount(keyframe.picture) + pictureCount(keyframe.draftPicture)
        }
        func textCount(_ text: Text) -> Int {
            text.string.utf8.count * MemoryLayout<UInt8>.size
        }
        var si = 0
        func isMax() -> Bool {
            if si > maxSheetByte {
                let maxO = O(OError(String(format: "Not support more than %1$@ in total".localized, IOResult.fileSizeNameFrom(fileSize: maxSheetByte))))
                draw(maxO.description,
                     at: nodePoint(from: text), isNewUndoGroup: false,
                     in: sheetView)
                return true
            } else {
                return false
            }
        }
        
        var isNewUndoGroup = true
        func updateNewUndoGroup() {
            if isNewUndoGroup {
                sheetView.newUndoGroup()
            }
            isNewUndoGroup = false
        }
        
        let oSheet = sheetView.model
        let diffKeyframes = ArrayDiff(from: oSheet.animation.keyframes,
                                      to: nSheet.animation.keyframes)
        if !diffKeyframes.replaces.isEmpty {
            si += diffKeyframes.replaces.reduce(0) { $0 + keyframeCount($1.value) }
            if isMax() { return }
            
            var keyframeOptions = [IndexValue<KeyframeOption>]()
            var repKLIVs = [IndexValue<[IndexValue<Line>]>](),
                removeKLIVs = [IndexValue<[Int]>](),
                insertKLIVs = [IndexValue<[IndexValue<Line>]>]()
            var repKPIVs = [IndexValue<[IndexValue<Plane>]>](),
                removeKPIVs = [IndexValue<[Int]>](),
                insertKPIVs = [IndexValue<[IndexValue<Plane>]>]()
            for kv in diffKeyframes.replaces {
                let oldKeyframe = oSheet.animation.keyframes[kv.index]
                let newKeyframe = kv.value
                
                if oldKeyframe.option != newKeyframe.option {
                    keyframeOptions.append(.init(value: newKeyframe.option, index: kv.index))
                }
                
                let diffLines = ArrayDiff(from: oldKeyframe.picture.lines,
                                          to: newKeyframe.picture.lines)
                if !diffLines.replaces.isEmpty {
                    si += diffLines.replaces.reduce(0) { $0 + lineCount($1.value) }
                    if isMax() { return }
                    repKLIVs.append(.init(value: diffLines.replaces, index: kv.index))
                }
                if !diffLines.removes.isEmpty {
                    updateNewUndoGroup()
                    removeKLIVs.append(.init(value: diffLines.removes, index: kv.index))
                }
                if !diffLines.inserts.isEmpty {
                    si += diffLines.inserts.reduce(0) { $0 + lineCount($1.value) }
                    if isMax() { return }
                    insertKLIVs.append(.init(value: diffLines.inserts, index: kv.index))
                }
                
                let diffPlanes = ArrayDiff(from: oldKeyframe.picture.planes,
                                           to: newKeyframe.picture.planes)
                if !diffPlanes.replaces.isEmpty {
                    si += diffPlanes.replaces.reduce(0) { $0 + planeCount($1.value) }
                    if isMax() { return }
                    repKPIVs.append(.init(value: diffPlanes.replaces, index: kv.index))
                }
                if !diffPlanes.removes.isEmpty {
                    updateNewUndoGroup()
                    removeKPIVs.append(.init(value: diffPlanes.removes, index: kv.index))
                }
                if !diffPlanes.inserts.isEmpty {
                    si += diffPlanes.inserts.reduce(0) { $0 + planeCount($1.value) }
                    if isMax() { return }
                    insertKPIVs.append(.init(value: diffPlanes.inserts, index: kv.index))
                }
            }
            if !keyframeOptions.isEmpty {
                updateNewUndoGroup()
                sheetView.set(keyframeOptions)
            }
            
            if !repKLIVs.isEmpty {
                updateNewUndoGroup()
                sheetView.replaceKeyLines(repKLIVs)
            }
            if !removeKLIVs.isEmpty {
                updateNewUndoGroup()
                sheetView.removeKeyLines(removeKLIVs)
            }
            if !insertKLIVs.isEmpty {
                updateNewUndoGroup()
                sheetView.insertKeyLines(insertKLIVs)
            }
            if !repKPIVs.isEmpty {
                updateNewUndoGroup()
                sheetView.replaceKeyPlanes(repKPIVs)
            }
            if !removeKPIVs.isEmpty {
                updateNewUndoGroup()
                sheetView.removeKeyPlanes(removeKPIVs)
            }
            if !insertKPIVs.isEmpty {
                updateNewUndoGroup()
                sheetView.insertKeyPlanes(insertKPIVs)
            }
        }
        if !diffKeyframes.removes.isEmpty {
            updateNewUndoGroup()
            sheetView.removeTexts(at: diffKeyframes.removes)
        }
        if !diffKeyframes.inserts.isEmpty {
            si += diffKeyframes.inserts.reduce(0) { $0 + keyframeCount($1.value) }
            if isMax() { return }
            updateNewUndoGroup()
            sheetView.insert(diffKeyframes.inserts)
        }
        
        let diffTexts = ArrayDiff(from: oSheet.texts, to: nSheet.texts)
        if !diffTexts.replaces.isEmpty {
            si += diffTexts.replaces.reduce(0) { $0 + textCount($1.value) }
            if isMax() { return }
            updateNewUndoGroup()
            sheetView.replace(diffTexts.replaces)
        }
        if !diffTexts.removes.isEmpty {
            updateNewUndoGroup()
            sheetView.removeTexts(at: diffTexts.removes)
        }
        if !diffTexts.inserts.isEmpty {
            si += diffTexts.inserts.reduce(0) { $0 + textCount($1.value) }
            if isMax() { return }
            updateNewUndoGroup()
            sheetView.insert(diffTexts.inserts)
        }
        
        if oSheet.animation.option != nSheet.animation.option {
            updateNewUndoGroup()
            sheetView.set(nSheet.animation.option)
        }
        if oSheet.score.option != nSheet.score.option {
            updateNewUndoGroup()
            sheetView.set(nSheet.score.option)
        }
        if oSheet.option != nSheet.option {
            updateNewUndoGroup()
            sheetView.set(nSheet.option)
        }
        if oSheet.backgroundUUColor.value != nSheet.backgroundUUColor.value {
            let uuColor = UUColor(nSheet.backgroundUUColor.value, id: .init())
            updateNewUndoGroup()
            sheetView.set(ColorValue(uuColor: uuColor, isBackground: true))
        }
    }
    func draw(_ s: String,
              at p: Point, isNewUndoGroup: Bool = true,
              in sheetView: SheetView) {
        let nt = Text(string: s, size: runTypobute.font.size, origin: p)
        if !sheetView.model.texts.contains(nt) {
            if isNewUndoGroup {
                sheetView.newUndoGroup()
            }
            if let i = sheetView.model.texts.firstIndex(where: { $0.origin == p }) {
                sheetView.removeText(at: i)
            }
            sheetView.append(nt)
        }
    }
    func drawTime(_ t: Double, from text: Text,
                  isNewUndoGroup: Bool = true,
                  in sheetView: SheetView, _ shp: IntPoint) {
        let size = text.typesetter.typoBounds?.size ?? Size()
        let padding = runTypobute.font.size * 2 * 2 / 3.0
        let p = Point(text.origin.x + padding + size.width,
                      text.origin.y + runTypobute.font.size * 1.5)
        let nt = Text(string: String(format: "%.4f s", t),
                      size: runTypobute.font.size,
                      origin: p)
        if !sheetView.model.texts.contains(nt) {
            if isNewUndoGroup {
                sheetView.newUndoGroup()
            }
            if let i = sheetView.model.texts.firstIndex(where: { $0.origin == p }) {
                sheetView.removeText(at: i)
            }
            sheetView.append(nt)
        }
    }
    func draw(_ id: ID, in sheetView: SheetView) {
        guard let b = id.typoBounds, let ratio = id.typobute?.font.defaultRatio else { return }
        let p = b.centerPoint
        if let nSheetView = rootView.sheetView(at: p) {
            let nb = nSheetView.convertFromWorld(b)
            let s = Line.defaultLineWidth * ratio
            let line = Line.wave(Edge(nb.minXMinYPoint + Point(-s * 2, -s * 2),
                                      nb.maxXMinYPoint + Point(s * 2, -s * 2)),
                                 a: s, length: s * 2, size: s)
            if !nSheetView.model.picture.lines.contains(line) {
                if sheetView != nSheetView {
                    nSheetView.newUndoGroup()
                }
                nSheetView.append(line)
            }
        }
    }
}
