// Logic checks. Run: swiftc -D TEST -parse-as-library main.swift tests.swift -o t && ./t
import Foundation

#if TEST
@main enum Tests {
    static func main() {
        // hidutilJSON emits valid JSON hidutil understands.
        let json = hidutilJSON([Mapping(from: 0x7_0000_0039, to: 0x7_0000_0029)])
        let obj = try! JSONSerialization.jsonObject(with: Data(json.utf8)) as! [String: [[String: Int]]]
        assert(obj["UserKeyMapping"]! == [["HIDKeyboardModifierMappingSrc": 0x7_0000_0039,
                                           "HIDKeyboardModifierMappingDst": 0x7_0000_0029]])
        assert(hidutilJSON([]) == #"{"UserKeyMapping":[]}"#)

        // Key table: no duplicate codes or names, names resolve.
        assert(Set(keys.map(\.code)).count == keys.count, "duplicate key code")
        assert(Set(keys.map(\.name)).count == keys.count, "duplicate key name")
        assert(keyName(0x7_0000_0039) == "Caps Lock")
        assert(keyName(0x123) == "123")
        print("tests passed")
    }
}
#endif
