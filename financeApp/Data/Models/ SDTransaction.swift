import SwiftData
import Foundation

@Model
final class SDTransaction {
  @Attribute(.unique) var id: Int
  var date: Date
  var amount: Double
  var categoryID: Int
  var directionRaw: String

  init(id: Int, date: Date, amount: Double, categoryID: Int, directionRaw: String) {
    self.id = id
    self.date = date
    self.amount = amount
    self.categoryID = categoryID
    self.directionRaw = directionRaw
  }
}
