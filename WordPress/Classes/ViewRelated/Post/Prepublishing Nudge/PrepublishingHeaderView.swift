import UIKit
import Gridicons

protocol PrepublishingHeaderViewDelegate: class {
    func backButtonTapped()
}

class PrepublishingHeaderView: UIView, NibLoadable {
    
    @IBOutlet weak var blogImageView: UIImageView!
    @IBOutlet weak var publishingToLabel: UILabel!
    @IBOutlet weak var blogTitleLabel: UILabel!
    @IBOutlet weak var backButtonView: UIView!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var backButton: UIButton!

    weak var delegate: PrepublishingHeaderViewDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackButton()
        configurePublishingToLabel()
        configureBlogTitleLabel()
    }

    func configure(_ blog: Blog) {
        blogImageView.downloadSiteIcon(for: blog)
        blogTitleLabel.text = blog.title
    }

    func hideBackButton() {
        backButtonView.layer.opacity = 0
        backButtonView.isHidden = true
        leadingConstraint.constant = Constants.leftRightInset
    }

    func showBackButton() {
        backButtonView.layer.opacity = 1
        backButtonView.isHidden = false
        leadingConstraint.constant = 0
    }

    @IBAction func backButtonTapped(_ sender: Any) {
        delegate?.backButtonTapped()
    }

    private func configureBackButton() {
        backButtonView.isHidden = true
        backButton.setImage(Gridicon.iconOfType(.chevronLeft, withSize: Constants.backButtonSize), for: .normal)
    }

    private func configurePublishingToLabel() {
        publishingToLabel.text = publishingToLabel.text?.uppercased()
        publishingToLabel.font = WPStyleGuide.TableViewHeaderDetailView.titleFont
        publishingToLabel.textColor = WPStyleGuide.TableViewHeaderDetailView.titleColor
    }

    private func configureBlogTitleLabel() {
        WPStyleGuide.applyPostTitleStyle(blogTitleLabel)
    }

    private enum Constants {
        static let backButtonSize = CGSize(width: 28, height: 28)
        static let leftRightInset: CGFloat = 20
    }
}
