// CustomNotification
import UIKit
import UserNotifications
import UserNotificationsUI
import WebKit

class NotificationViewController: UIViewController, UNNotificationContentExtension {
    
    var wkWebView: WKWebView!
    private var loadingObservation: NSKeyValueObservation?
    var isLoaded = false
    
    private lazy var indicator: UIActivityIndicatorView  = {
        let progressView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        progressView.hidesWhenStopped = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()
    
    override func loadView() {
        self.loadWebView()
    }
    
    func loadWebView() {
       
        wkWebView = makeWebView()
        
        self.view = wkWebView
        view.addSubview(indicator)

        //To show activity indicator when webview is Loading..
        loadingObservation = wkWebView.observe(\.isLoading, options: [.new, .old]) { [weak self] (_, change) in
            guard let strongSelf = self else { return }

            let new = change.newValue!
            let old = change.oldValue!

            if new && !old {
                strongSelf.view.addSubview(strongSelf.indicator)
                strongSelf.indicator.startAnimating()
                NSLayoutConstraint.activate([strongSelf.indicator.centerXAnchor.constraint(equalTo: strongSelf.view.centerXAnchor),
                                             strongSelf.indicator.centerYAnchor.constraint(equalTo: strongSelf.view.centerYAnchor)])
                strongSelf.view.bringSubviewToFront(strongSelf.indicator)
            }
            else if !new && old {
                strongSelf.indicator.stopAnimating()
                strongSelf.indicator.removeFromSuperview()
            }
        }
        
    }
    
    func makeWebView() -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        let configuration = WebConfiguration.getWebViewConfiguration()
        configuration.preferences = preferences
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        let configuration = WebConfiguration.getWebViewConfiguration()
//        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
//        self.webContainer.addSubview(webView)
//
//        //Add Constraints
//        webView.translatesAutoresizingMaskIntoConstraints = false
//        webContainer.addConstraint(NSLayoutConstraint(item: webView, attribute: .trailing, relatedBy: .equal, toItem: webContainer, attribute: .trailing, multiplier: 1, constant: 0))
//        webContainer.addConstraint(NSLayoutConstraint(item: webView, attribute: .leading, relatedBy: .equal, toItem: webContainer, attribute: .leading, multiplier: 1, constant: 0))
//
//        webContainer.addConstraint(NSLayoutConstraint(item: webView, attribute: .top, relatedBy: .equal, toItem: webContainer, attribute: .top, multiplier: 1, constant: 0))
//        webContainer.addConstraint(NSLayoutConstraint(item: webView, attribute: .bottom, relatedBy: .equal, toItem: webContainer, attribute: .bottom, multiplier: 1, constant: 0))
//        webContainer.setNeedsUpdateConstraints()
//
//        webContainer.bringSubviewToFront(activityIndicator)
//
//        webView.scrollView.backgroundColor = UIColor.white
//        view.backgroundColor = .white
//
//        webView.navigationDelegate = self
//        wkWebView = webView
//    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    func didReceive(_ notification: UNNotification) {
        
        self.preferredContentSize = CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height - 120)
        self.view.setNeedsUpdateConstraints()
        self.view.setNeedsLayout()
        
        let content = notification.request.content
        if let page = content.userInfo["page"] as? String, let pageURL = URL(string: Endpoint.appendURLTokenTo(urlString: page)) {
            wkWebView.load(URLRequest(url: pageURL))
        }
    }
}

//// MARK: - UIWebViewDelegate
//extension NotificationViewController: WKNavigationDelegate {
//    
//    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        activityIndicator.stopAnimating()
//    }
//    
//    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
//        activityIndicator.stopAnimating()
//    }
//    
//    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//        decisionHandler(.allow)
//        return
//    }
//}
