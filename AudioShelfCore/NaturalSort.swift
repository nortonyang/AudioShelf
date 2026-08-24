import Foundation

public enum NaturalSort {
    public static func isOrderedBefore(_ lhs: String, _ rhs: String) -> Bool {
        let result = lhs.localizedStandardCompare(rhs)
        if result == .orderedSame {
            return lhs < rhs
        }
        return result == .orderedAscending
    }

    public static func sorted<S: Sequence>(_ values: S) -> [String] where S.Element == String {
        values.sorted(by: isOrderedBefore)
    }
}
