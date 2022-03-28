
/// Labels and button titles
struct WhatIsNewViewTitles {
    let header: String
    let version: String
    let continueButtonTitle: String
}


/// Main view of the What's New page
class WhatIsNewView: UIView {

    // MARK: - View elements
    private lazy var titleLabel: UILabel = {
        let label = makeLabel(viewTitles.header)
        label.font = self.appearance.headlineFont
        label.numberOfLines = 0
        return label
    }()

    private lazy var versionLabel: UILabel = {
        let label = makeLabel(viewTitles.version)

        // if there's no version, just hide the label and save that space
        guard !viewTitles.version.isEmpty else {
            label.isHidden = true
            return label
        }

        label.font = self.appearance.subHeadlineFont
        label.textColor = .textSubtle
        return label
    }()

    private lazy var backButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentEdgeInsets = UIEdgeInsets(top: self.appearance.backButtonInset, left: self.appearance.backButtonInset, bottom: 0, right: 0)
        button.setImage(UIImage.gridicon(.arrowLeft), for: .normal)
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        button.accessibilityLabel = NSLocalizedString("Back", comment: "Dismiss view")
        button.tintColor = self.appearance.backButtonTintColor
        return button
    }()

    private lazy var continueButton: UIButton = {
        let button = FancyButton()
        button.isPrimary = true
        button.titleFont = self.appearance.continueButtonFont
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(viewTitles.continueButtonTitle, for: .normal)
        button.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        button.accessibilityIdentifier = Accessibility.continueButtonIdentifier
        button.accessibilityHint = Accessibility.continueButtonHint
        return button
    }()

    private lazy var continueButtonView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(systemMaterialView)
        view.pinSubviewToAllEdges(systemMaterialView)
        return view
    }()

    private lazy var divider: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .divider
        return view
    }()

    private lazy var continueButtonStackView: UIStackView = {
        let stackView = makeVerticalStackView(arrangedSubviews: [divider, continueButtonView])
        return stackView
    }()

    private lazy var systemMaterialView: UIVisualEffectView = {
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: self.appearance.material))
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.contentView.addSubview(continueButton)
        visualEffectView.contentView.pinSubviewToSafeArea(continueButton, insets: self.appearance.continueButtonInsets)
        return visualEffectView
    }()

    private lazy var announcementsTableView: UITableView = {
        let tableView = UITableView()
        tableView.tableFooterView = UIView() // To hide the separators for empty cells
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = self.appearance.tableViewContentInsets
        tableView.estimatedRowHeight = self.appearance.estimatedRowHeight
        return tableView
    }()

    private lazy var headerStackView: UIStackView = {
        let stackView = makeVerticalStackView(arrangedSubviews: [titleLabel, versionLabel])
        stackView.setCustomSpacing(self.appearance.titleVersionSpacing, after: titleLabel)
        return stackView
    }()

    private lazy var headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerStackView)
        view.pinSubviewToAllEdges(headerStackView, insets: self.appearance.headerViewInsets)
        return view
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(announcementsTableView)
        view.pinSubviewToSafeArea(announcementsTableView, insets: self.appearance.mainContentInsets)
        return view
    }()

    // MARK: - Properties
    private let viewTitles: WhatIsNewViewTitles
    private let dataSource: AnnouncementsDataSource
    private let appearance: WhatIsNewViewAppearance

    var continueAction: (() -> Void)?
    var dismissAction: (() -> Void)?

    init(viewTitles: WhatIsNewViewTitles, dataSource: AnnouncementsDataSource, appearance: WhatIsNewViewAppearance, showsBackButton: Bool = false) {
        self.viewTitles = viewTitles
        self.dataSource = dataSource
        self.appearance = appearance

        super.init(frame: .zero)

        backgroundColor = .basicBackground
        addSubview(contentView)
        addSubview(continueButtonStackView)
        pinSubviewToAllEdges(contentView)
        announcementsTableView.tableHeaderView = headerView

        NSLayoutConstraint.activate([
            continueButton.heightAnchor.constraint(equalToConstant: self.appearance.continueButtonHeight),
            divider.heightAnchor.constraint(equalToConstant: .hairlineBorderWidth),
            continueButtonStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            continueButtonStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            continueButtonStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerView.widthAnchor.constraint(equalTo: announcementsTableView.widthAnchor)
        ])

        if showsBackButton {
            addSubview(backButton)
            NSLayoutConstraint.activate([
                backButton.leftAnchor.constraint(equalTo: leftAnchor),
                backButton.topAnchor.constraint(equalTo: topAnchor),
            ])
        }

        setupTableViewDataSource()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


// MARK: - Helpers
private extension WhatIsNewView {

    func makeVerticalStackView(arrangedSubviews: [UIView]) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }

    func makeLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        return label
    }

    func setupTableViewDataSource() {
        announcementsTableView.dataSource = dataSource
        dataSource.registerCells(for: announcementsTableView)
        dataSource.dataDidChange = { [weak self] in
            self?.announcementsTableView.reloadData()
        }
    }

    @objc func continueButtonTapped() {
        continueAction?()
    }

    @objc func backButtonTapped() {
        dismissAction?()
    }
}


// MARK: - Layout
extension WhatIsNewView {

    override func layoutSubviews() {
        super.layoutSubviews()
        adjustTableHeaderViewLayout()
    }

    /// Resizes the `tableHeaderView` in `announcementsTableView` as necessary whenever its size changes.
    private func adjustTableHeaderViewLayout() {
        guard let headerView = announcementsTableView.tableHeaderView else {
            return
        }

        let height = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        var headerFrame = headerView.frame

        if height != headerFrame.size.height {
            headerFrame.size.height = height
            headerView.frame = headerFrame
            announcementsTableView.tableHeaderView = headerView
        }
    }
}

// MARK: - Accessibility
private extension WhatIsNewView {
    enum Accessibility {
        static let continueButtonIdentifier = "AnnouncementsContinueButton"
        static let continueButtonHint = NSLocalizedString("Dismiss announcements", comment: "Accessibility hint for the continue button in the Feature Announcements screen.")
    }
}
