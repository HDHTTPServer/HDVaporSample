import Vapor
import HTTP
import BigInt

class NumberUtilities {

    static func fibonacci(_ n: Int) -> String {
        if (n < 2) {
            return n.description
        }
        var first: BigUInt = 0
        var second: BigUInt = 1
        var result: BigUInt = 0;
        (2 ..< n + 1).forEach { _ in
            let next: BigUInt = first + second
            result = next
            first = second
            second = next
        }
        return String(result)
    }
}
