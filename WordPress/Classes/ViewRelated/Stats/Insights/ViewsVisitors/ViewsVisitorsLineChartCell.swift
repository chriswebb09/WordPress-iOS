import UIKit

struct StatsSegmentedControlData {
    var segmentTitle: String
    var segmentData: Int
    var segmentPrevData: Int
    var segmentDataStub: String?
    var difference: Int
    var differenceText: String
    var differencePercent: Int
    var date: Date?
    var period: StatsPeriodUnit?
    var analyticsStat: WPAnalyticsStat?

    private(set) var accessibilityHint: String?

    init(segmentTitle: String, segmentData: Int, segmentPrevData: Int, difference: Int, differenceText: String, segmentDataStub: String? = nil, date: Date? = nil, period: StatsPeriodUnit? = nil, analyticsStat: WPAnalyticsStat? = nil, accessibilityHint: String? = nil, differencePercent: Int) {
        self.segmentTitle = segmentTitle
        self.segmentData = segmentData
        self.segmentPrevData = segmentPrevData
        self.segmentDataStub = segmentDataStub
        self.difference = difference
        self.differenceText = differenceText
        self.differencePercent = differencePercent
        self.date = date
        self.period = period
        self.analyticsStat = analyticsStat
        self.accessibilityHint = accessibilityHint
    }

    var attributedDifferenceText: NSAttributedString? {
        guard difference != 0 || segmentData > 0 else {
            // No comparison shown if there's no change and 0 data
            return nil
        }

        let defaultAttributes = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .subheadline), NSAttributedString.Key.foregroundColor: UIColor.textSubtle]

        if difference == 0 && segmentData != 0 {
            return NSAttributedString(string: differenceText, attributes: defaultAttributes)
        }

        let differenceText = String(format: differenceText, differenceLabel)
        let attributedString = NSMutableAttributedString(string: differenceText, attributes: defaultAttributes)

        let str = attributedString.string as NSString
        let range = str.range(of: differenceLabel)

        attributedString.addAttributes([.foregroundColor: differenceTextColor,
                                        .font: UIFont.preferredFont(forTextStyle: .subheadline).bold()],
                range: NSRange(location: range.location, length: differenceLabel.count))

        return attributedString
    }

    var differenceLabel: String {
        let stringFormat = NSLocalizedString("%@%@ (%@%%)", comment: "Difference label for Insights Overview stat, indicating change from previous period. Ex: +99.9K(5%)")
        return String.localizedStringWithFormat(stringFormat,
                difference < 0 ? "" : "+",
                difference.abbreviatedString(),
                differencePercent.abbreviatedString())
    }

    var differenceTextColor: UIColor {
        return difference < 0 ? WPStyleGuide.Stats.negativeColor : WPStyleGuide.Stats.positiveColor
    }

    var title: String {
        return self.segmentTitle
    }

    var accessibilityIdentifier: String {
        return self.segmentTitle.localizedLowercase
    }

    var accessibilityLabel: String? {
        segmentTitle
    }

    var accessibilityValue: String? {
        return segmentDataStub != nil ? "" : "\(segmentData)"
    }

    enum Constants {
        static let viewsHigher = NSLocalizedString("Your views this week are %@ higher than the previous week.\n", comment: "Stats insights views higher than previous week")
        static let viewsLower = NSLocalizedString("Your views this week are %@ lower than the previous week.\n", comment: "Stats insights views lower than previous week")
        static let visitorsHigher = NSLocalizedString("Your visitors this week are %@ higher than the previous week.\n", comment: "Stats insights visitors higher than previous week")
        static let visitorsLower = NSLocalizedString("Your visitors this week are %@ lower than the previous week.\n", comment: "Stats insights visitors lower than previous week")
    }
}

class ViewsVisitorsLineChartCell: StatsBaseCell, NibLoadable {

    @IBOutlet weak var labelsStackView: UIStackView!
    @IBOutlet weak var legendLatestView: UIView!
    @IBOutlet weak var legendLatestLabel: UILabel!
    @IBOutlet weak var latestLabel: UILabel!
    @IBOutlet weak var latestData: UILabel!
    @IBOutlet weak var legendPreviousView: UIView!
    @IBOutlet weak var legendPreviousLabel: UILabel!
    @IBOutlet weak var previousLabel: UILabel!
    @IBOutlet weak var previousData: UILabel!
    @IBOutlet var differenceLabel: UILabel!
    @IBOutlet weak var chartContainerView: UIView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var bottomStackView: UIStackView!

    private weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    private typealias Style = WPStyleGuide.Stats
    private var segmentsData = [StatsSegmentedControlData]()

    private var chartData: [LineChartDataConvertible] = []
    private var chartStyling: [LineChartStyling] = []
    private weak var statsLineChartViewDelegate: StatsLineChartViewDelegate?
    private var chartHighlightIndex: Int?

    private var period: StatsPeriodUnit?
    private var xAxisDates: [Date] = []

    fileprivate lazy var tipView: DashboardStatsNudgeView = {
        let tipView = DashboardStatsNudgeView(title: Constants.topTipsText, hint: nil, insets: .zero)
        tipView.onTap = { [weak self] in
            if let url = URL(string: Constants.topTipsURLString) {
                self?.siteStatsInsightsDelegate?.displayWebViewWithURL?(url)
            }
        }
        return tipView
    }()

    // MARK: - Configure

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    func configure(segmentsData: [StatsSegmentedControlData],
                   lineChartData: [LineChartDataConvertible] = [],
                   lineChartStyling: [LineChartStyling] = [],
                   period: StatsPeriodUnit? = nil,
                   statsLineChartViewDelegate: StatsLineChartViewDelegate? = nil,
                   xAxisDates: [Date],
                   delegate: SiteStatsInsightsDelegate? = nil
    ) {
        siteStatsInsightsDelegate = delegate
        siteStatsInsightDetailsDelegate = siteStatsInsightsDelegate
        statSection = .insightsViewsVisitors

        self.segmentsData = segmentsData
        self.chartData = lineChartData
        self.chartStyling = lineChartStyling
        self.statsLineChartViewDelegate = statsLineChartViewDelegate
        self.period = period
        self.xAxisDates = xAxisDates

        setupSegmentedControl()
        configureChartView()
        updateLabels()
    }

    @IBAction func selectedSegmentDidChange(_ sender: Any) {
        if let event = segmentsData[segmentedControl.selectedSegmentIndex].analyticsStat {
            captureAnalyticsEvent(event)
        }

        configureChartView()
        updateLabels()
    }

}


// MARK: - Private Extension

private extension ViewsVisitorsLineChartCell {

    func applyStyles() {
        Style.configureCell(self)
        styleLabels()
    }

    func setupSegmentedControl() {
        segmentedControl.selectedSegmentTintColor = UIColor.white
        segmentedControl.setTitleTextAttributes([.font: UIFont.preferredFont(forTextStyle: .subheadline).bold()], for: .normal)
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        segmentedControl.setTitle(segmentsData[0].segmentTitle, forSegmentAt: 0)
        segmentedControl.setTitle(segmentsData[1].segmentTitle, forSegmentAt: 1)
    }

    func styleLabels() {
        latestData.font = UIFont.preferredFont(forTextStyle: .title2).bold()
        previousData.font = UIFont.preferredFont(forTextStyle: .title2).bold()

        legendLatestLabel.text = NSLocalizedString("This week", comment: "This week legend label")
        legendPreviousLabel.text = NSLocalizedString("Previous week", comment: "Previous week legend label")
    }

    func updateLabels() {
        let selectedSegmentIndex = segmentedControl.selectedSegmentIndex

        guard chartStyling.count > selectedSegmentIndex, segmentsData.count > selectedSegmentIndex else {
            return
        }

        let chartStyle = chartStyling[selectedSegmentIndex]
        legendLatestView.backgroundColor = chartStyle.primaryLineColor
        legendLatestLabel.textColor = chartStyle.primaryLineColor
        latestData.textColor = chartStyle.primaryLineColor
        latestLabel.textColor = chartStyle.primaryLineColor


        let segmentData = segmentsData[selectedSegmentIndex]
        latestLabel.text = segmentData.segmentTitle
        previousLabel.text = segmentData.segmentTitle

        latestData.text = segmentData.segmentData.abbreviatedString(forHeroNumber: true)
        previousData.text = segmentData.segmentPrevData.abbreviatedString(forHeroNumber: true)

        differenceLabel.attributedText = segmentData.attributedDifferenceText

        if segmentData.segmentData == 0 && segmentData.segmentPrevData == 0 {
            differenceLabel.removeFromSuperview()
            bottomStackView.addArrangedSubview(tipView)
        } else {
            tipView.removeFromSuperview()
            bottomStackView.addArrangedSubview(differenceLabel)
        }
    }

    // MARK: Chart support

    func configureChartView() {
        let selectedSegmentIndex = segmentedControl.selectedSegmentIndex

        guard chartData.count > selectedSegmentIndex, chartStyling.count > selectedSegmentIndex else {
            return
        }

        let configuration = StatsLineChartConfiguration(data: chartData[selectedSegmentIndex],
                                                       styling: chartStyling[selectedSegmentIndex],
                                                       analyticsGranularity: period?.analyticsGranularityLine,
                                                       indexToHighlight: 0,
                                                       xAxisDates: xAxisDates)

        let statsInsightsFilterDimension: StatsInsightsFilterDimension = selectedSegmentIndex == 0 ? .views : .visitors

        let chartView = StatsLineChartView(configuration: configuration, delegate: statsLineChartViewDelegate, statsInsightsFilterDimension: statsInsightsFilterDimension)

        resetChartContainerView()
        chartContainerView.addSubview(chartView)
        chartContainerView.accessibilityElements = [chartView]

        NSLayoutConstraint.activate([
            chartView.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
            chartView.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor),
            chartView.topAnchor.constraint(equalTo: chartContainerView.topAnchor),
            chartView.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor)
            ])
    }

    func resetChartContainerView() {
        for subview in chartContainerView.subviews {
            subview.removeFromSuperview()
        }
    }

    // MARK: - Analytics support

    func captureAnalyticsEvent(_ event: WPAnalyticsStat) {
        let properties: [AnyHashable: Any] = [StatsPeriodUnit.analyticsPeriodKey: period?.description as Any]

        if let blogIdentifier = SiteStatsInformation.sharedInstance.siteID {
            WPAppAnalytics.track(event, withProperties: properties, withBlogID: blogIdentifier)
        } else {
            WPAppAnalytics.track(event, withProperties: properties)
        }
    }

    enum Constants {
        static let topTipsText = NSLocalizedString("Check out our top tips to increase your views and traffic", comment: "Title for a button that opens up the 'Getting More Views and Traffic' support page when tapped.")
        static let topTipsURLString = "https://wordpress.com/support/getting-more-views-and-traffic/"
    }

}
