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
import struct Foundation.Data
import struct Foundation.URL
import class Foundation.FileManager

final class ImportAction: InputKeyEventAction {
    let action: IOAction
    
    init(_ rootAction: RootAction) {
        action = IOAction(rootAction)
    }
    
    func flow(with event: InputKeyEvent) {
        action.importFile(with: event)
    }
    func updateNode() {
        action.updateNode()
    }
}
final class StartExportAction: InputKeyEventAction {
    let action: IOAction
    
    init(_ rootAction: RootAction) {
        action = IOAction(rootAction)
    }
    
    func flow(with event: InputKeyEvent) {
        action.exportFile(with: event, .image)
    }
    func updateNode() {
        action.updateNode()
    }
}
final class ExportAsImageAction: InputKeyEventAction {
    let action: IOAction
    
    init(_ rootAction: RootAction) {
        action = IOAction(rootAction)
    }
    
    func flow(with event: InputKeyEvent) {
        action.exportFile(with: event, .image)
    }
    func updateNode() {
        action.updateNode()
    }
}
final class ExportAs4KImageAction: InputKeyEventAction {
    let action: IOAction
    
    init(_ rootAction: RootAction) {
        action = IOAction(rootAction)
    }
    
    func flow(with event: InputKeyEvent) {
        action.exportFile(with: event, .image4K)
    }
    func updateNode() {
        action.updateNode()
    }
}
final class ExportAsPDFAction: InputKeyEventAction {
    let action: IOAction
    
    init(_ rootAction: RootAction) {
        action = IOAction(rootAction)
    }
    
    func flow(with event: InputKeyEvent) {
        action.exportFile(with: event, .pdf)
    }
    func updateNode() {
        action.updateNode()
    }
}
final class ExportAsGIFAction: InputKeyEventAction {
    let action: IOAction
    
    init(_ rootAction: RootAction) {
        action = IOAction(rootAction)
    }
    
    func flow(with event: InputKeyEvent) {
        action.exportFile(with: event, .gif)
    }
    func updateNode() {
        action.updateNode()
    }
}
final class ExportAsMovieAction: InputKeyEventAction {
    let action: IOAction
    
    init(_ rootAction: RootAction) {
        action = IOAction(rootAction)
    }
    
    func flow(with event: InputKeyEvent) {
        
        action.exportFile(with: event, .movie)
    }
    func updateNode() {
        action.updateNode()
    }
}
final class ExportAs4KMovieAction: InputKeyEventAction {
    let action: IOAction
    
    init(_ rootAction: RootAction) {
        action = IOAction(rootAction)
    }
    
    func flow(with event: InputKeyEvent) {
        action.exportFile(with: event, .movie4K)
    }
    func updateNode() {
        action.updateNode()
    }
}
final class ExportAsSoundAction: InputKeyEventAction {
    let action: IOAction
    
    init(_ rootAction: RootAction) {
        action = IOAction(rootAction)
    }
    
    func flow(with event: InputKeyEvent) {
        action.exportFile(with: event, .sound)
    }
    func updateNode() {
        action.updateNode()
    }
}
final class ExportAsLinearPCMAction: InputKeyEventAction {
    let action: IOAction
    
    init(_ rootAction: RootAction) {
        action = IOAction(rootAction)
    }
    
    func flow(with event: InputKeyEvent) {
        action.exportFile(with: event, .linearPCM)
    }
    func updateNode() {
        action.updateNode()
    }
}
final class ExportAsCaptionAction: InputKeyEventAction {
    let action: IOAction
    
    init(_ rootAction: RootAction) {
        action = IOAction(rootAction)
    }
    
    func flow(with event: InputKeyEvent) {
        action.exportFile(with: event, .caption)
    }
    func updateNode() {
        action.updateNode()
    }
}
final class ExportAsTimelapseAction: InputKeyEventAction {
    let action: IOAction
    
    init(_ rootAction: RootAction) {
        action = IOAction(rootAction)
    }
    
    func flow(with event: InputKeyEvent) {
        action.exportFile(with: event, .timelapse)
    }
    func updateNode() {
        action.updateNode()
    }
}
final class ExportAsDocumentAction: InputKeyEventAction {
    let action: IOAction
    
    init(_ rootAction: RootAction) {
        action = IOAction(rootAction)
    }
    
    func flow(with event: InputKeyEvent) {
        action.exportFile(with: event, .document)
    }
    func updateNode() {
        action.updateNode()
    }
}
final class ExportAsDocumentWithHistoryAction: InputKeyEventAction {
    let action: IOAction
    
    init(_ rootAction: RootAction) {
        action = IOAction(rootAction)
    }
    
    func flow(with event: InputKeyEvent) {
        action.exportFile(with: event, .documentWithHistory)
    }
    func updateNode() {
        action.updateNode()
    }
}
final class IOAction: Action {
    let rootAction: RootAction, rootView: RootView
    let isEditingSheet: Bool
    
    init(_ rootAction: RootAction) {
        self.rootAction = rootAction
        rootView = rootAction.rootView
        isEditingSheet = rootView.isEditingSheet
    }
    
    var beganP = Point()
    
    let pngMaxWidth = 2048.0, pdfMaxWidth = 512.0
    
    let selectingLineNode = Node(lineWidth: 1.5)
    func updateNode() {
        selectingLineNode.lineWidth = rootView.worldLineWidth
    }
    func end(isUpdateSelect: Bool = false, isUpdateCursor: Bool = true) {
        selectingLineNode.removeFromParent()
        
        if isUpdateSelect {
            rootView.updateSelectedFrame()
        }
        if isUpdateCursor {
            rootView.cursor = rootView.defaultCursor
        }
        rootView.updateSelectedColor(isMain: true)
    }
    func name(from shp: IntPoint) -> String {
        return "\(shp.x)_\(shp.y)"
    }
    func name(from shps: [IntPoint]) -> String {
        if shps.isEmpty {
            return "Empty"
        } else if shps.count == 1 {
            return name(from: shps[0])
        } else {
            return "\(name(from: shps[.first]))__"
        }
    }
    
    func orientation(_ vs: [SelectingValue], at shp: IntPoint) -> Orientation {
        let vsSHPs = Set(vs.map { $0.shp })
        let svvs = rootView.sheetViewValues.filter { vsSHPs.contains($0.key) }
        let isEnabledTimeline = svvs.contains { $0.value.sheetView?.model.enabledTimeline ?? false }
        if isEnabledTimeline {
            return .horizontal
        }
        var allV = 0, allT = 0
        svvs.forEach {
            if let sheetView = $0.value.sheetView {
                for text in sheetView.model.texts {
                    if text.orientation == .vertical {
                        allV += 1
                    }
                    allT += 1
                }
            }
        }
        return allV > allT / 2 ? .vertical : .horizontal
    }
    func sorted(_ vs: [SelectingValue], with orientation: Orientation) -> [SelectingValue] {
        switch orientation {
        case .horizontal:
            vs.sorted {
                $0.shp.y != $1.shp.y ? $0.shp.y > $1.shp.y : $0.shp.x < $1.shp.x
            }
        case .vertical:
            vs.sorted {
                $0.shp.y != $1.shp.y ? $0.shp.y > $1.shp.y : $0.shp.x > $1.shp.x
            }
        }
    }
    
    @discardableResult func beginImportFile(at sp: Point) -> IntPoint {
        beganP = rootView.convertScreenToWorld(sp)
        selectingLineNode.lineWidth = rootView.worldLineWidth
        selectingLineNode.fillType = .color(.subSelected)
        selectingLineNode.lineType = .color(.selected)
        let shp = rootView.sheetPosition(at: beganP)
        let frame = rootView.sheetFrame(with: shp)
        selectingLineNode.path = Path(frame)
        rootView.node.append(child: selectingLineNode)
        
        rootView.textCursorNode.isHidden = true
        rootView.textMaxTypelineWidthNode.isHidden = true
        
        rootView.updateSelectedColor(isMain: false)
        
        return shp
    }
    func importFile(from urls: [URL], at shp: IntPoint) {
        var mshp = shp
        var onSHPs = [IntPoint](), willremoveSHPs = [IntPoint]()
        for url in urls {
            let importedDocument = Document(url, isLoadOnly: true)
            let world = importedDocument.world()
            
            var maxX = mshp.x
            for (osid, _) in importedDocument.sheetRecorders {
                guard let oshp = world.sheetPositions[osid] else {
                    continue
                }
                let nshp = oshp + mshp
                if rootView.sheetID(at: nshp) != nil {
                    willremoveSHPs.append(nshp)
                }
                
                onSHPs.append(nshp)
                
                if nshp.x > maxX {
                    maxX = nshp.x
                }
            }
            mshp.x = maxX + 2
        }
        let nSHPs = onSHPs
        
        var oldP: Point?
        let viewSHPs = sorted(nSHPs.map { SelectingValue(shp: $0, bounds: Rect()) }, with: .horizontal)
            .map { $0.shp }
        selectingLineNode.children = viewSHPs.map {
            let frame = rootView.sheetFrame(with: $0)
            if let op = oldP {
                let cp = frame.centerPoint
                let path = Path([Pathline([op, cp])])
                let arrowNode = Node(path: path,
                                     lineWidth: selectingLineNode.lineWidth,
                                     lineType: selectingLineNode.lineType)
                oldP = frame.centerPoint
                return Node(children: [arrowNode],
                            path: Path(frame),
                            lineWidth: selectingLineNode.lineWidth,
                            lineType: selectingLineNode.lineType,
                            fillType: selectingLineNode.fillType)
            } else {
                oldP = frame.centerPoint
                return Node(path: Path(frame),
                            lineWidth: selectingLineNode.lineWidth,
                            lineType: selectingLineNode.lineType,
                            fillType: selectingLineNode.fillType)
            }
        } + willremoveSHPs.map {
            Node(path: Path(rootView.sheetFrame(with: $0)),
                 lineWidth: selectingLineNode.lineWidth * 2,
                 lineType: selectingLineNode.lineType,
                 fillType: selectingLineNode.fillType)
        }
        
        let length = urls.reduce(0) { $0 + ($1.fileSize ?? 0) }
        
        let contentURLs = urls.filter { Content.type(from: $0) != .none }
        if !contentURLs.isEmpty {
            var dshp = IntPoint()
            let xCount = max(1, Int(Double(contentURLs.count).squareRoot()))
            for url in contentURLs {
                if let sheetView = rootView.madeSheetView(at: shp + dshp) {
                    let np = contentURLs.count == 1 ? sheetView.convertFromWorld(beganP) : Point(10, 50)
                    let filename = url.deletingPathExtension().lastPathComponent
                    let name = UUID().uuidString + "." + url.pathExtension
                    
                    if let directory = rootView.model.sheetRecorders[sheetView.id]?.contentsDirectory {
                        directory.isWillwrite = true
                        try? directory.write()
                        try? directory.copy(name: name, from: url)
                    }
                    
                    let maxBounds = rootView.sheetFrame(with: shp).bounds.inset(by: Sheet.textPadding)
                    let content = Content(directoryName: sheetView.id.uuidString,
                                          name: name, origin: rootView.roundedPoint(from: np))
                    if content.type == .movie {
                        Task.detached(priority: .userInitiated) {
                            if let size = try? await Movie.size(from: content.url),
                               let durSec = try? await Movie.durSec(from: content.url),
                               let frameRate = try? await Movie.frameRate(from: content.url) {
                                
                                Task { @MainActor in
                                    var content = content
                                    var size = size / 2
                                    let maxSize = maxBounds.size
                                    if size.width > maxSize.width || size.height > maxSize.height {
                                        size *= min(maxSize.width / size.width, maxSize.height / size.height)
                                    }
                                    content.size = size
                                    let nnp = maxBounds.clipped(Rect(origin: content.origin,
                                                                     size: content.size)).origin
                                    content.origin = nnp
                                    
                                    content.durSec = durSec
                                    content.frameRate = Rational(Int(frameRate))
                                    
                                    let tempo = Music.defaultTempo
                                    let durBeat = ContentTimeOption.beat(fromSec: durSec, tempo: tempo)
                                    let beatRange = Range(start: 0, length: durBeat)
                                    content.timeOption = .init(beatRange: beatRange, tempo: tempo)
                                    
                                    var text = Text(string: filename, origin: nnp)
                                    text.origin.y -= (content.type.hasDur ? Sheet.timelineHalfHeight : 0) + text.size / 2 + 4
                                    if text.origin.y < Sheet.textPadding.height {
                                        let d = Sheet.textPadding.height - text.origin.y
                                        text.origin.y += d
                                        content.origin.y += d
                                    }
                                    
                                    sheetView.newUndoGroup()
                                    sheetView.unselect()
                                    sheetView.append(text)
                                    sheetView.append(content)
                                    sheetView.doSet(.init(textSelections: text.string.isEmpty ?
                                                          [:] :
                                                             [sheetView.model.texts.count - 1:
                                                                     .init(ranges: [text.string.allIntRange])],
                                                          contentIs: [sheetView.model.contents.count - 1]))
                                }
                            }
                        }
                    } else {
                        var content = content
                        content.normalizeVolm()
                        if let size = content.image?.size {
                            var size = size / 2
                            let maxSize = maxBounds.size
                            if size.width > maxSize.width || size.height > maxSize.height {
                                size *= min(maxSize.width / size.width, maxSize.height / size.height)
                            }
                            content.size = size
                        }
                        let nnp = maxBounds.clipped(Rect(origin: content.origin,
                                                         size: content.size)).origin
                        content.origin = nnp
                        if content.type.hasDur {
                            let tempo = sheetView.nearestTempo(at: np) ?? Music.defaultTempo
                            let interval = rootView.currentBeatInterval
                            let startBeat = sheetView.animationView.beat(atX: np.x, interval: interval)
                            let durBeat = ContentTimeOption.beat(fromSec: content.durSec, tempo: tempo)
                            let beatRange = Range(start: startBeat, length: durBeat)
                            content.timeOption = .init(beatRange: beatRange, tempo: tempo)
                        }
                        
                        var text = Text(string: filename, origin: nnp)
                        text.origin.y -= (content.type.hasDur ? Sheet.timelineHalfHeight : 0) + text.size / 2 + 4
                        if text.origin.y < Sheet.textPadding.height {
                            let d = Sheet.textPadding.height - text.origin.y
                            text.origin.y += d
                            content.origin.y += d
                        }
                        
                        sheetView.newUndoGroup()
                        sheetView.unselect()
                        sheetView.append(text)
                        sheetView.append(content)
                        sheetView.doSet(.init(textSelections: text.string.isEmpty ?
                                              [:] :
                                                 [sheetView.model.texts.count - 1:
                                                         .init(ranges: [text.string.allIntRange])],
                                              contentIs: [sheetView.model.contents.count - 1]))
                    }
                }
                
                dshp.x += 1
                if dshp.x >= xCount {
                    dshp.x = 0
                    dshp.y -= 1
                }
            }
            end(isUpdateSelect: true)
            return
        }
        
        if willremoveSHPs.isEmpty && urls.count == 1 {
            loadFile(from: urls, at: shp)
            end(isUpdateSelect: true)
        } else {
            let message: String
            if willremoveSHPs.isEmpty {
                if urls.count >= 2 {
                    message = String(format: "Do you want to import a total of %2$d sheets from %1$d documents?".localized, urls.count, nSHPs.count)
                } else {
                    message = String(format: "Do you want to import %1$d sheets?".localized, nSHPs.count)
                }
            } else {
                if urls.count >= 2 {
                    message = String(format: "Do you want to import a total of $2$d sheets from %1$d documents, replacing %3$d existing sheets?".localized, urls.count, nSHPs.count, willremoveSHPs.count)
                } else {
                    message = String(format: "Do you want to import $1$d sheets and replace the %2$d existing sheets?".localized, nSHPs.count, willremoveSHPs.count)
                }
            }
            Task { @MainActor in
                let result = await rootView.node
                    .show(message: message,
                          infomation: "This operation can be undone when the root is displayed, but the data will remain in the root history until the root history is cleared.".localized,
                          okTitle: "Import".localized,
                          isSaftyCheck: nSHPs.count > 100 || length > 20*1024*1024)
                switch result {
                case .ok:
                    loadFile(from: urls, at: shp)
                    end(isUpdateSelect: true)
                case .cancel:
                    end(isUpdateSelect: true)
                }
            }
        }
    }
    func loadFile(from urls: [URL], at shp: IntPoint) {
        var mshp = shp
        var nSIDs = [IntPoint: UUID](), willremoveSHPs = [IntPoint]()
        var resetSIDs = Set<UUID>()
        for url in urls {
            let importedDocument = Document(url, isLoadOnly: true)
            let world = importedDocument.world()
            
            var maxX = mshp.x
            for (osid, osrr) in importedDocument.sheetRecorders {
                guard let oshp = world.sheetPositions[osid] else {
                    let nsid = rootView.appendSheet(from: osrr)
                    resetSIDs.insert(nsid)
                    continue
                }
                let nshp = oshp + mshp
                if rootView.sheetID(at: nshp) != nil {
                    willremoveSHPs.append(nshp)
                }
                nSIDs[nshp] = rootView.appendSheet(from: osrr)
                
                if nshp.x > maxX {
                    maxX = nshp.x
                }
            }
            mshp.x = maxX + 2
        }
        if !willremoveSHPs.isEmpty || !nSIDs.isEmpty || !resetSIDs.isEmpty {
            rootView.history.newUndoGroup()
            if !willremoveSHPs.isEmpty {
                rootView.removeSheets(at: willremoveSHPs)
            }
            if !nSIDs.isEmpty {
                rootView.append(nSIDs)
            }
            let nSelection = WorldSelection(sheetIDs: Array(nSIDs.values))
            if nSelection != rootView.world.selection {
                rootView.doSet(nSelection)
            }
            if !resetSIDs.isEmpty {
                rootView.moveSheetsToUpperRightCorner(with: Array(resetSIDs),
                                                      isNewUndoGroup: false)
                rootView.node.show(RootView.ReadingError())
            }
            rootView.updateNode()
        }
    }
    func importFile(with event: InputKeyEvent) {
        let p = rootView.convertScreenToWorld(event.screenPoint)
        switch event.phase {
        case .began:
            rootView.cursor = .arrow
            rootAction.closeLookingUpAndStop(at: p)
            
            beginImportFile(at: event.screenPoint)
        case .changed:
            break
        case .ended:
            Task { @MainActor in
                let result = await URL.load(prompt: "Import".localized,
                                            allowsMultipleSelection: true,
                                            fileTypes: Document.FileType.allCases + Content.FileType.allCases)
                switch result {
                case .complete(let ioResults):
                    let shp = rootView.sheetPosition(at: beganP)
                    importFile(from: ioResults.map { $0.url }, at: shp)
                case .cancel:
                    end(isUpdateSelect: true)
                }
            }
        }
    }
    
    struct SelectingValue {
        var shp: IntPoint, bounds: Rect
    }
    
    func exportFile(with event: InputKeyEvent, _ type: Exporting.ExportType) {
        let p = rootView.convertScreenToWorld(event.screenPoint)
        switch event.phase {
        case .began:
            rootView.cursor = .arrow
            rootAction.closeLookingUpAndStop(at: p)
            
            beganP = p
            if let shps = rootView.selectedSheetPositions(p) {
                let fshp = rootView.sheetPosition(at: p)
                let vs = shps.map {
                    SelectingValue(shp: $0, bounds: rootView.sheetFrame(with: $0).bounds)
                }
                let nvs = sorted(vs, with: orientation(vs, at: fshp))
                
                let mainFrame = rootView.sheetView(at: p)?.model.mainFrame
                
                var oldP: Point?
                selectingLineNode.children = nvs.map {
                    let frame = !type.isDocument ?
                    ((mainFrame ?? $0.bounds) + rootView.sheetFrame(with: $0.shp).origin) :
                    rootView.sheetFrame(with: $0.shp)
                    
                    if !type.isDocument, let op = oldP {
                        let cp = frame.centerPoint
                        let a = op.angle(cp) - .pi
                        let d = min(frame.width, frame.height) / 4
                        let p0 = cp.movedWith(distance: d, angle: a + .pi / 6)
                        let p1 = cp.movedWith(distance: d, angle: a - .pi / 6)
                        let path = Path([Pathline([op, cp]),
                                         Pathline([p0, cp, p1])])
                        let arrowNode = Node(path: path,
                                             lineWidth: rootView.worldLineWidth,
                                             lineType: .color(.selected))
                        oldP = frame.centerPoint
                        return Node(children: [arrowNode],
                                    path: Path(frame),
                                    lineWidth: rootView.worldLineWidth,
                                    lineType: .color(.selected),
                                    fillType: .color(.subSelected))
                    } else {
                        oldP = frame.centerPoint
                        return Node(path: Path(frame),
                                    lineWidth: rootView.worldLineWidth,
                                    lineType: .color(.selected),
                                    fillType: .color(.subSelected))
                    }
                }
            } else {
                selectingLineNode.lineWidth = rootView.worldLineWidth
                selectingLineNode.fillType = .color(.subSelected)
                selectingLineNode.lineType = .color(.selected)
                if !type.isDocument {
                    let (_, _, frame, _) = rootView.sheetViewAndFrame(at: p)
                    if frame.bounds != Sheet.defaultBounds,
                       let pathline = Rect(p, distance: 0).minLine(frame) {
                        selectingLineNode.path = Path([.init(frame), pathline])
                    } else {
                        selectingLineNode.path = Path(frame)
                    }
                } else {
                    let frame = rootView.sheetFrame(with: rootView.sheetPosition(at: p))
                    selectingLineNode.path = Path(frame)
                }
                
                rootView.updateSelectedColor(isMain: false)
            }
            rootView.node.append(child: selectingLineNode)
            
            rootView.textCursorNode.isHidden = true
            rootView.textMaxTypelineWidthNode.isHidden = true
        case .changed:
            break
        case .ended:
            beginExportFile(type, at: beganP)
        }
    }
    
    struct Rendering {
        struct Item {
            var id: UUID, sheet: Sheet?, data: Data?, url: URL?, frame = Rect()
            var sheetHistory: SheetHistory?, historyData: Data?, historyURL: URL?
            
            func decodedSheet() -> Sheet? {
                if let sheet {
                    sheet
                } else if let data {
                    try? .init(serializedData: data)
                } else if let url, let data = try? Data(contentsOf: url) {
                    try? .init(serializedData: data)
                } else {
                    nil
                }
            }
            func decodedSheetHistory() -> SheetHistory? {
                if let sheetHistory {
                    sheetHistory
                } else if let historyData {
                    try? .init(serializedData: historyData)
                } else if let historyURL, let data = try? Data(contentsOf: historyURL) {
                    try? .init(serializedData: data)
                } else {
                    nil
                }
            }
            
            mutating func makeTemps(urls: inout [URL]) throws {
                if let oURL = url {
                    let nURL = URL.appTemporaryDirectory
                        .appending(component: UUID().uuidString)
                    try FileManager.default.copyItem(at: oURL, to: nURL)
                    self.url = nURL
                    urls.append(nURL)
                }
                if let oURL = historyURL {
                    let nURL = URL.appTemporaryDirectory
                        .appending(component: UUID().uuidString)
                    try FileManager.default.copyItem(at: oURL, to: nURL)
                    self.historyURL = nURL
                    urls.append(nURL)
                }
            }
        }
        var mainItem: Item, bottomItems = [Item](), topItems = [Item]()
        var bounds: Rect
        var tempURLs = [URL]()
        
        func renderableMainSheetNode() -> CPUNode? {
            guard mainItem.url != nil else {
                return .init(path: .init(bounds), fillType: .color(.background))
            }
            guard let sheet = mainItem.decodedSheet() else { return nil }
            return sheet.node(isBorder: false, attitude: .init(position: mainItem.frame.origin), in: bounds)
        }
        
        mutating func makeTemps() throws {
            if !FileManager.default.fileExists(atPath: URL.appTemporaryDirectory.path()) {
                try FileManager.default.createDirectory(at: URL.appTemporaryDirectory,
                                                        withIntermediateDirectories: true)
            }
            try mainItem.makeTemps(urls: &tempURLs)
            for i in bottomItems.count.range {
                try bottomItems[i].makeTemps(urls: &tempURLs)
            }
            for i in topItems.count.range {
                try topItems[i].makeTemps(urls: &tempURLs)
            }
        }
        func resetTemps() {
            tempURLs.forEach { try? FileManager.default.removeItem(at: $0) }
        }
    }
    
    func beginExportFile(_ type: Exporting.ExportType, at p: Point) {
        let nvs: [SelectingValue]
        let isSelect = rootView.containsSelectedSheetPositions(p)
        if isSelect {
            let fshp = rootView.sheetPosition(at: p)
            let vs = rootView.world.selectedSheetPositions.map {
                SelectingValue(shp: $0, bounds: rootView.sheetFrame(with: $0).bounds)
            }
            nvs = sorted(vs, with: orientation(vs, at: fshp))
        } else {
            let (shp, sheetView, frame, _) = rootView.sheetViewAndFrame(at: p)
            if let sheetView {
                let bounds = sheetView.model
                    .boundsTuple(at: sheetView.convertFromWorld(p),
                                 in: rootView.sheetFrame(with: shp).bounds).bounds.integral
                nvs = [SelectingValue(shp: shp, bounds: bounds)]
            } else {
                let bounds = Rect(size: frame.size)
                nvs = [SelectingValue(shp: shp, bounds: bounds)]
            }
        }
        
        guard let fv = nvs.first else {
            end()
            return
        }
        let mainFrame = isSelect ? rootView.sheetView(at: p)?.model.mainFrame : nil
        let size = mainFrame?.size ?? fv.bounds.size
        guard size.width > 0 && size.height > 0 else {
            end()
            return
        }
        
        let colorSpace = ColorSpace.export
        
        let renderings: [Rendering], documentRecorders: [Document.SheetRecorder]
        switch type {
        case .image, .image4K, .images, .images4K, .pdf:
            renderings = nvs.map {
                if let sid = rootView.sheetID(at: $0.shp),
                   let sheetRecord = rootView.model.sheetRecorders[sid]?.sheetRecord {
                    
                    .init(mainItem: .init(id: sid, sheet: sheetRecord.value,
                                          data: sheetRecord.data, url: sheetRecord.url,
                                          frame: rootView.sheetFrame(with: $0.shp)),
                          bounds: mainFrame ?? $0.bounds)
                } else {
                    .init(mainItem: .init(id: .init(), sheet: nil,
                                          data: nil, url: nil,
                                          frame: rootView.sheetFrame(with: $0.shp)),
                          bounds: mainFrame ?? $0.bounds)
                }
            }
            documentRecorders = []
        case .gif, .movie, .movie4K, .sound, .linearPCM, .caption:
            renderings = nvs.map {
                var filledShps = Set<IntPoint>()
                
                var bottomItems = [Rendering.Item]()
                var shp = $0.shp
                shp.y -= 1
                while let sid = self.rootView.sheetID(at: shp),
                      let sheetRecord = rootView.model.sheetRecorders[sid]?.sheetRecord {
                    
                    if !filledShps.contains(shp) {
                        filledShps.insert(shp)
                        
                        bottomItems.append(.init(id: sid, sheet: sheetRecord.value,
                                                 data: sheetRecord.data, url: sheetRecord.url,
                                                 frame: rootView.sheetFrame(with: shp)))
                    }
                    shp.y -= 1
                }
                
                var topItems = [Rendering.Item]()
                shp = $0.shp
                shp.y += 1
                while let sid = self.rootView.sheetID(at: shp),
                      let sheetRecord = rootView.model.sheetRecorders[sid]?.sheetRecord {
                    
                    if !filledShps.contains(shp) {
                        filledShps.insert(shp)
                        
                        topItems.append(.init(id: sid, sheet: sheetRecord.value,
                                              data: sheetRecord.data, url: sheetRecord.url,
                                              frame: rootView.sheetFrame(with: shp)))
                    }
                    
                    shp.y += 1
                }
                
                return if let sid = rootView.sheetID(at: $0.shp),
                          let sheetRecord = rootView.model.sheetRecorders[sid]?.sheetRecord {
                    .init(mainItem: .init(id: sid, sheet: sheetRecord.value,
                                          data: sheetRecord.data, url: sheetRecord.url,
                                          frame: rootView.sheetFrame(with: $0.shp)),
                          bottomItems: bottomItems, topItems: topItems,
                          bounds: mainFrame ?? $0.bounds)
                } else {
                    .init(mainItem: .init(id: .init(), sheet: nil,
                                          data: nil, url: nil,
                                          frame: rootView.sheetFrame(with: $0.shp)),
                          bottomItems: bottomItems, topItems: topItems,
                          bounds: mainFrame ?? $0.bounds)
                }
            }
            documentRecorders = []
        case .timelapse:
            renderings = nvs.map {
                if let sid = rootView.sheetID(at: $0.shp),
                   let sheetRecord = rootView.model.sheetRecorders[sid]?.sheetRecord,
                   let sheetHistoryRecord = rootView.model.sheetRecorders[sid]?.sheetHistoryRecord {
                    .init(mainItem: .init(id: sid, sheet: sheetRecord.value,
                                          data: sheetRecord.data, url: sheetRecord.url,
                                          frame: rootView.sheetFrame(with: $0.shp),
                                          sheetHistory: sheetHistoryRecord.value,
                                          historyData: sheetHistoryRecord.data,
                                          historyURL: sheetHistoryRecord.url),
                          bottomItems: [], topItems: [],
                          
                          bounds: mainFrame ?? $0.bounds)
                } else {
                    .init(mainItem: .init(id: .init(), sheet: nil,
                                          data: nil, url: nil,
                                          frame: rootView.sheetFrame(with: $0.shp)),
                          bottomItems: [], topItems: [],
                          bounds: mainFrame ?? $0.bounds)
                }
            }
            documentRecorders = []
        case .document, .documentWithHistory:
            let sids = nvs.reduce(into: [IntPoint: UUID]()) {
                $0[$1.shp] = rootView.sheetID(at: $1.shp)
            }
            let csv = CopiedSheetsValue(deltaPoint: Point(), sheetIDs: sids)
            renderings = []
            documentRecorders = csv.sheetIDs.compactMap { rootView.model.sheetRecorders[$0.value] }
        }
        
        let isAlphaChannel = (rootView.sheetView(at: p)?.model.backgroundUUColor.value.opacity ?? 1) != 1
        
        let fType: any FileTypeProtocol = switch type {
        case .image, .images: nvs.count > 1 ? Image.FileType.pngs : Image.FileType.png
        case .image4K, .images4K: nvs.count > 1 ? Image.FileType.pngs : Image.FileType.png
        case .pdf: PDF.FileType.pdf
        case .gif: Image.FileType.gif
        case .movie, .movie4K, .timelapse: isAlphaChannel ? Movie.FileType.mov : Movie.FileType.mp4
        case .sound: Content.FileType.m4a
        case .linearPCM: Content.FileType.wav
        case .caption: Caption.FileType.itt
        case .document: Document.FileType.shikisendoc
        case .documentWithHistory: Document.FileType.shikisendoch
        }
        
        let fileSize: @Sendable () -> (Int?) = {
            switch type {
            case .image, .images:
                if renderings.count == 1, let node = renderings[0].renderableMainSheetNode() {
                    let nSize = size.width > size.height ?
                    size.snapped(height: 1080).rounded(.down) :
                    size.snapped(max: Size(width: 1200, height: 1920).rounded(.down))
                    let image = node.image(in: renderings[0].bounds, to: nSize, colorSpace)
                    return image?.data(.png)?.count ?? 0
                } else {
                    return nil
                }
            case .image4K, .images4K:
                if renderings.count == 1, let node = renderings[0].renderableMainSheetNode() {
                    let nSize = size.width > size.height ?
                    size.snapped(height: 2160).rounded(.down) :
                    size.snapped(max: Size(width: 2160, height: 3840)).rounded(.down)
                    let image = node.image(in: renderings[0].bounds, to: nSize, colorSpace)
                    return image?.data(.png)?.count ?? 0
                } else {
                    return nil
                }
            case .pdf:
                if renderings.count == 1, let node = renderings[0].renderableMainSheetNode(),
                   let pdf = try? PDF(mediaBox: Rect(size: size)) {
                   
                    pdf.newPage { pdf in
                        node.render(in: renderings[0].bounds, to: size, in: pdf)
                    }
                    pdf.finish()
                    return pdf.dataSize
                } else {
                    return nil
                }
            case .gif, .movie, .movie4K, .timelapse: return nil
            case .sound, .linearPCM: return nil
            case .caption: return nil
            case .document:
                return documentRecorders.sum { $0.fileSizeWithoutHistory }
            case .documentWithHistory:
                return documentRecorders.sum { $0.fileSize }
            }
        }
        
        let message = String(format: "Export as %@".localized, type.displayName)
        let name = name(from: nvs.map { $0.shp }) + (type.is4K ? "_4k" : "")
        
        Task { @MainActor in
            let result = await URL.export(message: message,
                                          name: name,
                                          fileType: fType,
                                          fileSizeHandler: fileSize)
            switch result {
            case .complete(let ioResult):
                rootView.syncSave()
                end()
                
                switch type {
                case .image, .images:
                    let nSize = size.width > size.height ?
                    size.snapped(height: 1080).rounded(.down) :
                    size.snapped(max: Size(width: 1200, height: 1920).rounded(.down))
                    exportImage(from: renderings, is4K: false, colorSpace,
                                size: nSize, at: ioResult)
                case .image4K, .images4K:
                    let nSize = size.width > size.height ?
                    size.snapped(height: 2160).rounded(.down) :
                    size.snapped(max: Size(width: 2160, height: 3840)).rounded(.down)
                    exportImage(from: renderings, is4K: true, colorSpace,
                                size: nSize, at: ioResult)
                case .pdf:
                    exportPDF(from: renderings, size: size, at: ioResult)
                case .gif:
                    let nSize = size.snapped(max: Size(width: 800, height: 800)).rounded(.down)
                    exportGIF(from: renderings, colorSpace, size: nSize, at: ioResult)
                case .movie:
                    let nSize = size.width > size.height ?
                    size.snapped(height: 1080).rounded(.down) :
                    size.snapped(max: Size(width: 1200, height: 1920).rounded(.down))
                    exportMovie(from: renderings, is4K: false, isAlphaChannel: isAlphaChannel,
                                colorSpace, size: nSize, at: ioResult)
                case .movie4K:
                    let nSize = size.width > size.height ?
                    size.snapped(height: 2160).rounded(.down) :
                    size.snapped(max: Size(width: 2160, height: 3840)).rounded(.down)
                    exportMovie(from: renderings, is4K: true, isAlphaChannel: isAlphaChannel,
                                colorSpace, size: nSize, at: ioResult)
                case .sound:
                    exportSound(from: renderings, isLinearPCM: false, at: ioResult)
                case .linearPCM:
                    exportSound(from: renderings, isLinearPCM: true, at: ioResult)
                case .caption:
                    exportCaption(from: renderings, at: ioResult)
                case .timelapse:
                    let nSize = size.width > size.height ?
                    size.snapped(height: 1080).rounded(.down) :
                    size.snapped(max: Size(width: 1200, height: 1920).rounded(.down))
                    exportTimelapse(from: renderings,
                                    isAlphaChannel: isAlphaChannel,
                                    colorSpace, size: nSize, at: ioResult)
                case .document:
                    exportDocument(from: nvs, isHistory: false, at: ioResult)
                case .documentWithHistory:
                    exportDocument(from: nvs, isHistory: true, at: ioResult)
                }
            case .cancel:
                end()
            }
        }
    }
    
    func exportImage(from renderings: [Rendering], is4K: Bool,
                     _ colorSpace: ColorSpace, size: Size, at ioResult: IOResult) {
        if renderings.isEmpty {
            return
        } else if renderings.count == 1 {
            do {
                try ioResult.remove()
                
                if let node = renderings[0].renderableMainSheetNode() {
                    if let image = node.image(in: renderings[0].bounds, to: size, colorSpace) {
                        try image.write(.png, to: ioResult.url)
                        try ioResult.setAttributes()
                    }
                }
            } catch {
                rootView.node.show(error)
            }
        } else {
            let exportingView = ExportingView(type: is4K ? .images4K : .images,
                                              name: ioResult.name)
            rootAction.hudView.append(exportingView)
            do {
                try ioResult.remove()
                try ioResult.makeDirectory()
                
                @Sendable func export(from renderings: [Rendering],
                                      progressHandler: (Double, inout Bool) -> ()) throws {
                    var isStop = false
                    for (j, rendering) in renderings.enumerated() {
                        if let node = rendering.renderableMainSheetNode() {
                            if let image = node.image(in: rendering.bounds, to: size,
                                                      colorSpace) {
                                let subIOResult = ioResult.sub(name: "\(j).png")
                                try image.write(.png, to: subIOResult.url)
                                try subIOResult.setAttributes()
                            }
                        }
                        progressHandler(Double(j + 1) / Double(renderings.count), &isStop)
                        if isStop { break }
                    }
                    if isStop {
                        try? ioResult.remove()
                    }
                }
                
                let task = Task.detached(priority: .utility) {
                    var renderings = renderings
                    for i in renderings.count.range {
                        try? renderings[i].makeTemps()
                    }
                    defer { renderings.forEach { $0.resetTemps() } }
                    
                    do {
                        try export(from: renderings) { (progress, isStop) in
                            if Task.isCancelled {
                                isStop = true
                                return
                            }
                            Task { @MainActor in
                                exportingView.progress = progress
                            }
                        }
                        Task { @MainActor in
                            exportingView.close()
                        }
                    } catch {
                        Task { @MainActor in
                            self.rootView.node.show(error)
                            exportingView.close()
                        }
                    }
                }
                exportingView.cancelHandler = { task.cancel() }
            } catch {
                self.rootView.node.show(error)
                exportingView.close()
            }
        }
    }
    
    func exportPDF(from renderings: [Rendering], size: Size, at ioResult: IOResult) {
        @Sendable func export(from renderings: [Rendering],
                              progressHandler: (Double, inout Bool) -> ()) throws {
            var isStop = false
            let pdf = try PDF(url: ioResult.url, mediaBox: Rect(size: size))
            
            for (i, rendering) in renderings.enumerated() {
                if let node = rendering.renderableMainSheetNode() {
                    pdf.newPage { pdf in
                        node.render(in: rendering.bounds, to: size, in: pdf)
                    }
                }
                
                progressHandler(Double(i + 1) / Double(renderings.count), &isStop)
                if isStop { break }
            }
            if !isStop {
                pdf.finish()
                try ioResult.setAttributes()
            } else {
                try? ioResult.remove()
            }
        }
        
        if renderings.count == 1 {
            do {
                try export(from: renderings) { (_, isStop) in }
            } catch {
                rootView.node.show(error)
            }
        } else {
            let exportingView = ExportingView(type: .pdf,
                                              name: ioResult.name)
            rootAction.hudView.append(exportingView)
            do {
                try ioResult.remove()
                
                let task = Task.detached(priority: .utility) {
                    var renderings = renderings
                    for i in renderings.count.range {
                        try? renderings[i].makeTemps()
                    }
                    defer { renderings.forEach { $0.resetTemps() } }
                    
                    do {
                        try export(from: renderings) { (progress, isStop) in
                            if Task.isCancelled {
                                isStop = true
                                return
                            }
                            Task { @MainActor in
                                exportingView.progress = progress
                            }
                        }
                        Task { @MainActor in
                            exportingView.close()
                        }
                    } catch {
                        Task { @MainActor in
                            self.rootView.node.show(error)
                            exportingView.close()
                        }
                    }
                }
                exportingView.cancelHandler = { task.cancel() }
            } catch {
                rootView.node.show(error)
                exportingView.close()
            }
        }
    }
    
    func exportGIF(from renderings: [Rendering], _ colorSpace: ColorSpace,
                   size: Size, at ioResult: IOResult) {
        @Sendable func export(from renderings: [Rendering],
                              progressHandler: (Double, inout Bool) -> ()) throws {
            var images = [(image: Image, time: Rational)]()
            var isStop = false, t = 0.0
            let allC = renderings.count + 1
            
            for rendering in renderings {
                if let sheet = rendering.mainItem.decodedSheet() {
                    let ot = t
                    var sec = Rational(0)
                    for (i, _) in sheet.animation.keyframes.enumerated() {
                        let node = sheet.node(isBorder: false, atSec: sec,
                                              enabledCaption: false,
                                              attitude: .init(position: rendering.mainItem.frame.origin),
                                              in: rendering.bounds)
                        let durBeat = sheet.animation.rendableKeyframeDurBeat(at: i)
                        let durSec = sheet.animation.sec(fromBeat: durBeat)
                        if let image = node.image(in: rendering.bounds, to: size, colorSpace) {
                            images.append((image, durSec))
                        }
                        sec += durSec
                        let d = Double(i + 1) / Double(sheet.animation.keyframes.count)
                        t = ot + d / Double(allC)
                        progressHandler(t, &isStop)
                    }
                } else {
                    let ot = t
                    if let node = renderings[0].renderableMainSheetNode(),
                       let image = node.image(in: renderings[0].bounds, to: size,
                                                                   colorSpace) {
                        images.append((image, Keyframe.defaultDurBeat))
                        t = ot + 1 / Double(allC)
                        progressHandler(t, &isStop)
                    }
                }
                
                if isStop { break }
            }
            if !isStop {
                try Image.writeGIF(images, to: ioResult.url)
                progressHandler(1, &isStop)
                if !isStop {
                    try ioResult.setAttributes()
                } else {
                    try? ioResult.remove()
                }
            }
        }
        
        let exportingView = ExportingView(type: .gif, name: ioResult.name)
        rootAction.hudView.append(exportingView)
        do {
            try ioResult.remove()
            
            let task = Task.detached(priority: .utility) {
                var renderings = renderings
                for i in renderings.count.range {
                    try? renderings[i].makeTemps()
                }
                defer { renderings.forEach { $0.resetTemps() } }
                
                do {
                    try export(from: renderings) { (progress, isStop) in
                        if Task.isCancelled {
                            isStop = true
                            return
                        }
                        Task { @MainActor in
                            exportingView.progress = progress
                        }
                    }
                    Task { @MainActor in
                        exportingView.close()
                    }
                } catch {
                    Task { @MainActor in
                        self.rootView.node.show(error)
                        exportingView.close()
                    }
                }
            }
            exportingView.cancelHandler = { task.cancel() }
        } catch {
            rootView.node.show(error)
            exportingView.close()
        }
    }
    
    func exportMovie(from renderings: [Rendering], is4K: Bool, isAlphaChannel: Bool,
                     _ colorSpace: ColorSpace,
                     size: Size, at ioResult: IOResult) {
        @Sendable func export(from renderings: [Rendering],
                              progressHandler: (Double, inout Bool) -> (),
                              completionHandler handler: @escaping (Bool, (any Error)?) -> ()) async {
            do {
                var isStop = false
                var durSecs = [Int: Rational](), allDurSec: Rational = 0
                struct Track {
                    var captions: [Caption]
                    var sheets: [(sheet: Sheet, sheetBounds: Rect)]
                    var secRange: Range<Rational>
                    var sheetOrigin: Point
                    var sheetBounds: Rect
                    var renderBounds: Rect
                    var backgroundColor: Color
                    
                    func frameRange(frameRate: Int) -> Range<Int> {
                        Animation.frame(fromSec: secRange.start, frameRate: frameRate)
                        ..< Animation.frame(fromSec: secRange.end, frameRate: frameRate)
                    }
                }
                var filledIDs = Set<UUID>()
                var tracks = [Track](), isEnabledAudio = false
                for (i, rendering) in renderings.enumerated() {
                    guard !filledIDs.contains(rendering.mainItem.id) else { continue }
                    filledIDs.insert(rendering.mainItem.id)
                    
                    var maxEndSec: Rational = 0
                    if let sheet = rendering.mainItem.decodedSheet() {
                        var captions = sheet.captions
                        
                        if sheet.isEnabledAudio {
                            isEnabledAudio = true
                        }
                        var sheets = [(sheet: Sheet, sheetBounds: Rect)]()
                        for item in rendering.bottomItems {
                            filledIDs.insert(item.id)
                            guard let sheet = item.decodedSheet(), sheet.enabledTimeline else { break }
                            if sheet.isEnabledAudio {
                                isEnabledAudio = true
                            }
                            captions += sheet.captions
                            if sheet.enabledAnimation {
                                sheets.append((sheet, item.frame.bounds))
                                maxEndSec = max(sheet.allEndSec, maxEndSec)
                            }
                        }
                        sheets.reverse()
                        
                        let sheetBounds = rendering.mainItem.frame.bounds
                        sheets.append((sheet, sheetBounds))
                        maxEndSec = max(sheet.allEndSec, maxEndSec)
                        
                        for item in rendering.topItems {
                            filledIDs.insert(item.id)
                            guard let sheet = item.decodedSheet(), sheet.enabledTimeline else { break }
                            if sheet.isEnabledAudio {
                                isEnabledAudio = true
                            }
                            captions += sheet.captions
                            if sheet.enabledAnimation {
                                sheets.append((sheet, item.frame.bounds))
                                maxEndSec = max(sheet.allEndSec, maxEndSec)
                            }
                        }
                        
                        let origin = rendering.mainItem.frame.origin
                        let b = rendering.bounds
                        tracks.append(.init(captions: captions, sheets: sheets,
                                            secRange: allDurSec ..< (allDurSec + maxEndSec),
                                            sheetOrigin: origin, sheetBounds: sheetBounds,
                                            renderBounds: b,
                                            backgroundColor: sheet.backgroundUUColor.value))
                    } else {
                        maxEndSec = Animation.sec(fromBeat: Keyframe.defaultDurBeat,
                                                  tempo: Music.defaultTempo)
                        
                        let origin = rendering.mainItem.frame.origin
                        tracks.append(.init(captions: [], sheets: [(.init(), rendering.bounds)],
                                            secRange: allDurSec ..< (allDurSec + maxEndSec),
                                            sheetOrigin: origin,
                                            sheetBounds: rendering.bounds,
                                            renderBounds: rendering.bounds,
                                            backgroundColor: .background))
                    }
                    durSecs[i] = maxEndSec
                    allDurSec += maxEndSec
                    
                    progressHandler(.init(i) / .init(renderings.count) * 0.1, &isStop)
                    if isStop { break }
                }
                
                let frameRate = Sheet.standardFrameRate(from: tracks.flatMap { $0.sheets.map { $0.sheet }})
                let movie = try Movie(url: ioResult.url, renderSize: size,
                                      isAlphaChannel: isAlphaChannel,
                                      isLinearPCM: is4K, colorSpace, frameRate: frameRate)
                let frameCount = Int(allDurSec * Rational(frameRate).rounded(.up))
                var oldImage: Image?, oldCaptionNodes = [CPUNode](), oldCaptions = [Caption]()
                var oldTrackI: Int?, oldSheetNodes = [(oki: Int?, oldNode: CPUNode?)]()
                for i in frameCount.range {
                    let trackI = tracks.firstIndex { $0.frameRange(frameRate: frameRate).contains(i) } ?? tracks.count - 1
                    if trackI != oldTrackI {
                        oldTrackI = trackI
                        
                        oldCaptionNodes = []
                        oldCaptions = []
                        oldImage = nil
                        oldSheetNodes = tracks[trackI].sheets.map { _ in (nil, nil) }
                    }
                    let track = tracks[trackI]
                    
                    var isChanged = false
                    
                    var children = [CPUNode]()
                    for si in track.sheets.count.range {
                        let (sheet, sheetBounds) = track.sheets[si]
                        let (oki, oldNode) = oldSheetNodes[si]
                        let ki = sheet.animation.indexInBeatRange(atFrame: i,
                                                                  startSec: track.secRange.start,
                                                                  frameRate: frameRate)
                        if oki != ki {
                            let node = sheet.node(isBorder: false, atKeyframe: ki,
                                                  isBackground: false,
                                                  in: sheetBounds)
                            children.append(node)
                            oldSheetNodes[si] = (ki, node)
                            isChanged = true
                        } else if let oldNode {
                            children.append(oldNode)
                        }
                    }
                    
                    let captions = Caption.captions(atFrame: i, frameRate: frameRate,
                                                    startSec: track.secRange.start,
                                                    in: track.captions)
                    let captionNodes: [CPUNode]
                    if captions != oldCaptions {
                        captionNodes = Caption.cpuNodes(in: track.renderBounds, from: captions)
                        oldCaptionNodes = captionNodes
                        oldCaptions = captions
                        isChanged = true
                    } else {
                        captionNodes = oldCaptionNodes
                    }
                    
                    let image: Image?
                    if isChanged || oldImage == nil {
                        let node = CPUNode(children: children + [.init(children: captionNodes)], attitude: .init(position: track.sheetOrigin),
                                           path: Path(track.sheetBounds),
                                           fillType: .color(track.backgroundColor))
                        image = node.image(in: track.renderBounds, to: size, colorSpace)
                        oldImage = image
                    } else {
                        image = oldImage
                    }
                    
                    guard let image else { throw Movie.exportError }
                    let isAppend = movie.write(image, duration: 1, timeScale: frameRate) { (stop) in
                        progressHandler(.init(i) / .init(frameCount) * (isEnabledAudio ? 0.8 : 0.9) + 0.1, &isStop)
                        if isStop {
                            stop = true
                        }
                    }
                    if isStop || !isAppend { break }
                }
                
                var audiotracks = [Audiotrack]()
                
                if !isStop {
                    var filledIDs = Set<UUID>()
                    for (i, rendering) in renderings.enumerated() {
                        guard !filledIDs.contains(rendering.mainItem.id),
                              let durSec = durSecs[i] else { continue }
                        filledIDs.insert(rendering.mainItem.id)
                        
                        var audiotrack: Audiotrack?
                        if let sheet = rendering.mainItem.decodedSheet() {
                            audiotrack += sheet.audiotrack
                        }
                        for item in rendering.bottomItems {
                            filledIDs.insert(item.id)
                            guard let sheet = item.decodedSheet(), sheet.enabledTimeline else { break }
                            audiotrack += sheet.audiotrack
                        }
                        for item in rendering.topItems {
                            filledIDs.insert(item.id)
                            guard let sheet = item.decodedSheet(), sheet.enabledTimeline else { break }
                            audiotrack += sheet.audiotrack
                        }
                        audiotrack?.durSec = durSec
                        if let audiotrack {
                            audiotracks.append(audiotrack)
                        }
                        
                        let t = (Double(i) / Double(renderings.count)) * 0.05 + 0.9
                        progressHandler(t, &isStop)
                        if isStop { break }
                    }
                    if !isStop {
                        if let sequencer = Sequencer(audiotracks: audiotracks, type: .normal) {
                            try movie.writeAudio(from: sequencer) { t, stop in
                                progressHandler(t * 0.05 + 0.95, &isStop)
                                if isStop {
                                    stop = true
                                }
                            }
                        }
                    }
                }
                
                do {
                    let isStop = try await movie.finish()
                    if !isStop {
                        try ioResult.setAttributes()
                    } else {
                        try? ioResult.remove()
                    }
                    handler(isStop, nil)
                } catch {
                    handler(true, error)
                }
            } catch {
                handler(false, error)
            }
        }
        
        let exportingView = ExportingView(type: is4K ? .movie4K : .movie, name: ioResult.name)
        rootAction.hudView.append(exportingView)
        do {
            try ioResult.remove()
            
            let task = Task.detached(priority: .utility) {
                var renderings = renderings
                for i in renderings.count.range {
                    try? renderings[i].makeTemps()
                }
                defer { renderings.forEach { $0.resetTemps() } }
                
                await export(from: renderings, progressHandler: { (progress, isStop) in
                    if Task.isCancelled {
                        isStop = true
                        return
                    }
                    Task { @MainActor in
                        exportingView.progress = progress
                    }
                }, completionHandler: { (stop, error) in
                    Task { @MainActor in
                        if !stop, let error {
                            self.rootView.node.show(error)
                        }
                        exportingView.close()
                    }
                })
            }
            exportingView.cancelHandler = { task.cancel() }
        } catch {
            rootView.node.show(error)
            exportingView.close()
        }
    }
    
    func exportSound(from renderings: [Rendering], isLinearPCM: Bool, at ioResult: IOResult) {
        @Sendable func export(from renderings: [Rendering],
                              progressHandler: (Double, inout Bool) -> (),
                    completionHandler handler: @escaping ((any Error)?) -> ()) {
            do {
                var audiotracks = [Audiotrack]()
                
                var filledIDs = Set<UUID>()
                var isStop = false
                for (i, rendering) in renderings.enumerated() {
                    guard !filledIDs.contains(rendering.mainItem.id) else { continue }
                    filledIDs.insert(rendering.mainItem.id)
                    
                    var audiotrack: Audiotrack?
                    if let sheet = rendering.mainItem.decodedSheet() {
                        audiotrack += sheet.audiotrack
                    }
                    for item in rendering.bottomItems {
                        filledIDs.insert(item.id)
                        guard let sheet = item.decodedSheet(), sheet.enabledTimeline else { break }
                        audiotrack += sheet.audiotrack
                    }
                    for item in rendering.topItems {
                        filledIDs.insert(item.id)
                        guard let sheet = item.decodedSheet(), sheet.enabledTimeline else { break }
                        audiotrack += sheet.audiotrack
                    }
                    if let audiotrack {
                        audiotracks.append(audiotrack)
                    }
                    
                    let t = 0.2 * Double(i) / Double(renderings.count)
                    progressHandler(t, &isStop)
                    if isStop { break }
                }
                if !isStop {
                    if let sequencer = Sequencer(audiotracks: audiotracks, type: .normal) {
                        try sequencer.export(url: ioResult.url,
                                             sampleRate: Audio.defaultSampleRate,
                                             isLinearPCM: isLinearPCM) { (t, stop) in
                            progressHandler(t * 0.8 + 0.2, &isStop)
                            if isStop {
                                stop = true
                            }
                        }
                        if !isStop {
                            try ioResult.setAttributes()
                        } else {
                            try? ioResult.remove()
                        }
                    }
                }
                
                handler(nil)
            } catch {
                handler(error)
            }
        }
        
        let exportingView = ExportingView(type: isLinearPCM ? .linearPCM : .sound,
                                          name: ioResult.name)
        rootAction.hudView.append(exportingView)
        do {
            try ioResult.remove()
            
            let task = Task.detached(priority: .utility) {
                var renderings = renderings
                for i in renderings.count.range {
                    try? renderings[i].makeTemps()
                }
                defer { renderings.forEach { $0.resetTemps() } }
                
                export(from: renderings, progressHandler: { (progress, isStop) in
                    if Task.isCancelled {
                        isStop = true
                        return
                    }
                    Task { @MainActor in
                        exportingView.progress = progress
                    }
                }, completionHandler: { error in
                    Task { @MainActor in
                        if let error {
                            self.rootView.node.show(error)
                        }
                        exportingView.close()
                    }
                })
            }
            exportingView.cancelHandler = { task.cancel() }
        } catch {
            rootView.node.show(error)
            exportingView.close()
        }
    }
    
    func exportCaption(from renderings: [Rendering], at ioResult: IOResult) {
        @Sendable func export(from renderings: [Rendering],
                              progressHandler: (Double, inout Bool) -> ()) async throws -> Bool {
            var isStop = false,
                sheets = [Sheet](), currentSec: Rational = 0, captions = [Caption]()
            for (ri, rendering) in renderings.enumerated() {
                if let sheet = rendering.mainItem.decodedSheet() {
                    var maxEndSec: Rational = 0
                    for item in rendering.bottomItems {
                        guard let sheet = item.decodedSheet(), sheet.enabledTimeline else { break }
                        maxEndSec = max(sheet.allEndSec, maxEndSec)
                        captions += sheet.captions.map { $0.move(sec: currentSec) }
                        sheets.append(sheet)
                    }
                    for item in rendering.topItems {
                        guard let sheet = item.decodedSheet(), sheet.enabledTimeline else { break }
                        maxEndSec = max(sheet.allEndSec, maxEndSec)
                        captions += sheet.captions.map { $0.move(sec: currentSec) }
                        sheets.append(sheet)
                    }
                    
                    maxEndSec = max(sheet.allEndSec, maxEndSec)
                    captions += sheet.captions.map { $0.move(sec: currentSec) }
                    sheets.append(sheet)
                    
                    currentSec += maxEndSec
                } else {
                    let maxEndSec = Animation.sec(fromBeat: Keyframe.defaultDurBeat,
                                                  tempo: Music.defaultTempo)
                    currentSec += maxEndSec
                }
                
                let t = Double(ri) / Double(renderings.count)
                progressHandler(t * 0.7, &isStop)
                if isStop {
                    return true
                }
            }
            
            captions.sort { $0.secRange.start < $1.secRange.start }
            var nCaptions = [Caption]()
            if !captions.isEmpty {
                var preCaption = captions[0]
                for i in 1 ..< captions.count {
                    let caption = captions[i]
                    if preCaption.secRange.end == caption.secRange.start
                        && preCaption.string == caption.string {
                        
                        preCaption.secRange.end = caption.secRange.end
                    } else {
                        nCaptions.append(preCaption)
                        preCaption = caption
                    }
                }
                nCaptions.append(preCaption)
            }
            
            let frameRate = Sheet.standardFrameRate(from: sheets)
            let renderer = try CaptionRenderer(url: ioResult.url, frameRate: frameRate)
            renderer.write(captions: nCaptions, duration: currentSec,
                           progressHandler: { (t, stop) in
                progressHandler(t * 0.3 + 0.7, &isStop)
                if isStop {
                    stop = true
                }
            })
            try await renderer.finish()
            if !isStop {
                try ioResult.setAttributes()
            } else {
                try? ioResult.remove()
            }
            return isStop
        }
        
        let exportingView = ExportingView(type: .caption, name: ioResult.name)
        rootAction.hudView.append(exportingView)
        do {
            try ioResult.remove()
            
            let task = Task.detached(priority: .utility) {
                var renderings = renderings
                for i in renderings.count.range {
                    try? renderings[i].makeTemps()
                }
                defer { renderings.forEach { $0.resetTemps() } }
                
                do {
                    _ = try await export(from: renderings,
                                         progressHandler: { (progress, isStop) in
                        if Task.isCancelled {
                            isStop = true
                            return
                        }
                        Task { @MainActor in
                            exportingView.progress = progress
                        }
                    })
                    Task { @MainActor in
                        exportingView.close()
                    }
                } catch {
                    Task { @MainActor in
                        self.rootView.node.show(error)
                        exportingView.close()
                    }
                }
            }
            exportingView.cancelHandler = { task.cancel() }
        } catch {
            rootView.node.show(error)
            exportingView.close()
        }
    }
    
    func exportDocument(from vs: [SelectingValue],
                        isHistory: Bool,
                        at ioResult: IOResult) {
        guard let shp0 = vs.first?.shp else { return }
        
        @Sendable func export(progressHandler: (Double, inout Bool) -> ()) throws {
            try ioResult.remove()
            
            let sids = vs.reduce(into: [IntPoint: UUID]()) {
                $0[$1.shp - shp0] = rootView.sheetID(at: $1.shp)
            }
            let csv = CopiedSheetsValue(deltaPoint: Point(), sheetIDs: sids)
            
            var isStop = false
            let nDocument = Document(ioResult.url)
            var world = World()
            for (i, v) in csv.sheetIDs.enumerated() {
                let (shp, osid) = v
                guard let osrr = rootView.model.sheetRecorders[osid] else { continue }
                let nsid = UUID()
                let nsrr = nDocument.makeSheetRecorder(at: nsid)
                
                if let oldSID = world.sheetIDs[shp] {
                    world.sheetPositions[oldSID] = nil
                }
                world.sheetIDs[shp] = nsid
                world.sheetPositions[nsid] = shp
                
                nsrr.sheetRecord.data = osrr.sheetRecord.decodedData
                nsrr.thumbnail4Record.data = osrr.thumbnail4Record.decodedData
                nsrr.thumbnail16Record.data = osrr.thumbnail16Record.decodedData
                nsrr.thumbnail64Record.data = osrr.thumbnail64Record.decodedData
                nsrr.thumbnail256Record.data = osrr.thumbnail256Record.decodedData
                nsrr.thumbnail1024Record.data = osrr.thumbnail1024Record.decodedData
                nsrr.stringRecord.data = osrr.stringRecord.decodedData
                nsrr.sheetRecord.isWillwrite = true
                nsrr.thumbnail4Record.isWillwrite = true
                nsrr.thumbnail16Record.isWillwrite = true
                nsrr.thumbnail64Record.isWillwrite = true
                nsrr.thumbnail256Record.isWillwrite = true
                nsrr.thumbnail1024Record.isWillwrite = true
                nsrr.stringRecord.isWillwrite = true
                
                if isHistory {
                    nsrr.sheetHistoryRecord.data = osrr.sheetHistoryRecord.decodedData
                    nsrr.sheetHistoryRecord.isWillwrite = true
                }
                
                if !osrr.contentsDirectory.childrenURLs.isEmpty {
                    for (key, url) in osrr.contentsDirectory.childrenURLs {
                        nsrr.contentsDirectory.isWillwrite = true
                        try? nsrr.contentsDirectory.write()
                        try? nsrr.contentsDirectory.copy(name: key, from: url)
                    }
                    if var sheet = nsrr.sheetRecord.decodedValue {
                        if !sheet.contents.isEmpty {
                            let dn = nsid.uuidString
                            for i in sheet.contents.count.range {
                                sheet.contents[i].directoryName = dn
                            }
                            nsrr.sheetRecord.value = sheet
                        }
                    }
                }
                
                progressHandler(Double(i + 1) / Double(csv.sheetIDs.count + 1), &isStop)
                if isStop { break }
            }
            nDocument.worldRecord.data = try? world.serializedData()
            nDocument.worldRecord.isWillwrite = true
            nDocument.povRecord.data = try? rootView.pov.serializedData()
            nDocument.povRecord.isWillwrite = true
            try nDocument.write()
            
            try ioResult.setAttributes()
        }
        
        if vs.count == 1 {
            do {
                try export { (_, isStop) in }
            } catch {
                rootView.node.show(error)
            }
        } else {
            let type: Exporting.ExportType = isHistory ? .documentWithHistory : .document
            let progressPanel = ProgressPanel(message: String(format: "Exporting %1$@ \"%2$@\"".localized, type.displayName, ioResult.name))
            rootView.node.show(progressPanel)
            let task = Task.detached(priority: .utility) {
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
        }
    }
    
    func exportTimelapse(from renderings: [Rendering], isAlphaChannel: Bool,
                         _ colorSpace: ColorSpace,
                         size: Size, at ioResult: IOResult) {
        @Sendable func export(from renderings: [Rendering],
                              progressHandler: (Double, inout Bool) -> (),
                              completionHandler handler: @escaping (Bool, (any Error)?) -> ()) async {
            do {
                var isStop = false, filledIDs = Set<UUID>()
                let movie = try Movie(url: ioResult.url, renderSize: size,
                                      isAlphaChannel: isAlphaChannel,
                                      isLinearPCM: false, colorSpace, frameRate: 60)
                for (i, rendering) in renderings.enumerated() {
                    guard !filledIDs.contains(rendering.mainItem.id) else { continue }
                    filledIDs.insert(rendering.mainItem.id)
                    
                    if let url = rendering.mainItem.url,
                       let sheet = rendering.mainItem.decodedSheet(),
                       let history = rendering.mainItem.decodedSheetHistory() {
                        
                        let sheetBinder = RecordBinder(value: sheet, record: Record(url: url))
                        let sheetView = SheetView(binder: sheetBinder,
                                                  keyPath: \SheetBinder.value,
                                                  history: history)
                        var allGroups = [(version: Version,
                                          group: UndoGroup<SheetUndoItem>)]()
                        history.allGroups { indexPath, groups in
                            allGroups += groups.enumerated()
                                .map { (.init(indexPath: indexPath, groupIndex: $0.offset),
                                        $0.element) }
                        }
                        allGroups.sort { $0.group.date < $1.group.date }
                        let frameCount = allGroups.count
                        let vs = [nil] + allGroups.map { $0.version }
                        for (vi, version) in vs.enumerated() {
                            try sheetView.history.move(to: version) { yIndexPath in
                                sheetView.history.set(indexPath: yIndexPath)
                            } topIHandler: { topIndex in
                                sheetView.undo(to: topIndex, isMakeRect: false, isSleep: false)
                                if vi == 0 && topIndex != 0 {
                                    progressHandler(.init(vi) / .init(frameCount) * 0.6 + 0.1, &isStop)
                                    if isStop {
                                        throw CancellationError()
                                    }
                                    return
                                }
                                
                                let children = [sheetView.node]
                                let backgroundColor = sheetView.model.backgroundUUColor.value
                                let origin = rendering.mainItem.frame.origin
                                let b = rendering.bounds
                                let sheetBounds = rendering.mainItem.frame.bounds
                                
                                let node = Node(children: children,
                                                attitude: .init(position: origin),
                                                path: Path(sheetBounds),
                                                fillType: .color(backgroundColor))
                                guard let image = node.renderedTexture(in: b, to: size, backgroundColor: backgroundColor)?.image else { throw Movie.exportError }
                                let isAppend = movie.write(image, duration: 1, timeScale: 60) { (stop) in
                                    progressHandler(.init(vi) / .init(frameCount) * 0.6 + 0.1, &isStop)
                                    if isStop {
                                        stop = true
                                    }
                                }
                                if isStop || !isAppend {
                                    throw CancellationError()
                                }
                            }
                        }
                    }
                    
                    progressHandler(.init(i) / .init(renderings.count) * 0.1, &isStop)
                    if isStop { break }
                }
                
                do {
                    let isStop = try await movie.finish()
                    if !isStop {
                        try ioResult.setAttributes()
                    } else {
                        try? ioResult.remove()
                    }
                    handler(isStop, nil)
                } catch {
                    handler(true, error)
                }
            } catch is CancellationError {
                try? ioResult.remove()
                handler(true, nil)
            } catch {
                handler(false, error)
            }
        }
        
        let exportingView = ExportingView(type: .timelapse, name: ioResult.name)
        rootAction.hudView.append(exportingView)
        do {
            try ioResult.remove()
            
            let task = Task.detached(priority: .utility) {
                var renderings = renderings
                for i in renderings.count.range {
                    try? renderings[i].makeTemps()
                }
                defer { renderings.forEach { $0.resetTemps() } }
                
                await export(from: renderings,
                             progressHandler: { (progress, isStop) in
                    if Task.isCancelled {
                        isStop = true
                        return
                    }
                    Task { @MainActor in
                        exportingView.progress = progress
                    }
                }, completionHandler: { (stop, error) in
                    Task { @MainActor in
                        if !stop, let error {
                            self.rootView.node.show(error)
                        }
                        exportingView.close()
                    }
                })
            }
            exportingView.cancelHandler = { task.cancel() }
        } catch {
            rootView.node.show(error)
            exportingView.close()
        }
    }
}

final class ToMP4MovieAction: InputKeyEventAction {
    let rootAction: RootAction, rootView: RootView
    
    init(_ rootAction: RootAction) {
        self.rootAction = rootAction
        rootView = rootAction.rootView
    }
    
    func flow(with event: InputKeyEvent) {
        Task { @MainActor in
            let result = await URL.load(prompt: "Import".localized,
                                        fileTypes: [Movie.FileType.mp4, Movie.FileType.mov])
            switch result {
            case .complete(let ioResult0s):
                let result = await URL.export(name: "",
                                              fileType: Movie.FileType.mp4,
                                              fileSizeHandler: { return nil })
                switch result {
                case .complete(let ioResult1):
                    let fromURL = ioResult0s[0].url
                    let toURL = ioResult1.url
                    Task {
                        do {
                            try await Movie.toMP4(from: fromURL, to: toURL)
                        } catch {
                            rootView.node.show(error)
                        }
                    }
                case .cancel: break
                }
            case .cancel: break
            }
        }
    }
}
