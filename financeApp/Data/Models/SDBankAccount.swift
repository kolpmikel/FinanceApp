import Foundation
import SwiftData

@Model
final class SDBankAccount {
  @Attribute(.unique) var id: Int
  var userId: Int
  var name: String
  var balance: Double
  var currency: String
  var createdAt: Date
  var updatedAt: Date

  init(
    id: Int,
    userId: Int,
    name: String,
    balance: Double,
    currency: String,
    createdAt: Date,
    updatedAt: Date
  ) {
    self.id = id
    self.userId = userId
    self.name = name
    self.balance = balance
    self.currency = currency
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}
