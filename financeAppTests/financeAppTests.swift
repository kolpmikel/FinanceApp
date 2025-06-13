import XCTest
import Foundation
@testable import financeApp

private typealias AppCategory = financeApp.Category
private typealias AppTransaction = financeApp.Transaction
private typealias AppBankAccount = financeApp.BankAccount

final class FinancialAppTests: XCTestCase {
    func testCategoryDecoding() throws {
        let json: Data = """
        [
          { "id": 1, "name": "Salary", "emoji": "💰", "isIncome": true },
          { "id": 2, "name": "Coffee", "emoji": "☕️", "isIncome": false }
        ]
        """.data(using: .utf8)!

        let categories: [AppCategory] = try JSONDecoder().decode([AppCategory].self, from: json)
        XCTAssertEqual(categories.count, 2)
        XCTAssertEqual(categories[0], AppCategory(id: 1, name: "Salary", emoji: "💰", direction: .income))
        XCTAssertEqual(categories[1], AppCategory(id: 2, name: "Coffee", emoji: "☕️", direction: .outcome))
    }

    func testMockCategoriesFiltering() async throws {
        let service = MockCategoriesService()
        let all: [AppCategory] = try await service.fetchAll()
        XCTAssertFalse(all.isEmpty)
        let incomes = try await service.fetch(by: .income)
        XCTAssertTrue(incomes.allSatisfy { $0.direction == .income })
        let outcomes = try await service.fetch(by: .outcome)
        XCTAssertTrue(outcomes.allSatisfy { $0.direction == .outcome })
    }

    func testBankAccountDecodingAndEncoding() throws {
        let json: Data = """
        {
          "id": 10,
          "userId": 42,
          "name": "Main",
          "balance": "1234.56",
          "currency": "USD",
          "createdAt": "2021-01-01T00:00:00Z",
          "updatedAt": "2021-06-01T12:00:00Z"
        }
        """.data(using: .utf8)!

        let account: AppBankAccount = try JSONDecoder().decode(AppBankAccount.self, from: json)
        XCTAssertEqual(account, AppBankAccount(
            id: 10,
            userId: 42,
            name: "Main",
            balance: Decimal(string: "1234.56")!,
            currency: "USD",
            createdAt: ISO8601DateFormatter().date(from: "2021-01-01T00:00:00Z")!,
            updatedAt: ISO8601DateFormatter().date(from: "2021-06-01T12:00:00Z")!
        ))

        let encoded = try JSONEncoder().encode(account)
        let dict = try JSONSerialization.jsonObject(with: encoded, options: []) as? [String: Any]
        XCTAssertEqual(dict?["id"] as? Int, 10)
        if let num = dict?["balance"] as? NSNumber {
            XCTAssertEqual(num.decimalValue, Decimal(string: "1234.56"))
        } else if let str = dict?["balance"] as? String {
            XCTAssertEqual(Decimal(string: str), Decimal(string: "1234.56"))
        } else {
            XCTFail("Balance encoding type mismatch")
        }
    }

    func testTransactionJSONDecodingAndParse() throws {
        let json: Data = """
        {
          "id": 100,
          "accountId": 10,
          "categoryId": 2,
          "amount": 99.99,
          "transactionDate": "2021-06-01T08:30:00Z",
          "comment": "Morning coffee",
          "createdAt": "2021-06-01T08:30:01Z",
          "updatedAt": "2021-06-01T08:30:02Z"
        }
        """.data(using: .utf8)!

        let tx: AppTransaction = try JSONDecoder().decode(AppTransaction.self, from: json)
        XCTAssertEqual(tx.id, 100)
        XCTAssertEqual(tx.accountId, 10)
        XCTAssertEqual(tx.categoryId, 2)
        XCTAssertEqual(tx.amount, Decimal(string: "99.99"))
        XCTAssertEqual(tx.comment, "Morning coffee")

        let obj = tx.jsonObject
        guard let dict = obj as? [String: Any] else {
            XCTFail("jsonObject should be [String: Any]")
            return
        }
        let parsed = AppTransaction.parse(jsonObject: dict)
        XCTAssertEqual(parsed, tx)
    }

    func testTransactionCSVParsing() throws {
        let header = AppTransaction.csvHeader
        let line = "1,1,2,50.00,2021-01-01T00:00:00Z,Test,2021-01-01T00:00:00Z,2021-01-01T00:00:00Z"
        let csv = header + "\n" + line

        let txs = AppTransaction.parse(csv: csv)
        XCTAssertEqual(txs.count, 1)
        let tx = txs[0]
        XCTAssertEqual(tx.id, 1)
        XCTAssertEqual(tx.amount, Decimal(string: "50.00"))
        XCTAssertEqual(tx.comment, "Test")
    }

    func testTransactionsFileCacheAddRemove() throws {
        let fileName = "test-cache.json"
        let cache = TransactionsFileCache(fileName: fileName)
        _ = cache.load()

        let date = ISO8601DateFormatter().date(from: "2021-01-01T00:00:00Z")!
        let tx = AppTransaction(
            id: 1,
            accountId: 1,
            categoryId: 1,
            amount: Decimal(string: "5.00")!,
            transactionDate: date,
            comment: "c",
            createdAt: date,
            updatedAt: date
        )
        cache.add(tx)
        XCTAssertEqual(cache.allTransactions.count, 1)
        cache.remove(id: 1)
        XCTAssertTrue(cache.allTransactions.isEmpty)
    }

    func testMockBankAccountsService() async throws {
        let service = MockBankAccountsService()
        let acct1 = try await service.fetchPrimary()
        XCTAssertEqual(acct1.id, 1)
        let updated = try await service.update(account: acct1)
        XCTAssertEqual(updated.id, acct1.id)
        XCTAssertTrue(updated.updatedAt > acct1.updatedAt)
    }

    func testMockTransactionsServiceCRUD() async throws {
        let now = Date()
        let service = MockTransactionsService(initial: [])

        let created = try await service.create(AppTransaction(
            id: 0,
            accountId: 1,
            categoryId: 1,
            amount: Decimal(string: "1.23")!,
            transactionDate: now,
            comment: nil,
            createdAt: now,
            updatedAt: now
        ))
        XCTAssertEqual(created.id, 1)

        let fetched = try await service.fetch(start: now.addingTimeInterval(-1), end: now.addingTimeInterval(1))
        XCTAssertTrue(fetched.contains { $0.id == created.id })

        var mod = created
        mod.amount = Decimal(string: "2.00")!
        let updated2 = try await service.update(mod)
        XCTAssertEqual(updated2.amount, Decimal(string: "2.00"))

        try await service.delete(id: created.id)
        let afterDelete = try await service.fetch(start: now.addingTimeInterval(-1), end: now.addingTimeInterval(1))
        XCTAssertFalse(afterDelete.contains { $0.id == created.id })
    }
}
