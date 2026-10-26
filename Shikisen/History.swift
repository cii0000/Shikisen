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

import struct Foundation.Data
import struct Foundation.Date
import protocol Foundation.LocalizedError

extension Date: Protobuf {
    init(_ pb: PBDate) throws {
        self.init(timeIntervalSinceReferenceDate: pb.timestamp)
    }
    var pb: PBDate {
        .with {
            $0.timestamp = timeIntervalSinceReferenceDate
        }
    }
}

struct Version: Hashable, Codable {
    var indexPath = [Int](), groupIndex = 0
}

protocol UndoItem: Sendable, Protobuf, Hashable, Codable {
    func reversed() -> Self?
}
extension UndoItem {
    var caseName: String {
        Mirror(reflecting: self).children.first?.label ?? .init(describing: self)
    }
}

struct UndoItemValue<T: UndoItem>: Codable {
    var undoItem: T
    var redoItem: T
    
    init(undo undoItem: T, redo redoItem: T) {
        self.undoItem = undoItem
        self.redoItem = redoItem
    }
    init(undo undoItem: T, redo redoItem: T, isReversed: Bool) {
        if isReversed {
            self.undoItem = redoItem
            self.redoItem = undoItem
        } else {
            self.undoItem = undoItem
            self.redoItem = redoItem
        }
    }
    func item(at type: UndoType) -> T {
        switch type {
        case .undo: undoItem
        case .redo: redoItem
        }
    }
}

struct UndoError: LocalizedError, Equatable {
    var errorDescription: String?
    
    private init(errorDescription: String?) {
        self.errorDescription = errorDescription
    }
    static let load = Self.init(errorDescription: "\("History Error".localized): \("Failed to load".localized)")
    static let errored = Self.init(errorDescription: "errored")
    init<T: UndoItem>(_ undoItem: T) {
        errorDescription = "\("History Error".localized): \(undoItem.caseName)"
    }
    
    init<T: UndoItem>(from undoItem: T) {
        errorDescription = "\("History Error".localized): from \(undoItem.caseName)"
    }
}
struct UndoDataValue<T: UndoItem>: Codable {
    enum LoadType: Codable {
        case unload, loaded, error
    }
    
    var undoItemData = Data()
    var redoItemData = Data()
    var undoItemValue = UndoItemValue<T>?.none
    var loadType = LoadType.unload
}
extension UndoDataValue {
    init(save itemValue: UndoItemValue<T>) {
        self.undoItemValue = itemValue
        self.loadType = .loaded
        save()
    }
    mutating func save(redo redoItem: T) {
        self.undoItemValue?.redoItem = redoItem
        save()
    }
    mutating func save() {
        undoItemData = (try? undoItemValue?.undoItem.serializedData()) ?? .init()
        redoItemData = (try? undoItemValue?.redoItem.serializedData()) ?? .init()
    }
}
extension UndoDataValue: Protobuf {
    typealias PB = PBUndoDataValue
    init(_ pb: PBUndoDataValue) throws {
        undoItemData = pb.undoItemData
        redoItemData = pb.redoItemData
    }
    var pb: PBUndoDataValue {
        .with {
            $0.undoItemData = undoItemData
            $0.redoItemData = redoItemData
        }
    }
}

struct UndoGroup<T: UndoItem>: Codable {
    var values = [UndoDataValue<T>]()
    private(set) var firstUndoItem: T?, firstUndoItemData = Data()
    var date = Date()
}
extension UndoGroup {
    func reverse(_ handler: (EnumeratedSequence<[UndoDataValue<T>]>.Element) -> ()) {
        values.enumerated().reversed().forEach {
            handler($0)
        }
    }
    var isEnabledFirst: Bool {
        firstUndoItem != nil || !firstUndoItemData.isEmpty
    }
    mutating func loadFirstUndoItem() -> T? {
        if let firstUndoItem {
            return firstUndoItem
        } else if !firstUndoItemData.isEmpty {
            let undoItem = try? T(serializedData: firstUndoItemData)
            firstUndoItem = undoItem
            return undoItem
        }
        return nil
    }
    mutating func save(first undoItem: T) {
        self.firstUndoItem = undoItem
        firstUndoItemData = (try? undoItem.serializedData()) ?? .init()
    }
}
extension UndoGroup: Protobuf {
    typealias PB = PBUndoGroup
    init(_ pb: PBUndoGroup) throws {
        values = try pb.values.map { try UndoDataValue($0) }
        
        if pb.isFirstReverse, values.count >= 1 {
            self.firstUndoItemData = values[0].undoItemData
            values.removeFirst()
        } else {
            firstUndoItemData = pb.firstUndoItemData
        }
        
        date = (try? Date(pb.date)) ?? Date(timeIntervalSinceReferenceDate: 0)
    }
    var pb: PBUndoGroup {
        .with {
            $0.values = values.map { $0.pb }
            if !firstUndoItemData.isEmpty {
                $0.firstUndoItemData = firstUndoItemData
            }
            $0.date = date.pb
        }
    }
}

private final class _Branch<T: UndoItem>: @unchecked Sendable {
    var groups = [UndoGroup<T>]()
    var children = [_Branch<T>]()
    var selectedChildIndex = Int?.none
    fileprivate var childrenCount = 0
    
    init(groups: [UndoGroup<T>] = .init(), children: [_Branch<T>] = .init(),
         selectedChildIndex: Int? = nil) {
        self.groups = groups
        self.children = children
        self.selectedChildIndex = selectedChildIndex
        self.childrenCount = children.count
    }
    private init(groups: [UndoGroup<T>], childrenCount: Int, selectedChildIndex: Int?) {
        self.groups = groups
        self.childrenCount = childrenCount
        self.selectedChildIndex = selectedChildIndex
    }
    
    deinit {
        var count = 0
        self.allBranchs { _, _ in count += 1 }
        
        var allBranchs = [_Branch<T>](capacity: count)
        var branchStack = Stack<_Branch<T>>(minimumCapacity: count)
        branchStack.push(self)
        while let branch = branchStack.pop() {
            allBranchs.append(branch)
            for child in branch.children.reversed() {
                branchStack.push(child)
            }
        }
        allBranchs.forEach {
            $0.groups = []
            $0.children = []
            $0.selectedChildIndex = nil
        }
        allBranchs = []
    }
}
extension _Branch: Protobuf {
    typealias PB = PBBranch
    convenience init(_ pb: PBBranch) throws {
        self.init()
        groups = try pb.groups.map { try UndoGroup($0) }
        childrenCount = Int(pb.childrenCount)
        if case .selectedChildIndex(let selectedChildIndex)?
            = pb.selectedChildIndexOptional {
            
            self.selectedChildIndex = Int(selectedChildIndex)
        } else {
            selectedChildIndex = nil
        }
    }
    var pb: PBBranch {
        .with {
            $0.groups = groups.map { $0.pb }
            $0.childrenCount = Int64(children.count)
            if let selectedChildIndex = selectedChildIndex {
                $0.selectedChildIndexOptional
                    = .selectedChildIndex(Int64(selectedChildIndex))
            } else {
                $0.selectedChildIndexOptional = nil
            }
        }
    }
}
extension _Branch: Codable {
    public convenience init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.init()
        groups = try container.decode([UndoGroup<T>].self)
        childrenCount = try container.decode(Int.self)
        selectedChildIndex = try container.decodeIfPresent(Int.self)
    }
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(groups)
        try container.encode(children.count)
        try container.encode(selectedChildIndex)
    }
}
extension _Branch {
    func appendInLastGroup(undo undoItem: T, redo redoItem: T) {
        groups[.last].values.append(.init(save: .init(undo: undoItem, redo: redoItem)))
    }
    func appendInLastGroup(_ uiv: UndoItemValue<T>) {
        groups[.last].values.append(.init(save: uiv))
    }
    func replaceInLastGroup(redo redoItem: T) {
        groups[.last].values[.last].save(redo: redoItem)
    }
    func setInLastGroup(first undoItem: T) {
        groups[.last].save(first: undoItem)
    }
    
    subscript(version: Version) -> UndoGroup<T> {
        get { self[version.indexPath].groups[version.groupIndex] }
        set { self[version.indexPath].groups[version.groupIndex] = newValue }
    }
    subscript(indexPath: [Int]) -> _Branch<T> {
        var branch = self
        indexPath.forEach {
            branch = branch.children[$0]
        }
        return branch
    }
    func version(atAll i: Int) -> Version? {
        guard i > 0 else { return nil }
        let i = i - 1
        var branch = self, j = 0, indexPath = [Int]()
        while true {
            let nj = j + branch.groups.count
            if nj > i {
                return Version(indexPath: indexPath, groupIndex: i - j)
            }
            guard let sci = branch.selectedChildIndex else { break }
            indexPath.append(sci)
            j = nj
            branch = branch.children[sci]
        }
        return .init(indexPath: indexPath, groupIndex: branch.groups.count - 1)
    }
    
    func allBranchs(_ handler: ([Int], _Branch<T>) -> ()) {
        var indexPathAndBranchs = [([Int](), self)]
        while let (indexPath, branch) = indexPathAndBranchs.last {
            indexPathAndBranchs.removeLast()
            handler(indexPath, branch)
            for (i, child) in branch.children.enumerated().reversed() {
                var indexPath = indexPath
                indexPath.append(i)
                indexPathAndBranchs.append((indexPath, child))
            }
        }
    }
    func allGroups(_ handler: ([Int], [UndoGroup<T>]) -> ()) {
        var indexPathAndBranchs = [([Int](), self)]
        while let (indexPath, branch) = indexPathAndBranchs.last {
            indexPathAndBranchs.removeLast()
            handler(indexPath, branch.groups)
            for (i, child) in branch.children.enumerated().reversed() {
                var indexPath = indexPath
                indexPath.append(i)
                indexPathAndBranchs.append((indexPath, child))
            }
        }
    }
    
    func coderCopy() -> Self {
        .init(groups: groups, childrenCount: children.count,
              selectedChildIndex: selectedChildIndex)
    }
}

struct Branch<T: UndoItem> {
    var groups = [UndoGroup<T>]()
    var childrenCount = 0
    var selectedChildIndex = Int?.none
}

private struct BranchCoder<T: UndoItem> {
    var rootBranch: _Branch<T>
}
extension BranchCoder: Protobuf {
    typealias PB = PBBranchCoder
    init(_ pb: PBBranchCoder) throws {
        let allBranches = try pb.allBranches.map { try _Branch<T>($0) }
        rootBranch = BranchCoder.rootBranch(from: allBranches)
    }
    var pb: PBBranchCoder {
        .with {
            $0.allBranches = allBranches.map { $0.pb }
        }
    }
}
extension BranchCoder: Codable {
    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let allBranches = try container.decode([_Branch<T>].self)
        rootBranch = BranchCoder.rootBranch(from: allBranches)
    }
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(allBranches)
    }
}
private enum BranchLoop<T: UndoItem> {
    case first(_ branch: _Branch<T>)
    case next(_ children: [_Branch<T>], _ branch: _Branch<T>, _ j: Int)
}
extension BranchCoder {
    static func rootBranch(from allBranches: [_Branch<T>]) -> _Branch<T> {
        guard let root = allBranches.first else {
            return _Branch<T>()
        }
        
        var i = 0, loopStack = Stack<BranchLoop<T>>()
        var returnStack = Stack<_Branch<T>>()
        loopStack.push(.first(root))
        loop: while true {
            let branch: _Branch<T>, nj: Int
            var children: [_Branch<T>]
            switch loopStack.pop()! {
            case .first(let oBranch):
                children = [_Branch<T>]()
                children.reserveCapacity(oBranch.childrenCount)
                branch = oBranch
                nj = 0
            case .next(var nChildren, let oBranch, let oj):
                nChildren.append(returnStack.pop()!)
                children = nChildren
                branch = oBranch
                nj = oj
            }
            for j in nj ..< branch.childrenCount {
                i += 1
                
                loopStack.push(.next(children, branch, j + 1))
                loopStack.push(.first(allBranches[i]))
                continue loop
            }
            
            let nBranch = branch
            nBranch.children = children
            nBranch.children.enumerated().reversed().forEach {
                if $0.element.groups.isEmpty {
                    nBranch.children.remove(at: $0.offset)
                }
            }
            
            if loopStack.isEmpty {
                return nBranch
            } else {
                returnStack.push(nBranch)
                continue loop
            }
        }
    }
    var allBranches: [_Branch<T>] {
        var allBranches = [_Branch<T>]()
        var uns = [rootBranch]
        while let un = uns.last {
            uns.removeLast()
            allBranches.append(un)
            for child in un.children.reversed() {
                uns.append(child)
            }
        }
        return allBranches
    }
}

enum UndoType {
    case undo, redo
}
extension UndoType {
    var reversed: Self {
        switch self {
        case .undo: .redo
        case .redo: .undo
        }
    }
}

struct History<T: UndoItem> {
    private var rootBranch = _Branch<T>()
    var currentVersionIndex = 0, currentVersion = Version?.none
}
extension History: Protobuf {
    typealias PB = PBHistory
    init(_ pb: PBHistory) throws {
        rootBranch = try BranchCoder(pb.branchCoder).rootBranch
        currentVersionIndex = Int(pb.currentVersionIndex)
        check()
    }
    var pb: PBHistory {
        .with {
            $0.branchCoder = BranchCoder(rootBranch: rootBranch).pb
            $0.currentVersionIndex = Int64(currentVersionIndex)
        }
    }
    mutating func check() {
        copyIfShared()
        
        guard currentVersionIndex > 0 else {
            currentVersion = nil
            return
        }
        let i = currentVersionIndex - 1
        var branch = rootBranch, j = 0, indexPath = [Int]()
        while true {
            let nj = j + branch.groups.count
            if nj > i {
                currentVersion = Version(indexPath: indexPath, groupIndex: i - j)
                return
            }
            guard let sci = branch.selectedChildIndex else { break }
            indexPath.append(sci)
            j = nj
            branch = branch.children[sci]
        }
        currentVersionIndex = j + branch.groups.count - 1
        currentVersion = .init(indexPath: indexPath, groupIndex: branch.groups.count - 1)
    }
}
extension History: Codable {
    private enum CodingKeys: String, CodingKey {
        case rootBranch, currentVersionIndex
    }
    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        rootBranch = try values.decode(BranchCoder.self, forKey: .rootBranch).rootBranch
        currentVersionIndex = try values.decode(Int.self, forKey: .currentVersionIndex)
        check()
    }
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(BranchCoder(rootBranch: rootBranch), forKey: .rootBranch)
        try container.encode(currentVersionIndex, forKey: .currentVersionIndex)
    }
}
extension History {
    private mutating func copyIfShared() {
        if isKnownUniquelyReferenced(&rootBranch) { return }
        let coder = BranchCoder(rootBranch: rootBranch)
        let copiedAllBranches = coder.allBranches.map { $0.coderCopy() }
        rootBranch = BranchCoder.rootBranch(from: copiedAllBranches)
    }
    
    mutating func newBranch() {
        copyIfShared()
        
        if let currentVersion {
            var indexPath = currentVersion.indexPath
            let branch = rootBranch[indexPath]
            if currentVersion.groupIndex == branch.groups.count - 1 {
                guard let i = branch.selectedChildIndex else { return }
                let branch0 = _Branch<T>(groups: [.init()])
                let ni = i + 1
                branch.children.insert(branch0, at: ni)
                branch.selectedChildIndex = ni
                indexPath.append(ni)
            } else {
                let branch0 = _Branch<T>(groups: Array(branch.groups[(currentVersion.groupIndex + 1)...]),
                                         children: branch.children,
                                         selectedChildIndex: branch.selectedChildIndex)
                let branch1 = _Branch<T>(groups: [.init()])
                branch.groups.removeLast(branch.groups.count - currentVersion.groupIndex - 1)
                branch.children = [branch0, branch1]
                branch.selectedChildIndex = 1
                indexPath.append(1)
            }
            self.currentVersion = .init(indexPath: indexPath, groupIndex: 0)
            currentVersionIndex += 1
        } else {
            let branch0 = rootBranch
            if branch0.groups.count == 0 {
                guard let i = branch0.selectedChildIndex else { return }
                let branch1 = _Branch<T>(groups: [.init()])
                let ni = i + 1
                rootBranch.children.insert(branch1, at: ni)
                rootBranch.selectedChildIndex = ni
                currentVersion = .init(indexPath: [ni], groupIndex: 0)
                currentVersionIndex = 1
            } else {
                let branch1 = _Branch<T>(groups: [.init()])
                rootBranch = .init(groups: [], children: [branch0, branch1], selectedChildIndex: 1)
                currentVersion = .init(indexPath: [1], groupIndex: 0)
                currentVersionIndex = 1
            }
        }
    }
    mutating func newUndoGroup() {
        copyIfShared()
        
        if !isLeafUndo {
            newBranch()
        } else {
            if let version = currentVersion {
                rootBranch[version.indexPath].groups.append(UndoGroup())
                currentVersionIndex += 1
                currentVersion!.groupIndex += 1
            } else {
                rootBranch.groups = [UndoGroup()]
                currentVersionIndex = 1
                currentVersion = Version(indexPath: .init(), groupIndex: 0)
            }
        }
    }
    mutating func append(undo undoItem: T, redo redoItem: T) {
        copyIfShared()
        
        rootBranch[currentVersion!.indexPath]
            .appendInLastGroup(undo: undoItem, redo: redoItem)
    }
    mutating func append(_ uiv: UndoItemValue<T>) {
        copyIfShared()
        
        rootBranch[currentVersion!.indexPath].appendInLastGroup(uiv)
    }
    mutating func set(first undoItem: T) {
        copyIfShared()
        
        rootBranch[currentVersion!.indexPath].setInLastGroup(first: undoItem)
    }
    
    mutating func newUndoGroupAndAppend(undo undoItem: T) {
        copyIfShared()
        
        if let currentVersion,
           let lastUndoItem = rootBranch[currentVersion.indexPath].groups.last?
            .values.last?.undoItemValue?.undoItem,
           undoItem.caseName == lastUndoItem.caseName {
            
            rootBranch[currentVersion.indexPath].replaceInLastGroup(redo: lastUndoItem)
        } else {
            newUndoGroup()
            rootBranch[currentVersion!.indexPath].appendInLastGroup(undo: undoItem,
                                                                    redo: undoItem)
        }
    }
    mutating func replace(redo redoItem: T) {
        guard let lastUndoItem = rootBranch[currentVersion!.indexPath].groups.last?
            .values.last?.undoItemValue?.undoItem,
              redoItem.caseName == lastUndoItem.caseName else { return }
        
        copyIfShared()
        rootBranch[currentVersion!.indexPath].replaceInLastGroup(redo: redoItem)
    }
    mutating func removeLastIfEqual(redo redoItem: T) {
        guard let uiv = rootBranch[currentVersion!.indexPath].groups.last?
            .values.last?.undoItemValue, redoItem.caseName == uiv.undoItem.caseName else { return }
        if uiv.undoItem == uiv.redoItem {
            copyIfShared()
            rootBranch[currentVersion!.indexPath].groups[.last].values.removeLast()
        }
    }
    
    struct UndoResult {
        var isEnabledFirst: Bool = false
        var undoDataValue: UndoDataValue<T>, type: UndoType
        var version: Version, valueIndex: Int
        
        static func isEnabledFirst(version: Version) -> Self {
            Self.init(isEnabledFirst: true, undoDataValue: .init(),
                      type: .undo, version: version, valueIndex: 0)
        }
        func undoItem(with iv: UndoItemValue<T>) -> T {
            switch type {
            case .undo: iv.undoItem
            case .redo: iv.redoItem
            }
        }
    }
    mutating func undoResults(to toTopIndex: Int) -> [UndoResult] {
        copyIfShared()
        
        let fromTopIndex = currentVersionIndex
        guard fromTopIndex != toTopIndex else { return [] }
        func enumerated(minI: Int, maxI: Int, _ handler: (Version) -> ()) {
            var minI = minI
            if minI == 0 {
                minI = 1
                handler(Version(indexPath: .init(), groupIndex: -1))
            }
            guard minI <= maxI else { return }
            for i in minI ... maxI {
                let version = rootBranch.version(atAll: i)!
                handler(version)
            }
        }
        var results = [UndoResult]()
        if fromTopIndex < toTopIndex {
            enumerated(minI: fromTopIndex + 1, maxI: toTopIndex) { (version) in
                let group = rootBranch[version]
                if group.isEnabledFirst {
                    results.append(UndoResult.isEnabledFirst(version: version))
                }
                group.values.enumerated().forEach {
                    results.append(UndoResult(undoDataValue: $0.element,
                                              type: .redo,
                                              version: version,
                                              valueIndex: $0.offset))
                }
            }
        } else {
            var versions = [(Version)]()
            versions.reserveCapacity(fromTopIndex - toTopIndex)
            enumerated(minI: toTopIndex, maxI: fromTopIndex - 1) { (version) in
                versions.append((version))
            }
            versions.reversed().forEach { (version) in
                let branch = rootBranch[version.indexPath]
                if version.groupIndex + 1 >= branch.groups.count {
                    var nVersion = version
                    nVersion.groupIndex = 0
                    nVersion.indexPath.append(branch.selectedChildIndex!)
                    let group = branch.children[branch.selectedChildIndex!].groups[0]
                    if group.isEnabledFirst {
                        results.append(UndoResult.isEnabledFirst(version: nVersion))
                    }
                    group.reverse {
                        results.append(UndoResult(undoDataValue: $0.element,
                                                  type: .undo,
                                                  version: nVersion,
                                                  valueIndex: $0.offset))
                    }
                } else {
                    var nVersion = version
                    nVersion.groupIndex = version.groupIndex + 1
                    let group = rootBranch[nVersion]
                    if group.isEnabledFirst {
                        results.append(UndoResult.isEnabledFirst(version: nVersion))
                    }
                    group.reverse {
                        results.append(UndoResult(undoDataValue: $0.element,
                                                  type: .undo,
                                                  version: nVersion,
                                                  valueIndex: $0.offset))
                    }
                }
            }
        }
        currentVersion = rootBranch.version(atAll: toTopIndex)
        currentVersionIndex = toTopIndex
        return results
    }
    
    subscript(version: Version) -> UndoGroup<T> {
        get { rootBranch[version.indexPath].groups[version.groupIndex] }
        set {
            copyIfShared()
            
            rootBranch[version.indexPath].groups[version.groupIndex] = newValue
        }
    }
    subscript(result: UndoResult) -> UndoDataValue<T> {
        get { self[result.version].values[result.valueIndex] }
        set {
            copyIfShared()
            
            self[result.version].values[result.valueIndex] = newValue
        }
    }
    
    mutating func set(selectedChildIndex: Int, at indexPath: [Int]) {
        copyIfShared()
        
        rootBranch[indexPath].selectedChildIndex = selectedChildIndex
        currentVersion = rootBranch.version(atAll: currentVersionIndex)
    }
    mutating func set(indexPath: [Int]) {
        copyIfShared()
        
        var un = rootBranch
        for vi in indexPath {
            un.selectedChildIndex = vi
            un = un.children[vi]
        }
        currentVersion = rootBranch.version(atAll: currentVersionIndex)
    }
    mutating func set(toTopIndex: Int) {
        currentVersion = rootBranch.version(atAll: toTopIndex)
        currentVersionIndex = toTopIndex
    }
    
    mutating func reset() {
        copyIfShared()
        
        rootBranch = _Branch()
        currentVersionIndex = 0
        currentVersion = nil
    }
    
    var isEmpty: Bool {
        rootBranch.groups.isEmpty && rootBranch.children.isEmpty
    }
    
    var currentMaxVersionIndex: Int {
        var un = rootBranch, i = un.groups.count
        while let sci = un.selectedChildIndex {
            un = un.children[sci]
            i += un.groups.count
        }
        return i
    }
    var isLeafUndo: Bool {
        currentVersionIndex == currentMaxVersionIndex
    }
    var isCanUndo: Bool {
        currentVersionIndex > 0
    }
    var isCanRedo: Bool {
        currentVersionIndex < currentMaxVersionIndex
    }
    
    func branch(from indexPath: [Int]) -> Branch<T> {
        let branch = rootBranch[indexPath]
        return .init(groups: branch.groups, childrenCount: branch.children.count,
                     selectedChildIndex: branch.selectedChildIndex)
    }
    var currentDate: Date? {
        if let version = currentVersion {
            rootBranch[version].date
        } else {
            nil
        }
    }
    
    mutating func setReverse(_ item: T, with result: UndoResult) {
        copyIfShared()
        
        switch result.type {
        case .undo: self[result].undoItemValue?.redoItem = item
        case .redo: self[result].undoItemValue?.undoItem = item
        }
    }
    
    func allGroups(_ handler: ([Int], [UndoGroup<T>]) -> ()) {
        rootBranch.allGroups(handler)
    }
    func allBranchsFromSelected(_ handler: (Branch<T>, Int) -> ()) {
        var branch = rootBranch
        while let i = branch.selectedChildIndex {
            handler(.init(groups: branch.groups, childrenCount: branch.children.count,
                          selectedChildIndex: branch.selectedChildIndex),
                    i)
            branch = branch.children[i]
        }
    }
    
    func currentYIndexPath() -> [Int]? {
        let currentVersion = currentVersion
        let indexPath = currentVersion?.indexPath ?? []
        let branch = branch(from: indexPath)
        if branch.selectedChildIndex != nil {
            if currentVersion?.groupIndex == nil
                || currentVersion?.groupIndex == branch.groups.count - 1 {
                
                return indexPath
            }
        }
        return nil
    }
    
    func topIndex(from version: Version?) -> Int {
        guard let version else { return 0 }
        var un = rootBranch, i = 1
        for vi in version.indexPath {
            i += un.groups.count
            un = un.children[vi]
        }
        return i + version.groupIndex
    }
    func move(to toVersion: Version?,
              yIndexPathHandler: ([Int]) -> (),
              topIHandler: (Int) async throws -> ()) async rethrows {
        let fromVersion = currentVersion
        if let toVersion {
            if let fromVersion {
                let fromTopI = topIndex(from: fromVersion)
                let toTopI = topIndex(from: toVersion)
                let isEqualIndexPath = fromVersion.indexPath == toVersion.indexPath
                let count = zip(fromVersion.indexPath, toVersion.indexPath)
                    .prefix(while: { $0 == $1 }).count
                if isEqualIndexPath
                    || (fromVersion.indexPath.count == count
                        || toVersion.indexPath.count == count) {
                    if fromTopI < toTopI {
                        if !isEqualIndexPath && fromVersion.indexPath.count == count {
                            yIndexPathHandler(toVersion.indexPath)
                        }
                        for i in fromTopI + 1 ... toTopI {
                            try await topIHandler(i)
                        }
                    } else {
                        for i in (toTopI ..< fromTopI).reversed() {
                            try await topIHandler(i)
                        }
                    }
                } else {
                    let nFromIndexPath = Array(fromVersion.indexPath[..<count])
                    let nFromVersion = Version(indexPath: nFromIndexPath,
                                               groupIndex: branch(from: nFromIndexPath).groups.count - 1)
                    let nFromTopI = topIndex(from: nFromVersion)
                    for i in (nFromTopI ..< fromTopI).reversed() {
                        try await topIHandler(i)
                    }
                    yIndexPathHandler(toVersion.indexPath)
                    for i in nFromTopI + 1 ... toTopI {
                        try await topIHandler(i)
                    }
                }
            } else {
                yIndexPathHandler(toVersion.indexPath)
                for i in 1 ... topIndex(from: toVersion) {
                    try await topIHandler(i)
                }
            }
        } else if let fromVersion {
            for i in (0 ..< topIndex(from: fromVersion)).reversed() {
                try await topIHandler(i)
            }
        }
    }
    
    mutating func _update() {
        allGroups { ip, groups in
            for (gi, group) in groups.enumerated() {
                for (vi, value) in group.values.enumerated() {
                    let undoItem = try? T(serializedData: value.undoItemData)
                    let redoItem = try? T(serializedData: value.redoItemData)
                    if undoItem == nil, let redoItem {
                        self[Version(indexPath: ip, groupIndex: gi)].values[vi].undoItemData
                        = try! redoItem.reversed()!.serializedData()
                    } else if let undoItem, redoItem == nil {
                        self[Version(indexPath: ip, groupIndex: gi)].values[vi].redoItemData
                        = try! undoItem.reversed()!.serializedData()
                    }
                }
            }
        }
    }
}

protocol HisotryOwner {
    associatedtype OwnerUndoItem: UndoItem
    func canSet(from item: OwnerUndoItem) -> Bool
    func canSet(_ item: OwnerUndoItem) -> Bool
    func reversed(_ item: OwnerUndoItem) -> OwnerUndoItem
}
extension History {
    mutating func undoItem<S: HisotryOwner>(with result: History<T>.UndoResult,
                                            _ owner: S) throws -> T where S.OwnerUndoItem == T {
        copyIfShared()
        
        if let uiv = result.undoDataValue.undoItemValue {
            return result.undoItem(with: uiv)
        } else {
            do {
                guard result.undoDataValue.loadType != .error else { throw UndoError.errored }
                if result.isEnabledFirst {
                    guard let firstUndoItem = self[result.version].loadFirstUndoItem()
                    else { throw UndoError.load }
                    return firstUndoItem
                }
                
                let udv = self[result]
//                guard let undoItem = try? T(serializedData: udv.undoItemData),
//                      let redoItem = try? T(serializedData: udv.redoItemData)
//                else { throw UndoError.load }
//                func uiv(from item: T, isReversed: Bool) throws -> UndoItemValue<T> {
//                    guard owner.canSet(item) else { throw UndoError(item) }
//                    return .init(undo: item, redo: owner.reversed(item),
//                                 isReversed: isReversed)
//                }
//                let nuiv = switch result.type {
//                case .undo: try uiv(from: undoItem, isReversed: false)
//                case .redo: try uiv(from: redoItem, isReversed: true)
//                }
                
                let undoItem = try? T(serializedData: udv.undoItemData)
                let redoItem = try? T(serializedData: udv.redoItemData)
                func uiv(from item: T,
                         isTo: Bool, isReversed: Bool) throws -> UndoItemValue<T> {
                    if isTo {
                        guard owner.canSet(item) else { throw UndoError(item) }
                    } else {
                        guard owner.canSet(from: item) else { throw UndoError(from: item) }
                    }
                    return .init(undo: item, redo: owner.reversed(item),
                                 isReversed: isReversed)
                }
                let nuiv = if let undoItem {
                    if let redoItem {
                        switch result.type {
                        case .undo:
                            try uiv(from: undoItem, isTo: true, isReversed: false)
                        case .redo:
                            try uiv(from: redoItem, isTo: true, isReversed: true)
                        }
                    } else {
                        switch result.type {
                        case .undo:
                            try uiv(from: undoItem, isTo: true, isReversed: false)
                        case .redo:
                            try uiv(from: undoItem, isTo: false, isReversed: false)
                        }
                    }
                } else if let redoItem {
                    switch result.type {
                    case .undo:
                        try uiv(from: redoItem, isTo: false, isReversed: true)
                    case .redo:
                        try uiv(from: redoItem, isTo: true, isReversed: true)
                    }
                } else { throw UndoError.load }
                
                self[result].undoItemValue = nuiv
                self[result].loadType = .loaded
                return result.undoItem(with: nuiv)
            } catch {
                self[result].undoItemValue = nil
                self[result].loadType = .error
                currentVersion = result.version
                currentVersionIndex = topIndex(from: result.version)
                throw error
            }
        }
    }
}
