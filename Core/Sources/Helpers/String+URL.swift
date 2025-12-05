import Foundation

public extension String {
    func parseIfUrl() throws -> String {
        guard self.contains("data:application/"), let url = URL(string: self) else {
            return self
        }
        let data = try Data(contentsOf: url)
        return String(data: data, encoding: .utf8) ?? self
    }
}
