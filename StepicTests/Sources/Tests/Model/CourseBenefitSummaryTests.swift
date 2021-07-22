@testable
import Stepic

import Nimble
import Quick
import SwiftyJSON

class CourseBenefitSummarySpec: QuickSpec {
    override func spec() {
        describe("CourseBenefitSummary") {
            describe("JSON parsing") {
                it("successfully parses course benefit summary") {
                    // Given
                    let json = TestData.courseBenefitSummary

                    // When
                    let summary = CourseBenefitSummary(json: json)

                    // Then
                    expect(summary.id) == 427139
                    expect(summary.currentDate!) == Parser.dateFromTimedateString("2021-06-07T16:13:25.147Z")!
                    expect(summary.totalIncome) == 14000
                    expect(summary.totalTurnover) == 20000
                    expect(summary.totalUserIncome) == 7000
                    expect(summary.monthIncome) == 0
                    expect(summary.monthTurnover) == 0
                    expect(summary.monthUserIncome) == 0
                    expect(summary.currencyCode) == "RUB"
                }
            }
        }
    }
}
