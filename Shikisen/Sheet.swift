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

struct InterOption: Hashable, Codable {
    var id = UUID()
    var interType = InterType.none
}
extension InterOption {
    func with(_ id: UUID) -> Self {
        .init(id: id, interType: interType)
    }
    func with(_ interType: InterType) -> Self {
        .init(id: id, interType: interType)
    }
}
extension InterOption: Protobuf {
    init(_ pb: PBInterOption) throws {
        self.id = (try? .init(pb.id)) ?? .init()
        self.interType = (try? .init(pb.interType)) ?? .none
    }
    var pb: PBInterOption {
        .with {
            $0.id = id.pb
            $0.interType = interType.pb
        }
    }
}
extension Line {
    var interOption: InterOption {
        get {
            .init(id: interID, interType: interType)
        }
        set {
            self.interID = newValue.id
            self.interType = newValue.interType
        }
    }
}

struct PlaneValue {
    var planes: [Plane]
    var moveIndexValues: [IndexValue<Int>]
}
extension PlaneValue: Protobuf {
    init(_ pb: PBPlaneValue) throws {
        planes = try pb.planes.map { try .init($0) }
        moveIndexValues = try pb.moveIndexValues.map { try .init($0) }
    }
    var pb: PBPlaneValue {
        .with {
            $0.planes = planes.map { $0.pb }
            $0.moveIndexValues = moveIndexValues.map { $0.pb }
        }
    }
}
extension PlaneValue: Codable {}

struct ColorValue {
    var uuColor: UUColor
    var planeIndexes: [Int], lineIndexes: [Int], isBackground: Bool
    var planeAnimationIndexes: [IndexValue<[Int]>]
    var lineAnimationIndexes: [IndexValue<[Int]>]
    var animationColors: [Color]
}
extension ColorValue: Protobuf {
    init(_ pb: PBColorValue) throws {
        uuColor = try .init(pb.uuColor)
        planeIndexes = pb.planeIndexes.map { max(.init($0), 0) }
        lineIndexes = pb.lineIndexes.map { max(.init($0), 0) }
        planeAnimationIndexes = try .init(pb.planeAnimationIndexes)
        lineAnimationIndexes = try .init(pb.lineAnimationIndexes)
        animationColors = pb.animationColors.compactMap { try? .init($0) }
        isBackground = pb.isBackground
    }
    var pb: PBColorValue {
        .with {
            $0.uuColor = uuColor.pb
            $0.planeIndexes = planeIndexes.map { .init($0) }
            $0.lineIndexes = lineIndexes.map { .init($0) }
            $0.planeAnimationIndexes = planeAnimationIndexes.pb
            $0.lineAnimationIndexes = lineAnimationIndexes.pb
            $0.animationColors = animationColors.map { $0.pb }
            $0.isBackground = isBackground
        }
    }
}
extension ColorValue: Hashable, Codable {}

struct TextValue: Hashable, Codable {
    var string: String, replacedRange: Range<Int>,
        origin: Point?, size: Double?, widthCount: Double?
}
extension TextValue {
    var newRange: Range<Int> {
        replacedRange.lowerBound ..< (replacedRange.lowerBound + string.count)
    }
}
extension TextValue: Protobuf {
    init(_ pb: PBTextValue) throws {
        string = pb.string
        replacedRange = try IntRange(pb.replacedRange).value
        if case .origin(let origin)? = pb.originOptional {
            self.origin = try Point(origin)
        } else {
            origin = nil
        }
        if case .size(let size)? = pb.sizeOptional {
            self.size = size
        } else {
            size = nil
        }
        if case .widthCount(let widthCount)? = pb.widthCountOptional {
            self.widthCount = widthCount
        } else {
            widthCount = nil
        }
    }
    var pb: PBTextValue {
        .with {
            $0.string = string
            $0.replacedRange = IntRange(value: replacedRange).pb
            if let origin {
                $0.originOptional = .origin(origin.pb)
            } else {
                $0.originOptional = nil
            }
            if let size {
                $0.sizeOptional = .size(size)
            } else {
                $0.sizeOptional = nil
            }
            if let widthCount {
                $0.widthCountOptional = .widthCount(widthCount)
            } else {
                $0.widthCountOptional = nil
            }
        }
    }
}

struct SheetValue {
    var lines = [Line](), planes = [Plane](),
        texts = [Text](), contents = [Content](), origin = Point()
    var id = UUID(), rootKeyframeIndex = 0
    var keyframes = [Keyframe]()
    var keyframeBeganIndex = 0
    var isSelected: Bool
}
extension SheetValue {
    var string: String? {
        if texts.count == 1 {
            texts[0].string
        } else {
            nil
        }
    }
    var allTextsString: String {
        let strings = texts
            .sorted { $0.origin.y == $1.origin.y ?
                $0.origin.x < $1.origin.x : $0.origin.y > $1.origin.y }
            .map { $0.string }
        var str = ""
        for nstr in strings {
            str += nstr
            str += "\n\n\n\n"
        }
        return str
    }
}
extension SheetValue: Protobuf {
    init(_ pb: PBSheetValue) throws {
        lines = try pb.lines.map { try Line($0) }
        planes = try pb.planes.map { try Plane($0) }
        texts = try pb.texts.map { try Text($0) }
        contents = try pb.contents.map { try Content($0) }
        origin = try Point(pb.origin)
        id = try UUID(pb.id)
        rootKeyframeIndex = Int(pb.rootKeyframeIndex)
        keyframes = try pb.keyframes.map { try Keyframe($0) }
        keyframeBeganIndex = Int(pb.keyframeBeganIndex)
            .clipped(min: 0, max: keyframes.count - 1)
        isSelected = pb.isSelected
    }
    var pb: PBSheetValue {
        .with {
            $0.lines = lines.map { $0.pb }
            $0.planes = planes.map { $0.pb }
            $0.texts = texts.map { $0.pb }
            $0.contents = contents.map { $0.pb }
            $0.origin = origin.pb
            $0.id = id.pb
            $0.rootKeyframeIndex = Int64(rootKeyframeIndex)
            $0.keyframes = keyframes.map { $0.pb }
            $0.keyframeBeganIndex = Int64(keyframeBeganIndex)
            $0.isSelected = isSelected
        }
    }
}
extension SheetValue: Codable {}
extension SheetValue: AppliableTransform {
    static func * (lhs: SheetValue, rhs: Transform) -> SheetValue {
        SheetValue(lines: lhs.lines.map { $0 * rhs },
                   planes: lhs.planes.map { $0 * rhs },
                   texts: lhs.texts.map { $0 * rhs },
                   contents: lhs.contents.map { $0 * rhs },
                   origin: lhs.origin,
                   id: lhs.id,
                   rootKeyframeIndex: lhs.rootKeyframeIndex,
                   keyframes: lhs.keyframes.map { $0 * rhs },
                   keyframeBeganIndex: lhs.keyframeBeganIndex,
                   isSelected: lhs.isSelected)
    }
}
extension SheetValue {
    var isEmpty: Bool {
        lines.isEmpty && planes.isEmpty && texts.isEmpty && keyframes.isEmpty
    }
    static func + (lhs: SheetValue, rhs: SheetValue) -> SheetValue {
        SheetValue(lines: lhs.lines + rhs.lines,
                   planes: lhs.planes + rhs.planes,
                   texts: lhs.texts + rhs.texts,
                   contents: lhs.contents + rhs.contents,
                   origin: lhs.origin,
                   id: lhs.id == rhs.id ? lhs.id : UUID(),
                   rootKeyframeIndex: lhs.rootKeyframeIndex,
                   keyframes: lhs.keyframes + rhs.keyframes,
                   keyframeBeganIndex: lhs.keyframeBeganIndex,
                   isSelected: lhs.isSelected)
    }
    static func += (lhs: inout SheetValue, rhs: SheetValue) {
        lhs.lines += rhs.lines
        lhs.planes += rhs.planes
        lhs.texts += rhs.texts
        lhs.contents += rhs.contents
        lhs.keyframeBeganIndex += rhs.keyframeBeganIndex
        if lhs.id != rhs.id {
            lhs.id = UUID()
        }
    }
}

extension Array where Element == Int {
    init(_ pb: PBInt64Array) throws {
        self = pb.value.map { Int($0) }
    }
    var pb: PBInt64Array {
        .with { $0.value = map { Int64($0) } }
    }
}
extension Array where Element == Line {
    init(_ pb: PBLineArray) throws {
        self = try pb.value.map { try Line($0) }
    }
    var pb: PBLineArray {
        .with { $0.value = map { $0.pb } }
    }
}
extension Array where Element == Plane {
    init(_ pb: PBPlaneArray) throws {
        self = try pb.value.map { try Plane($0) }
    }
    var pb: PBPlaneArray {
        .with { $0.value = map { $0.pb } }
    }
}
extension Array where Element == UUID {
    init(_ pb: PBUUIDArray) throws {
        self = try pb.value.map { try .init($0) }
    }
    var pb: PBUUIDArray {
        .with { $0.value = map { $0.pb } }
    }
}
extension IndexValue where Value == Int {
    init(_ pb: PBIntIndexValue) throws {
        value = Int(pb.value)
        index = max(Int(pb.index), 0)
    }
    var pb: PBIntIndexValue {
        .with {
            $0.value = Int64(value)
            $0.index = Int64(index)
        }
    }
}
extension IndexValue where Value == [Int] {
    init(_ pb: PBIntArrayIndexValue) throws {
        value = try [Int](pb.value)
        index = max(Int(pb.index), 0)
    }
    var pb: PBIntArrayIndexValue {
        .with {
            $0.value = value.pb
            $0.index = Int64(index)
        }
    }
}
extension Array where Element == IndexValue<Int> {
    init(_ pb: PBIntIndexValueArray) throws {
        self = try pb.value.map { try IndexValue<Int>($0) }
    }
    var pb: PBIntIndexValueArray {
        .with { $0.value = map { $0.pb } }
    }
}
extension Array where Element == IndexValue<[Int]> {
    init(_ pb: PBIntArrayIndexValueArray) throws {
        self = try pb.value.map { try IndexValue<[Int]>($0) }
    }
    var pb: PBIntArrayIndexValueArray {
        .with { $0.value = map { $0.pb } }
    }
}
extension IndexValue where Value == Line {
    init(_ pb: PBLineIndexValue) throws {
        value = try Line(pb.value)
        index = max(Int(pb.index), 0)
    }
    var pb: PBLineIndexValue {
        .with {
            $0.value = value.pb
            $0.index = Int64(index)
        }
    }
}
extension IndexValue where Value == [IndexValue<Line>] {
    init(_ pb: PBLineIndexValueArrayIndexValue) throws {
        value = try pb.value.map { try IndexValue<Line>($0) }
        index = max(Int(pb.index), 0)
    }
    var pb: PBLineIndexValueArrayIndexValue {
        .with {
            $0.value = value.map { $0.pb }
            $0.index = Int64(index)
        }
    }
}
extension IndexValue where Value == Plane {
    init(_ pb: PBPlaneIndexValue) throws {
        value = try Plane(pb.value)
        index = max(Int(pb.index), 0)
    }
    var pb: PBPlaneIndexValue {
        .with {
            $0.value = value.pb
            $0.index = Int64(index)
        }
    }
}
extension IndexValue where Value == [IndexValue<Plane>] {
    init(_ pb: PBPlaneIndexValueArrayIndexValue) throws {
        value = try pb.value.map { try IndexValue<Plane>($0) }
        index = max(Int(pb.index), 0)
    }
    var pb: PBPlaneIndexValueArrayIndexValue {
        .with {
            $0.value = value.map { $0.pb }
            $0.index = Int64(index)
        }
    }
}
extension IndexValue where Value == InterOption {
    init(_ pb: PBInterOptionIndexValue) throws {
        value = try InterOption(pb.value)
        index = max(Int(pb.index), 0)
    }
    var pb: PBInterOptionIndexValue {
        .with {
            $0.value = value.pb
            $0.index = Int64(index)
        }
    }
}
extension IndexValue where Value == [IndexValue<InterOption>] {
    init(_ pb: PBInterOptionIndexValueArrayIndexValue) throws {
        value = try pb.value.map { try IndexValue<InterOption>($0) }
        index = max(Int(pb.index), 0)
    }
    var pb: PBInterOptionIndexValueArrayIndexValue {
        .with {
            $0.value = value.map { $0.pb }
            $0.index = Int64(index)
        }
    }
}
extension IndexValue where Value == Text {
    init(_ pb: PBTextIndexValue) throws {
        value = try Text(pb.value)
        index = max(Int(pb.index), 0)
    }
    var pb: PBTextIndexValue {
        .with {
            $0.value = value.pb
            $0.index = Int64(index)
        }
    }
}
extension IndexValue where Value == Note {
    init(_ pb: PBNoteIndexValue) throws {
        value = (try? .init(pb.value)) ?? .init()
        index = max(Int(pb.index), 0)
    }
    var pb: PBNoteIndexValue {
        .with {
            $0.value = value.pb
            $0.index = Int64(index)
        }
    }
}
extension IndexValue where Value == Content {
    init(_ pb: PBContentIndexValue) throws {
        value = (try? .init(pb.value)) ?? .init()
        index = max(Int(pb.index), 0)
    }
    var pb: PBContentIndexValue {
        .with {
            $0.value = value.pb
            $0.index = Int64(index)
        }
    }
}
extension IndexValue where Value == Border {
    init(_ pb: PBBorderIndexValue) throws {
        value = try Border(pb.value)
        index = max(Int(pb.index), 0)
    }
    var pb: PBBorderIndexValue {
        .with {
            $0.value = value.pb
            $0.index = Int64(index)
        }
    }
}
extension IndexValue where Value == TextValue {
    init(_ pb: PBTextValueIndexValue) throws {
        value = try TextValue(pb.value)
        index = max(Int(pb.index), 0)
    }
    var pb: PBTextValueIndexValue {
        .with {
            $0.value = value.pb
            $0.index = Int64(index)
        }
    }
}
extension IndexValue where Value == Keyframe {
    init(_ pb: PBKeyframeIndexValue) throws {
        value = try Keyframe(pb.value)
        index = max(Int(pb.index), 0)
    }
    var pb: PBKeyframeIndexValue {
        .with {
            $0.value = value.pb
            $0.index = Int64(index)
        }
    }
}
extension IndexValue where Value == KeyframeOption {
    init(_ pb: PBKeyframeOptionIndexValue) throws {
        value = try KeyframeOption(pb.value)
        index = max(Int(pb.index), 0)
    }
    var pb: PBKeyframeOptionIndexValue {
        .with {
            $0.value = value.pb
            $0.index = Int64(index)
        }
    }
}
extension Array where Element == IndexValue<Line> {
    init(_ pb: PBLineIndexValueArray) throws {
        self = try pb.value.map { try IndexValue<Line>($0) }
    }
    var pb: PBLineIndexValueArray {
        .with { $0.value = map { $0.pb } }
    }
}
extension Array where Element == IndexValue<Plane> {
    init(_ pb: PBPlaneIndexValueArray) throws {
        self = try pb.value.map { try IndexValue<Plane>($0) }
    }
    var pb: PBPlaneIndexValueArray {
        .with { $0.value = map { $0.pb } }
    }
}
extension Array where Element == IndexValue<InterOption> {
    init(_ pb: PBInterOptionIndexValueArray) throws {
        self = try pb.value.map { try IndexValue<InterOption>($0) }
    }
    var pb: PBInterOptionIndexValueArray {
        .with { $0.value = map { $0.pb } }
    }
}
extension Array where Element == IndexValue<Text> {
    init(_ pb: PBTextIndexValueArray) throws {
        self = try pb.value.map { try IndexValue<Text>($0) }
    }
    var pb: PBTextIndexValueArray {
        .with { $0.value = map { $0.pb } }
    }
}
extension Array where Element == IndexValue<Note> {
    init(_ pb: PBNoteIndexValueArray) throws {
        self = try pb.value.map { try IndexValue<Note>($0) }
    }
    var pb: PBNoteIndexValueArray {
        .with { $0.value = map { $0.pb } }
    }
}
extension Array where Element == IndexValue<Content> {
    init(_ pb: PBContentIndexValueArray) throws {
        self = try pb.value.map { try IndexValue<Content>($0) }
    }
    var pb: PBContentIndexValueArray {
        .with { $0.value = map { $0.pb } }
    }
}
extension Array where Element == IndexValue<Border> {
    init(_ pb: PBBorderIndexValueArray) throws {
        self = try pb.value.map { try IndexValue<Border>($0) }
    }
    var pb: PBBorderIndexValueArray {
        .with { $0.value = map { $0.pb } }
    }
}
extension Array where Element == IndexValue<Keyframe> {
    init(_ pb: PBKeyframeIndexValueArray) throws {
        self = try pb.value.map { try IndexValue<Keyframe>($0) }
    }
    var pb: PBKeyframeIndexValueArray {
        .with { $0.value = map { $0.pb } }
    }
}
extension Array where Element == IndexValue<KeyframeOption> {
    init(_ pb: PBKeyframeOptionIndexValueArray) throws {
        self = try pb.value.map { try IndexValue<KeyframeOption>($0) }
    }
    var pb: PBKeyframeOptionIndexValueArray {
        .with { $0.value = map { $0.pb } }
    }
}
extension Array where Element == IndexValue<[IndexValue<Line>]> {
    init(_ pb: PBLineIndexValueArrayIndexValueArray) throws {
        self = try pb.value.map { try IndexValue<[IndexValue<Line>]>($0) }
    }
    var pb: PBLineIndexValueArrayIndexValueArray {
        .with { $0.value = map { $0.pb } }
    }
}
extension Array where Element == IndexValue<[IndexValue<Plane>]> {
    init(_ pb: PBPlaneIndexValueArrayIndexValueArray) throws {
        self = try pb.value.map { try IndexValue<[IndexValue<Plane>]>($0) }
    }
    var pb: PBPlaneIndexValueArrayIndexValueArray {
        .with { $0.value = map { $0.pb } }
    }
}
extension Array where Element == IndexValue<[IndexValue<InterOption>]> {
    init(_ pb: PBInterOptionIndexValueArrayIndexValueArray) throws {
        self = try pb.value.map { try IndexValue<[IndexValue<InterOption>]>($0) }
    }
    var pb: PBInterOptionIndexValueArrayIndexValueArray {
        .with { $0.value = map { $0.pb } }
    }
}

enum SheetUndoItem {
    case appendLine(_ line: Line)
    case appendLines(_ lines: [Line])
    case appendPlanes(_ planes: [Plane])
    case removeLastLines(count: Int)
    case removeLastPlanes(count: Int)
    case insertLines(_ lineIndexValues: [IndexValue<Line>])
    case insertPlanes(_ planeIndexValues: [IndexValue<Plane>])
    case replaceLines(_ lineIndexValue: [IndexValue<Line>])
    case replacePlanes(_ planeIndexValue: [IndexValue<Plane>])
    case removeLines(lineIndexes: [Int])
    case removePlanes(planeIndexes: [Int])
    case setPlaneValue(_ planeValue: PlaneValue)
    case changeToDraft(isReverse: Bool)
    case setPicture(_ picture: Picture)
    case insertDraftLines(_ lineIndexValues: [IndexValue<Line>])
    case insertDraftPlanes(_ planeIndexValues: [IndexValue<Plane>])
    case removeDraftLines(lineIndexes: [Int])
    case removeDraftPlanes(planeIndexes: [Int])
    case setDraftPicture(_ picture: Picture)
    case insertTexts(_ textIndexValues: [IndexValue<Text>])
    case replaceTexts(_ textIndexValue: [IndexValue<Text>])
    case removeTexts(textIndexes: [Int])
    case replaceString(_ textIndexValue: IndexValue<TextValue>)
    case changedColors(_ colorUndoValue: ColorValue)
    case insertBorders(_ borderIndexValues: [IndexValue<Border>])
    case removeBorders(borderIndexes: [Int])
    case setRootKeyframeIndex(rootKeyframeIndex: Int)
    case insertKeyframes(_ pivs: [IndexValue<Keyframe>])
    case removeKeyframes(keyframeIndexes: [Int])
    case setKeyframeOptions(_ options: [IndexValue<KeyframeOption>])
    case insertKeyLines(_ kvs: [IndexValue<[IndexValue<Line>]>])
    case replaceKeyLines(_ kvs: [IndexValue<[IndexValue<Line>]>])
    case removeKeyLines(_ indexes: [IndexValue<[Int]>])
    case insertKeyPlanes(_ kvs: [IndexValue<[IndexValue<Plane>]>])
    case replaceKeyPlanes(_ kvs: [IndexValue<[IndexValue<Plane>]>])
    case removeKeyPlanes(_ indexes: [IndexValue<[Int]>])
    case insertDraftKeyLines(_ kvs: [IndexValue<[IndexValue<Line>]>])
    case removeDraftKeyLines(_ indexes: [IndexValue<[Int]>])
    case insertDraftKeyPlanes(_ kvs: [IndexValue<[IndexValue<Plane>]>])
    case removeDraftKeyPlanes(_ indexes: [IndexValue<[Int]>])
    case setLineIDs(_ idvs: [IndexValue<[IndexValue<InterOption>]>])
    case setAnimationOption(_ option: AnimationOption)
    case insertNotes(_ noteIndexValues: [IndexValue<Note>])
    case replaceNotes(_ noteIndexValue: [IndexValue<Note>])
    case removeNotes(noteIndexes: [Int])
    case insertDraftNotes(_ noteIndexValues: [IndexValue<Note>])
    case removeDraftNotes(noteIndexes: [Int])
    case insertContents(_ contentIndexValues: [IndexValue<Content>])
    case replaceContents(_ contentIndexValue: [IndexValue<Content>])
    case removeContents(contentIndexes: [Int])
    case setScoreOption(_ option: ScoreOption)
    case setSheetOption(_ option: SheetOption)
    case setSelection(_ selection: SheetSelection)
}
extension SheetUndoItem: UndoItem {
    var type: UndoItemType {
        switch self {
        case .appendLine: .reversible
        case .appendLines: .reversible
        case .appendPlanes: .reversible
        case .removeLastLines: .unreversible
        case .removeLastPlanes: .unreversible
        case .insertLines: .reversible
        case .insertPlanes: .reversible
        case .replaceLines: .lazyReversible
        case .replacePlanes: .lazyReversible
        case .removeLines: .unreversible
        case .removePlanes: .unreversible
        case .setPlaneValue: .lazyReversible
        case .changeToDraft: .reversible
        case .setPicture: .lazyReversible
        case .insertDraftLines: .reversible
        case .insertDraftPlanes: .reversible
        case .removeDraftLines: .unreversible
        case .removeDraftPlanes: .unreversible
        case .setDraftPicture: .lazyReversible
        case .insertTexts: .reversible
        case .replaceTexts: .lazyReversible
        case .removeTexts: .unreversible
        case .replaceString: .lazyReversible
        case .changedColors: .lazyReversible
        case .insertBorders: .reversible
        case .removeBorders: .unreversible
        case .setRootKeyframeIndex: .lazyReversible
        case .insertKeyframes: .reversible
        case .removeKeyframes: .unreversible
        case .setKeyframeOptions: .lazyReversible
        case .insertKeyLines: .reversible
        case .replaceKeyLines: .lazyReversible
        case .removeKeyLines: .unreversible
        case .insertKeyPlanes: .reversible
        case .replaceKeyPlanes: .lazyReversible
        case .removeKeyPlanes: .unreversible
        case .insertDraftKeyLines: .reversible
        case .removeDraftKeyLines: .unreversible
        case .insertDraftKeyPlanes: .reversible
        case .removeDraftKeyPlanes: .unreversible
        case .setLineIDs: .lazyReversible
        case .setAnimationOption: .lazyReversible
        case .insertNotes: .reversible
        case .replaceNotes: .lazyReversible
        case .removeNotes: .unreversible
        case .insertDraftNotes: .reversible
        case .removeDraftNotes: .unreversible
        case .insertContents: .reversible
        case .replaceContents: .lazyReversible
        case .removeContents: .unreversible
        case .setScoreOption: .lazyReversible
        case .setSheetOption: .lazyReversible
        case .setSelection: .lazyReversible
        }
    }
    func reversed() -> SheetUndoItem? {
        switch self {
        case .appendLine:
             .removeLastLines(count: 1)
        case .appendLines(let lines):
             .removeLastLines(count: lines.count)
        case .appendPlanes(let planes):
             .removeLastPlanes(count: planes.count)
        case .removeLastLines:
             nil
        case .removeLastPlanes:
             nil
        case .insertLines(let livs):
             .removeLines(lineIndexes: livs.map { $0.index })
        case .insertPlanes(let pivs):
             .removePlanes(planeIndexes: pivs.map { $0.index })
        case .replaceLines:
             self
        case .replacePlanes:
             self
        case .removeLines:
             nil
        case .removePlanes:
             nil
        case .setPlaneValue:
             self
        case .changeToDraft(let isReverse):
             .changeToDraft(isReverse: !isReverse)
        case .setPicture(_):
             self
        case .insertDraftLines(let livs):
             .removeDraftLines(lineIndexes: livs.map { $0.index })
        case .insertDraftPlanes(let pivs):
             .removeDraftPlanes(planeIndexes: pivs.map { $0.index })
        case .removeDraftLines:
             nil
        case .removeDraftPlanes:
             nil
        case .setDraftPicture(_):
             self
        case .insertTexts(let tivs):
             .removeTexts(textIndexes: tivs.map { $0.index })
        case .replaceTexts:
             self
        case .removeTexts:
             nil
        case .replaceString(_):
             self
        case .changedColors(_):
             self
        case .insertBorders(let bivs):
             .removeBorders(borderIndexes: bivs.map { $0.index })
        case .removeBorders:
             nil
        case .setRootKeyframeIndex:
             self
        case .insertKeyframes(let pivs):
             .removeKeyframes(keyframeIndexes: pivs.map { $0.index })
        case .removeKeyframes:
             nil
        case .setKeyframeOptions:
             self
        case .insertKeyLines(let kivs):
             .removeKeyLines(kivs.map { IndexValue(value: $0.value.map { $0.index },
                                                         index: $0.index) })
        case .replaceKeyLines:
             self
        case .removeKeyLines:
             nil
        case .insertKeyPlanes(let kivs):
             .removeKeyPlanes(kivs.map { IndexValue(value: $0.value.map { $0.index },
                                                         index: $0.index) })
        case .replaceKeyPlanes:
             self
        case .removeKeyPlanes:
             nil
        case .insertDraftKeyLines(let kivs):
             .removeDraftKeyLines(kivs.map { IndexValue(value: $0.value.map { $0.index },
                                                         index: $0.index) })
        case .removeDraftKeyLines:
             nil
        case .insertDraftKeyPlanes(let kivs):
             .removeDraftKeyPlanes(kivs.map { IndexValue(value: $0.value.map { $0.index },
                                                         index: $0.index) })
        case .removeDraftKeyPlanes:
             nil
        case .setLineIDs:
             self
        case .setAnimationOption:
             self
        
        case .insertNotes(let nivs):
             .removeNotes(noteIndexes: nivs.map { $0.index })
        case .replaceNotes:
             self
        case .removeNotes:
             nil
            
        case .insertDraftNotes(let nivs):
             .removeDraftNotes(noteIndexes: nivs.map { $0.index })
        case .removeDraftNotes:
             nil
            
        case .insertContents(let civs):
             .removeContents(contentIndexes: civs.map { $0.index })
        case .replaceContents:
             self
        case .removeContents:
             nil
            
        case .setScoreOption:
             self
            
        case .setSheetOption:
             self
            
        case .setSelection:
             self
        }
    }
}
extension SheetUndoItem: Protobuf {
    init(_ pb: PBSheetUndoItem) throws {
        guard let value = pb.value else {
            throw ProtobufError()
        }
        switch value {
        case .appendLine(let line):
            self = .appendLine(try Line(line))
        case .appendLines(let lines):
            self = .appendLines(try [Line](lines))
        case .appendPlanes(let planes):
            self = .appendPlanes(try [Plane](planes))
        case .removeLastLines(let lineCount):
            self = .removeLastLines(count: Int(lineCount))
        case .removeLastPlanes(let planesCount):
            self = .removeLastPlanes(count: Int(planesCount))
        case .insertLines(let lineIndexValues):
            self = .insertLines(try [IndexValue<Line>](lineIndexValues))
        case .insertPlanes(let planeIndexValues):
            self = .insertPlanes(try [IndexValue<Plane>](planeIndexValues))
        case .replaceLines(let lines):
            self = .replaceLines(try [IndexValue<Line>](lines))
        case .replacePlanes(let planes):
            self = .replacePlanes(try [IndexValue<Plane>](planes))
        case .removeLines(let lineIndexes):
            self = .removeLines(lineIndexes: try [Int](lineIndexes))
        case .removePlanes(let planeIndexes):
            self = .removePlanes(planeIndexes: try [Int](planeIndexes))
        case .setPlaneValue(let planeValue):
            self = .setPlaneValue(try PlaneValue(planeValue))
        case .changeToDraft(let isReverse):
            self = .changeToDraft(isReverse: isReverse)
        case .setPicture(let picture):
            self = .setPicture(try Picture(picture))
        case .insertDraftLines(let lineIndexValues):
            self = .insertDraftLines(try [IndexValue<Line>](lineIndexValues))
        case .insertDraftPlanes(let planeIndexValues):
            self = .insertDraftPlanes(try [IndexValue<Plane>](planeIndexValues))
        case .removeDraftLines(let lineIndexes):
            self = .removeDraftLines(lineIndexes: try [Int](lineIndexes))
        case .removeDraftPlanes(let planeIndexes):
            self = .removeDraftPlanes(planeIndexes: try [Int](planeIndexes))
        case .setDraftPicture(let picture):
            self = .setDraftPicture(try Picture(picture))
        case .insertTexts(let texts):
            self = .insertTexts(try [IndexValue<Text>](texts))
        case .replaceTexts(let texts):
            self = .replaceTexts(try [IndexValue<Text>](texts))
        case .removeTexts(let textIndexes):
            self = .removeTexts(textIndexes: try [Int](textIndexes))
        case .replaceString(let textValue):
            self = .replaceString(try IndexValue<TextValue>(textValue))
        case .changedColors(let colorUndoValue):
            self = .changedColors(try ColorValue(colorUndoValue))
        case .insertBorders(let borders):
            self = .insertBorders(try [IndexValue<Border>](borders))
        case .removeBorders(let borderIndexes):
            self = .removeBorders(borderIndexes: try [Int](borderIndexes))
        case .setRootKeyframeIndex(let index):
            self = .setRootKeyframeIndex(rootKeyframeIndex: Int(index))
        case .insertKeyframes(let pivs):
            self = .insertKeyframes(try [IndexValue<Keyframe>](pivs))
        case .removeKeyframes(let keyframeIndexes):
            self = .removeKeyframes(keyframeIndexes: try [Int](keyframeIndexes))
        case .setKeyframeOptions(let option):
            self = .setKeyframeOptions(try [IndexValue<KeyframeOption>](option))
        case .insertKeyLines(let kvs):
            self = .insertKeyLines(try [IndexValue<[IndexValue<Line>]>](kvs))
        case .replaceKeyLines(let kvs):
            self = .replaceKeyLines(try [IndexValue<[IndexValue<Line>]>](kvs))
        case .removeKeyLines(let iivs):
            self = .removeKeyLines(try [IndexValue<[Int]>](iivs))
        case .insertKeyPlanes(let kvs):
            self = .insertKeyPlanes(try [IndexValue<[IndexValue<Plane>]>](kvs))
        case .replaceKeyPlanes(let kvs):
            self = .replaceKeyPlanes(try [IndexValue<[IndexValue<Plane>]>](kvs))
        case .removeKeyPlanes(let iivs):
            self = .removeKeyPlanes(try [IndexValue<[Int]>](iivs))
        case .insertDraftKeyLines(let kvs):
            self = .insertDraftKeyLines(try [IndexValue<[IndexValue<Line>]>](kvs))
        case .removeDraftKeyLines(let iivs):
            self = .removeDraftKeyLines(try [IndexValue<[Int]>](iivs))
        case .insertDraftKeyPlanes(let kvs):
            self = .insertDraftKeyPlanes(try [IndexValue<[IndexValue<Plane>]>](kvs))
        case .removeDraftKeyPlanes(let iivs):
            self = .removeDraftKeyPlanes(try [IndexValue<[Int]>](iivs))
        case .setLineIds(let idvs):
            self = .setLineIDs(try [IndexValue<[IndexValue<InterOption>]>](idvs))
        case .setAnimationOption(let option):
            self = .setAnimationOption(try AnimationOption(option))
        case .insertNotes(let notes):
            self = .insertNotes(try [IndexValue<Note>](notes))
        case .replaceNotes(let notes):
            self = .replaceNotes(try [IndexValue<Note>](notes))
        case .removeNotes(let noteIndexes):
            self = .removeNotes(noteIndexes: try [Int](noteIndexes))
        case .insertDraftNotes(let noteIndexValues):
            self = .insertDraftNotes(try [IndexValue<Note>](noteIndexValues))
        case .removeDraftNotes(let noteIndexes):
            self = .removeDraftNotes(noteIndexes: try [Int](noteIndexes))
        case .insertContents(let contents):
            self = .insertContents(try [IndexValue<Content>](contents))
        case .replaceContents(let contents):
            self = .replaceContents(try [IndexValue<Content>](contents))
        case .removeContents(let contentIndexes):
            self = .removeContents(contentIndexes: try [Int](contentIndexes))
        case .setScoreOption(let option):
            self = .setScoreOption(try ScoreOption(option))
        case .setSheetOption(let option):
            self = .setSheetOption(try SheetOption(option))
        case .setSelection(let selection):
            self = .setSelection(try .init(selection))
        }
    }
    var pb: PBSheetUndoItem {
        .with {
            switch self {
            case .appendLine(let line):
                $0.value = .appendLine(line.pb)
            case .appendLines(let lines):
                $0.value = .appendLines(lines.pb)
            case .appendPlanes(let planes):
                $0.value = .appendPlanes(planes.pb)
            case .removeLastLines(let lineCount):
                $0.value = .removeLastLines(Int64(lineCount))
            case .removeLastPlanes(let planesCount):
                $0.value = .removeLastPlanes(Int64(planesCount))
            case .insertLines(let lineIndexValues):
                $0.value = .insertLines(lineIndexValues.pb)
            case .insertPlanes(let planeIndexValues):
                $0.value = .insertPlanes(planeIndexValues.pb)
            case .replaceLines(let livs):
                $0.value = .replaceLines(livs.pb)
            case .replacePlanes(let pivs):
                $0.value = .replacePlanes(pivs.pb)
            case .removeLines(let lineIndexes):
                $0.value = .removeLines(lineIndexes.pb)
            case .removePlanes(let planeIndexes):
                $0.value = .removePlanes(planeIndexes.pb)
            case .setPlaneValue(let planeValue):
                $0.value = .setPlaneValue(planeValue.pb)
            case .changeToDraft(let isReverse):
                $0.value = .changeToDraft(isReverse)
            case .setPicture(let picture):
                $0.value = .setPicture(picture.pb)
            case .insertDraftLines(let lineIndexValues):
                $0.value = .insertDraftLines(lineIndexValues.pb)
            case .insertDraftPlanes(let planeIndexValues):
                $0.value = .insertDraftPlanes(planeIndexValues.pb)
            case .removeDraftLines(let lineIndexes):
                $0.value = .removeDraftLines(lineIndexes.pb)
            case .removeDraftPlanes(let planeIndexes):
                $0.value = .removeDraftPlanes(planeIndexes.pb)
            case .setDraftPicture(let picture):
                $0.value = .setDraftPicture(picture.pb)
            case .insertTexts(let texts):
                $0.value = .insertTexts(texts.pb)
            case .replaceTexts(let tivs):
                $0.value = .replaceTexts(tivs.pb)
            case .removeTexts(let textIndexes):
                $0.value = .removeTexts(textIndexes.pb)
            case .replaceString(let textValue):
                $0.value = .replaceString(textValue.pb)
            case .changedColors(let colorUndoValue):
                $0.value = .changedColors(colorUndoValue.pb)
            case .insertBorders(let borders):
                $0.value = .insertBorders(borders.pb)
            case .removeBorders(let borderIndexes):
                $0.value = .removeBorders(borderIndexes.pb)
            case .setRootKeyframeIndex(let keyframeIndex):
                $0.value = .setRootKeyframeIndex(Int64(keyframeIndex))
            case .insertKeyframes(let pivs):
                $0.value = .insertKeyframes(pivs.pb)
            case .removeKeyframes(let indexes):
                $0.value = .removeKeyframes(indexes.pb)
            case .setKeyframeOptions(let option):
                $0.value = .setKeyframeOptions(option.pb)
            case .insertKeyLines(let kvs):
                $0.value = .insertKeyLines(kvs.pb)
            case .replaceKeyLines(let kvs):
                $0.value = .replaceKeyLines(kvs.pb)
            case .removeKeyLines(let iivs):
                $0.value = .removeKeyLines(iivs.pb)
            case .insertKeyPlanes(let kvs):
                $0.value = .insertKeyPlanes(kvs.pb)
            case .replaceKeyPlanes(let kvs):
                $0.value = .replaceKeyPlanes(kvs.pb)
            case .removeKeyPlanes(let iivs):
                $0.value = .removeKeyPlanes(iivs.pb)
            case .insertDraftKeyLines(let kvs):
                $0.value = .insertDraftKeyLines(kvs.pb)
            case .removeDraftKeyLines(let iivs):
                $0.value = .removeDraftKeyLines(iivs.pb)
            case .insertDraftKeyPlanes(let kvs):
                $0.value = .insertDraftKeyPlanes(kvs.pb)
            case .removeDraftKeyPlanes(let iivs):
                $0.value = .removeDraftKeyPlanes(iivs.pb)
            case .setLineIDs(let idvs):
                $0.value = .setLineIds(idvs.pb)
            case .setAnimationOption(let option):
                $0.value = .setAnimationOption(option.pb)
            case .insertNotes(let nivs):
                $0.value = .insertNotes(nivs.pb)
            case .replaceNotes(let nivs):
                $0.value = .replaceNotes(nivs.pb)
            case .removeNotes(let nis):
                $0.value = .removeNotes(nis.pb)
            case .insertDraftNotes(let noteIndexValues):
                $0.value = .insertDraftNotes(noteIndexValues.pb)
            case .removeDraftNotes(let noteIndexes):
                $0.value = .removeDraftNotes(noteIndexes.pb)
            case .insertContents(let civs):
                $0.value = .insertContents(civs.pb)
            case .replaceContents(let civs):
                $0.value = .replaceContents(civs.pb)
            case .removeContents(let cis):
                $0.value = .removeContents(cis.pb)
            case .setScoreOption(let option):
                $0.value = .setScoreOption(option.pb)
            case .setSheetOption(let option):
                $0.value = .setSheetOption(option.pb)
            case .setSelection(let selection):
                $0.value = .setSelection(selection.pb)
            }
        }
    }
}
extension SheetUndoItem: Codable {
    private enum CodingTypeKey: String, Codable {
        case appendLine = "0"
        case appendLines = "1"
        case appendPlanes = "2"
        case removeLastLines = "3"
        case removeLastPlanes = "4"
        case insertLines = "5"
        case insertPlanes = "6"
        case replaceLines = "53"
        case replacePlanes = "54"
        case removeLines = "7"
        case removePlanes = "8"
        case setPlaneValue = "9"
        case changeToDraft = "10"
        case setPicture = "11"
        case insertDraftLines = "12"
        case insertDraftPlanes = "13"
        case removeDraftLines = "14"
        case removeDraftPlanes = "15"
        case setDraftPicture = "16"
        case insertTexts = "17"
        case replaceTexts = "55"
        case removeTexts = "18"
        case replaceString = "19"
        case changedColors = "20"
        case insertBorders = "21"
        case removeBorders = "22"
        case setRootKeyframeIndex = "23"
        case insertKeyframes = "24"
        case removeKeyframes = "25"
        case setKeyframeOptions = "26"
        case insertKeyLines = "27"
        case replaceKeyLines = "28"
        case removeKeyLines = "29"
        case insertKeyPlanes = "33"
        case replaceKeyPlanes = "40"
        case removeKeyPlanes = "34"
        case insertDraftKeyLines = "35"
        case removeDraftKeyLines = "36"
        case insertDraftKeyPlanes = "37"
        case removeDraftKeyPlanes = "38"
        case setLineIDs = "30"
        case setAnimationOption = "39"
        case insertNotes = "41"
        case replaceNotes = "42"
        case removeNotes = "43"
        case insertDraftNotes = "49"
        case removeDraftNotes = "50"
        case insertContents = "45"
        case replaceContents = "46"
        case removeContents = "47"
        case setScoreOption = "48"
        case setSheetOption = "51"
        case setSelection = "52"
    }
    init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let key = try container.decode(CodingTypeKey.self)
        switch key {
        case .appendLine:
            self = .appendLine(try container.decode(Line.self))
        case .appendLines:
            self = .appendLines(try container.decode([Line].self))
        case .appendPlanes:
            self = .appendPlanes(try container.decode([Plane].self))
        case .removeLastLines:
            self = .removeLastLines(count: try container.decode(Int.self))
        case .removeLastPlanes:
            self = .removeLastPlanes(count: try container.decode(Int.self))
        case .insertLines:
            self = .insertLines(try container.decode([IndexValue<Line>].self))
        case .insertPlanes:
            self = .insertPlanes(try container.decode([IndexValue<Plane>].self))
        case .replaceLines:
            self = .replaceLines(try container.decode([IndexValue<Line>].self))
        case .replacePlanes:
            self = .replacePlanes(try container.decode([IndexValue<Plane>].self))
        case .removeLines:
            self = .removeLines(lineIndexes: try container.decode([Int].self))
        case .removePlanes:
            self = .removePlanes(planeIndexes: try container.decode([Int].self))
        case .setPlaneValue:
            self = .setPlaneValue(try container.decode(PlaneValue.self))
        case .changeToDraft:
            self = .changeToDraft(isReverse: try container.decode(Bool.self))
        case .setPicture:
            self = .setPicture(try container.decode(Picture.self))
        case .insertDraftLines:
            self = .insertDraftLines(try container.decode([IndexValue<Line>].self))
        case .insertDraftPlanes:
            self = .insertDraftPlanes(try container.decode([IndexValue<Plane>].self))
        case .removeDraftLines:
            self = .removeDraftLines(lineIndexes: try container.decode([Int].self))
        case .removeDraftPlanes:
            self = .removeDraftPlanes(planeIndexes: try container.decode([Int].self))
        case .setDraftPicture:
            self = .setDraftPicture(try container.decode(Picture.self))
        case .insertTexts:
            self = .insertTexts(try container.decode([IndexValue<Text>].self))
        case .replaceTexts:
            self = .replaceTexts(try container.decode([IndexValue<Text>].self))
        case .removeTexts:
            self = .removeTexts(textIndexes: try container.decode([Int].self))
        case .replaceString:
            self = .replaceString(try container.decode(IndexValue<TextValue>.self))
        case .changedColors:
            self = .changedColors(try container.decode(ColorValue.self))
        case .insertBorders:
            self = .insertBorders(try container.decode([IndexValue<Border>].self))
        case .removeBorders:
            self = .removeBorders(borderIndexes: try container.decode([Int].self))
        case .setRootKeyframeIndex:
            self = .setRootKeyframeIndex(rootKeyframeIndex: try container.decode(Int.self))
        case .insertKeyframes:
            self = .insertKeyframes(try container.decode([IndexValue<Keyframe>].self))
        case .removeKeyframes:
            self = .removeKeyframes(keyframeIndexes: try container.decode([Int].self))
        case .setKeyframeOptions:
            self = .setKeyframeOptions(try container.decode([IndexValue<KeyframeOption>].self))
        case .insertKeyLines:
            self = .insertKeyLines(try container.decode([IndexValue<[IndexValue<Line>]>].self))
        case .replaceKeyLines:
            self = .replaceKeyLines(try container.decode([IndexValue<[IndexValue<Line>]>].self))
        case .removeKeyLines:
            self = .removeKeyLines(try container.decode([IndexValue<[Int]>].self))
        case .insertKeyPlanes:
            self = .insertKeyPlanes(try container.decode([IndexValue<[IndexValue<Plane>]>].self))
        case .replaceKeyPlanes:
            self = .replaceKeyPlanes(try container.decode([IndexValue<[IndexValue<Plane>]>].self))
        case .removeKeyPlanes:
            self = .removeKeyPlanes(try container.decode([IndexValue<[Int]>].self))
        case .insertDraftKeyLines:
            self = .insertDraftKeyLines(try container.decode([IndexValue<[IndexValue<Line>]>].self))
        case .removeDraftKeyLines:
            self = .removeDraftKeyLines(try container.decode([IndexValue<[Int]>].self))
        case .insertDraftKeyPlanes:
            self = .insertDraftKeyPlanes(try container.decode([IndexValue<[IndexValue<Plane>]>].self))
        case .removeDraftKeyPlanes:
            self = .removeDraftKeyPlanes(try container.decode([IndexValue<[Int]>].self))
        case .setLineIDs:
            self = .setLineIDs(try container.decode([IndexValue<[IndexValue<InterOption>]>].self))
        case .setAnimationOption:
            self = .setAnimationOption(try container.decode(AnimationOption.self))
        case .insertNotes:
            self = .insertNotes(try container.decode([IndexValue<Note>].self))
        case .replaceNotes:
            self = .replaceNotes(try container.decode([IndexValue<Note>].self))
        case .removeNotes:
            self = .removeNotes(noteIndexes: try container.decode([Int].self))
        case .insertDraftNotes:
            self = .insertDraftNotes(try container.decode([IndexValue<Note>].self))
        case .removeDraftNotes:
            self = .removeDraftNotes(noteIndexes: try container.decode([Int].self))
        case .insertContents:
            self = .insertContents(try container.decode([IndexValue<Content>].self))
        case .replaceContents:
            self = .replaceContents(try container.decode([IndexValue<Content>].self))
        case .removeContents:
            self = .removeContents(contentIndexes: try container.decode([Int].self))
        case .setScoreOption:
            self = .setScoreOption(try container.decode(ScoreOption.self))
        case .setSheetOption:
            self = .setSheetOption(try container.decode(SheetOption.self))
        case .setSelection:
            self = .setSelection(try container.decode(SheetSelection.self))
        }
    }
    func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        switch self {
        case .appendLine(let line):
            try container.encode(CodingTypeKey.appendLine)
            try container.encode(line)
        case .appendLines(let lines):
            try container.encode(CodingTypeKey.appendLines)
            try container.encode(lines)
        case .appendPlanes(let planes):
            try container.encode(CodingTypeKey.appendPlanes)
            try container.encode(planes)
        case .removeLastLines(let lineCount):
            try container.encode(CodingTypeKey.removeLastLines)
            try container.encode(lineCount)
        case .removeLastPlanes(let planesCount):
            try container.encode(CodingTypeKey.removeLastPlanes)
            try container.encode(planesCount)
        case .insertLines(let lineIndexValues):
            try container.encode(CodingTypeKey.insertLines)
            try container.encode(lineIndexValues)
        case .insertPlanes(let planeIndexValues):
            try container.encode(CodingTypeKey.insertPlanes)
            try container.encode(planeIndexValues)
        case .replaceLines(let vs):
            try container.encode(CodingTypeKey.replaceLines)
            try container.encode(vs)
        case .replacePlanes(let vs):
            try container.encode(CodingTypeKey.replacePlanes)
            try container.encode(vs)
        case .removeLines(let lineIndexes):
            try container.encode(CodingTypeKey.removeLines)
            try container.encode(lineIndexes)
        case .removePlanes(let planeIndexes):
            try container.encode(CodingTypeKey.removePlanes)
            try container.encode(planeIndexes)
        case .setPlaneValue(let planeValue):
            try container.encode(CodingTypeKey.setPlaneValue)
            try container.encode(planeValue)
        case .changeToDraft(let isReverse):
            try container.encode(CodingTypeKey.changeToDraft)
            try container.encode(isReverse)
        case .setPicture(let picture):
            try container.encode(CodingTypeKey.setPicture)
            try container.encode(picture)
        case .insertDraftLines(let lineIndexValues):
            try container.encode(CodingTypeKey.insertDraftLines)
            try container.encode(lineIndexValues)
        case .insertDraftPlanes(let planeIndexValues):
            try container.encode(CodingTypeKey.insertDraftPlanes)
            try container.encode(planeIndexValues)
        case .removeDraftLines(let lineIndexes):
            try container.encode(CodingTypeKey.removeDraftLines)
            try container.encode(lineIndexes)
        case .removeDraftPlanes(let planeIndexes):
            try container.encode(CodingTypeKey.removeDraftPlanes)
            try container.encode(planeIndexes)
        case .setDraftPicture(let picture):
            try container.encode(CodingTypeKey.setDraftPicture)
            try container.encode(picture)
        case .insertTexts(let texts):
            try container.encode(CodingTypeKey.insertTexts)
            try container.encode(texts)
        case .replaceTexts(let vs):
            try container.encode(CodingTypeKey.replaceTexts)
            try container.encode(vs)
        case .removeTexts(let textIndexes):
            try container.encode(CodingTypeKey.removeTexts)
            try container.encode(textIndexes)
        case .replaceString(let textValue):
            try container.encode(CodingTypeKey.replaceString)
            try container.encode(textValue)
        case .changedColors(let colorUndoValue):
            try container.encode(CodingTypeKey.changedColors)
            try container.encode(colorUndoValue)
        case .insertBorders(let borders):
            try container.encode(CodingTypeKey.insertBorders)
            try container.encode(borders)
        case .removeBorders(let borderIndexes):
            try container.encode(CodingTypeKey.removeBorders)
            try container.encode(borderIndexes)
        case .setRootKeyframeIndex(let keyframeIndex):
            try container.encode(CodingTypeKey.setRootKeyframeIndex)
            try container.encode(keyframeIndex)
        case .insertKeyframes(let pivs):
            try container.encode(CodingTypeKey.insertKeyframes)
            try container.encode(pivs)
        case .removeKeyframes(let indexes):
            try container.encode(CodingTypeKey.removeKeyframes)
            try container.encode(indexes)
        case .setKeyframeOptions(let options):
            try container.encode(CodingTypeKey.setKeyframeOptions)
            try container.encode(options)
        case .insertKeyLines(let kvs):
            try container.encode(CodingTypeKey.insertKeyLines)
            try container.encode(kvs)
        case .replaceKeyLines(let kvs):
            try container.encode(CodingTypeKey.replaceKeyLines)
            try container.encode(kvs)
        case .removeKeyLines(let iivs):
            try container.encode(CodingTypeKey.removeKeyLines)
            try container.encode(iivs)
        case .insertKeyPlanes(let kvs):
            try container.encode(CodingTypeKey.insertKeyPlanes)
            try container.encode(kvs)
        case .replaceKeyPlanes(let kvs):
            try container.encode(CodingTypeKey.replaceKeyPlanes)
            try container.encode(kvs)
        case .removeKeyPlanes(let iivs):
            try container.encode(CodingTypeKey.removeKeyPlanes)
            try container.encode(iivs)
        case .insertDraftKeyLines(let kvs):
            try container.encode(CodingTypeKey.insertDraftKeyLines)
            try container.encode(kvs)
        case .removeDraftKeyLines(let iivs):
            try container.encode(CodingTypeKey.removeDraftKeyLines)
            try container.encode(iivs)
        case .insertDraftKeyPlanes(let kvs):
            try container.encode(CodingTypeKey.insertDraftKeyPlanes)
            try container.encode(kvs)
        case .removeDraftKeyPlanes(let iivs):
            try container.encode(CodingTypeKey.removeDraftKeyPlanes)
            try container.encode(iivs)
        case .setLineIDs(let idvs):
            try container.encode(CodingTypeKey.setLineIDs)
            try container.encode(idvs)
        case .setAnimationOption(let option):
            try container.encode(CodingTypeKey.setAnimationOption)
            try container.encode(option)
        case .insertNotes(let vs):
            try container.encode(CodingTypeKey.insertNotes)
            try container.encode(vs)
        case .replaceNotes(let vs):
            try container.encode(CodingTypeKey.replaceNotes)
            try container.encode(vs)
        case .removeNotes(let vs):
            try container.encode(CodingTypeKey.removeNotes)
            try container.encode(vs)
        case .insertDraftNotes(let noteIndexValues):
            try container.encode(CodingTypeKey.insertDraftNotes)
            try container.encode(noteIndexValues)
        case .removeDraftNotes(let noteIndexes):
            try container.encode(CodingTypeKey.removeDraftNotes)
            try container.encode(noteIndexes)
        case .insertContents(let vs):
            try container.encode(CodingTypeKey.insertContents)
            try container.encode(vs)
        case .replaceContents(let vs):
            try container.encode(CodingTypeKey.replaceContents)
            try container.encode(vs)
        case .removeContents(let vs):
            try container.encode(CodingTypeKey.removeContents)
            try container.encode(vs)
        case .setScoreOption(let option):
            try container.encode(CodingTypeKey.setScoreOption)
            try container.encode(option)
        case .setSheetOption(let option):
            try container.encode(CodingTypeKey.setSheetOption)
            try container.encode(option)
        case .setSelection(let selection):
            try container.encode(CodingTypeKey.setSelection)
            try container.encode(selection)
        }
    }
}
extension SheetUndoItem: CustomStringConvertible {
    var description: String {
        switch self {
        case .appendLine: "appendLine"
        case .appendLines: "appendLines"
        case .appendPlanes: "appendPlanes"
        case .removeLastLines: "removeLastLines"
        case .removeLastPlanes: "removeLastPlanes"
        case .insertLines: "insertLines"
        case .insertPlanes: "insertPlane"
        case .replaceLines: "replaceLines"
        case .replacePlanes: "replacePlanes"
        case .removeLines: "removeLines"
        case .removePlanes: "removePlanes"
        case .setPlaneValue: "setPlaneValue"
        case .changeToDraft: "changeToDraft"
        case .setPicture: "setPicture"
        case .insertDraftLines: "insertDraftLines"
        case .insertDraftPlanes: "insertDraftPlanes"
        case .removeDraftLines: "removeDraftLines"
        case .removeDraftPlanes: "removeDraftPlanes"
        case .setDraftPicture: "setDraftPicture"
        case .insertTexts: "insertTexts"
        case .replaceTexts: "replaceTexts"
        case .removeTexts: "removeTexts"
        case .replaceString: "replaceString"
        case .changedColors: "changedColors"
        case .insertBorders: "insertBorders"
        case .removeBorders: "removeBorders"
        case .setRootKeyframeIndex: "setRootKeyframeIndex"
        case .insertKeyframes: "insertKeyframes"
        case .removeKeyframes: "removeKeyframes"
        case .setKeyframeOptions: "setKeyframeOptions"
        case .insertKeyLines: "insertKeyLines"
        case .replaceKeyLines: "replaceKeyLines"
        case .removeKeyLines: "removeKeyLines"
        case .insertKeyPlanes: "insertKeyPlanes"
        case .replaceKeyPlanes: "replaceKeyPlanes"
        case .removeKeyPlanes: "removeKeyPlanes"
        case .insertDraftKeyLines: "insertDraftKeyLines"
        case .removeDraftKeyLines: "removeDraftKeyLines"
        case .insertDraftKeyPlanes: "insertDraftKeyPlanes"
        case .removeDraftKeyPlanes: "removeDraftKeyPlanes"
        case .setLineIDs: "setLineIDs"
        case .setAnimationOption: "setAnimationOption"
        case .insertNotes: "insertNotes"
        case .replaceNotes: "replaceNotes"
        case .removeNotes: "removeNotes"
        case .insertDraftNotes: "insertDraftNotes"
        case .removeDraftNotes: "removeDraftNotes"
        case .insertContents: "insertContents"
        case .replaceContents: "replaceContents"
        case .removeContents: "removeContents"
        case .setScoreOption: "setScoreOption"
        case .setSheetOption: "setSheetOption"
        case .setSelection: "setSelection"
        }
    }
}

struct Border {
    var location = 0.0, orientation = Orientation.horizontal
}
extension Border {
    init(location: Double, _ orientation: Orientation) {
        self.location = location
        self.orientation = orientation
    }
    init(_ orientation: Orientation) {
        location = 0
        self.orientation = orientation
    }
}
extension Border: Protobuf {
    init(_ pb: PBBorder) throws {
        location = try pb.location.notInfiniteAndNAN()
        orientation = try Orientation(pb.orientation)
    }
    var pb: PBBorder {
        .with {
            $0.location = location
            $0.orientation = orientation.pb
        }
    }
}
extension Border: Hashable, Codable {}
extension Border {
    init(position: Point, border: Border) {
        switch border.orientation {
        case .horizontal: location = position.y
        case .vertical: location = position.x
        }
        orientation = border.orientation
    }
}
extension Border {
    func edge(with bounds: Rect) -> Edge {
        switch orientation {
        case .horizontal:
             Edge(Point(bounds.minX, location),
                        Point(bounds.maxX, location))
        case .vertical:
             Edge(Point(location, bounds.minY),
                        Point(location, bounds.maxY))
        }
    }
    func path(with bounds: Rect) -> Path {
        Path([Pathline(edge(with: bounds))])
    }
}

extension Line {
    var node: Node {
        .init(path: .init(self),
              lineWidth: size,
              lineType: .color(uuColor.value))
    }
    func node(from color: Color) -> Node {
        .init(path: .init(self),
              lineWidth: size,
              lineType: .color(color))
    }
    var cpuNode: CPUNode {
        .init(path: .init(self),
              lineWidth: size,
              lineType: .color(uuColor.value))
    }
    func cpuNode(from color: Color, isDrawLineAntialias: Bool = false) -> CPUNode {
        .init(path: .init(self),
              lineWidth: size,
              lineType: .color(color), isDrawLineAntialias: isDrawLineAntialias)
    }
}
extension Plane {
    var node: Node {
        .init(path: path, fillType: .color(uuColor.value))
    }
    func node(from color: Color) -> Node {
        .init(path: path, fillType: .color(color))
    }
    var cpuNode: CPUNode {
        .init(path: path, fillType: .color(uuColor.value))
    }
    func cpuNode(from color: Color) -> CPUNode {
        .init(path: path, fillType: .color(color))
    }
}
extension Text {
    var node: Node {
        .init(attitude: .init(position: origin),
              path: typesetter.path(), fillType: .color(.content))
    }
    var cpuNode: CPUNode {
        .init(attitude: .init(position: origin),
              path: typesetter.path(), fillType: .color(.content))
    }
}
extension Border {
    func node(with bounds: Rect) -> Node {
        .init(path: path(with: bounds), lineWidth: 1, lineType: .color(.border))
    }
    func cpuNode(with bounds: Rect) -> CPUNode {
        .init(path: path(with: bounds), lineWidth: 1, lineType: .color(.border))
    }
}

protocol Picable {
    var picture: Picture { get set }
    var draftPicture: Picture { get set }
}

struct KeyframeOption {
    var beat = Rational(0)
    var previousPosition = Point(), nextPosition = Point()
}
extension KeyframeOption: Protobuf {
    init(_ pb: PBKeyframeOption) throws {
        beat = (try? .init(pb.beat)) ?? 0
        previousPosition = (try? .init(pb.previousPosition)) ?? .init()
        nextPosition = (try? .init(pb.nextPosition)) ?? .init()
    }
    var pb: PBKeyframeOption {
        .with {
            $0.beat = beat.pb
            $0.previousPosition = previousPosition.pb
            $0.nextPosition = nextPosition.pb
        }
    }
}
extension KeyframeOption: Hashable, Codable {}

struct Keyframe: Picable {
    var picture = Picture() {
        didSet {
            isKey = (picture.lines.contains { $0.interType != .interpolated }) || picture.isEmpty
        }
    }
    var draftPicture = Picture()
    
    var beat = Rational()
    var previousPosition = Point(), nextPosition = Point()
    var id = UUID()
    private(set) var isKey = true
    
    init(picture: Picture = Picture(), draftPicture: Picture = Picture(),
         beat: Rational = Keyframe.defaultDurBeat,
         previousPosition: Point = .init(), nextPosition: Point = .init(), id: UUID = .init()) {
        
        self.picture = picture
        self.draftPicture = draftPicture
        self.beat = beat
        self.previousPosition = previousPosition
        self.nextPosition = nextPosition
        self.id = id
        isKey = (picture.lines.contains { $0.interType != .interpolated }) || picture.isEmpty
    }
}
extension Keyframe {
    static let defaultFrameRate = 8
    static let defaultDurBeat = Rational(1, defaultFrameRate)
    static let minDurBeat = defaultDurBeat / 2
}
extension Keyframe {
    var isEmpty: Bool {
        picture.isEmpty && draftPicture.isEmpty
    }
    var isKeyWhereAllLines: Bool {
        picture.lines.allSatisfy { $0.interType == .key }
    }
    var containsInterpolated: Bool {
        picture.lines.contains { $0.interType == .interpolated }
    }
    
//    var isKey: Bool {
//        (picture.lines.contains { $0.interType != .interpolated }) || isEmpty
//    }
    func containsInterline(_ id: UUID) -> Bool {
        picture.lines.contains { $0.interID == id }
    }
    func containsKeyline(_ id: UUID) -> Bool {
        picture.lines.contains { $0.interID == id && $0.interType == .key }
    }
    
    var option: KeyframeOption {
        get {
            .init(beat: beat,
                  previousPosition: previousPosition, nextPosition: nextPosition)
        }
        set {
            self.beat = newValue.beat
            self.previousPosition = newValue.previousPosition
            self.nextPosition = newValue.nextPosition
        }
    }
}
extension Keyframe: Hashable, Codable {}
extension Keyframe: AppliableTransform {
    static func * (lhs: Self, rhs: Transform) -> Self {
        .init(picture: lhs.picture * rhs,
              draftPicture: lhs.draftPicture * rhs,
              beat: lhs.beat,
              previousPosition: lhs.previousPosition, nextPosition: lhs.nextPosition, id: lhs.id)
    }
}
extension Keyframe: Protobuf {
    init(_ pb: PBKeyframe) throws {
        picture = (try? Picture(pb.picture)) ?? Picture()
        draftPicture = (try? Picture(pb.draftPicture)) ?? Picture()
        beat = max((try? Rational(pb.beat)) ?? 1, 0)
        id = (try? .init(pb.id)) ?? .init()
        isKey = (picture.lines.contains { $0.interType != .interpolated }) || picture.isEmpty
    }
    var pb: PBKeyframe {
        .with {
            $0.picture = picture.pb
            $0.draftPicture = draftPicture.pb
            $0.beat = beat.pb
            $0.id = id.pb
        }
    }
}

struct AnimationOption {
    var beatRange = Music.defaultBeatRange
    var loopDurBeat: Rational = 0
    var tempo = Music.defaultTempo
    var previousNext = PreviousNext.none
    var keyBeats = [Rational]()
    var timelineY = Sheet.timelineY
    var enabled = false
}
extension AnimationOption: Protobuf {
    init(_ pb: PBAnimationOption) throws {
        beatRange = (try? RationalRange(pb.beatRange).value) ?? Music.defaultBeatRange
        loopDurBeat = (try? Rational(pb.loopDurBeat)) ?? 0
        tempo = (try? Rational(pb.tempo))?.clipped(Music.tempoRange) ?? Music.defaultTempo
        previousNext = (try? .init(pb.previousNext)) ?? .none
        keyBeats = pb.keyBeats.compactMap { try? Rational($0) }
        timelineY = pb.timelineY
        enabled = pb.enabled
    }
    var pb: PBAnimationOption {
        .with {
            $0.beatRange = RationalRange(value: beatRange).pb
            $0.loopDurBeat = loopDurBeat.pb
            $0.tempo = tempo.pb
            $0.previousNext = previousNext.pb
            $0.keyBeats = keyBeats.map { $0.pb }
            $0.timelineY = timelineY
            $0.enabled = enabled
        }
    }
}
extension AnimationOption: Hashable, Codable {}
extension AnimationOption {
    var endLoopDurBeat: Rational {
        beatRange.end + loopDurBeat
    }
}

struct KeyframeKey {
    var lineIs = [Int](), planeIs = [Int]()
    var draftLineIs = [Int](), draftPlaneIs = [Int]()
    var beat: Rational = 0
    var id = UUID()
}
extension KeyframeKey: Protobuf {
    init(_ pb: PBKeyframeKey) throws {
        lineIs = pb.lineIs.map { Int($0) }
        planeIs = pb.planeIs.map { Int($0) }
        draftLineIs = pb.draftLineIs.map { Int($0) }
        draftPlaneIs = pb.draftPlaneIs.map { Int($0) }
        beat = max((try? Rational(pb.beat)) ?? 1, 0)
        id = (try? .init(pb.id)) ?? .init()
    }
    var pb: PBKeyframeKey {
        .with {
            $0.lineIs = lineIs.map { Int64($0) }
            $0.planeIs = planeIs.map { Int64($0) }
            $0.draftLineIs = draftLineIs.map { Int64($0) }
            $0.draftPlaneIs = draftPlaneIs.map { Int64($0) }
            $0.beat = beat.pb
            $0.id = id.pb
        }
    }
}
struct AnimationCompressor {
    var keys = [KeyframeKey]()
    var lines = [Line](), planes = [Plane]()
    var draftLines = [Line](), draftPlanes = [Plane]()
}
extension AnimationCompressor: Protobuf {
    init(_ pb: PBAnimationCompressor) throws {
        keys = pb.keys.compactMap { try? KeyframeKey($0) }
        lines = pb.lines.compactMap { try? Line($0) }
        planes = pb.planes.compactMap { try? Plane($0) }
        draftLines = pb.draftLines.compactMap { try? Line($0) }
        draftPlanes = pb.draftPlanes.compactMap { try? Plane($0) }
    }
    var pb: PBAnimationCompressor {
        .with {
            $0.keys = keys.map { $0.pb }
            $0.lines = lines.map { $0.pb }
            $0.planes = planes.map { $0.pb }
            $0.draftLines = draftLines.map { $0.pb }
            $0.draftPlanes = draftPlanes.map { $0.pb }
        }
    }
}

struct Animation {
    var keyframes = [Keyframe]()

    var rootBeat = Rational(0) {
        didSet {
            index = index(atRootBeat: rootBeat)
        }
    }
    private(set) var index = 0
    
    var beatRange = Music.defaultBeatRange
    var loopDurBeat: Rational = 0
    var tempo = Music.defaultTempo
    var previousNext = PreviousNext.none
    var keyBeats = [Rational]()
    var timelineY = Sheet.timelineY
    var enabled = false
    
    init(keyframes: [Keyframe] = [],
         rootBeat: Rational = 0,
         beatRange: Range<Rational> = Music.defaultBeatRange,
         loopDurBeat: Rational = 0,
         tempo: Rational = Music.defaultTempo,
         previousNext: PreviousNext = .none,
         keyBeats: [Rational] = [],
         timelineY: Double = Sheet.timelineY,
         enabled: Bool = false) {
        
        self.keyframes = keyframes
        self.rootBeat = rootBeat
        self.beatRange = beatRange
        self.loopDurBeat = loopDurBeat
        self.tempo = tempo
        self.previousNext = previousNext
        self.keyBeats = keyBeats
        self.timelineY = timelineY
        self.enabled = enabled
        index = keyframes.isEmpty ?
            0 : index(atRootBeat: rootBeat)
    }
}
extension Animation: Hashable, Codable {}
extension Animation: Protobuf {
    init(_ pb: PBAnimation) throws {
        keyframes = pb.keyframes.compactMap { try? Keyframe($0) }.sorted(by: { $0.beat < $1.beat })
        if keyframes.isEmpty,
            let compressor = try? AnimationCompressor(pb.compressor) {
            
            keyframes = compressor.keys.map {
                let lines = $0.lineIs.map {
                    $0 < compressor.lines.count ?
                        compressor.lines[$0] : .init()
                }
                let planes = $0.planeIs.map {
                    $0 < compressor.planes.count ?
                        compressor.planes[$0] : .init()
                }
                let draftLines = $0.draftLineIs.map {
                    $0 < compressor.draftLines.count ?
                        compressor.draftLines[$0] : .init()
                }
                let draftPlanes = $0.draftPlaneIs.map {
                    $0 < compressor.draftPlanes.count ?
                        compressor.draftPlanes[$0] : .init()
                }
                
                return .init(picture: .init(lines: lines,
                                            planes: planes),
                             draftPicture: .init(lines: draftLines,
                                                 planes: draftPlanes),
                             beat: $0.beat, id: $0.id)
            }
        }
        
        rootBeat = (try? Rational(pb.rootBeat)) ?? 0
        beatRange = (try? RationalRange(pb.beatRange).value) ?? Music.defaultBeatRange
        loopDurBeat = (try? Rational(pb.loopDurBeat)) ?? 0
        tempo = (try? Rational(pb.tempo))?.clipped(Music.tempoRange) ?? Music.defaultTempo
        previousNext = (try? .init(pb.previousNext)) ?? .none
        keyBeats = pb.keyBeats.compactMap { try? Rational($0) }
        timelineY = pb.timelineY.clipped(min: Sheet.timelineY,
                                         max: Sheet.height - Sheet.timelineY)
        enabled = pb.enabled
        index = keyframes.isEmpty ?
            0 : index(atRootBeat: rootBeat)
    }
    var pb: PBAnimation {
        .with {
            var lineIs = [Line: Int]()
            var planeIs = [Plane: Int]()
            var draftLineIs = [Line: Int]()
            var draftPlaneIs = [Plane: Int]()
            let keys: [KeyframeKey] = keyframes.map { keyframe in
                let lineIs: [Int] = keyframe.picture.lines.map {
                    if let i = lineIs[$0] {
                        return i
                    } else {
                        let i = lineIs.count
                        lineIs[$0] = i
                        return i
                    }
                }
                let planeIs: [Int] = keyframe.picture.planes.map {
                    if let i = planeIs[$0] {
                        return i
                    } else {
                        let i = planeIs.count
                        planeIs[$0] = i
                        return i
                    }
                }
                let draftLineIs: [Int] = keyframe.draftPicture.lines.map {
                    if let i = draftLineIs[$0] {
                        return i
                    } else {
                        let i = draftLineIs.count
                        draftLineIs[$0] = i
                        return i
                    }
                }
                let draftPlaneIs: [Int] = keyframe.draftPicture.planes.map {
                    if let i = draftPlaneIs[$0] {
                        return i
                    } else {
                        let i = draftPlaneIs.count
                        draftPlaneIs[$0] = i
                        return i
                    }
                }
                
                return .init(lineIs: lineIs,
                             planeIs: planeIs,
                             draftLineIs: draftLineIs,
                             draftPlaneIs: draftPlaneIs,
                             beat: keyframe.beat,
                             id: keyframe.id)
            }
            
            let lines = lineIs
                .sorted(by: { $0.value < $1.value }).map { $0.key }
            let planes = planeIs
                .sorted(by: { $0.value < $1.value }).map { $0.key }
            let draftLines = draftLineIs
                .sorted(by: { $0.value < $1.value }).map { $0.key }
            let draftPlanes = draftPlaneIs
                .sorted(by: { $0.value < $1.value }).map { $0.key }
            let compressor = AnimationCompressor(keys: keys,
                                                 lines: lines, planes: planes,
                                                 draftLines: draftLines,
                                                 draftPlanes: draftPlanes)
            $0.compressor = compressor.pb
            
            $0.rootBeat = rootBeat.pb
            $0.beatRange = RationalRange(value: beatRange).pb
            $0.loopDurBeat = loopDurBeat.pb
            $0.tempo = tempo.pb
            $0.previousNext = previousNext.pb
            $0.keyBeats = keyBeats.map { $0.pb }
            $0.timelineY = timelineY
            $0.enabled = enabled
        }
    }
}
extension Animation: BeatRangeType {
    var isEmpty: Bool {
        keyframes.isEmpty
    }
    
    func keyframeIndex(at id: UUID) -> Int? {
        keyframes.firstIndex { $0.id == id }
    }
    
    var mainBeat: Rational {
        rootBeat.loop(0 ..< localDurBeat) + beatRange.start
    }
    var mainSec: Rational {
        sec(fromBeat: mainBeat)
    }
    
    var endLoopDurBeat: Rational {
        get {
            beatRange.end + loopDurBeat
        }
        set {
            loopDurBeat = max(0, newValue - beatRange.end)
        }
    }
    var endLoopDurSec: Rational {
        secRange.end + loopDurSec
    }
    var loopDurSec: Rational {
        sec(fromBeat: loopDurBeat)
    }
    
    var allSecRange: Range<Rational> {
        secRange(fromBeat: beatRange.start ..< endLoopDurBeat)
    }
    
    var localDurBeat: Rational {
        beatRange.length
    }
    var localBeatRange: Range<Rational> {
        0 ..< localDurBeat
    }
    var localBeat: Rational {
        get { rootBeat.loop(0 ..< localDurBeat) }
        set { rootBeat = newValue }
    }
    func localBeat(at i: Int) -> Rational {
        keyframes[i].beat
    }
    func localBeat(atRoot rootI: Int) -> Rational {
        localBeat(at: index(atRoot: rootI))
    }
    func localBeat(atRootBeat rootBeat: Rational) -> Rational {
        rootBeat.loop(0 ..< localDurBeat)
    }
    var localSec: Rational {
        sec(fromBeat: localBeat)
    }
    
    var internalBeat: Rational {
        internalBeat(atBeat: localBeat) ?? 0
    }
    func internalBeat(atBeat beat: Rational) -> Rational? {
        guard !keyframes.isEmpty && beat >= 0 else { return nil }
        var previousBeat = Rational(0)
        for keyframe in keyframes {
            let nextBeat = keyframe.beat
            if beat < nextBeat {
                return beat - previousBeat
            }
            previousBeat = nextBeat
        }
        return beat - keyframes.last!.beat
    }
    
    func index(atRoot rootI: Int) -> Int {
        rootI.mod(keyframes.count)
    }
    func index(atBeat beat: Rational) -> Int? {
        guard !keyframes.isEmpty else { return nil }
        for i in 1 ... keyframes.count {
            let nextBeat = i == keyframes.count ? localDurBeat : keyframes[i].beat
            if beat < nextBeat {
                return i - 1
            }
        }
        return nil
    }
    func index(atRootBeat rootBeat: Rational) -> Int {
        index(atRoot: rootIndex(atRootBeat: rootBeat))
    }
    func indexInBeatRange(atRootBeat beat: Rational) -> Int? {
        if loopDurBeat > 0 && beatRange.length > 0 {
            if (beatRange.end ..< (beatRange.end + loopDurBeat)).contains(beat) {
                return index(atRootBeat: (beat - beatRange.end).mod(beatRange.length))
            }
        }
        return beatRange.contains(beat) ? index(atRootBeat: beat - beatRange.start) : nil
    }
    func index(atSec sec: Rational) -> Int {
        index(atRootBeat: beat(fromSec: sec) - beatRange.start)
    }
    func indexInBeatRange(atSec sec: Rational) -> Int? {
        indexInBeatRange(atRootBeat: beat(fromSec: sec))
    }
    func indexAndInternalBeat(atRootBeat beat: Rational) -> (index: Int, internalBeat: Rational)? {
        let beat = localBeat(atRootBeat: beat)
        guard !keyframes.isEmpty else { return nil }
        var previousBeat = Rational(0)
        for i in 1 ... keyframes.count {
            let nextBeat = i == keyframes.count ? localDurBeat : keyframes[i].beat
            if beat < nextBeat {
                return (i - 1, beat - previousBeat)
            }
            previousBeat = nextBeat
        }
        return nil
    }
    func indexInBeatRange(atFrame fi: Int, startSec: Rational, frameRate: Int) -> Int? {
        let beatRange = beatRange, loopDurBeat = loopDurBeat
        let sBeat = beatRange.start, eBeat = beatRange.end
        let sfi = Animation.frame(fromSec: sec(fromBeat: sBeat) + startSec, frameRate: frameRate)
        let efi = Animation.frame(fromSec: sec(fromBeat: eBeat + loopDurBeat) + startSec, frameRate: frameRate)
        guard fi >= sfi && fi < efi, !keyframes.isEmpty else { return nil }
        for (i, keyframe) in keyframes.enumerated() {
            let kfi = Animation.frame(fromSec: sec(fromBeat: keyframe.beat + beatRange.start) + startSec,
                                      frameRate: frameRate)
            if fi < kfi {
                return max(i - 1, 0)
            }
        }
        let neBeat = eBeat + loopDurBeat
        if loopDurBeat > 0 {
            var beat = eBeat
            loop: while true {
                for (i, keyframe) in keyframes.enumerated() {
                    let nBeat = keyframe.beat + beat
                    guard nBeat < neBeat else { return i - 1 >= 0 ? i - 1 : keyframes.count - 1 }
                    let kfi = Animation.frame(fromSec: sec(fromBeat: nBeat) + startSec, frameRate: frameRate)
                    if fi < kfi {
                        return i - 1 >= 0 ? i - 1 : keyframes.count - 1
                    }
                }
                beat += beatRange.length
            }
        } else {
            return keyframes.count - 1
        }
    }
    
    func keyframeDurBeat(at i: Int) -> Rational {
        if i + 1 < keyframes.count {
            keyframes[i + 1].beat - keyframes[i].beat
        } else {
            max(localDurBeat - keyframes[i].beat, 0)
        }
    }
    func rendableKeyframeDurBeat(at i: Int) -> Rational {
        guard !keyframes.isEmpty else {
            return 0
        }
        let beat = i == 0 && keyframes[i].beat > 0 ? 0 : keyframes[i].beat
        let durBeat = beatRange.length
        let nextBeat = i + 1 < keyframes.count ? keyframes[i + 1].beat : durBeat
        return if beat < 0 {
            nextBeat < 0 ? 0 : min(nextBeat, durBeat)
        } else {
            beat < durBeat ? min(nextBeat, durBeat) - beat : 0
        }
    }
    func rendableKeyframeDurSec(at i: Int) -> Rational {
        sec(fromBeat: rendableKeyframeDurBeat(at: i))
    }
    
    func rootBeat(atRoot rootI: Int) -> Rational {
        let ki = index(atRoot: rootI)
        let loopI = (rootI - ki) / keyframes.count
        return Rational(loopI) * localDurBeat + localBeat(at: ki)
    }
    func rootIndex(atRootBeat rootBeat: Rational) -> Int {
        let durBeat = localDurBeat
        guard durBeat > 0 else { return 0 }
        let beat = rootBeat.loop(0 ..< durBeat)
        let loopI = Int((rootBeat - beat) / durBeat)
        return loopI * keyframes.count + (index(atBeat: beat) ?? 0)
    }
    func nearestRootIndex(atRootBeat rootBeat: Rational) -> Int {
        let durBeat = localDurBeat
        guard durBeat > 0 else { return 0 }
        let beat = rootBeat.loop(0 ..< durBeat)
        let loopI = Int((rootBeat - beat) / durBeat)
        let index = index(atBeat: beat) ?? 0
        let rootI = loopI * keyframes.count + index
        let nBeat = beat - localBeat(at: index)
        let halfBeat = keyframeDurBeat(at: index) / 2
        return nBeat > halfBeat ? rootI + 1 : rootI
    }
    var rootIndex: Int {
        get { rootLoopIndex(atRootBeat: rootBeat) * keyframes.count + index }
        set {
            rootBeat = self.rootBeat(atRoot: newValue)
            let index = index(atRoot: newValue)
            if index != self.index {
                self.index = index
            }
        }
    }
    mutating func goNext() {
        self.rootBeat = rootBeat(dx: 1, fromRoot: rootBeat, keyD: 1, otherD: 1)
    }
    mutating func goPrevious() {
        self.rootBeat = rootBeat(dx: -1, fromRoot: rootBeat, keyD: 1, otherD: 1)
    }
    func rootBeat(dx: Double, fromRoot beganRootBeat: Rational,
                  keyD: Double = 17.5, otherD: Double = 8.75) -> Rational {
        var bws = keyframes.count.range.reduce(into: [Rational: Double]()) {
            $0[keyframes[$1].beat] = keyframes[$1].isKey ? keyD : otherD
        }
        let roundedSBeat = beatRange.start.rounded(.down)
        let deltaBeat: Rational = 1
        var cBeat = roundedSBeat
        while cBeat < beatRange.end {
            if cBeat >= beatRange.start {
                if bws[cBeat - beatRange.start] == nil {
                    bws[cBeat - beatRange.start] = otherD
                }
            }
            cBeat += deltaBeat
        }
        let beatAndWidths = bws.sorted(by: { $0.key < $1.key })
        guard !beatAndWidths.isEmpty else { return beganRootBeat }
        let localbeat = localBeat(atRootBeat: beganRootBeat)
        var bwI = 0
        for (i, v) in beatAndWidths.enumerated().reversed() {
            if localbeat >= v.key {
                bwI = i
                break
            }
        }
        var nRootBeat = rootLoopIndexBeat(atRootLoop: rootLoopIndex(atRootBeat: beganRootBeat))
        + beatAndWidths[bwI].key
        var x = -beatAndWidths[bwI].value / 2
        
        while true {
            x += beatAndWidths[bwI].value
            guard abs(x) < abs(dx) else { break }
            
            let dBeat = if dx < 0 {
                if bwI - 1 >= 0 {
                    -(beatAndWidths[bwI].key - beatAndWidths[bwI - 1].key)
                } else {
                    -(beatAndWidths[bwI].key
                      + beatRange.length - beatAndWidths[.last].key)
                }
            } else {
                if bwI + 1 < beatAndWidths.count {
                    beatAndWidths[bwI + 1].key - beatAndWidths[bwI].key
                } else {
                    beatRange.length - beatAndWidths[bwI].key
                    + beatAndWidths[0].key
                }
            }
            nRootBeat = Rational.saftyAdd(nRootBeat, dBeat)
            
            bwI = (dx < 0 ? bwI - 1 : bwI + 1)
                .loop(start: 0, end: beatAndWidths.count)
        }
        return nRootBeat
    }
    
    var rootLoopIndex: Int {
        rootLoopIndex(atRoot: rootIndex)
    }
    func rootLoopIndex(atRoot rootI: Int) -> Int {
        rootI.divFloor(keyframes.count)
    }
    func rootLoopIndex(atRootBeat rootBeat: Rational) -> Int {
        rootLoopIndex(atRoot: rootIndex(atRootBeat: rootBeat))
    }
    func rootLoopIndexBeat(atRootLoop loopI: Int) -> Rational {
        localDurBeat * Rational(loopI)
    }
    
    struct RootBeatIndex: Hashable, Codable {
        var internalBeat = Rational(0), index = 0, loopIndex = 0
    }
    var rootBeatIndex: RootBeatIndex {
        get {
            .init(internalBeat: internalBeat,
                  index: index,
                  loopIndex: rootLoopIndex(atRoot: rootIndex))
        }
        set {
            rootBeat = rootBeat(at: newValue)
        }
    }
    func rootIndex(at rootBeatIndex: RootBeatIndex) -> Int {
        rootBeatIndex.index + rootBeatIndex.loopIndex * keyframes.count
    }
    func rootBeat(at rootBeatIndex: RootBeatIndex) -> Rational {
        rootBeatIndex.internalBeat
        + localBeat(at: rootBeatIndex.index)
        + rootLoopIndexBeat(atRootLoop: rootBeatIndex.loopIndex)
    }
    
    struct RootBeatPosition: Hashable, Codable {
        var beat = Rational(0), loopIndex = 0
    }
    var rootBeatPosition: RootBeatPosition {
        get {
            .init(beat: localBeat, loopIndex: rootLoopIndex(atRoot: rootIndex))
        }
        set {
            rootBeat = rootBeat(at: newValue)
        }
    }
    func rootIndex(at rootBP: RootBeatPosition) -> Int {
        (index(atBeat: rootBP.beat) ?? 0) + rootBeatIndex.loopIndex * keyframes.count
    }
    func rootBeat(at rootBP: RootBeatPosition) -> Rational {
        rootBP.beat + rootLoopIndexBeat(atRootLoop: rootBP.loopIndex)
    }
    
    var interIndexes: [Int] {
        keyframes.enumerated()
            .compactMap { $0.offset == 0 || $0.element.isKey ? $0.offset : nil }
    }
    var rootInterIndex: Int {
        get { rootInterIndex(atRoot: rootIndex) }
        set { self.rootIndex = rootIndex(atRootInter: newValue) }
    }
    func rootIndex(atRootInter rootInterI: Int) -> Int {
        let ii = interIndex(atRootInter: rootInterI)
        let count = (rootInterI - ii) / interIndexes.count
        return count * keyframes.count + index(atInter: ii)
    }
    func interIndex(atRootInter rootInterI: Int) -> Int {
        rootInterI.mod(interIndexes.count)
    }
    func index(atInter interI: Int) -> Int {
        var n = 0
        for (j, keyframe) in keyframes.enumerated() {
            if j == 0 || keyframe.isKey {
                n += 1
            }
            if n - 1 == interI {
                return j
            }
        }
        return keyframes.count - 1
    }
    func index(atRootInter rootInterI: Int) -> Int {
        let j = interIndex(atRootInter: rootInterI)
        return index(atInter: j)
    }
    func rootInterIndex(atRoot rootI: Int) -> Int {
        let pi = index(atRoot: rootI)
        let count = (rootI - pi) / keyframes.count
        return count * interIndexes.count + interIndex(at: pi)
    }
    func interIndex(at i: Int) -> Int {
        var n = 0
        for j in 0 ... i {
            let isInter = j == 0 || keyframes[j].isKey
            if isInter {
                n += 1
            }
        }
        return n - 1
    }
    
    func keyframe(atBeat beat: Rational) -> Keyframe {
        guard let i = index(atBeat: beat) else { return Keyframe() }
        return keyframes[i]
    }
    func keyframe(atRootBeat rootBeat: Rational) -> Keyframe? {
        if let i = indexInBeatRange(atRootBeat: rootBeat) { keyframes[i] } else { nil }
    }
    func keyframe(atSec sec: Rational) -> Keyframe? {
        if let i = indexInBeatRange(atSec: sec) { keyframes[i] } else { nil }
    }
    func keyframe(atRoot rootI: Int) -> Keyframe {
        keyframes[index(atRootBeat: rootBeat(atRoot: rootI))]
    }
    func keyframe(atRootInter rootInterI: Int) -> Keyframe {
        keyframe(atRoot: rootIndex(atRootInter: rootInterI))
    }
    var currentKeyframe: Keyframe {
        get { keyframes[index] }
        set { keyframes[index] = newValue }
    }
    var currentDurBeat: Rational {
        keyframeDurBeat(at: index)
    }
    
    mutating func set(_ koivs: [IndexValue<KeyframeOption>]) {
        koivs.forEach {
            keyframes[$0.index].option = $0.value
        }
    }
    
    static func timeString(fromTime time: Rational, frameRate: Rational) -> String {
        let minusStr = time < 0 ? "-" : ""
        let time = abs(time)
        let dPart = time.decimalPart * frameRate
        let idPart = Int(dPart)
        let iPart = time.integralPart
        let iddPart = Int(dPart.decimalPart * 12)
        return if iddPart != 0 {
            minusStr + String(format: "%02d.%02d.%d", iPart, idPart, iddPart)
        } else {
            minusStr + String(format: "%02d.%02d", iPart, idPart)
        }
    }
}
extension Animation {
    var option: AnimationOption {
        get {
            .init(beatRange: beatRange, loopDurBeat: loopDurBeat, tempo: tempo,
                  previousNext: previousNext, keyBeats: keyBeats,
                  timelineY: timelineY, enabled: enabled)
        }
        set {
            beatRange = newValue.beatRange
            loopDurBeat = newValue.loopDurBeat
            tempo = newValue.tempo
            previousNext = newValue.previousNext
            keyBeats = newValue.keyBeats
            timelineY = newValue.timelineY
            enabled = newValue.enabled
        }
    }
}

enum PreviousNext: Int32, Hashable, Codable {
    case none, previous, next, previousAndNext
}
extension PreviousNext {
    var displayName: String {
        switch self {
        case .none: "Hidden Prev, Hidden Next".localized
        case .previous: "Shown  Prev, Hidden Next".localized
        case .next: "Hidden Prev, Shown  Next".localized
        case .previousAndNext: "Shown  Prev, Shown  Next".localized
        }
    }
}
extension PreviousNext: Protobuf {
    init(_ pb: PBPreviousNext) throws {
        switch pb {
        case .off: self = .none
        case .previous: self = .previous
        case .next: self = .next
        case .previousAndNext: self = .previousAndNext
        case .UNRECOGNIZED: self = .none
        }
    }
    var pb: PBPreviousNext {
        switch self {
        case .none: .off
        case .previous: .previous
        case .next: .next
        case .previousAndNext: .previousAndNext
        }
    }
}

struct SheetOption {
    var mainFrame = Sheet.defaultBounds
}
extension SheetOption: Protobuf {
    init(_ pb: PBSheetOption) throws {
        let mainFrame = (try? Rect(pb.mainFrame)) ?? Sheet.defaultBounds
        self.mainFrame = mainFrame.isEmpty ? Sheet.defaultBounds : mainFrame
    }
    var pb: PBSheetOption {
        .with {
            if mainFrame != Sheet.defaultBounds {
                $0.mainFrame = mainFrame.pb
            }
        }
    }
}
extension SheetOption: Hashable, Codable {}

struct TextSelection: Hashable, Codable {
    var ranges = [Range<Int>]()
}
extension TextSelection {
    var isEmpty: Bool {
        ranges.isEmpty
    }
}
extension TextSelection: Protobuf {
    init(_ pb: PBTextSelection) throws {
        ranges = pb.ranges.compactMap { try? .init($0) }
    }
    var pb: PBTextSelection {
        .with {
            $0.ranges = ranges.map { $0.pb }
        }
    }
}

struct PitSelection: Hashable, Codable {
    var sprolIs = Set<Int>()
}
extension PitSelection {
    var isEmpty: Bool {
        sprolIs.isEmpty
    }
}
extension PitSelection: Protobuf {
    init(_ pb: PBPitSelection) throws {
        sprolIs = .init(pb.sprolIs.map { .init($0) })
    }
    var pb: PBPitSelection {
        .with {
            $0.sprolIs = sprolIs.map { .init($0) }
        }
    }
}
struct NoteSelection: Hashable, Codable {
    var pitSelections = [Int: PitSelection]()
}
extension NoteSelection {
    var isEmpty: Bool {
        pitSelections.isEmpty
    }
}
extension NoteSelection: Protobuf {
    init(_ pb: PBNoteSelection) throws {
        pitSelections = pb.pitSelections.reduce(into: .init()) {
            $0[.init($1.key)] = try? .init($1.value)
        }
    }
    var pb: PBNoteSelection {
        .with {
            $0.pitSelections = pitSelections.reduce(into: .init()) {
                $0[.init($1.key)] = $1.value.pb
            }
        }
    }
}

struct KeyframeSelection: Hashable, Codable {
    var lineIs = Set<Int>()
    var planeIs = Set<Int>()
}
extension KeyframeSelection {
    var isEmpty: Bool {
        lineIs.isEmpty && planeIs.isEmpty
    }
}
extension KeyframeSelection: Protobuf {
    init(_ pb: PBKeyframeSelection) throws {
        lineIs = .init(pb.lineIs.map { .init($0) })
        planeIs = .init(pb.planeIs.map { .init($0) })
    }
    var pb: PBKeyframeSelection {
        .with {
            $0.lineIs = lineIs.map { .init($0) }
            $0.planeIs = planeIs.map { .init($0) }
        }
    }
}

struct SheetSelection: Hashable, Codable {
    static let empty = Self()
    
    var keyframeSelections = [Int: KeyframeSelection]()
    var noteSelections = [Int: NoteSelection]()
    var textSelections = [Int: TextSelection]()
    var contentIs = Set<Int>()
    var lastPosition: Point?
}
extension SheetSelection {
    var isEmpty: Bool {
        keyframeSelections.isEmpty && noteSelections.isEmpty
        && textSelections.isEmpty && contentIs.isEmpty
    }
    var isEmptySheetValue: Bool {
        keyframeSelections.contains { !$0.value.isEmpty }
        || !textSelections.isEmpty || !contentIs.isEmpty
    }
    func isChangeSelectedFrame(old: SheetSelection) -> Bool {
        keyframeSelections != old.keyframeSelections
        || textSelections != old.textSelections
        || contentIs != old.contentIs
        || noteSelections != old.noteSelections
        || lastPosition != old.lastPosition
    }
    var notePitSprolIs: [Int: [Int: Set<Int>]] {
        get {
            noteSelections.reduce(into: .init()) {
                $0[$1.key] = $1.value.pitSelections.reduce(into: .init()) {
                    $0[$1.key] = .init($1.value.sprolIs)
                }
            }
        }
        set {
            noteSelections = newValue.reduce(into: .init()) {
                $0[$1.key] = .init(pitSelections: $1.value.reduce(into: .init()) {
                    $0[$1.key] = .init(sprolIs: .init($1.value))
                })
            }
        }
    }
}
extension SheetSelection: Protobuf {
    init(_ pb: PBSheetSelection) throws {
        keyframeSelections = pb.keyframeSelections.reduce(into: .init()) {
            $0[.init($1.key)] = try? .init($1.value)
        }
        noteSelections = pb.noteSelections.reduce(into: .init()) {
            $0[.init($1.key)] = try? .init($1.value)
        }
        textSelections = pb.textSelections.reduce(into: .init()) {
            $0[.init($1.key)] = try? .init($1.value)
        }
        contentIs = .init(pb.contentIs.map { .init($0) })
        self.lastPosition = if case .lastPosition(let lastPosition)? = pb.lastPositionOptional {
            try? .init(lastPosition)
        } else {
            nil
        }
    }
    var pb: PBSheetSelection {
        .with {
            $0.keyframeSelections = keyframeSelections.reduce(into: .init()) {
                $0[.init($1.key)] = $1.value.pb
            }
            $0.noteSelections = noteSelections.reduce(into: .init()) {
                $0[.init($1.key)] = $1.value.pb
            }
            $0.textSelections = textSelections.reduce(into: .init()) {
                $0[.init($1.key)] = $1.value.pb
            }
            $0.contentIs = contentIs.map { .init($0) }
            $0.lastPositionOptional = if let lastPosition {
                .lastPosition(lastPosition.pb)
            } else {
                nil
            }
        }
    }
}

struct Sheet {
    var animation = Animation(keyframes: [Keyframe(beat: 0)])
    var score = Score()
    var texts = [Text]()
    var contents = [Content]()
    var borders = [Border]()
    var mainFrame = Sheet.defaultBounds
    var backgroundUUColor = Sheet.defalutBackgroundUUColor
    var selection = SheetSelection.empty
}
extension Sheet: Protobuf {
    init(_ pb: PBSheet) throws {
        if let animation = try? Animation(pb.animation), !animation.isEmpty {
            self.animation = animation
        } else {
            let picture = (try? Picture(pb.picture)) ?? Picture()
            let draftPicture = (try? Picture(pb.draftPicture)) ?? Picture()
            let kf = Keyframe(picture: picture, draftPicture: draftPicture, beat: 0)
            animation = Animation(keyframes: [kf])
        }
        
        score = (try? .init(pb.score)) ?? .init()
        texts = pb.texts.compactMap { try? Text($0) }
        contents = pb.contents.compactMap { try? .init($0) }
        borders = pb.borders.compactMap { try? Border($0) }
        let mainFrame = (try? Rect(pb.mainFrame)) ?? Sheet.defaultBounds
        self.mainFrame = mainFrame.isEmpty ? Sheet.defaultBounds : mainFrame
        backgroundUUColor = (try? UUColor(pb.backgroundUucolor))
            ?? Sheet.defalutBackgroundUUColor
        selection = (try? .init(pb.selection)) ?? .empty
        if !checkConsistency(selection) {
            selection = .empty
        }
    }
    var pb: PBSheet {
        .with {
            if !animation.isEmpty {
                $0.animation = animation.pb
            } else {
                $0.picture = picture.pb
                $0.draftPicture = draftPicture.pb
            }
            $0.score = score.pb
            $0.texts = texts.map { $0.pb }
            $0.contents = contents.map { $0.pb }
            $0.borders = borders.map { $0.pb }
            if mainFrame != Sheet.defaultBounds {
                $0.mainFrame = mainFrame.pb
            }
            $0.backgroundUucolor = backgroundUUColor.pb
            $0.selection = selection.pb
        }
    }
}
extension Sheet: Hashable, Codable {}
extension Sheet {
    static let width = 720.0, height = 720.0
    static let defaultBounds = Rect(width: width, height: height)
    static let defalutBackgroundUUColor = UU(Color.background, id: .zero)
    static let textPadding = Size(width: 16, height: 15)
    static let textPaddingBounds = defaultBounds.inset(by: textPadding)
    static let beatWidth = 43.0, secPadding = 16.0
    static let timelineHalfHeight = 12.0
    static let knobWidth = 2.0, knobHeight = 12.0, rulerHeight = 4.0
    static let mainFrameLineWidth = 4.0
    static let knobEditDistance = 20.0
    static let noteEditDistance = 50.0
    static let keyframeEditDistance = 80.0
    static let moveKnobEditDistance = 10.0
    static let lastPositionEditDistance = 60.0
    static let timelineY = 18.0
    static let pitchHeight = 5.375
    static let noteHeight = 1.75
    static let tonePadding = 2.0
    static let evenY = 1.0
    static let spectlopeHeight = 2.0, maxSpectlopeHeight = 12.0
    static let reverbHeight = 0.5
    static let timelinePadding = 6.0, interpolatedKnobHeight = 6.0
    static let timelineMargin = 24.0
}
extension Sheet {
    var picture: Picture {
        get { animation.currentKeyframe.picture }
        set { animation.currentKeyframe.picture = newValue }
    }
    var draftPicture: Picture {
        get { animation.currentKeyframe.draftPicture }
        set { animation.currentKeyframe.draftPicture = newValue }
    }
    var isEmpty: Bool {
        picture.lines.isEmpty && draftPicture.lines.isEmpty
    }
    
    var keyframeSelection: KeyframeSelection? {
        selection.keyframeSelections[animation.index]
    }
    
    func checkConsistency(_ selection: SheetSelection) -> Bool {
        if let maxKeyframeI = selection.keyframeSelections.keys.max() {
            if !animation.keyframes.count.range.contains(maxKeyframeI) {
                return false
            }
            for (keyframeI, keyframeSelection) in selection.keyframeSelections {
                let keyframe = animation.keyframes[keyframeI]
                if let maxLineI = keyframeSelection.lineIs.max(),
                   !keyframe.picture.lines.count.range.contains(maxLineI) {
                   return false
                }
                if let maxPlaneI = keyframeSelection.planeIs.max(),
                   !keyframe.picture.planes.count.range.contains(maxPlaneI) {
                   return false
                }
            }
        }
        
        if let maxNoteI = selection.noteSelections.keys.max() {
            if !score.notes.count.range.contains(maxNoteI) {
                return false
            }
            for (noteI, noteSelection) in selection.noteSelections {
                let note = score.notes[noteI]
                if let maxPitI = noteSelection.pitSelections.keys.max() {
                    if !note.pits.count.range.contains(maxPitI) {
                        return false
                    }
                    for (pitI, pitSelection) in noteSelection.pitSelections {
                        let pit = note.pits[pitI]
                        if let maxSprolI = pitSelection.sprolIs.max() {
                            if !pit.tone.spectlope.sprols.count.range.contains(maxSprolI) {
                                return false
                            }
                        }
                    }
                } else {
                    return false
                }
            }
        }
        
        if let maxTextI = selection.textSelections.keys.max() {
            if !texts.count.range.contains(maxTextI) {
                return false
            }
            for (textI, textSelection) in selection.textSelections {
                let text = texts[textI]
                for range in textSelection.ranges {
                    if range.lowerBound < 0 || range.upperBound > text.string.count {
                        return false
                    }
                }
            }
        }
        
        if let maxContentI = selection.contentIs.max(),
            !contents.count.range.contains(maxContentI) {
            return false
        }
        
        return true
    }
    
    var enabledAnimation: Bool {
        animation.enabled
    }
    var enabledTimeline: Bool {
        animation.enabled
        || score.enabled
        || contents.contains { $0.timeOption != nil }
        || texts.contains { $0.timeOption != nil }
    }
    
    static func frameRate(from sheets: [Sheet]) -> Int {
        let qs = sheets
            .flatMap { sheet in
                if sheet.enabledAnimation {
                    sheet.animation.keyframes.count.range
                        .map { sheet.animation.rendableKeyframeDurSec(at: $0).q }
                        .filter { $0 != 0 }
                } else {
                    sheet.captions.flatMap { [$0.secRange.start.q, $0.secRange.length.q] }
                        .filter { $0 != 0 }
                }
        }
        if !qs.isEmpty {
            let frameRate = Int.lcd(qs)
            return frameRate <= 60 ? frameRate : 60
        }
        return 60
    }
    static func standardFrameRate(from sheets: [Sheet]) -> Int {
        let frameRate = frameRate(from: sheets)
        return [24, 25, 30, 48, 50, 60].first(where: { $0 % frameRate == 0 }) ?? 60
    }
    
    static func temposFromStandardFrameRate() -> [Rational] {
        func tempo(fps: Int, k: Int) -> Rational {
            Rational(60 * fps, k)
        }
        return Set((1 ... 48).map { tempo(fps: 24, k: $0) }
                   + (1 ... 50).map { tempo(fps: 25, k: $0) }
                   + (1 ... 60).map { tempo(fps: 30, k: $0) }
                   + (1 ... 96).map { tempo(fps: 48, k: $0) }
                   + (1 ... 100).map { tempo(fps: 50, k: $0) }
                   + (1 ... 120).map { tempo(fps: 60, k: $0) }).sorted()
            .filter { fpb(fromTempo: $0) != nil }
    }
    static func tempoNameFromStandardFrameRate(withTempo tempo: Rational) -> String {
        let fpbName = if let fpb = fpb(fromTempo: tempo) {
            fpb % 3 != 0 ? " (\(fpb) fpb)" : " (\(fpb / 3) * 3 fpb)"
        } else {
            ""
        }
        return Double(tempo).string(digitsCount: 2) + " bpm" + fpbName
    }
    static func fpbPrime(fromTempo tempo: Rational, fps: Int) -> (two: Int, three: Int) {
        let v = Rational(60 * fps) / tempo
        guard v.isInteger else { return (0, 0) }
        var i = v.integralPart, two = 0, three = 0
        for _ in 7.range {
            if i % 2 != 0 { break }
            i /= 2
            two += 1
        }
        if i % 3 == 0 {
            three += 1
        }
        return (two, three)
    }
    static func fpb(fromTempo tempo: Rational) -> Int? {
        let fpb48 = fpbPrime(fromTempo: tempo, fps: 48)
        let fpb50 = fpbPrime(fromTempo: tempo, fps: 50)
        let fpb60 = fpbPrime(fromTempo: tempo, fps: 60)
        let (two, three) = [fpb48, fpb50, fpb60].max { $0.two < $1.two }!
        return two == 0 ? nil : 2 ** two * 3 ** three
    }
    
    var mainLineUUColor: UUColor? {
        picture.lines.reduce(into: [UUColor: Int]()) {
            if let i = $0[$1.uuColor] {
                $0[$1.uuColor] = i + 1
            } else {
                $0[$1.uuColor] = 1
            }
        }.max { $0.value < $1.value }?.key
    }
    
    func boundsTuple(at p: Point,
                     in bounds: Rect) -> (bounds: Rect, isAll: Bool) {
        guard !borders.isEmpty || mainFrame != Sheet.defaultBounds else { return (bounds, true) }
        guard !borders.isEmpty else { return (mainFrame, false) }
        var aabb = AABB(bounds)
        
        let mainBorders = mainFrame != Sheet.defaultBounds ?
        [Border(location: mainFrame.minX, .vertical),
         Border(location: mainFrame.maxX, .vertical),
         Border(location: mainFrame.minY, .horizontal),
         Border(location: mainFrame.maxY, .horizontal)] : []
        
        (borders + mainBorders).forEach {
            switch $0.orientation {
            case .horizontal:
                if p.y > $0.location && aabb.minY < $0.location {
                    aabb.yRange.lowerBound = $0.location
                } else if p.y < $0.location && aabb.maxY > $0.location {
                    aabb.yRange.upperBound = $0.location
                }
            case .vertical:
                if p.x > $0.location && aabb.minX < $0.location {
                    aabb.xRange.lowerBound = $0.location
                } else if p.x < $0.location && aabb.maxX > $0.location {
                    aabb.xRange.upperBound = $0.location
                }
            }
        }
        return (aabb.rect, false)
    }
    
    static func clipped(_ lines: [Line], in bounds: Rect) -> [Line] {
        let lassoLine = Line(controls:
                                [.init(point: bounds.minXMinYPoint),
                                 .init(point: bounds.minXMinYPoint),
                                 .init(point: bounds.minXMaxYPoint),
                                 .init(point: bounds.minXMaxYPoint),
                                 .init(point: bounds.maxXMaxYPoint),
                                 .init(point: bounds.maxXMaxYPoint),
                                 .init(point: bounds.maxXMinYPoint),
                                 .init(point: bounds.maxXMinYPoint)])
        let lasso = Lasso(line: lassoLine)
        return lines.reduce(into: [Line]()) {
            if let splitedLine = lasso.splitedLine(with: $1) {
                switch splitedLine {
                case .around(let line):
                    $0.append(line)
                case .split((var inLines, _)):
                    if !inLines.isEmpty {
                        let idI: Int
                        if inLines.count == 1 {
                            idI = 0
                        } else {
                            var maxD = 0.0, j = 0
                            for (k, l) in inLines.enumerated() {
                                let d = l.length()
                                if d > maxD {
                                    j = k
                                    maxD = d
                                }
                            }
                            idI = j
                        }
                        inLines[idI].interID = $1.interID
                        inLines[idI].interType = $1.interType
                        
                        $0 += inLines
                    }
                }
            }
        }
    }
    static func clipped(_ planes: [Plane], in bounds: Rect) -> [Plane] {
        planes.filter { $0.path.intersects(bounds) }
    }
    static func clipped(_ texts: [Text], in bounds: Rect) -> [Text] {
        texts.filter { bounds.contains($0.origin) }
    }
    
    func color(at p: Point) -> UUColor {
        if let plane = picture.planes.reversed().first(where: { $0.path.contains(p) }) {
            return plane.uuColor
        } else {
            return backgroundUUColor
        }
    }
    
    var allTextsString: String {
        let strings = texts
            .sorted(by: { $0.origin.y == $1.origin.y ? $0.origin.x < $1.origin.x : $0.origin.y > $1.origin.y })
            .map { $0.string }
        var str = ""
        str += "((\(mainFrame.minX.shortString), \(mainFrame.minY.shortString)) (\(mainFrame.size.width.shortString) x \(mainFrame.size.height.shortString)))"
        str += "\n\n\n"
        var tempos = Set<Rational>()
        if animation.enabled { tempos.insert(animation.tempo) }
        if score.enabled { tempos.insert(score.tempo) }
        texts.forEach {
            if let tempo = $0.timeOption?.tempo { tempos.insert(tempo) }
        }
        contents.forEach {
            if let tempo = $0.timeOption?.tempo { tempos.insert(tempo) }
        }
        for tempo in tempos {
            str += "\(tempo) bpm, \(Self.tempoNameFromStandardFrameRate(withTempo: tempo))\n"
        }
        str += "\n\n\n"
        if score.enabled {
            score.scales.forEach { str += "\($0) " }
        }
        str += "\n\n\n"
        var ids = Set<UUID>()
        for plane in picture.planes {
            ids.insert(plane.uuColor.id)
        }
        for plane in draftPicture.planes {
            ids.insert(plane.uuColor.id)
        }
        for id in ids {
            str += id.uuidString
            str += "\n"
        }
        str += "\n\n\n"
        for nstr in strings {
            str += nstr
            str += "\n\n\n"
        }
        return str
    }
    
    func node(isBorder: Bool, isBackground: Bool = true,
              attitude: Attitude = .init(),
              in bounds: Rect) -> CPUNode {
        node(isBorder: isBorder, picture: picture, draftPicture: draftPicture,
             isBackground: isBackground,
             attitude: attitude,
             in: bounds)
    }
    
    func node(isBorder: Bool, atKeyframe ki: Int?,
              isBackground: Bool = true,
              attitude: Attitude = .init(),
              in bounds: Rect) -> CPUNode {
        let k = ki != nil ? animation.keyframes[ki!] : nil
        return node(isBorder: isBorder, captionNodes: [],
                    picture: k?.picture ?? .init(), draftPicture: k?.draftPicture ?? .init(),
                    isBackground: isBackground,
                    attitude: attitude,
                    in: bounds)
    }
    func node(isBorder: Bool, atSec sec: Rational,
              enabledCaption: Bool, renderingCaptionFrame: Rect? = nil,
              isBackground: Bool = true,
              attitude: Attitude = .init(),
              in bounds: Rect) -> CPUNode {
        let rootBeat = animation.beat(fromSec: sec)
        
        let captionNodes: [CPUNode] = if enabledCaption {
            Caption.cpuNodes(in: renderingCaptionFrame ?? bounds,
                             from: captions(atSec: sec))
        } else {
            []
        }
        
        let k = animation.keyframe(atRootBeat: rootBeat)
        return node(isBorder: isBorder, captionNodes: captionNodes,
                    picture: k?.picture ?? .init(), draftPicture: k?.draftPicture ?? .init(),
                    isBackground: isBackground,
                    attitude: attitude,
                    in: bounds)
    }
    func node(isBorder: Bool, captionNodes: [CPUNode] = [],
              picture: Picture, draftPicture: Picture,
              isBackground: Bool,
              attitude: Attitude = .init(),
              in bounds: Rect) -> CPUNode {
        let lineNodes = picture.lines.map { $0.cpuNode }
        let planeNodes = picture.planes.map { $0.cpuNode }
        let textNodes = texts.map { $0.cpuNode }
        let borderNodes = isBorder ? borders.map { $0.cpuNode(with: bounds) } : []
        
        let draftPlaneNodes: [CPUNode] = if !draftPicture.planes.isEmpty {
            draftPicture.planes.map {
                $0.cpuNode(from: $0.uuColor.value.with(opacity: $0.uuColor.value.opacity * 0.075))
            }
        } else {
            []
        }
        
        let draftLineNodes: [CPUNode] = if !draftPicture.lines.isEmpty {
            [CPUNode(children: draftPicture.lines.map { $0.cpuNode(from: .background,
                                                                   isDrawLineAntialias: true) },
                     path: .init(bounds),
                     fillType: .color(.draftLine),
                     isClippingChildrenLines: true)]
        } else {
            []
        }
        
        let children0 = draftPlaneNodes + draftLineNodes
        let children1 = planeNodes + lineNodes
        let children2 = textNodes + borderNodes + captionNodes
        if isBackground {
            return .init(children: children0 + children1 + children2,
                         attitude: attitude,
                         path: Path(bounds),
                         fillType: .color(backgroundUUColor.value))
        } else{
            return .init(children: children0 + children1 + children2,
                         attitude: attitude,
                         path: Path(bounds))
        }
    }
    
    var animationEndBeat: Rational {
        animation.enabled ? animation.beatRange.end + animation.loopDurBeat : 0
    }
    var animationEndSec: Rational {
        animation.enabled ? animation.secRange.end + animation.loopDurSec : 0
    }
    
    var musicEndBeat: Rational {
        var v = Rational(0)
        if score.enabled {
            v = max(v, score.allBeatRange.end)
        }
        v = contents.reduce(into: v) {
            if let timeOption = $1.timeOption {
                $0 = max($0, timeOption.beatRange.end)
            }
        }
        v = texts.reduce(into: v) {
            if let timeOption = $1.timeOption {
                $0 = max($0, timeOption.beatRange.end)
            }
        }
        return v
    }
    var musicEndSec: Rational {
        var v = Rational(0)
        if score.enabled {
            v = max(v, score.allSecRange.end)
        }
        v = contents.reduce(into: v) {
            if let timeOption = $1.timeOption {
                $0 = max($0, timeOption.secRange.end)
            }
        }
        v = texts.reduce(into: v) {
            if let timeOption = $1.timeOption {
                $0 = max($0, timeOption.secRange.end)
            }
        }
        return v
    }
    
    var isEnabledAudio: Bool {
        score.enabled || contents.contains { $0.type.isAudio }
    }
    var audiotrack: Audiotrack {
        .init(values: (score.enabled ? [.score(score)] : [])
              + contents.compactMap { $0.type.isAudio ? .sound($0) : nil })
    }
    var pcmBuffer: PCMBuffer? {
        let audiotrack = audiotrack
        if !audiotrack.isEmpty {
            let sequencer = Sequencer(audiotracks: [audiotrack], type: .normal)
            return try? sequencer.buffer(sampleRate: Audio.defaultSampleRate) { _ in }
        }
        return nil
    }
    
    var captions: [Caption] {
        texts.compactMap {
            if let timeOption = $0.timeOption {
                Caption(string: $0.string, origin: $0.origin, orientation: $0.orientation,
                        isTitle: $0.typobute.font.isProportional,
                        secRange: timeOption.secRange)
            } else {
                nil
            }
        }.sorted {
            $0.secRange.start < $1.secRange.start
        }
    }
    func captions(atSec sec: Rational) -> [Caption] {
        Caption.captions(atSec: sec, in: captions)
    }
    
    var allEndBeat: Rational {
        max(animationEndBeat, musicEndBeat)
    }
    var allBeatRange: Range<Rational> { 0 ..< allEndBeat }
    var allEndSec: Rational {
        max(animationEndSec, musicEndSec)
    }
    var allSecRange: Range<Rational> { 0 ..< allEndSec }
    
    init(message: String, in bounds: Rect = Sheet.defaultBounds) {
        var text = Text(string: message)
        if let textBounds = text.bounds {
            text.origin = bounds.centerPoint - textBounds.centerPoint
        }
        self.init(texts: [text])
    }
    
    static func snappableBorderLocations(from orientation: Orientation,
                                         with sb: Rect) -> [Double] {
        switch orientation {
        case .horizontal:
            [((sb.height - sb.width / 2.0.squareRoot()) / 2).rounded(),
             (sb.height - (sb.height - sb.width / 2.0.squareRoot()) / 2).rounded()].sorted()
        case .vertical:
            [((sb.width - sb.height / 2.0.squareRoot()) / 2).rounded(),
             (sb.width - (sb.width - sb.height / 2.0.squareRoot()) / 2).rounded()].sorted()
        }
    }
    static func borderSnappedPoint(_ p: Point, with sb: Rect, distance d: Double,
                                   oldBorder: Border) -> (isSnapped: Bool,
                                                          point: Point) {
        func snapped(_ v: Double, values: [Double]) -> (Bool, Double) {
            for value in values {
                if v > value - d && v < value + d {
                    return (true, value)
                }
            }
            if oldBorder.location != 0 {
                let value = oldBorder.location
                if v > value - d && v < value + d {
                    return (true, value)
                }
            }
            return (false, v)
        }
        switch oldBorder.orientation {
        case .horizontal:
            let values = snappableBorderLocations(from: oldBorder.orientation,
                                                  with: sb)
            let (iss, y) = snapped(p.y, values: values)
            return (iss, Point(p.x, y).rounded())
        case .vertical:
            let values = snappableBorderLocations(from: oldBorder.orientation,
                                                  with: sb)
            let (iss, x) = snapped(p.x, values: values)
            return (iss, Point(x, p.y).rounded())
        }
    }
}
extension Sheet {
    var option: SheetOption {
        get {
            .init(mainFrame: mainFrame)
        }
        set {
            mainFrame = newValue.mainFrame
        }
    }
}

typealias SheetHistory = History<SheetUndoItem>
extension Sheet {
    func undoItemValue(with result: SheetHistory.UndoResult,
                       reverses: inout [Version: Int],
                       in history: inout SheetHistory) -> UndoItemValue<SheetUndoItem>? {
        if result.item.loadType == .unload {
            _ = history[result.version].values[result.valueIndex].loadRedoItem()
            loadCheck(with: result, reverses: &reverses, in: &history)
            return history[result.version].values[result.valueIndex].undoItemValue
        } else {
            return result.item.undoItemValue
        }
    }
    func loadCheck(with result: SheetHistory.UndoResult,
                   reverses: inout [Version: Int],
                   in history: inout SheetHistory) {
        guard let uiv = history[result.version].values[result.valueIndex]
                .undoItemValue else { return }
        
        let isUndo = result.type == .undo
        let reversedType: UndoType = isUndo ? .redo : .undo
        
        func updateFirstReverse() {
            if enabledAnimation {
                if !history[result.version].isFirstReverse {
                    history[result.version].isFirstReverse = true
                }
                if case .setRootKeyframeIndex? =  history[result.version].values.first?.loadedRedoItem()?.undoItem {
                    
                } else {
                    reverses[result.version] = animation.rootIndex
                    print("first reverse error")
                }
            }
        }
        switch isUndo ? uiv.redoItem : uiv.undoItem {
        case .appendLine(let line):
            updateFirstReverse()
            if let lastLine = picture.lines.last {
                if lastLine != line {
                    history[result.version].values[result.valueIndex]
                        .saveUndoItemValue?.set(.appendLine(lastLine), type: reversedType)
                }
            } else {
                history[result.version].values[result.valueIndex].error()
            }
        case .appendLines(let lines):
            updateFirstReverse()
            let di = picture.lines.count - lines.count
            if di >= 0 {
                let lastLines = Array(picture.lines[di...])
                if lastLines != lines {
                    history[result.version].values[result.valueIndex]
                        .saveUndoItemValue?.set(.appendLines(lastLines), type: reversedType)
                }
            } else {
                history[result.version].values[result.valueIndex].error()
            }
        case .appendPlanes(let planes):
            updateFirstReverse()
            let di = picture.planes.count - planes.count
            if di >= 0 {
                let lastPlanes = Array(picture.planes[di...])
                if lastPlanes != planes {
                    history[result.version].values[result.valueIndex]
                        .saveUndoItemValue?.set(.appendPlanes(lastPlanes),
                                                type: reversedType)
                }
            } else {
                history[result.version].values[result.valueIndex].error()
            }
        case .removeLastLines:
            updateFirstReverse()
        case .removeLastPlanes:
            updateFirstReverse()
        case .insertLines(let livs):
            updateFirstReverse()
            let maxI = livs.max { $0.index < $1.index }?.index
            if let maxI = maxI, maxI < picture.lines.count {
                let oldLIVS = livs.map { IndexValue(value: picture.lines[$0.index],
                                                    index: $0.index) }
                if oldLIVS != livs {
                    history[result.version].values[result.valueIndex]
                        .saveUndoItemValue?.set(.insertLines(oldLIVS), type: reversedType)
                }
            } else {
                history[result.version].values[result.valueIndex].error()
            }
        case .insertPlanes(let pivs):
            updateFirstReverse()
            let maxI = pivs.max { $0.index < $1.index }?.index
            if let maxI = maxI, maxI < picture.planes.count {
                let oldPIVS = pivs.map { IndexValue(value: picture.planes[$0.index],
                                                    index: $0.index) }
                if oldPIVS != pivs {
                    history[result.version].values[result.valueIndex]
                        .saveUndoItemValue?.set(.insertPlanes(oldPIVS), type: reversedType)
                }
            } else {
                history[result.version].values[result.valueIndex].error()
            }
        case .replaceLines(let livs):
            updateFirstReverse()
            let lines = picture.lines
            for liv in livs {
                if liv.index >= lines.count || liv.value != lines[liv.index] {
                    history.error(result)
                    break
                }
            }
        case .replacePlanes(let pivs):
            updateFirstReverse()
            let planes = picture.planes
            for piv in pivs {
                if piv.index >= planes.count || piv.value != planes[piv.index] {
                    history.error(result)
                    break
                }
            }
        case .removeLines(let lineIndexes):
            updateFirstReverse()
            let oldLIS = lineIndexes.filter { $0 < picture.lines.count + lineIndexes.count }.sorted()
            if oldLIS != lineIndexes {
                history[result.version].values[result.valueIndex]
                    .saveUndoItemValue?.set(.removeLines(lineIndexes: oldLIS), type: reversedType)
            }
        case .removePlanes(let planeIndexes):
            updateFirstReverse()
            let oldPIS = planeIndexes.filter { $0 < picture.planes.count + planeIndexes.count }.sorted()
            if oldPIS != planeIndexes {
                history[result.version].values[result.valueIndex]
                    .saveUndoItemValue?.set(.removePlanes(planeIndexes: oldPIS), type: reversedType)
            }
        case .setPlaneValue(let planeValue):
            updateFirstReverse()
            func error() {
                history[result.version]
                    .values[result.valueIndex].error()
            }
            if planeValue.planes.count + planeValue.moveIndexValues.count
                == picture.planes.count {
                
                var isArray = Array(repeating: false,
                                    count: picture.planes.count)
                for v in planeValue.moveIndexValues {
                    if v.index < isArray.count {
                        isArray[v.index] = true
                    } else {
                        error()
                    }
                }
                var i = 0
                for (j, isMoved) in isArray.enumerated() {
                    if !isMoved {
                        if i < planeValue.planes.count
                            && planeValue.planes[i] != picture.planes[j] {
                            
                            error()
                            break
                        }
                        i += 1
                    }
                }
            } else {
                error()
            }
        case .changeToDraft:
            updateFirstReverse()
        case .setPicture(let picture):
            updateFirstReverse()
            if self.picture != picture {
                history[result.version].values[result.valueIndex]
                    .saveUndoItemValue?.set(.setPicture(self.picture), type: reversedType)
            }
        case .insertDraftLines(let livs):
            updateFirstReverse()
            let maxI = livs.max { $0.index < $1.index }?.index
            if let maxI = maxI, maxI < draftPicture.lines.count {
                let oldLIVS = livs.map { IndexValue(value: draftPicture.lines[$0.index],
                                                    index: $0.index) }
                if oldLIVS != livs {
                    history[result.version].values[result.valueIndex]
                        .saveUndoItemValue?.set(.insertDraftLines(oldLIVS), type: reversedType)
                }
            } else {
                history[result.version].values[result.valueIndex].error()
            }
        case .insertDraftPlanes(let pivs):
            updateFirstReverse()
            let maxI = pivs.max { $0.index < $1.index }?.index
            if let maxI = maxI, maxI < draftPicture.planes.count {
                let oldPIVS = pivs.map { IndexValue(value: draftPicture.planes[$0.index],
                                                    index: $0.index) }
                if oldPIVS != pivs {
                    history[result.version].values[result.valueIndex]
                        .saveUndoItemValue?.set(.insertDraftPlanes(oldPIVS), type: reversedType)
                }
            } else {
                history[result.version].values[result.valueIndex].error()
            }
        case .removeDraftLines(let lineIndexes):
            updateFirstReverse()
            let oldLIS = lineIndexes.filter { $0 < draftPicture.lines.count + lineIndexes.count }.sorted()
            if oldLIS != lineIndexes {
                history[result.version].values[result.valueIndex]
                    .saveUndoItemValue?.set(.removeDraftLines(lineIndexes: oldLIS), type: reversedType)
            }
        case .removeDraftPlanes(let planeIndexes):
            updateFirstReverse()
            let oldPIS = planeIndexes.filter { $0 < draftPicture.planes.count + planeIndexes.count }.sorted()
            if oldPIS != planeIndexes {
                history[result.version].values[result.valueIndex]
                    .saveUndoItemValue?.set(.removeDraftPlanes(planeIndexes: oldPIS), type: reversedType)
            }
        case .setDraftPicture(let draftPicture):
            updateFirstReverse()
            if self.draftPicture != draftPicture {
                history[result.version].values[result.valueIndex]
                    .saveUndoItemValue?.set(.setDraftPicture(self.draftPicture),
                                            type: reversedType)
            }
        case .insertTexts(let tivs):
            updateFirstReverse()
            let maxI = tivs.max { $0.index < $1.index }?.index
            if let maxI = maxI, maxI < texts.count {
                let oldTIVS = tivs.map { IndexValue(value: texts[$0.index],
                                                    index: $0.index) }
                if oldTIVS != tivs {
                    history[result.version].values[result.valueIndex]
                        .saveUndoItemValue?.set(.insertTexts(oldTIVS), type: reversedType)
                }
            } else {
                history[result.version].values[result.valueIndex].error()
            }
        case .replaceTexts(let tivs):
            updateFirstReverse()
            for tiv in tivs {
                if tiv.index >= texts.count || tiv.value != texts[tiv.index] {
                    history.error(result)
                    break
                }
            }
        case .removeTexts(let textIndexes):
            updateFirstReverse()
            let oldTIS = textIndexes.filter { $0 < texts.count + textIndexes.count }.sorted()
            if oldTIS != textIndexes {
                history[result.version].values[result.valueIndex]
                    .saveUndoItemValue?.set(.removeTexts(textIndexes: oldTIS), type: reversedType)
            }
        case .replaceString(let tuiv):
            updateFirstReverse()
            guard tuiv.index < texts.count else {
                history[result.version]
                    .values[result.valueIndex].error()
                break
            }
            let text = texts[tuiv.index]
            let intRange = tuiv.value.newRange
            if intRange.lowerBound >= 0
                && intRange.upperBound <= text.string.count {
                
                let range = text.string.range(fromInt: intRange)
                let oldString = text.string[range]
                let oldOrigin = tuiv.value.origin != nil ? text.origin : nil
                let oldSize = tuiv.value.size != nil ? text.size : nil
                let oldWidthCount
                = tuiv.value.widthCount != nil ? text.widthCount : nil
                if oldString != tuiv.value.string
                    || oldOrigin != tuiv.value.origin
                    || oldSize != tuiv.value.size
                    || oldWidthCount != tuiv.value.widthCount {
                    
                    let nOrigin = oldOrigin != tuiv.value.origin ?
                        oldOrigin : tuiv.value.origin
                    let nSize = oldSize != tuiv.value.size ?
                        oldSize : tuiv.value.size
                    let nWidthCount = oldWidthCount != tuiv.value.widthCount ?
                        oldWidthCount : tuiv.value.widthCount
                    let tv = TextValue(string: String(oldString),
                                       replacedRange: tuiv.value.replacedRange,
                                       origin: nOrigin, size: nSize,
                                       widthCount: nWidthCount)
                    let nTUIV = IndexValue(value: tv, index: tuiv.index)
                    history[result.version].values[result.valueIndex]
                        .saveUndoItemValue?.set(.replaceString(nTUIV), type: reversedType)
                }
            } else {
                history[result.version]
                    .values[result.valueIndex].error()
            }
        case .changedColors(let colorUndoValue):
            updateFirstReverse()
            func error() {
                history[result.version]
                    .values[result.valueIndex].error()
            }
            
            if !colorUndoValue.planeIndexes.isEmpty {
                let maxPISI = colorUndoValue.planeIndexes.max { $0 < $1 }
                if let maxPISI = maxPISI, maxPISI < picture.planes.count {
                    for i in colorUndoValue.planeIndexes {
                        if picture.planes[i].uuColor != colorUndoValue.uuColor {
                            error()
                            break
                        }
                    }
                } else {
                    error()
                }
            } else if !colorUndoValue.planeAnimationIndexes.isEmpty {
                loop: for k in colorUndoValue.planeAnimationIndexes {
                    if k.index >= animation.keyframes.count {
                        error()
                        break loop
                    }
                    let planes = animation.keyframes[k.index].picture.planes
                    for pi in k.value {
                        if pi >= planes.count {
                            error()
                            break loop
                        }
                        if planes[pi].uuColor != colorUndoValue.uuColor {
                            error()
                            break loop
                        }
                    }
                }
            }
            
            if !colorUndoValue.lineIndexes.isEmpty {
                let maxLISI = colorUndoValue.lineIndexes.max { $0 < $1 }
                if let maxLISI, maxLISI < picture.lines.count {
                    for i in colorUndoValue.lineIndexes {
                        if picture.lines[i].uuColor != colorUndoValue.uuColor {
                            error()
                            break
                        }
                    }
                } else {
                    error()
                }
            } else if !colorUndoValue.lineAnimationIndexes.isEmpty {
                loop: for k in colorUndoValue.lineAnimationIndexes {
                    if k.index >= animation.keyframes.count {
                        error()
                        break loop
                    }
                    let lines = animation.keyframes[k.index].picture.lines
                    for li in k.value {
                        if li >= lines.count {
                            error()
                            break loop
                        }
                        if lines[li].uuColor != colorUndoValue.uuColor {
                            error()
                            break loop
                        }
                    }
                }
            }
            
            if colorUndoValue.isBackground && backgroundUUColor != colorUndoValue.uuColor {
                error()
            }
        case .insertBorders(let bivs):
            updateFirstReverse()
            let maxI = bivs.max { $0.index < $1.index }?.index
            if let maxI = maxI, maxI < borders.count {
                let oldBIVS = bivs.map { IndexValue(value: borders[$0.index],
                                                    index: $0.index) }
                if oldBIVS != bivs {
                    history[result.version].values[result.valueIndex]
                        .saveUndoItemValue?.set(.insertBorders(oldBIVS), type: reversedType)
                }
            } else {
                history[result.version]
                    .values[result.valueIndex].error()
            }
        case .removeBorders(let borderIndexes):
            updateFirstReverse()
            let oldBIS = borderIndexes.filter { $0 < borders.count + borderIndexes.count }.sorted()
            if oldBIS != borderIndexes {
                history[result.version].values[result.valueIndex]
                    .saveUndoItemValue?.set(.removeBorders(borderIndexes: oldBIS), type: reversedType)
            }
        case .setRootKeyframeIndex(_): break
        case .insertKeyframes(let kivs):
            let maxI = kivs.max { $0.index < $1.index }?.index
            if let maxI = maxI, maxI < animation.keyframes.count {
                let oldKIVS = kivs.map { IndexValue(value: animation.keyframes[$0.index],
                                                    index: $0.index) }
                if oldKIVS != kivs {
                    history[result.version].values[result.valueIndex]
                        .saveUndoItemValue?.set(.insertKeyframes(oldKIVS), type: reversedType)
                }
            } else {
                history[result.version]
                    .values[result.valueIndex].error()
            }
        case .removeKeyframes(let indexes):
            let oldKIS = indexes.filter { $0 < animation.keyframes.count + indexes.count }.sorted()
            if oldKIS != indexes {
                history[result.version].values[result.valueIndex]
                    .saveUndoItemValue?.set(.removeKeyframes(keyframeIndexes: oldKIS), type: reversedType)
            }
        case .setKeyframeOptions(let koivs):
            var isError = false
            for koiv in koivs {
                if koiv.index >= animation.keyframes.count {
                    isError = true
                }
            }
            if isError {
                history[result.version]
                    .values[result.valueIndex].error()
            } else {
                let okoivs = koivs.map {
                    IndexValue(value: animation.keyframes[$0.index].option,
                               index: $0.index)
                }
                if okoivs != koivs {
                    history[result.version].values[result.valueIndex]
                        .saveUndoItemValue?
                        .set(.setKeyframeOptions(okoivs), type: reversedType)
                }
            }
            
        case .insertKeyLines(let kvs):
            updateFirstReverse()
            func error() {
                history[result.version]
                    .values[result.valueIndex].error()
            }
            loop: for k in kvs {
                if k.index >= animation.keyframes.count {
                    error()
                    break loop
                }
                let lines = animation.keyframes[k.index].picture.lines
                let maxI = k.value.max { $0.index < $1.index }?.index
                if let maxI = maxI, maxI < lines.count {
                    let oldLIVS = k.value.map { IndexValue(value: lines[$0.index],
                                                           index: $0.index) }
                    if oldLIVS != k.value {
                        error()
                        break loop
                    }
                } else {
                    error()
                    break loop
                }
            }
        case .replaceKeyLines(let kvs):
            updateFirstReverse()
            func error() {
                history[result.version]
                    .values[result.valueIndex].error()
            }
            loop: for k in kvs {
                if k.index >= animation.keyframes.count {
                    error()
                    break loop
                }
                let lines = animation.keyframes[k.index].picture.lines
                for liv in k.value {
                    if liv.index >= lines.count {
                        error()
                        break loop
                    }
                    if liv.value != lines[liv.index] {
                        error()
                        break loop
                    }
                }
            }
        case .removeKeyLines(let iivs):
            updateFirstReverse()
            func error() {
                history[result.version]
                    .values[result.valueIndex].error()
            }
            loop: for k in iivs {
                if k.index >= animation.keyframes.count {
                    error()
                    break loop
                }
                let lines = animation.keyframes[k.index].picture.lines
                let oldLIS = k.value.filter { $0 < lines.count + k.value.count }.sorted()
                if oldLIS != k.value {
                    error()
                    break loop
                }
            }
            
        case .insertKeyPlanes(let kvs):
            updateFirstReverse()
            func error() {
                history[result.version]
                    .values[result.valueIndex].error()
            }
            loop: for k in kvs {
                if k.index >= animation.keyframes.count {
                    error()
                    break loop
                }
                let planes = animation.keyframes[k.index].picture.planes
                let maxI = k.value.max { $0.index < $1.index }?.index
                if let maxI = maxI, maxI < planes.count {
                    let oldPIVS = k.value.map { IndexValue(value: planes[$0.index],
                                                           index: $0.index) }
                    if oldPIVS != k.value {
                        error()
                        break loop
                    }
                } else {
                    error()
                    break loop
                }
            }
        case .replaceKeyPlanes(let kvs):
            updateFirstReverse()
            func error() {
                history[result.version]
                    .values[result.valueIndex].error()
            }
            loop: for k in kvs {
                if k.index >= animation.keyframes.count {
                    error()
                    break loop
                }
                let planes = animation.keyframes[k.index].picture.planes
                for piv in k.value {
                    if piv.index >= planes.count {
                        error()
                        break loop
                    }
                    if piv.value != planes[piv.index] {
                        error()
                        break loop
                    }
                }
            }
        case .removeKeyPlanes(let iivs):
            updateFirstReverse()
            func error() {
                history[result.version]
                    .values[result.valueIndex].error()
            }
            loop: for k in iivs {
                if k.index >= animation.keyframes.count {
                    error()
                    break loop
                }
                let planes = animation.keyframes[k.index].picture.planes
                let oldPIS = k.value.filter { $0 < planes.count + k.value.count }.sorted()
                if oldPIS != k.value {
                    error()
                    break loop
                }
            }
            
        case .insertDraftKeyLines(let kvs):
            updateFirstReverse()
            func error() {
                history[result.version]
                    .values[result.valueIndex].error()
            }
            loop: for k in kvs {
                if k.index >= animation.keyframes.count {
                    error()
                    break loop
                }
                let lines = animation.keyframes[k.index].draftPicture.lines
                let maxI = k.value.max { $0.index < $1.index }?.index
                if let maxI = maxI, maxI < lines.count {
                    let oldLIVS = k.value.map { IndexValue(value: lines[$0.index],
                                                           index: $0.index) }
                    if oldLIVS != k.value {
                        error()
                        break loop
                    }
                } else {
                    error()
                    break loop
                }
            }
        case .removeDraftKeyLines(let iivs):
            updateFirstReverse()
            func error() {
                history[result.version]
                    .values[result.valueIndex].error()
            }
            loop: for k in iivs {
                if k.index >= animation.keyframes.count {
                    error()
                    break loop
                }
                let lines = animation.keyframes[k.index].draftPicture.lines
                let oldLIS = k.value.filter { $0 < lines.count + k.value.count }.sorted()
                if oldLIS != k.value {
                    error()
                    break loop
                }
            }
            
        case .insertDraftKeyPlanes(let kvs):
            updateFirstReverse()
            func error() {
                history[result.version]
                    .values[result.valueIndex].error()
            }
            loop: for k in kvs {
                if k.index >= animation.keyframes.count {
                    error()
                    break loop
                }
                let planes = animation.keyframes[k.index].draftPicture.planes
                let maxI = k.value.max { $0.index < $1.index }?.index
                if let maxI = maxI, maxI < planes.count {
                    let oldPIVS = k.value.map { IndexValue(value: planes[$0.index],
                                                           index: $0.index) }
                    if oldPIVS != k.value {
                        error()
                        break loop
                    }
                } else {
                    error()
                    break loop
                }
            }
        case .removeDraftKeyPlanes(let iivs):
            updateFirstReverse()
            func error() {
                history[result.version]
                    .values[result.valueIndex].error()
            }
            loop: for k in iivs {
                if k.index >= animation.keyframes.count {
                    error()
                    break loop
                }
                let planes = animation.keyframes[k.index].draftPicture.planes
                let oldPIS = k.value.filter { $0 < planes.count + k.value.count }.sorted()
                if oldPIS != k.value {
                    error()
                    break loop
                }
            }
            
        case .setLineIDs(let kvs):
            updateFirstReverse()
            func error() {
                history[result.version]
                    .values[result.valueIndex].error()
            }
            loop: for k in kvs {
                if k.index >= animation.keyframes.count {
                    error()
                    break loop
                }
                let lines = animation.keyframes[k.index].picture.lines
                for liv in k.value {
                    if liv.index >= lines.count {
                        error()
                        break loop
                    }
                    if liv.value != lines[liv.index].interOption {
                        error()
                        break loop
                    }
                }
            }
            
        case .setAnimationOption(let option):
            let oldOption = animation.option
            if oldOption != option {
                history[result.version].values[result.valueIndex]
                    .saveUndoItemValue?.set(.setAnimationOption(oldOption), type: reversedType)
            }
            
        case .insertNotes(let nivs):
            updateFirstReverse()
            let maxI = nivs.max { $0.index < $1.index }?.index
            if let maxI = maxI, maxI < score.notes.count {
                let oldNIVS = nivs.map { IndexValue(value: score.notes[$0.index],
                                                    index: $0.index) }
                if oldNIVS != nivs {
                    print("InsertNotesUndoError", score.notes.count, oldNIVS.count, nivs.count, oldNIVS, nivs)
                    history[result.version].values[result.valueIndex]
                        .saveUndoItemValue?.set(.insertNotes(oldNIVS), type: reversedType)
                }
            } else {
                history[result.version]
                    .values[result.valueIndex].error()
            }
        case .replaceNotes(let nivs):
            updateFirstReverse()
            func error() {
                history[result.version]
                    .values[result.valueIndex].error()
            }
            let notes = score.notes
            for niv in nivs {
                if niv.index >= notes.count {
                    error()
                    break
                }
                if niv.value != notes[niv.index] {
                    error()
                    break
                }
            }
        case .removeNotes(let noteIndexes):
            updateFirstReverse()
            let oldNIS = noteIndexes.filter { $0 < score.notes.count + noteIndexes.count }.sorted()
            if oldNIS != noteIndexes {
                history[result.version].values[result.valueIndex]
                    .saveUndoItemValue?.set(.removeNotes(noteIndexes: oldNIS), type: reversedType)
            }
        case .insertDraftNotes(let nivs):
            updateFirstReverse()
            let maxI = nivs.max { $0.index < $1.index }?.index
            if let maxI = maxI, maxI < score.notes.count {
                let oldNIVS = nivs.map { IndexValue(value: score.notes[$0.index],
                                                    index: $0.index) }
                if oldNIVS != nivs {
                    history[result.version].values[result.valueIndex]
                        .saveUndoItemValue?.set(.insertDraftNotes(oldNIVS), type: reversedType)
                }
            } else {
                history[result.version].values[result.valueIndex].error()
            }
        case .removeDraftNotes(let noteIndexes):
            updateFirstReverse()
            let oldNIS = noteIndexes.filter { $0 < score.notes.count + noteIndexes.count }.sorted()
            if oldNIS != noteIndexes {
                history[result.version].values[result.valueIndex]
                    .saveUndoItemValue?.set(.removeDraftNotes(noteIndexes: oldNIS), type: reversedType)
            }
        case .insertContents(let civs):
            updateFirstReverse()
            let maxI = civs.max { $0.index < $1.index }?.index
            if let maxI = maxI, maxI < contents.count {
                let oldCIVS = civs.map { IndexValue(value: contents[$0.index],
                                                    index: $0.index) }
                if oldCIVS != civs {
                    history[result.version].values[result.valueIndex]
                        .saveUndoItemValue?.set(.insertContents(oldCIVS), type: reversedType)
                }
            } else {
                history[result.version]
                    .values[result.valueIndex].error()
            }
        case .replaceContents(let civs):
            updateFirstReverse()
            let contents = contents
            for civ in civs {
                if civ.index >= contents.count || civ.value != contents[civ.index] {
                    history.error(result)
                    break
                }
            }
        case .removeContents(let contentIndexes):
            updateFirstReverse()
            let oldCIS = contentIndexes.filter { $0 < contents.count + contentIndexes.count }.sorted()
            if oldCIS != contentIndexes {
                history[result.version].values[result.valueIndex]
                    .saveUndoItemValue?.set(.removeContents(contentIndexes: oldCIS), type: reversedType)
            }
        case .setScoreOption(let option):
            let oldOption = score.option
            if oldOption != option {
                history[result.version].values[result.valueIndex]
                    .saveUndoItemValue?.set(.setScoreOption(oldOption), type: reversedType)
            }
        case .setSheetOption(let option):
            let oldOption = self.option
            if oldOption != option {
                history[result.version].values[result.valueIndex]
                    .saveUndoItemValue?.set(.setSheetOption(oldOption), type: reversedType)
            }
        case .setSelection(let selection):
            updateFirstReverse()
            
            let oldSelection = self.selection
            if selection != oldSelection {
                history[result.version].values[result.valueIndex]
                    .saveUndoItemValue?.set(.setSelection(oldSelection), type: reversedType)
            }
        }
        
        guard let nuiv = history[result.version].values[result.valueIndex]
                .undoItemValue else { return }
        switch isUndo ? nuiv.undoItem : nuiv.redoItem {
        case .appendLine(_):
            updateFirstReverse()
        case .appendLines(_):
            updateFirstReverse()
        case .appendPlanes(_):
            updateFirstReverse()
        case .removeLastLines(let count):
            updateFirstReverse()
            if count > picture.lines.count {
                history[result.version]
                    .values[result.valueIndex].saveUndoItemValue
                    = UndoItemValue(undoItem: .appendLines(picture.lines),
                                    redoItem: .removeLastLines(count: picture.lines.count),
                                    isReversed: isUndo)
            }
        case .removeLastPlanes(let count):
            updateFirstReverse()
            if count > picture.planes.count {
                history[result.version].values[result.valueIndex].saveUndoItemValue
                    = UndoItemValue(undoItem: .appendPlanes(picture.planes),
                                    redoItem: .removeLastPlanes(count: picture.planes.count),
                                    isReversed: isUndo)
            }
        case .insertLines(var livs):
            updateFirstReverse()
            var isChanged = false, linesCount = picture.lines.count
            livs.enumerated().forEach { (k, iv) in
                if iv.index > linesCount {
                    livs[k].index = linesCount
                    isChanged = true
                }
                linesCount += 1
            }
            if isChanged {
                history[result.version].values[result.valueIndex].saveUndoItemValue
                    = UndoItemValue(undoItem: .removeLines(lineIndexes: livs.map { $0.index }),
                                    redoItem: .insertLines(livs),
                                    isReversed: isUndo)
            }
        case .insertPlanes(var pivs):
            updateFirstReverse()
            var isChanged = false, planesCount = picture.planes.count
            pivs.enumerated().forEach { (k, iv) in
                if iv.index > planesCount {
                    pivs[k].index = planesCount
                    isChanged = true
                }
                planesCount += 1
            }
            if isChanged {
                history[result.version].values[result.valueIndex].saveUndoItemValue
                    = UndoItemValue(undoItem: .removePlanes(planeIndexes: pivs.map { $0.index }),
                                    redoItem: .insertPlanes(pivs),
                                    isReversed: isUndo)
            }
        case .replaceLines(let livs):
            updateFirstReverse()
            let lines = picture.lines
            if livs.contains(where: { $0.index >= lines.count }) {
                history.error(result)
            } else {
                let oldLIVs = livs.map { IndexValue(value: lines[$0.index], index: $0.index) }
                history.setReverse(.replaceLines(oldLIVs), with: result)
            }
        case .replacePlanes(let pivs):
            updateFirstReverse()
            let planes = picture.planes
            if pivs.contains(where: { $0.index >= planes.count }) {
                history.error(result)
            } else {
                let oldPIVs = pivs.map { IndexValue(value: planes[$0.index], index: $0.index) }
                history.setReverse(.replacePlanes(oldPIVs), with: result)
            }
        case .removeLines(var lineIndexes):
            updateFirstReverse()
            let lis = lineIndexes.filter { $0 < picture.lines.count }.sorted()
            if lineIndexes != lis {
                lineIndexes = lis
                let livs = lineIndexes.map {
                    IndexValue(value: picture.lines[$0], index: $0)
                }
                history[result.version].values[result.valueIndex].saveUndoItemValue
                    = UndoItemValue(undoItem: .insertLines(livs),
                                    redoItem: .removeLines(lineIndexes: lis),
                                    isReversed: isUndo)
            }
        case .removePlanes(var planeIndexes):
            updateFirstReverse()
            let pis = planeIndexes.filter { $0 < picture.planes.count }.sorted()
            if planeIndexes != pis {
                planeIndexes = pis
                let pivs = planeIndexes.map {
                    IndexValue(value: picture.planes[$0], index: $0)
                }
                history[result.version].values[result.valueIndex].saveUndoItemValue
                    = UndoItemValue(undoItem: .insertPlanes(pivs),
                                    redoItem: .removePlanes(planeIndexes: pis),
                                    isReversed: isUndo)
            }
        case .setPlaneValue(var planeValue):
            updateFirstReverse()
            var isChanged = false
            let oldPlanesCount = picture.planes.count
            if oldPlanesCount > 0 {
                for (i, v) in planeValue.moveIndexValues.enumerated() {
                    if v.value >= oldPlanesCount {
                        planeValue.moveIndexValues[i].value = oldPlanesCount - 1
                        isChanged = true
                    }
                }
            } else {
                planeValue.moveIndexValues = []
            }
            
            var planesCount = planeValue.planes.count
            planeValue.moveIndexValues.enumerated().forEach { (k, iv) in
                if iv.index > planesCount {
                    planeValue.moveIndexValues[k].index = planesCount
                    isChanged = true
                }
                planesCount += 1
            }
            
            var isArray = Array(repeating: false,
                                count: picture.planes.count)
            for v in planeValue.moveIndexValues {
                isArray[v.value] = true
            }
            let oldPlanes = picture.planes.enumerated().compactMap {
                isArray[$0.offset] ? nil : $0.element
            }
            let oldVs = planeValue.moveIndexValues
                .map { IndexValue(value: $0.index, index: $0.value) }
                .sorted { $0.index < $1.index }
            let oldPlaneValue = PlaneValue(planes: oldPlanes,
                                           moveIndexValues: oldVs)
            
            if isChanged {
                history[result.version].values[result.valueIndex].saveUndoItemValue
                    = UndoItemValue(undoItem: .setPlaneValue(oldPlaneValue),
                                    redoItem: .setPlaneValue(planeValue),
                                    isReversed: isUndo)
            } else {
                switch result.type {
                case .undo:
                    history[result.version].values[result.valueIndex]
                        .undoItemValue?.redoItem = .setPlaneValue(oldPlaneValue)
                case .redo:
                    history[result.version].values[result.valueIndex]
                        .undoItemValue?.undoItem = .setPlaneValue(oldPlaneValue)
                }
            }
        case .changeToDraft(_):
            updateFirstReverse()
        case .setPicture(_):
            updateFirstReverse()
            switch result.type {
            case .undo:
                history[result.version].values[result.valueIndex]
                    .undoItemValue?.redoItem = .setPicture(self.picture)
            case .redo:
                history[result.version].values[result.valueIndex]
                    .undoItemValue?.undoItem = .setPicture(self.picture)
            }
        case .insertDraftLines(var livs):
            updateFirstReverse()
            var isChanged = false, linesCount = draftPicture.lines.count
            livs.enumerated().forEach { (k, iv) in
                if iv.index > linesCount {
                    livs[k].index = linesCount
                    isChanged = true
                }
                linesCount += 1
            }
            if isChanged {
                history[result.version].values[result.valueIndex].saveUndoItemValue
                    = UndoItemValue(undoItem: .removeDraftLines(lineIndexes: livs.map { $0.index }),
                                    redoItem: .insertDraftLines(livs),
                                    isReversed: isUndo)
            }
        case .insertDraftPlanes(var pivs):
            updateFirstReverse()
            var isChanged = false, planesCount = draftPicture.planes.count
            pivs.enumerated().forEach { (k, iv) in
                if iv.index > planesCount {
                    pivs[k].index = planesCount
                    isChanged = true
                }
                planesCount += 1
            }
            if isChanged {
                history[result.version].values[result.valueIndex].saveUndoItemValue
                    = UndoItemValue(undoItem: .removeDraftPlanes(planeIndexes: pivs.map { $0.index }),
                                    redoItem: .insertDraftPlanes(pivs),
                                    isReversed: isUndo)
            }
        case .removeDraftLines(var lineIndexes):
            updateFirstReverse()
            let lis = lineIndexes.filter { $0 < draftPicture.lines.count }.sorted()
            if lineIndexes != lis {
                lineIndexes = lis
                let livs = lineIndexes.map {
                    IndexValue(value: draftPicture.lines[$0], index: $0)
                }
                history[result.version].values[result.valueIndex].saveUndoItemValue
                    = UndoItemValue(undoItem: .insertDraftLines(livs),
                                    redoItem: .removeDraftLines(lineIndexes: lis),
                                    isReversed: isUndo)
            }
        case .removeDraftPlanes(var planeIndexes):
            updateFirstReverse()
            let pis = planeIndexes.filter { $0 < draftPicture.planes.count }.sorted()
            if planeIndexes != pis {
                planeIndexes = pis
                let pivs = planeIndexes.map {
                    IndexValue(value: draftPicture.planes[$0], index: $0)
                }
                history[result.version].values[result.valueIndex].saveUndoItemValue
                    = UndoItemValue(undoItem: .insertDraftPlanes(pivs),
                                    redoItem: .removeDraftPlanes(planeIndexes: pis),
                                    isReversed: isUndo)
            }
        case .setDraftPicture(_):
            updateFirstReverse()
            switch result.type {
            case .undo:
                history[result.version].values[result.valueIndex]
                    .undoItemValue?.redoItem = .setDraftPicture(self.draftPicture)
            case .redo:
                history[result.version].values[result.valueIndex]
                    .undoItemValue?.undoItem = .setDraftPicture(self.draftPicture)
            }
        case .insertTexts(var tivs):
            updateFirstReverse()
            var isChanged = false, textsCount = texts.count
            tivs.enumerated().forEach { (k, iv) in
                if iv.index > textsCount {
                    tivs[k].index = textsCount
                    isChanged = true
                }
                textsCount += 1
            }
            if isChanged {
                history[result.version].values[result.valueIndex].saveUndoItemValue
                    = UndoItemValue(undoItem: .removeTexts(textIndexes: tivs.map { $0.index }),
                                    redoItem: .insertTexts(tivs),
                                    isReversed: isUndo)
            }
        case .replaceTexts(let tivs):
            updateFirstReverse()
            if tivs.contains(where: { $0.index >= texts.count }) {
                history.error(result)
            } else {
                let oldTIVs = tivs.map { IndexValue(value: texts[$0.index], index: $0.index) }
                history.setReverse(.replaceTexts(oldTIVs), with: result)
            }
        case .removeTexts(var textIndexes):
            updateFirstReverse()
            let tis = textIndexes.filter { $0 < texts.count }.sorted()
            if textIndexes != tis {
                textIndexes = tis
                let tivs = textIndexes.map {
                    IndexValue(value: texts[$0], index: $0)
                }
                history[result.version].values[result.valueIndex].saveUndoItemValue
                    = UndoItemValue(undoItem: .insertTexts(tivs),
                                    redoItem: .removeTexts(textIndexes: tis),
                                    isReversed: isUndo)
            }
        case .replaceString(var tuiv):
            updateFirstReverse()
            guard !texts.isEmpty else {
                history[result.version]
                    .values[result.valueIndex].error()
                break
            }
            var isChanged = false
            if tuiv.index >= texts.count {
                tuiv.index = texts.count - 1
                isChanged = true
            }
            let oldString = texts[tuiv.index].string
            if tuiv.value.replacedRange.lowerBound < 0 {
                tuiv.value.replacedRange
                    = 0 ..< tuiv.value.replacedRange.upperBound
                isChanged = true
            }
            if tuiv.value.replacedRange.lowerBound > oldString.count {
                tuiv.value.replacedRange
                    = oldString.count ..< oldString.count
                isChanged = true
            }
            if tuiv.value.replacedRange.upperBound > oldString.count {
                tuiv.value.replacedRange
                    = tuiv.value.replacedRange.lowerBound ..< oldString.count
                isChanged = true
            }
            let oldRange = tuiv.value.newRange
            let oldOrigin = tuiv.value.origin != nil ?
                texts[tuiv.index].origin : nil
            let oldSize = tuiv.value.size != nil ?
                texts[tuiv.index].size : nil
            let oldWidthCount = tuiv.value.widthCount != nil ?
                texts[tuiv.index].widthCount : nil
            let nRange = oldString.range(fromInt: tuiv.value.replacedRange)
            let nString = String(oldString[nRange])
            let tv = TextValue(string: nString,
                               replacedRange: oldRange,
                               origin: oldOrigin, size: oldSize,
                               widthCount: oldWidthCount)
            let tiv = IndexValue(value: tv, index: tuiv.index)
            if isChanged {
                history[result.version]
                    .values[result.valueIndex].saveUndoItemValue
                    = UndoItemValue(undoItem: .replaceString(tiv),
                                    redoItem: .replaceString(tuiv),
                                    isReversed: isUndo)
            } else {
                switch result.type {
                case .undo:
                    history[result.version].values[result.valueIndex]
                        .undoItemValue?.redoItem = .replaceString(tiv)
                case .redo:
                    history[result.version].values[result.valueIndex]
                        .undoItemValue?.undoItem = .replaceString(tiv)
                }
            }
        case .changedColors(var colorUndoValue):
            updateFirstReverse()
            var isChanged = false, isError = false
            if !colorUndoValue.planeIndexes.isEmpty {
                let pis = colorUndoValue.planeIndexes.filter {
                    $0 < picture.planes.count
                }
                if colorUndoValue.planeIndexes != pis {
                    colorUndoValue.planeIndexes = pis
                    isChanged = true
                }
            } else if !colorUndoValue.planeAnimationIndexes.isEmpty {
                func error() {
                    history[result.version]
                        .values[result.valueIndex].error()
                    isError = true
                }
                loop: for k in colorUndoValue.planeAnimationIndexes {
                    if k.index >= animation.keyframes.count {
                        error()
                        break loop
                    }
                    let planes = animation.keyframes[k.index].picture.planes
                    for i in k.value {
                        if i >= planes.count {
                            error()
                            break loop
                        }
                    }
                }
            }
            
            if !colorUndoValue.lineIndexes.isEmpty {
                let lis = colorUndoValue.lineIndexes.filter {
                    $0 < picture.lines.count
                }
                if colorUndoValue.lineIndexes != lis {
                    colorUndoValue.lineIndexes = lis
                    isChanged = true
                }
            } else if !colorUndoValue.lineAnimationIndexes.isEmpty {
                func error() {
                    history[result.version]
                        .values[result.valueIndex].error()
                    isError = true
                }
                loop: for k in colorUndoValue.lineAnimationIndexes {
                    if k.index >= animation.keyframes.count {
                        error()
                        break loop
                    }
                    let lines = animation.keyframes[k.index].picture.lines
                    for i in k.value {
                        if i >= lines.count {
                            error()
                            break loop
                        }
                    }
                }
            }
            
            if !isError {
                var oColorUndoValue = colorUndoValue
                var isBackground = true
                if let pi = oColorUndoValue.planeIndexes.first {
                    oColorUndoValue.uuColor = picture.planes[pi].uuColor
                    isBackground = false
                } else if let piv = oColorUndoValue.planeAnimationIndexes.first,
                          let pi = piv.value.first {
                    if oColorUndoValue.planeAnimationIndexes.count == oColorUndoValue.animationColors.count {
                        
                        oColorUndoValue.animationColors = oColorUndoValue.planeAnimationIndexes.map {
                            animation.keyframes[$0.index].picture.planes[$0.value.first!].uuColor.value
                        }
                    } else {
                        oColorUndoValue.uuColor
                        = animation.keyframes[piv.index].picture.planes[pi].uuColor
                    }
                    isBackground = false
                }
                
                if let li = oColorUndoValue.lineIndexes.first {
                    oColorUndoValue.uuColor = picture.lines[li].uuColor
                    isBackground = false
                } else if let liv = oColorUndoValue.lineAnimationIndexes.first,
                          let li = liv.value.first {
                    if oColorUndoValue.lineAnimationIndexes.count == oColorUndoValue.animationColors.count {
                        
                        oColorUndoValue.animationColors = oColorUndoValue.lineAnimationIndexes.map {
                            animation.keyframes[$0.index].picture.lines[$0.value.first!].uuColor.value
                        }
                    } else {
                        oColorUndoValue.uuColor
                        = animation.keyframes[liv.index].picture.lines[li].uuColor
                    }
                    isBackground = false
                }
                
                if isBackground {
                    oColorUndoValue.uuColor = backgroundUUColor
                }
                
                if isChanged {
                    history[result.version].values[result.valueIndex].saveUndoItemValue
                        = UndoItemValue(undoItem: .changedColors(oColorUndoValue),
                                        redoItem: .changedColors(colorUndoValue),
                                        isReversed: isUndo)
                } else {
                    switch result.type {
                    case .undo:
                        history[result.version].values[result.valueIndex]
                            .undoItemValue?.redoItem = .changedColors(oColorUndoValue)
                    case .redo:
                        history[result.version].values[result.valueIndex]
                            .undoItemValue?.undoItem = .changedColors(oColorUndoValue)
                    }
                }
            }
        case .insertBorders(var bivs):
            updateFirstReverse()
            var isChanged = false, bordersCount = borders.count
            bivs.enumerated().forEach { (k, iv) in
                if iv.index > bordersCount {
                    bivs[k].index = bordersCount
                    isChanged = true
                }
                bordersCount += 1
            }
            if isChanged {
                history[result.version].values[result.valueIndex].saveUndoItemValue
                    = UndoItemValue(undoItem: .removeBorders(borderIndexes: bivs.map { $0.index }),
                                    redoItem: .insertBorders(bivs),
                                    isReversed: isUndo)
            }
        case .removeBorders(var borderIndexes):
            updateFirstReverse()
            let bis = borderIndexes.filter { $0 < borders.count }.sorted()
            if borderIndexes != bis {
                borderIndexes = bis
                let bivs = borderIndexes.map {
                    IndexValue(value: borders[$0], index: $0)
                }
                history[result.version].values[result.valueIndex].saveUndoItemValue
                    = UndoItemValue(undoItem: .insertBorders(bivs),
                                    redoItem: .removeBorders(borderIndexes: bis),
                                    isReversed: isUndo)
            }
        case .setRootKeyframeIndex(let rootKeyframeIndex):
            switch result.type {
            case .undo:
                history[result.version].values[result.valueIndex]
                    .undoItemValue?.redoItem = .setRootKeyframeIndex(rootKeyframeIndex: rootKeyframeIndex)
            case .redo:
                history[result.version].values[result.valueIndex]
                    .undoItemValue?.undoItem = .setRootKeyframeIndex(rootKeyframeIndex: rootKeyframeIndex)
            }
        case .insertKeyframes(var pivs):
            var isChanged = false, keyframesCount = animation.keyframes.count
            pivs.enumerated().forEach { (k, iv) in
                if iv.index > keyframesCount {
                    pivs[k].index = keyframesCount
                    isChanged = true
                }
                keyframesCount += 1
            }
            if isChanged {
                history[result.version].values[result.valueIndex].saveUndoItemValue
                    = UndoItemValue(undoItem: .removeKeyframes(keyframeIndexes: pivs.map { $0.index }),
                                    redoItem: .insertKeyframes(pivs),
                                    isReversed: isUndo)
            }
        case .removeKeyframes(var indexes):
            let pis = indexes.filter { $0 < animation.keyframes.count }.sorted()
            if indexes != pis {
                indexes = pis
                let pivs = indexes.map {
                    IndexValue(value: animation.keyframes[$0], index: $0)
                }
                history[result.version].values[result.valueIndex].saveUndoItemValue
                    = UndoItemValue(undoItem: .insertKeyframes(pivs),
                                    redoItem: .removeKeyframes(keyframeIndexes: pis),
                                    isReversed: isUndo)
            }
        case .setKeyframeOptions(let koivs):
            updateFirstReverse()
            let isError = {
                for koiv in koivs {
                    if koiv.index >= animation.keyframes.count {
                        return true
                    }
                }
                return false
            } ()
            if isError {
                history[result.version]
                    .values[result.valueIndex].error()
            } else {
                let okoivs = koivs.map {
                    IndexValue(value: animation.keyframes[$0.index].option,
                               index: $0.index)
                }
                switch result.type {
                case .undo:
                    history[result.version].values[result.valueIndex]
                        .undoItemValue?.redoItem = .setKeyframeOptions(okoivs)
                case .redo:
                    history[result.version].values[result.valueIndex]
                        .undoItemValue?.undoItem = .setKeyframeOptions(okoivs)
                }
            }
            
        case .insertKeyLines(let kvs):
            updateFirstReverse()
            func error() {
                history[result.version]
                    .values[result.valueIndex].error()
            }
            loop: for k in kvs {
                if k.index >= animation.keyframes.count {
                    error()
                    break loop
                }
                let lines = animation.keyframes[k.index].picture.lines
                var linesCount = lines.count
                for liv in k.value {
                    if liv.index > linesCount {
                        error()
                        break loop
                    }
                    linesCount += 1
                }
            }
        case .replaceKeyLines(let kvs):
            updateFirstReverse()
            var isError = false
            func error() {
                history[result.version]
                    .values[result.valueIndex].error()
                isError = true
            }
            var oldKVs = [IndexValue<[IndexValue<Line>]>]()
            loop: for k in kvs {
                if k.index >= animation.keyframes.count {
                    error()
                    break loop
                }
                let lines = animation.keyframes[k.index].picture.lines
                var oldLIVs = [IndexValue<Line>]()
                for liv in k.value {
                    if liv.index >= lines.count {
                        error()
                        break loop
                    }
                    oldLIVs.append(IndexValue(value: lines[liv.index],
                                              index: liv.index))
                }
                oldKVs.append(IndexValue(value: oldLIVs, index: k.index))
            }
            if !isError {
                switch result.type {
                case .undo:
                    history[result.version].values[result.valueIndex]
                        .undoItemValue?.redoItem = .replaceKeyLines(oldKVs)
                case .redo:
                    history[result.version].values[result.valueIndex]
                        .undoItemValue?.undoItem = .replaceKeyLines(oldKVs)
                }
            }
        case .removeKeyLines(let iivs):
            updateFirstReverse()
            func error() {
                history[result.version]
                    .values[result.valueIndex].error()
            }
            loop: for k in iivs {
                if k.index >= animation.keyframes.count {
                    error()
                    break loop
                }
                let lines = animation.keyframes[k.index].picture.lines
                let lis = k.value.filter { $0 < lines.count }.sorted()
                if k.value != lis {
                    error()
                    break loop
                }
            }
            
        case .insertKeyPlanes(let kvs):
            updateFirstReverse()
            func error() {
                history[result.version]
                    .values[result.valueIndex].error()
            }
            loop: for k in kvs {
                if k.index >= animation.keyframes.count {
                    error()
                    break loop
                }
                let planes = animation.keyframes[k.index].picture.planes
                var planesCount = planes.count
                for piv in k.value {
                    if piv.index > planesCount {
                        error()
                        break loop
                    }
                    planesCount += 1
                }
            }
        case .replaceKeyPlanes(let kvs):
            updateFirstReverse()
            var isError = false
            func error() {
                history[result.version]
                    .values[result.valueIndex].error()
                isError = true
            }
            var oldKVs = [IndexValue<[IndexValue<Plane>]>]()
            loop: for k in kvs {
                if k.index >= animation.keyframes.count {
                    error()
                    break loop
                }
                let planes = animation.keyframes[k.index].picture.planes
                var oldPIVs = [IndexValue<Plane>]()
                for piv in k.value {
                    if piv.index >= planes.count {
                        error()
                        break loop
                    }
                    oldPIVs.append(IndexValue(value: planes[piv.index],
                                              index: piv.index))
                }
                oldKVs.append(IndexValue(value: oldPIVs, index: k.index))
            }
            if !isError {
                switch result.type {
                case .undo:
                    history[result.version].values[result.valueIndex]
                        .undoItemValue?.redoItem = .replaceKeyPlanes(oldKVs)
                case .redo:
                    history[result.version].values[result.valueIndex]
                        .undoItemValue?.undoItem = .replaceKeyPlanes(oldKVs)
                }
            }
        case .removeKeyPlanes(let iivs):
            updateFirstReverse()
            func error() {
                history[result.version]
                    .values[result.valueIndex].error()
            }
            loop: for k in iivs {
                if k.index >= animation.keyframes.count {
                    error()
                    break loop
                }
                let planes = animation.keyframes[k.index].picture.planes
                let pis = k.value.filter { $0 < planes.count }.sorted()
                if k.value != pis {
                    error()
                    break loop
                }
            }
            
        case .insertDraftKeyLines(let kvs):
            updateFirstReverse()
            func error() {
                history[result.version]
                    .values[result.valueIndex].error()
            }
            loop: for k in kvs {
                if k.index >= animation.keyframes.count {
                    error()
                    break loop
                }
                let lines = animation.keyframes[k.index].draftPicture.lines
                var linesCount = lines.count
                for liv in k.value {
                    if liv.index > linesCount {
                        error()
                        break loop
                    }
                    linesCount += 1
                }
            }
        case .removeDraftKeyLines(let iivs):
            updateFirstReverse()
            func error() {
                history[result.version]
                    .values[result.valueIndex].error()
            }
            loop: for k in iivs {
                if k.index >= animation.keyframes.count {
                    error()
                    break loop
                }
                let lines = animation.keyframes[k.index].draftPicture.lines
                let lis = k.value.filter { $0 < lines.count }.sorted()
                if k.value != lis {
                    error()
                    break loop
                }
            }
            
        case .insertDraftKeyPlanes(let kvs):
            updateFirstReverse()
            func error() {
                history[result.version]
                    .values[result.valueIndex].error()
            }
            loop: for k in kvs {
                if k.index >= animation.keyframes.count {
                    error()
                    break loop
                }
                let planes = animation.keyframes[k.index].draftPicture.planes
                var planesCount = planes.count
                for piv in k.value {
                    if piv.index > planesCount {
                        error()
                        break loop
                    }
                    planesCount += 1
                }
            }
        case .removeDraftKeyPlanes(let iivs):
            updateFirstReverse()
            func error() {
                history[result.version]
                    .values[result.valueIndex].error()
            }
            loop: for k in iivs {
                if k.index >= animation.keyframes.count {
                    error()
                    break loop
                }
                let planes = animation.keyframes[k.index].draftPicture.planes
                let pis = k.value.filter { $0 < planes.count }.sorted()
                if k.value != pis {
                    error()
                    break loop
                }
            }
            
        case .setLineIDs(let kvs):
            updateFirstReverse()
            var isError = false
            func error() {
                history[result.version]
                    .values[result.valueIndex].error()
                isError = true
            }
            var oldKvs = [IndexValue<[IndexValue<InterOption>]>]()
            loop: for k in kvs {
                if k.index >= animation.keyframes.count {
                    error()
                    break loop
                }
                let lines = animation.keyframes[k.index].picture.lines
                var oldVs = [IndexValue<InterOption>]()
                for liv in k.value {
                    if liv.index >= lines.count {
                        error()
                        break loop
                    }
                    oldVs.append(IndexValue(value: lines[liv.index].interOption,
                                              index: liv.index))
                }
                oldKvs.append(IndexValue(value: oldVs, index: k.index))
            }
            if !isError {
                switch result.type {
                case .undo:
                    history[result.version].values[result.valueIndex]
                        .undoItemValue?.redoItem = .setLineIDs(oldKvs)
                case .redo:
                    history[result.version].values[result.valueIndex]
                        .undoItemValue?.undoItem = .setLineIDs(oldKvs)
                }
            }
            
        case .setAnimationOption:
            let oldOption = animation.option
            switch result.type {
            case .undo:
                history[result.version].values[result.valueIndex]
                    .undoItemValue?.redoItem = .setAnimationOption(oldOption)
            case .redo:
                history[result.version].values[result.valueIndex]
                    .undoItemValue?.undoItem = .setAnimationOption(oldOption)
            }
            
        case .insertNotes(var nivs):
            updateFirstReverse()
            var isChanged = false, notesCount = score.notes.count
            nivs.enumerated().forEach { (k, iv) in
                if iv.index > notesCount {
                    nivs[k].index = notesCount
                    isChanged = true
                }
                notesCount += 1
            }
            if isChanged {
                history[result.version].values[result.valueIndex].saveUndoItemValue
                    = UndoItemValue(undoItem: .removeNotes(noteIndexes: nivs.map { $0.index }),
                                    redoItem: .insertNotes(nivs),
                                    isReversed: isUndo)
            }
        case .replaceNotes(let nivs):
            updateFirstReverse()
            var isError = false
            func error() {
                history[result.version]
                    .values[result.valueIndex].error()
                isError = true
            }
            let notes = score.notes
            var oldNIVs = [IndexValue<Note>]()
            for niv in nivs {
                if niv.index >= notes.count {
                    error()
                    break
                }
                oldNIVs.append(IndexValue(value: notes[niv.index],
                                          index: niv.index))
            }
            if !isError {
                switch result.type {
                case .undo:
                    history[result.version].values[result.valueIndex]
                        .undoItemValue?.redoItem = .replaceNotes(oldNIVs)
                case .redo:
                    history[result.version].values[result.valueIndex]
                        .undoItemValue?.undoItem = .replaceNotes(oldNIVs)
                }
            }
        case .removeNotes(var noteIndexes):
            updateFirstReverse()
            let nis = noteIndexes.filter { $0 < score.notes.count }.sorted()
            if noteIndexes != nis {
                noteIndexes = nis
                let nivs = noteIndexes.map {
                    IndexValue(value: score.notes[$0], index: $0)
                }
                history[result.version].values[result.valueIndex].saveUndoItemValue
                    = UndoItemValue(undoItem: .insertNotes(nivs),
                                    redoItem: .removeNotes(noteIndexes: nis),
                                    isReversed: isUndo)
            }
        case .insertDraftNotes(var nivs):
            updateFirstReverse()
            var isChanged = false, notesCount = score.notes.count
            nivs.enumerated().forEach { (k, iv) in
                if iv.index > notesCount {
                    nivs[k].index = notesCount
                    isChanged = true
                }
                notesCount += 1
            }
            if isChanged {
                history[result.version].values[result.valueIndex].saveUndoItemValue
                    = UndoItemValue(undoItem: .removeDraftNotes(noteIndexes: nivs.map { $0.index }),
                                    redoItem: .insertDraftNotes(nivs),
                                    isReversed: isUndo)
            }
        case .removeDraftNotes(var noteIndexes):
            updateFirstReverse()
            let nis = noteIndexes.filter { $0 < score.notes.count }.sorted()
            if noteIndexes != nis {
                noteIndexes = nis
                let nivs = noteIndexes.map {
                    IndexValue(value: score.notes[$0], index: $0)
                }
                history[result.version].values[result.valueIndex].saveUndoItemValue
                    = UndoItemValue(undoItem: .insertDraftNotes(nivs),
                                    redoItem: .removeDraftNotes(noteIndexes: nis),
                                    isReversed: isUndo)
            }
        case .insertContents(var civs):
            updateFirstReverse()
            var isChanged = false, contentsCount = contents.count
            civs.enumerated().forEach { (k, iv) in
                if iv.index > contentsCount {
                    civs[k].index = contentsCount
                    isChanged = true
                }
                contentsCount += 1
            }
            if isChanged {
                history[result.version].values[result.valueIndex].saveUndoItemValue
                    = UndoItemValue(undoItem: .removeContents(contentIndexes: civs.map { $0.index }),
                                    redoItem: .insertContents(civs),
                                    isReversed: isUndo)
            }
        case .replaceContents(let civs):
            updateFirstReverse()
            if civs.contains(where: { $0.index >= contents.count }) {
                history.error(result)
            } else {
                let oldCIVs = civs.map { IndexValue(value: contents[$0.index], index: $0.index) }
                history.setReverse(.replaceContents(oldCIVs), with: result)
            }
        case .removeContents(var contentIndexes):
            updateFirstReverse()
            let cis = contentIndexes.filter { $0 < contents.count }.sorted()
            if contentIndexes != cis {
                contentIndexes = cis
                let civs = contentIndexes.map {
                    IndexValue(value: contents[$0], index: $0)
                }
                history[result.version].values[result.valueIndex].saveUndoItemValue
                    = UndoItemValue(undoItem: .insertContents(civs),
                                    redoItem: .removeContents(contentIndexes: cis),
                                    isReversed: isUndo)
            }
        case .setScoreOption:
            let oldOption = score.option
            switch result.type {
            case .undo:
                history[result.version].values[result.valueIndex]
                    .undoItemValue?.redoItem = .setScoreOption(oldOption)
            case .redo:
                history[result.version].values[result.valueIndex]
                    .undoItemValue?.undoItem = .setScoreOption(oldOption)
            }
        case .setSheetOption:
            let oldOption = self.option
            switch result.type {
            case .undo:
                history[result.version].values[result.valueIndex]
                    .undoItemValue?.redoItem = .setSheetOption(oldOption)
            case .redo:
                history[result.version].values[result.valueIndex]
                    .undoItemValue?.undoItem = .setSheetOption(oldOption)
            }
        case .setSelection(let selection):
            if checkConsistency(selection) {
                history.setReverse(.setSelection(self.selection), with: result)
            } else {
                history.error(result)
            }
        }
    }
}
