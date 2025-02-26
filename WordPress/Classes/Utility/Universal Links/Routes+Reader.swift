import Foundation

enum ReaderRoute {
    case root
    case discover
    case search
    case a8c
    case p2
    case likes
    case manageFollowing
    case list
    case tag
    case feed
    case blog
    case feedsPost
    case blogsPost
    case wpcomPost
}

extension ReaderRoute: Route {
    var path: String {
        switch self {
        case .root:
            return "/read"
        case .discover:
            return "/discover"
        case .search:
            return "/read/search"
        case .a8c:
            return "/read/a8c"
        case .p2:
            return "/read/p2"
        case .likes:
            return "/activities/likes"
        case .manageFollowing:
            return "/following/manage"
        case .list:
            return "/read/list/:username/:list_name"
        case .tag:
            return "/tag/:tag_name"
        case .feed:
            return "/read/feeds/:feed_id"
        case .blog:
            return "/read/blogs/:blog_id"
        case .feedsPost:
            return "/read/feeds/:feed_id/posts/:post_id"
        case .blogsPost:
            return "/read/blogs/:blog_id/posts/:post_id"
        case .wpcomPost:
            return "/:post_year/:post_month/:post_day/:post_name"
        }
    }

    var section: DeepLinkSection? {
        return .reader
    }

    var action: NavigationAction {
        return self
    }

    var jetpackPowered: Bool {
        return true
    }
}

extension ReaderRoute: NavigationAction {
    func perform(_ values: [String: String], source: UIViewController? = nil, router: LinkRouter) {
        guard JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled() else {
            RootViewCoordinator.sharedPresenter.showReaderTab() // Show static reader tab
            return
        }
        guard let coordinator = RootViewCoordinator.sharedPresenter.readerCoordinator else {
            return
        }

        switch self {
        case .root:
            coordinator.showReaderTab()
        case .discover:
            coordinator.showDiscover()
        case .search:
            coordinator.showSearch()
        case .a8c:
            coordinator.showA8C()
        case .p2:
            coordinator.showP2()
        case .likes:
            coordinator.showMyLikes()
        case .manageFollowing:
            coordinator.showManageFollowing()
        case .list:
            if let username = values["username"],
                let listName = values["list_name"] {
                coordinator.showList(named: listName, forUser: username)
            }
        case .tag:
            if let tagName = values["tag_name"] {
                coordinator.showTag(named: tagName)
            }
        case .feed:
            if let feedIDValue = values["feed_id"],
                let feedID = Int(feedIDValue) {
                coordinator.showStream(with: feedID, isFeed: true)
            }
        case .blog:
            if let blogIDValue = values["blog_id"],
                let blogID = Int(blogIDValue) {
                coordinator.showStream(with: blogID, isFeed: false)
            }
        case .feedsPost:
            if let (feedID, postID) = feedAndPostID(from: values) {
                coordinator.showPost(with: postID, for: feedID, isFeed: true)
            }
        case .blogsPost:
            if let (blogID, postID) = blogAndPostID(from: values) {
                coordinator.showPost(with: postID, for: blogID, isFeed: false)
            }
        case .wpcomPost:
            if let urlString = values[MatchedRouteURLComponentKey.url.rawValue],
               let url = URL(string: urlString),
               isValidWpcomUrl(values) {

                coordinator.showPost(with: url)
            }
        }
    }

    private func feedAndPostID(from values: [String: String]?) -> (Int, Int)? {
        guard let feedIDValue = values?["feed_id"],
            let postIDValue = values?["post_id"],
            let feedID = Int(feedIDValue),
            let postID = Int(postIDValue) else {
                return nil
        }

        return (feedID, postID)
    }

    private func blogAndPostID(from values: [String: String]?) -> (Int, Int)? {
        guard let blogIDValue = values?["blog_id"],
            let postIDValue = values?["post_id"],
            let blogID = Int(blogIDValue),
            let postID = Int(postIDValue) else {
                return nil
        }

        return (blogID, postID)
    }

    private func isValidWpcomUrl(_ values: [String: String]) -> Bool {
        let year = Int(values["post_year"] ?? "") ?? 0
        let month = Int(values["post_month"] ?? "") ?? 0
        let day = Int(values["post_day"] ?? "") ?? 0

        // we assume no posts were made in the 1800's or earlier
        func isYear(_ year: Int) -> Bool {
            year > 1900
        }

        func isMonth(_ month: Int) ->  Bool {
            (1...12).contains(month)
        }

        func isDay(_ day: Int) -> Bool {
            (1...31).contains(day)
        }

        return isYear(year) && isMonth(month) && isDay(day)
    }
}
