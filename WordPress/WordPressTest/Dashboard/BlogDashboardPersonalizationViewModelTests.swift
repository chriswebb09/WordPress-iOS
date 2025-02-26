import XCTest
import Nimble

@testable import WordPress

final class BlogDashboardPersonalizationViewModelTests: XCTestCase {
    private let repository = InMemoryUserDefaults()
    private lazy var service = BlogDashboardPersonalizationService(repository: repository, siteID: 1)

    var viewModel: BlogDashboardPersonalizationViewModel!

    override func setUp() {
        super.setUp()

        viewModel = BlogDashboardPersonalizationViewModel(service: service)
    }

    func testThatCardStateIsToggled() throws {
        // Given
        let cardViewModel = try XCTUnwrap(viewModel.cards.first)
        let card = cardViewModel.id
        XCTAssertEqual(card, .todaysStats)
        XCTAssertTrue(cardViewModel.isOn, "By default, the cards are enabled")
        XCTAssertTrue(service.isEnabled(card))

        // When
        cardViewModel.isOn.toggle()

        // Then
        XCTAssertFalse(cardViewModel.isOn)
        XCTAssertFalse(service.isEnabled(card), "Service wasn't updated")
    }
}
