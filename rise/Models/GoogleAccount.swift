import Foundation

struct GoogleAccount: Identifiable, Codable, Hashable {
  let id: String  // account email used as id
  let displayName: String
  let email: String
  let colorHex: String
  var autoJoinEnabled: Bool
}
