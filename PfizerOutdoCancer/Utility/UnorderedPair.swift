struct UnorderedPair<T> {
    let itemA: T
    let itemB: T
    
    init(_ itemA: T, _ itemB: T) {
        self.itemA = itemA
        self.itemB = itemB
    }
}

extension UnorderedPair: Equatable where T: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        (lhs.itemA == rhs.itemA && lhs.itemB == rhs.itemB) || 
        (lhs.itemA == rhs.itemB && lhs.itemB == rhs.itemA)
    }
}

extension UnorderedPair: Hashable where T: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(itemA.hashValue ^ itemB.hashValue)
    }
} 