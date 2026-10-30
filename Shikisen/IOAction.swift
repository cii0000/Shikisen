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
import struct Foundation.Date
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
        let isEnabledTimeline = svvs.contains { $0.value.sheetView?.model.isEnabledTimeline ?? false }
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
                            if let size = try? await MovieEncoder.size(from: content.url),
                               let durSec = try? await MovieEncoder.durSec(from: content.url),
                               let frameRate = try? await MovieEncoder.frameRate(from: content.url) {
                                
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
                                    sheetView.set(SheetSelection(textSelections: text.string.isEmpty ?
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
                        sheetView.set(SheetSelection(textSelections: text.string.isEmpty ?
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
                rootView.set(nSelection)
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
            return sheet.node(isBorder: false, pose: .init(position: mainItem.frame.origin), in: bounds)
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
        case .gif, .movie, .movie4K, .sound, .linearPCM, .caption, .timelapse:
            func item(sid: UUID, shp: IntPoint,
                      sheetRecord: Record<Sheet>) -> Rendering.Item {
                if type == .timelapse,
                   let sheetHistoryRecord
                    = rootView.model.sheetRecorders[sid]?.sheetHistoryRecord {
                  .init(id: sid, sheet: sheetRecord.value,
                        data: sheetRecord.data, url: sheetRecord.url,
                        frame: rootView.sheetFrame(with: shp),
                        sheetHistory: sheetHistoryRecord.value,
                        historyData: sheetHistoryRecord.data,
                        historyURL: sheetHistoryRecord.url)
                } else {
                    .init(id: sid, sheet: sheetRecord.value,
                          data: sheetRecord.data, url: sheetRecord.url,
                          frame: rootView.sheetFrame(with: shp))
                }
            }
            renderings = nvs.map {
                var filledShps = Set<IntPoint>()
                
                var bottomItems = [Rendering.Item]()
                var shp = $0.shp
                shp.y -= 1
                while let sid = self.rootView.sheetID(at: shp),
                      let sheetRecord = rootView.model.sheetRecorders[sid]?.sheetRecord {
                    
                    if !filledShps.contains(shp) {
                        filledShps.insert(shp)
                        
                        bottomItems.append(item(sid: sid, shp: shp, sheetRecord: sheetRecord))
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
                        
                        topItems.append(item(sid: sid, shp: shp, sheetRecord: sheetRecord))
                    }
                    
                    shp.y += 1
                }
                
                return if let sid = rootView.sheetID(at: $0.shp),
                          let sheetRecord = rootView.model.sheetRecorders[sid]?.sheetRecord {
                    .init(mainItem: item(sid: sid, shp: shp, sheetRecord: sheetRecord),
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
        case .movie, .movie4K, .timelapse: isAlphaChannel ? MovieEncoder.FileType.mov : MovieEncoder.FileType.mp4
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
        let name = name(from: nvs.map { $0.shp })
        + (type == .timelapse ? "_tl" : "") + (type.is4K ? "_4k" : "")
        
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
                                    colorSpace,
                                    size: nSize, at: ioResult)
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
                rootAction.hudView.show(error)
            }
        } else {
            @Sendable func export(from renderings: [Rendering],
                                  progressHandler: (Double) -> ()) async throws {
                for (ri, rendering) in renderings.enumerated() {
                    if let node = rendering.renderableMainSheetNode() {
                        if let image = node.image(in: rendering.bounds, to: size,
                                                  colorSpace) {
                            let subIOResult = ioResult.sub(name: "\(ri).png")
                            try image.write(.png, to: subIOResult.url)
                            try subIOResult.setAttributes()
                        }
                    }
                    
                    progressHandler(Double(ri + 1) / Double(renderings.count))
                    try Task.checkCancellation()
                }
            }
            
            let exportingView = ExportingView(type: is4K ? .images4K : .images,
                                              name: ioResult.name)
            rootAction.hudView.append(exportingView)
            do {
                try ioResult.remove()
                try ioResult.makeDirectory()
                
                let task = Task.detached(priority: .utility) {
                    var renderings = renderings
                    for i in renderings.count.range {
                        try? renderings[i].makeTemps()
                    }
                    defer { renderings.forEach { $0.resetTemps() } }
                    
                    var im = IntervalManager()
                    do {
                        try await export(from: renderings) { (progress) in
                            if im.isUpdate() {
                                Task { @MainActor in
                                    exportingView.progress = progress
                                }
                            }
                        }
                    } catch {
                        try ioResult.remove()
                        if !(error is CancellationError) {
                            Task { @MainActor in
                                self.rootAction.hudView.show(exportingView.error(with: error))
                            }
                        }
                    }
                    Task { @MainActor in
                        exportingView.close()
                    }
                }
                exportingView.cancelHandler = { task.cancel() }
            } catch {
                self.rootAction.hudView.show(error)
                exportingView.close()
            }
        }
    }
    
    func exportPDF(from renderings: [Rendering], size: Size, at ioResult: IOResult) {
        @Sendable func export(from renderings: [Rendering],
                              progressHandler: (Double) -> ()) async throws {
            let pdf = try PDF(url: ioResult.url, mediaBox: Rect(size: size))
            for (ri, rendering) in renderings.enumerated() {
                if let node = rendering.renderableMainSheetNode() {
                    pdf.newPage { pdf in
                        node.render(in: rendering.bounds, to: size, in: pdf)
                    }
                }
                
                progressHandler(Double(ri + 1) / Double(renderings.count))
                try Task.checkCancellation()
            }
            pdf.finish()
            try ioResult.setAttributes()
        }
        
        if renderings.count == 1 {
            do {
                let pdf = try PDF(url: ioResult.url, mediaBox: Rect(size: size))
                if let node = renderings[0].renderableMainSheetNode() {
                    pdf.newPage { pdf in
                        node.render(in: renderings[0].bounds, to: size, in: pdf)
                    }
                }
                pdf.finish()
                try ioResult.setAttributes()
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
                    
                    var im = IntervalManager()
                    do {
                        try await export(from: renderings) { (progress) in
                            if im.isUpdate() {
                                Task { @MainActor in
                                    exportingView.progress = progress
                                }
                            }
                        }
                    } catch {
                        try ioResult.remove()
                        if !(error is CancellationError) {
                            Task { @MainActor in
                                self.rootAction.hudView.show(exportingView.error(with: error))
                            }
                        }
                    }
                    Task { @MainActor in
                        exportingView.close()
                    }
                }
                exportingView.cancelHandler = { task.cancel() }
            } catch {
                rootAction.hudView.show(error)
                exportingView.close()
            }
        }
    }
    
    func exportGIF(from renderings: [Rendering], _ colorSpace: ColorSpace,
                   size: Size, at ioResult: IOResult) {
        @Sendable func export(from renderings: [Rendering],
                              progressHandler: (Double) -> ()) async throws {
            var images = [(image: Image, time: Rational)]()
            for (ri, rendering) in renderings.enumerated() {
                if let sheet = rendering.mainItem.decodedSheet() {
                    var sec = Rational(0)
                    for (ki, _) in sheet.animation.keyframes.enumerated() {
                        let node = sheet.node(isBorder: false, atSec: sec,
                                              isEnabledCaption: false,
                                              pose: .init(position: rendering.mainItem.frame.origin),
                                              in: rendering.bounds)
                        let durBeat = sheet.animation.rendableKeyframeDurBeat(at: ki)
                        let durSec = sheet.animation.sec(fromBeat: durBeat)
                        if let image = node.image(in: rendering.bounds, to: size, colorSpace) {
                            images.append((image, durSec))
                        }
                        sec += durSec
                        let dt = Double(ki + 1) / Double(sheet.animation.keyframes.count)
                        
                        progressHandler((Double(ri) + dt) / Double(renderings.count))
                        try Task.checkCancellation()
                    }
                } else {
                    if let node = renderings[0].renderableMainSheetNode(),
                       let image = node.image(in: renderings[0].bounds, to: size,
                                                                   colorSpace) {
                        images.append((image, Keyframe.defaultDurBeat))
                        
                        progressHandler(Double(ri + 1) / Double(renderings.count))
                        try Task.checkCancellation()
                    }
                }
            }
            try Image.writeGIF(images, to: ioResult.url)
            try ioResult.setAttributes()
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
                
                var im = IntervalManager()
                do {
                    try await export(from: renderings) { (progress) in
                        if im.isUpdate() {
                            Task { @MainActor in
                                exportingView.progress = progress
                            }
                        }
                    }
                } catch {
                    try ioResult.remove()
                    if !(error is CancellationError) {
                        Task { @MainActor in
                            self.rootAction.hudView.show(exportingView.error(with: error))
                        }
                    }
                }
                Task { @MainActor in
                    exportingView.close()
                }
            }
            exportingView.cancelHandler = { task.cancel() }
        } catch {
            rootAction.hudView.show(error)
            exportingView.close()
        }
    }
    
    func exportMovie(from renderings: [Rendering], is4K: Bool, isAlphaChannel: Bool,
                     _ colorSpace: ColorSpace,
                     size: Size, at ioResult: IOResult) {
        @Sendable func export(from renderings: [Rendering],
                              progressHandler: (Double) -> ()) async throws {
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
            var allDurSec: Rational = 0
            var audiotracks = [Audiotrack]()
            var filledIDs = Set<UUID>()
            var tracks = [Track](), isEnabledAudio = false
            for (ri, rendering) in renderings.enumerated() {
                guard !filledIDs.contains(rendering.mainItem.id) else { continue }
                filledIDs.insert(rendering.mainItem.id)
                
                var maxEndSec: Rational = 0
                if let sheet = rendering.mainItem.decodedSheet() {
                    var audiotrack: Audiotrack?
                    audiotrack += sheet.audiotrack
                    var captions = sheet.captions
                    
                    var sheets = [(sheet: Sheet, sheetBounds: Rect)]()
                    for item in rendering.bottomItems {
                        filledIDs.insert(item.id)
                        guard let sheet = item.decodedSheet(), sheet.isEnabledTimeline else { break }
                        
                        audiotrack += sheet.audiotrack
                        captions += sheet.captions
                        if sheet.isEnabledAnimation {
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
                        guard let sheet = item.decodedSheet(), sheet.isEnabledTimeline else { break }
                        
                        audiotrack += sheet.audiotrack
                        captions += sheet.captions
                        if sheet.isEnabledAnimation {
                            sheets.append((sheet, item.frame.bounds))
                            maxEndSec = max(sheet.allEndSec, maxEndSec)
                        }
                    }
                    
                    audiotrack?.durSec = maxEndSec
                    if !(audiotrack?.values.isEmpty ?? true) {
                        isEnabledAudio = true
                    }
                    audiotracks.append(audiotrack ?? .init(values: [], durSec: maxEndSec))
                    
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
                    
                    audiotracks.append(.init(values: [], durSec: maxEndSec))
                    
                    let origin = rendering.mainItem.frame.origin
                    tracks.append(.init(captions: [], sheets: [(.init(), rendering.bounds)],
                                        secRange: allDurSec ..< (allDurSec + maxEndSec),
                                        sheetOrigin: origin,
                                        sheetBounds: rendering.bounds,
                                        renderBounds: rendering.bounds,
                                        backgroundColor: .background))
                }
                
                allDurSec += maxEndSec
                
                progressHandler(.init(ri + 1) / .init(renderings.count) * 0.1)
                try Task.checkCancellation()
            }
            
            let frameRate = Sheet.standardFrameRate(from: tracks.flatMap { $0.sheets.map { $0.sheet }})
            let movieEncoder = try MovieEncoder(url: ioResult.url, renderSize: size,
                                                isAlphaChannel: isAlphaChannel,
                                                colorSpace, frameRate: frameRate,
                                                isEnabledAudio: isEnabledAudio,
                                                isLinearPCM: is4K)
            do {
                let frameCount = Int(allDurSec * Rational(frameRate).rounded(.up))
                var oldImage: Image?, oldCaptionNodes = [CPUNode](), oldCaptions = [Caption]()
                var oldTrackI: Int?, oldSheetNodes = [(oki: Int?, oldNode: CPUNode?)]()
                for fi in frameCount.range {
                    let trackI = tracks.firstIndex { $0.frameRange(frameRate: frameRate).contains(fi) } ?? tracks.count - 1
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
                        let ki = sheet.animation.indexInBeatRange(atFrame: fi,
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
                    
                    let captions = Caption.captions(atFrame: fi, frameRate: frameRate,
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
                        let node = CPUNode(children: children + [.init(children: captionNodes)], pose: .init(position: track.sheetOrigin),
                                           path: Path(track.sheetBounds),
                                           fillType: .color(track.backgroundColor))
                        image = node.image(in: track.renderBounds, to: size, colorSpace)
                        oldImage = image
                    } else {
                        image = oldImage
                    }
                    guard let image else { throw MovieEncoder.ExportingError() }
                    
                    try await movieEncoder.write(image, dur: 1, timeScale: frameRate)
                    
                    progressHandler(.init(fi + 1) / .init(frameCount) * (isEnabledAudio ? 0.8 : 0.9) + 0.1)
                    try Task.checkCancellation()
                }
                
                if isEnabledAudio {
                    let sequencer = Sequencer(audiotracks: audiotracks, type: .normal)
                    try await movieEncoder.writeAudio(from: sequencer) { t in
                        progressHandler(t * 0.1 + 0.9)
                        try Task.checkCancellation()
                    }
                }
                
                try await movieEncoder.finish()
                try ioResult.setAttributes()
            } catch {
                movieEncoder.cancel()
                throw error
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
                
                var im = IntervalManager()
                do {
                    try await export(from: renderings) { (progress) in
                        if im.isUpdate() {
                            Task { @MainActor in
                                exportingView.progress = progress
                            }
                        }
                    }
                } catch {
                    try ioResult.remove()
                    if !(error is CancellationError) {
                        Task { @MainActor in
                            self.rootAction.hudView.show(exportingView.error(with: error))
                        }
                    }
                }
                Task { @MainActor in
                    exportingView.close()
                }
            }
            exportingView.cancelHandler = { task.cancel() }
        } catch {
            rootAction.hudView.show(error)
            exportingView.close()
        }
    }
    
    func exportSound(from renderings: [Rendering], isLinearPCM: Bool, at ioResult: IOResult) {
        @Sendable func export(from renderings: [Rendering],
                              progressHandler: (Double) -> ()) async throws {
            var audiotracks = [Audiotrack]()
            
            var filledIDs = Set<UUID>()
            for (ri, rendering) in renderings.enumerated() {
                guard !filledIDs.contains(rendering.mainItem.id) else { continue }
                filledIDs.insert(rendering.mainItem.id)
                
                if let sheet = rendering.mainItem.decodedSheet() {
                    var audiotrack: Audiotrack?
                    audiotrack += sheet.audiotrack
                    
                    for item in rendering.bottomItems {
                        filledIDs.insert(item.id)
                        guard let sheet = item.decodedSheet(), sheet.isEnabledTimeline else { break }
                        audiotrack += sheet.audiotrack
                    }
                    for item in rendering.topItems {
                        filledIDs.insert(item.id)
                        guard let sheet = item.decodedSheet(), sheet.isEnabledTimeline else { break }
                        audiotrack += sheet.audiotrack
                    }
                    if let audiotrack {
                        audiotracks.append(audiotrack)
                    }
                }
                
                progressHandler(Double(ri + 1) / Double(renderings.count) * 0.2)
                try Task.checkCancellation()
            }
            
            let sequencer = Sequencer(audiotracks: audiotracks, type: .normal)
            try sequencer.export(url: ioResult.url,
                                 sampleRate: Audio.defaultSampleRate,
                                 isLinearPCM: isLinearPCM) { (t) in
                progressHandler(t * 0.8 + 0.2)
                try Task.checkCancellation()
            }
            try ioResult.setAttributes()
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
                
                var im = IntervalManager()
                do {
                    try await export(from: renderings) { (progress) in
                        if im.isUpdate() {
                            Task { @MainActor in
                                exportingView.progress = progress
                            }
                        }
                    }
                } catch {
                    try ioResult.remove()
                    if !(error is CancellationError) {
                        Task { @MainActor in
                            self.rootAction.hudView.show(exportingView.error(with: error))
                        }
                    }
                }
                Task { @MainActor in
                    exportingView.close()
                }
            }
            exportingView.cancelHandler = { task.cancel() }
        } catch {
            rootAction.hudView.show(error)
            exportingView.close()
        }
    }
    
    func exportCaption(from renderings: [Rendering], at ioResult: IOResult) {
        @Sendable func export(from renderings: [Rendering],
                              progressHandler: (Double) -> ()) async throws {
            var sheets = [Sheet](), currentSec: Rational = 0, captions = [Caption]()
            for (ri, rendering) in renderings.enumerated() {
                if let sheet = rendering.mainItem.decodedSheet() {
                    var maxEndSec: Rational = 0
                    for item in rendering.bottomItems {
                        guard let sheet = item.decodedSheet(), sheet.isEnabledTimeline else { break }
                        maxEndSec = max(sheet.allEndSec, maxEndSec)
                        captions += sheet.captions.map { $0.move(sec: currentSec) }
                        sheets.append(sheet)
                    }
                    for item in rendering.topItems {
                        guard let sheet = item.decodedSheet(), sheet.isEnabledTimeline else { break }
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
                
                progressHandler(Double(ri + 1) / Double(renderings.count) * 0.7)
                try Task.checkCancellation()
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
            let captionEncoder = try CaptionEncoder(url: ioResult.url, frameRate: frameRate)
            do {
                try await captionEncoder.write(captions: nCaptions, duration: currentSec) { (t) in
                    progressHandler(t * 0.3 + 0.7)
                    try Task.checkCancellation()
                }
                try await captionEncoder.finish()
                try ioResult.setAttributes()
            } catch {
                captionEncoder.cancel()
                throw error
            }
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
                
                var im = IntervalManager()
                do {
                    try await export(from: renderings) { (progress) in
                        if im.isUpdate() {
                            Task { @MainActor in
                                exportingView.progress = progress
                            }
                        }
                    }
                } catch {
                    try ioResult.remove()
                    if !(error is CancellationError) {
                        Task { @MainActor in
                            self.rootAction.hudView.show(exportingView.error(with: error))
                        }
                    }
                }
                Task { @MainActor in
                    exportingView.close()
                }
            }
            exportingView.cancelHandler = { task.cancel() }
        } catch {
            rootAction.hudView.show(error)
            exportingView.close()
        }
    }
    
    func exportTimelapse(from renderings: [Rendering], isAlphaChannel: Bool,
                         _ colorSpace: ColorSpace, clipTime: Double? = 60,
                         aroundColor: Color = .border,
                         size: Size, at ioResult: IOResult) {
        @Sendable func export(from renderings: [Rendering],
                              progressHandler: (Double) -> ()) async throws {
            var filledIDs = Set<UUID>()
            let movieEncoder = try MovieEncoder(url: ioResult.url, renderSize: size,
                                                isAlphaChannel: isAlphaChannel,
                                                colorSpace, frameRate: 60,
                                                isEnabledAudio: false, isLinearPCM: false)
            do {
                for (ri, rendering) in renderings.enumerated() {
                    guard !filledIDs.contains(rendering.mainItem.id) else { continue }
                    filledIDs.insert(rendering.mainItem.id)
                    
                    struct K {
                        var image: Image, beat: Rational = 0, isUpdate = true
                    }
                    class SB {
                        var view: SheetView, bounds: Rect, ks = [K]()
                        
                        init(item: Rendering.Item) throws {
                            guard let url = item.url,
                               let sheet = item.decodedSheet(),
                               let history = item.decodedSheetHistory()
                            else { throw MovieEncoder.ExportingError() }
                                
                            let sheetBinder = RecordBinder(value: sheet,
                                                           record: Record(url: url))
                            view = SheetView(binder: sheetBinder,
                                             keyPath: \SheetBinder.value,
                                             history: history)
                            bounds = item.frame.bounds
                        }
                    }
                    
                    var sbs = [SB]()
                    for item in rendering.bottomItems {
                        filledIDs.insert(item.id)
                        guard let sheet = item.decodedSheet(), sheet.isEnabledTimeline else { break }
                        if sheet.isEnabledAnimation {
                            sbs.append(try .init(item: item))
                        }
                    }
                    sbs.reverse()
                    
                    sbs.append(try .init(item: rendering.mainItem))
                    
                    let isEnabledAnimation = sbs.last!.view.model.isEnabledAnimation
                    let mainBackgroundColor = sbs.last!.view.model.backgroundUUColor.value
                    guard let fkImage = Image(size: size, color: mainBackgroundColor)
                    else { throw MovieEncoder.ExportingError() }
                    
                    for item in rendering.topItems {
                        filledIDs.insert(item.id)
                        guard let sheet = item.decodedSheet(), sheet.isEnabledTimeline else { break }
                        if sheet.isEnabledAnimation {
                            sbs.append(try .init(item: item))
                        }
                    }
                    
                    var allGroups = [(si: Int, sb: SB, version: Version?, date: Date)]()
                    for (si, sb) in sbs.enumerated() {
                        allGroups.append((si, sb, nil, .distantPast))
                        sb.view.history.allGroups { indexPath, groups in
                            allGroups += groups.enumerated()
                                .map { (si, sb,
                                        .init(indexPath: indexPath, groupIndex: $0.offset),
                                        $0.element.date) }
                        }
                        if allGroups.last?.date != sb.view.history.currentDate {
                            allGroups.append((si, sb, sb.view.history.currentVersion,
                                              .distantFuture))
                        }
                    }
                    allGroups.sort { $0.date < $1.date }
                    
                    let isMultiK = sbs.count > 1
                    
                    let minKeyframesCount = isMultiK ?
                    sbs.reduce(into: Set<Rational>()) {
                        $0.formUnion($1.view.model.animation.keyframes.map { $0.beat })
                    }.count :
                    sbs[0].view.model.animation.keyframes.count
                    
                    func moveFirst() async throws {
                        for (si, sb) in sbs.enumerated() {
                            let topCount = sb.view.history.currentVersionIndex + 1
                            try await sb.view.history.move(to: nil) { yIndexPath in
                                sb.view.history.set(indexPath: yIndexPath)
                            } topIHandler: { toTopIndex in
                                for result in sb.view.history.undoResults(to: toTopIndex) {
                                    let undoItem = try sb.view.history
                                        .undoItem(with: result, sb.view.model)
                                    sb.view.update(undoItem,
                                                   isMakeRect: false, isSleep: false)
                                    switch undoItem {
                                    case .setSelection(let selection):
                                        if !selection.isEmpty {
                                            sb.view.updateNode(from: .empty,
                                                               old: sb.view.model.selection)
                                        }
                                    default: break
                                    }
                                }
                                
                                let t = (.init(si) + .init(topCount - toTopIndex) / .init(topCount))
                                / Double(sbs.count)
                                progressHandler((.init(ri) + t * 0.05) / .init(renderings.count))
                                try Task.checkCancellation()
                            }
                        }
                    }
                    try await moveFirst()
                    
                    func calculateCount() async throws -> Int {
                        var allCount = 1
                        var countHistotys = sbs.map { $0.view.history }
                        for (vi, group) in allGroups.enumerated() {
                            try await countHistotys[group.si].move(to: group.version) { yIndexPath in
                                countHistotys[group.si].set(indexPath: yIndexPath)
                            } topIHandler: { toTopIndex in
                                allCount += 1
                                countHistotys[group.si].set(toTopIndex: toTopIndex)
                                
                                progressHandler((.init(ri) + .init(vi + 1) / .init(allGroups.count) * 0.05 + 0.05) / .init(renderings.count))
                                try Task.checkCancellation()
                            }
                        }
                        return allCount
                    }
                    let allCount = try await calculateCount()
                    
                    let speed = clipTime != nil ?
                    max(Int((Double(allCount / 60) / clipTime!).rounded(.up)), 1) : 1
                    
                    guard let bitmap = Bitmap<UInt8>(width: .init(size.width),
                                                     height: .init(size.height),
                                                     colorSpace: .sRGB)
                    else { throw MovieEncoder.ExportingError() }
                    bitmap.set(fillColor: aroundColor)
                    bitmap.fill(Rect(size: size))
                    
                    struct RowColumn: Hashable {
                        var row = 0.0, column = 0.0
                       
                        static func length(_ f0: Self, _ f1: Self,
                                           columnCount: Double) -> Double {
                            (f0.row * columnCount + f0.column)
                                .distance(f1.row * columnCount + f1.column)
                        }
                        static func linear(_ f0: Self, _ f1: Self,
                                           t: Double, columnCount: Double) -> [Self] {
                            let startV = f0.row * columnCount + f0.column
                            let endV = f1.row * columnCount + f1.column
                            let v = Double.linear(startV, endV, t: t)
                            let row = (v / columnCount).rounded(.down)
                            let column = v - row * columnCount
                            return if column > columnCount - 1 {
                                [.init(row: row, column: column),
                                 .init(row: row + 1, column: column - columnCount)]
                            } else if column < 1 {
                                [.init(row: row, column: column),
                                 .init(row: row - 1, column: column + columnCount)]
                            } else {
                                [.init(row: row, column: column)]
                            }
                        }
                    }
                    struct KR {
                        var image: Image, beat: Rational = 0, isUpdate = true,
                            rect = Rect?.none, rowColumn = RowColumn()
                    }
                    func drawBitmap() async throws {
                        guard let image = bitmap.image
                        else { throw MovieEncoder.ExportingError() }
                        try await movieEncoder.write(image, dur: 1, timeScale: 60)
                    }
                    
                    let padding = 2.0
                    let inB = Rect(size: size).inset(by: padding * 2)
                    
                    let columnCount = Int(Double(minKeyframesCount).squareRoot().rounded(.up))
                    let minCellWidth = (inB.width / Double(columnCount)).rounded(.up)
                    let minSize = Size(width: minCellWidth,
                                       height: (inB.height * minCellWidth / inB.width).rounded(.up))
                    
                    let emptyColor = Color(white: 0, opacity: 0)
                    guard let fkrImage = Image(size: minSize,
                                               color: mainBackgroundColor),
                          let ofkImage = isMultiK ?
                            Image(size: minSize, color: emptyColor) :
                                (isEnabledAnimation ? fkrImage : fkImage)
                    else { throw MovieEncoder.ExportingError() }
                    for i in sbs.count.range {
                        sbs[i].ks = [K(image: fkrImage)]
                    }
                    
                    var krs = [KR(image: ofkImage)], currentI = 0, isRedraw = false
                    func setIsupdateKRs(from beatRange: Range<Rational>) {
                        for kri in krs.count.range {
                            if beatRange.contains(krs[kri].beat) {
                                krs[kri].isUpdate = true
                            }
                        }
                    }
                    func make() async throws {
                        let origin = rendering.mainItem.frame.origin
                        let b = rendering.bounds
                        let sheetBounds = rendering.mainItem.frame.bounds
                        if isEnabledAnimation {
                            for sb in sbs {
                                let updateKIs = sb.ks.enumerated()
                                    .compactMap { $0.element.isUpdate ? $0.offset : nil }
                                let backgroundColor = isMultiK ?
                                emptyColor : mainBackgroundColor
                                for ki in updateKIs {
                                    let node = sb.view.animationView.elementViews[ki].node
                                    guard let image = Node(children: [node],
                                                           pose: .init(position: origin),
                                                           path: Path(sheetBounds),
                                                           fillType: .color(backgroundColor))
                                        .renderedTexture(in: b, to: minSize,
                                                         backgroundColor: backgroundColor)?.image
                                            else { throw MovieEncoder.ExportingError() }
                                    sb.ks[ki].image = image
                                }
                            }
                            
                            var updatedKRIs = Set<Int>()
                            if isMultiK {
                                for sb in sbs {
                                    let updateKIs = sb.ks.enumerated()
                                        .compactMap { $0.element.isUpdate ? $0.offset : nil }
                                    for ki in updateKIs {
                                        let beat = sb.ks[ki].beat
                                        let beatRange = beat ..< (ki + 1 < sb.ks.count ? sb.ks[ki + 1].beat : .max)
                                        setIsupdateKRs(from: beatRange)
                                    }
                                }
                                
                                func updateKR(at kri: Int) throws {
                                    guard !updatedKRIs.contains(kri) else { return }
                                    updatedKRIs.insert(kri)
                                    
                                    let beat = krs[kri].beat
                                    let nImages = (0 ..< sbs.count).compactMap {
                                        sbs[$0].ks.reversed()
                                            .first(where: { $0.beat <= beat })?.image
                                    }
                                    if nImages.count == 1 {
                                        krs[kri].image = nImages[0]
                                    } else {
                                        guard let nBitmap = Bitmap<UInt8>(width: .init(minSize.width),
                                                                         height: .init(minSize.height),
                                                                         colorSpace: .sRGB)
                                        else { throw MovieEncoder.ExportingError() }
                                        nBitmap.set(fillColor: mainBackgroundColor)
                                        nBitmap.fill(Rect(size: minSize))
                                        for nsi in 0 ..< sbs.count {
                                            if let nImage = sbs[nsi].ks.reversed()
                                                .first(where: { $0.beat <= beat })?.image {
                                                nBitmap.draw(nImage,
                                                             in: .init(size: minSize))
                                            }
                                        }
                                        guard let image = nBitmap.image
                                        else { throw MovieEncoder.ExportingError() }
                                        krs[kri].image = image
                                    }
                                }
                                
                                for kri in krs.count.range {
                                    if krs[kri].isUpdate {
                                        try updateKR(at: kri)
                                        krs[kri].isUpdate = false
                                    }
                                }
                            } else {
                                sbs[0].ks.enumerated().forEach {
                                    krs[$0.offset].image = $0.element.image
                                    updatedKRIs.insert($0.offset)
                                }
                            }
                            for sb in sbs {
                                for ki in sb.ks.count.range {
                                    sb.ks[ki].isUpdate = false
                                }
                            }
                            
                            let kCount = max(minKeyframesCount, krs.count)
                            let columnCount
                            = Int(Double(kCount).squareRoot().rounded(.up))
                            let cellWidth = inB.width / Double(columnCount)
                            let cellheight = inB.height * cellWidth / inB.width
                            func rowColumn(at ki: Int) -> RowColumn {
                                .init(row: Double(ki / columnCount),
                                      column: Double(ki % columnCount))
                            }
                            func rect(at rc: RowColumn) -> Rect {
                                Rect(x: inB.minX + rc.column * cellWidth,
                                     y: inB.maxY - (rc.row + 1) * cellheight,
                                     width: cellWidth,
                                     height: cellheight).inset(by: padding)
                            }
                            func rect(at ki: Int) -> Rect {
                                rect(at: rowColumn(at: ki))
                            }
                            
                            if isRedraw {
                                isRedraw = false
                                
                                func draw(t: Double) async throws {
                                    bitmap.set(fillColor: aroundColor)
                                    bitmap.fill(Rect(size: size))
                                    
                                    for (ki, kr) in krs.enumerated() {
                                        guard let oRect = t == 1 ?
                                                rect(at: ki) : krs[ki].rect else { continue }
                                        let oRC = kr.rowColumn, nRC = rowColumn(at: ki)
                                        if oRC.row != nRC.row {
                                            let rcs = RowColumn
                                                .linear(oRC, nRC, t: t,
                                                        columnCount: Double(columnCount))
                                            let b = Rect.linear(oRect,
                                                                rect(at: ki), t: t)
                                            func nRect(at rc: RowColumn) -> Rect {
                                                var r = rect(at: rc)
                                                r.size.width = b.width
                                                r.size.height = b.height
                                                return r
                                            }
                                            if rcs.count == 2 {
                                                bitmap.draw(kr.image,
                                                            in: nRect(at: rcs[0]))
                                                bitmap.draw(kr.image,
                                                            in: nRect(at: rcs[1]))
                                            } else {
                                                bitmap.draw(kr.image,
                                                            in: nRect(at: rcs[0]))
                                            }
                                        } else {
                                            let rect = Rect.linear(oRect,
                                                                   rect(at: ki), t: t)
                                            bitmap.draw(kr.image, in: rect)
                                        }
                                    }
                                    try await drawBitmap()
                                }
                                
                                let isMove = krs.count.range
                                    .contains { krs[$0].rect != nil
                                        && krs[$0].rect != rect(at: $0) }
                                if isMove {
                                    var maxLength = 1.0
                                    for (ki, kr) in krs.enumerated() {
                                        guard krs[ki].rect != nil else { continue }
                                        let oRC = kr.rowColumn, nRC = rowColumn(at: ki)
                                        let l = RowColumn
                                            .length(oRC, nRC,
                                                    columnCount: Double(columnCount))
                                        maxLength = max(l, maxLength)
                                    }
                                    let count = Int(maxLength.clipped(min: 1, max: 10,
                                                                      newMin: 6,
                                                                      newMax: 30))
                                    for i in 1 ... count {
                                        try await draw(t: (Double(i) / Double(count)).easeOut())
                                    }
                                } else {
                                    try await draw(t: 1)
                                }
                                for ki in krs.count.range {
                                    krs[ki].rect = rect(at: ki)
                                    krs[ki].rowColumn = rowColumn(at: ki)
                                }
                            } else {
                                for ki in updatedKRIs.sorted() {
                                    bitmap.draw(krs[ki].image, in: rect(at: ki))
                                }
                                try await drawBitmap()
                            }
                        } else {
                            guard let image = Node(children: [sbs[0].view.node],
                                                   pose: .init(position: origin),
                                                   path: Path(sheetBounds),
                                                   fillType: .color(mainBackgroundColor))
                                .renderedTexture(in: b, to: size,
                                                 backgroundColor: mainBackgroundColor)?.image
                            else { throw MovieEncoder.ExportingError() }
                            try await movieEncoder.write(image, dur: 1, timeScale: 60)
                        }
                    }
                    
                    try await make()
                    
                    let t = 1.0 / .init(allCount) * 0.9
                    progressHandler((.init(ri) + t + 0.1) / .init(renderings.count))
                    try Task.checkCancellation()
                    
                    currentI = 1
                    for group in allGroups {
                        let sb = group.sb
                        let sheetView = sb.view
                        try await sheetView.history.move(to: group.version) { yIndexPath in
                            sheetView.history.set(indexPath: yIndexPath)
                        } topIHandler: { toTopIndex in
                            defer { currentI += 1 }
                            for result in sheetView.history.undoResults(to: toTopIndex) {
                                let undoItem = try sheetView.history
                                    .undoItem(with: result, sheetView.model)
                                sheetView.update(undoItem, isMakeRect: false, isSleep: false)
                                switch undoItem {
                                case .setSelection(let selection):
                                    if !selection.isEmpty {
                                        sheetView.updateNode(from: .empty,
                                                             old: sheetView.model.selection)
                                    }
                                default: break
                                }
                                
                                if isEnabledAnimation {
                                    switch undoItem {
                                    case .appendKeyLine(let kv):
                                        sb.ks[kv.index].isUpdate = true
                                    case .removeKeyLastLine(let ki):
                                        sb.ks[ki].isUpdate = true
                                    case .appendKeyLines(let kv):
                                        sb.ks[kv.index].isUpdate = true
                                    case .removeKeyLastLines(let kv):
                                        sb.ks[kv.index].isUpdate = true
                                    case .insertDraftKeyLines(let kvs):
                                        kvs.forEach { sb.ks[$0.index].isUpdate = true }
                                    case .insertDraftKeyPlanes(let kvs):
                                        kvs.forEach { sb.ks[$0.index].isUpdate = true }
                                    case .insertKeyLines(let kvs):
                                        kvs.forEach { sb.ks[$0.index].isUpdate = true }
                                    case .insertKeyPlanes(let kvs):
                                        kvs.forEach { sb.ks[$0.index].isUpdate = true }
                                    case .removeDraftKeyLines(let kvs):
                                        kvs.forEach { sb.ks[$0.index].isUpdate = true }
                                    case .removeDraftKeyPlanes(let kvs):
                                        kvs.forEach { sb.ks[$0.index].isUpdate = true }
                                    case .removeKeyLines(let kvs):
                                        kvs.forEach { sb.ks[$0.index].isUpdate = true }
                                    case .removeKeyPlanes(let kvs):
                                        kvs.forEach { sb.ks[$0.index].isUpdate = true }
                                    case .replaceKeyLines(let kvs):
                                        kvs.forEach { sb.ks[$0.index].isUpdate = true }
                                    case .replaceKeyPlanes(let kvs):
                                        kvs.forEach { sb.ks[$0.index].isUpdate = true }
                                    case .setKeyPlaneValues(let kvs):
                                        kvs.forEach { sb.ks[$0.index].isUpdate = true }
                                    case .changedColors(let cv):
                                        if !cv.lineIs.isEmpty {
                                            sb.ks[sheetView.model.animation.index].isUpdate = true
                                        } else if !cv.keysLineIs.isEmpty {
                                            cv.keysLineIs
                                                .forEach { sb.ks[$0.index].isUpdate = true }
                                        }
                                        if !cv.planeIs.isEmpty {
                                            sb.ks[sheetView.model.animation.index].isUpdate = true
                                        } else if !cv.keysPlaneIs.isEmpty {
                                            cv.keysPlaneIs
                                                .forEach { sb.ks[$0.index].isUpdate = true }
                                        }
                                    case .insertKeyframes(let kvs):
                                        for kv in kvs {
                                            sb.ks.insert(K(image: ofkImage,
                                                           beat: kv.value.beat),
                                                         at: kv.index)
                                            
                                            if isMultiK {
                                                if let kri = krs.enumerated().reversed()
                                                    .first(where: { kv.value.beat >= $0.element.beat })?.offset {
                                                    if krs[kri].beat != kv.value.beat {
                                                        krs.insert(KR(image: fkrImage,
                                                                      beat: kv.value.beat),
                                                                   at: kri + 1)
                                                    }
                                                    for ki in krs.count.range {
                                                        krs[ki].isUpdate = true
                                                    }
                                                }
                                            } else {
                                                krs.insert(KR(image: fkrImage,
                                                              beat: kv.value.beat),
                                                           at: kv.index)
                                            }
                                        }
                                        
                                        isRedraw = true
                                    case .removeKeyframes(let kis):
                                        if isMultiK {
                                            for ki in kis.reversed() {
                                                let oldBeat = sb.ks[ki].beat
                                                let isNoRemove = sbs.enumerated().contains { (si, sb) in
                                                    si != group.si
                                                    && sb.ks.contains(where: { $0.beat == oldBeat })
                                                }
                                                
                                                sb.ks.remove(at: ki)
                                                
                                                if let kri = krs.firstIndex(where: { $0.beat == oldBeat }) {
                                                    if !isNoRemove {
                                                        krs.remove(at: kri)
                                                    }
                                                }
                                            }
                                            for ki in krs.count.range {
                                                krs[ki].isUpdate = true
                                            }
                                        } else {
                                            sb.ks.remove(at: kis)
                                            krs.remove(at: kis)
                                        }
                                        
                                        isRedraw = true
                                    case .setKeyframeOptions(let kvs):
                                        for kv in kvs {
                                            if isMultiK {
                                                let krsCount = krs.count
                                                let oldBeat = sb.ks[kv.index].beat
                                                let isNoRemove = sbs.enumerated().contains { (si, sb) in
                                                    si != group.si
                                                    && sb.ks.contains(where: { $0.beat == oldBeat })
                                                }
                                                if let kri = krs.firstIndex(where: { $0.beat == oldBeat }) {
                                                    if !isNoRemove {
                                                       krs.remove(at: kri)
                                                    }
                                                }
                                                
                                                if let kri = krs.enumerated().reversed()
                                                    .first(where: { kv.value.beat >= $0.element.beat })?.offset {
                                                    if krs[kri].beat != kv.value.beat {
                                                        krs.insert(KR(image: fkrImage,
                                                                      beat: kv.value.beat),
                                                                   at: kri + 1)
                                                    }
                                                }
                                                if krsCount != krs.count {
                                                    isRedraw = true
                                                }
                                                for ki in krs.count.range {
                                                    krs[ki].isUpdate = true
                                                }
                                            }
                                            sb.ks[kv.index].beat = kv.value.beat
                                        }
                                    default:
                                        sb.ks[sheetView.model.animation.index].isUpdate = true
                                    }
                                }
                            }
                            
                            if currentI % speed == 0 || currentI == allCount - 1 {
                                try await make()
                            }
                            let t = .init(currentI + 1) / .init(allCount) * 0.9
                            progressHandler((.init(ri) + t + 0.1) / .init(renderings.count))
                            try Task.checkCancellation()
                        }
                    }
                }
                
                try await movieEncoder.finish()
                try ioResult.setAttributes()
            } catch {
                movieEncoder.cancel()
                throw error
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
                
                var im = IntervalManager()
                do {
                    try await export(from: renderings) { (progress) in
                        if im.isUpdate() {
                            Task { @MainActor in
                                exportingView.progress = progress
                            }
                        }
                    }
                } catch {
                    try ioResult.remove()
                    if !(error is CancellationError) {
                        Task { @MainActor in
                            self.rootAction.hudView.show(exportingView.error(with: error))
                        }
                    }
                }
                Task { @MainActor in
                    exportingView.close()
                }
            }
            exportingView.cancelHandler = { task.cancel() }
        } catch {
            rootAction.hudView.show(error)
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
                        self.rootAction.hudView.show(error)
                        progressPanel.closePanel()
                    }
                }
            }
            progressPanel.cancelHandler = { task.cancel() }
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
                                        fileTypes: [MovieEncoder.FileType.mp4, MovieEncoder.FileType.mov])
            switch result {
            case .complete(let ioResult0s):
                let result = await URL.export(name: "",
                                              fileType: MovieEncoder.FileType.mp4,
                                              fileSizeHandler: { return nil })
                switch result {
                case .complete(let ioResult1):
                    let fromURL = ioResult0s[0].url
                    let toURL = ioResult1.url
                    Task {
                        do {
                            try await MovieEncoder.toMP4(from: fromURL, to: toURL)
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
