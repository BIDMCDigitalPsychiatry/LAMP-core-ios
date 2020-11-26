// CustomNotification
import UIKit
import UserNotifications
import UserNotificationsUI
import WebKit

class NotificationViewController: UIViewController, UNNotificationContentExtension {
    
    @IBOutlet weak var webContainer: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var wkWebView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let configuration = WebConfiguration.getWebViewConfiguration()
        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        self.webContainer.addSubview(webView)
        
        //Add Constraints
        webView.translatesAutoresizingMaskIntoConstraints = false
        webContainer.addConstraint(NSLayoutConstraint(item: webView, attribute: .trailing, relatedBy: .equal, toItem: webContainer, attribute: .trailing, multiplier: 1, constant: 0))
        webContainer.addConstraint(NSLayoutConstraint(item: webView, attribute: .leading, relatedBy: .equal, toItem: webContainer, attribute: .leading, multiplier: 1, constant: 0))
        
        webContainer.addConstraint(NSLayoutConstraint(item: webView, attribute: .top, relatedBy: .equal, toItem: webContainer, attribute: .top, multiplier: 1, constant: 0))
        webContainer.addConstraint(NSLayoutConstraint(item: webView, attribute: .bottom, relatedBy: .equal, toItem: webContainer, attribute: .bottom, multiplier: 1, constant: 0))
        webContainer.setNeedsUpdateConstraints()
        
        webContainer.bringSubviewToFront(activityIndicator)
        
        webView.scrollView.backgroundColor = UIColor.white
        view.backgroundColor = .white
        
        webView.navigationDelegate = self
        wkWebView = webView
    }
    
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

// MARK: - UIWebViewDelegate
extension NotificationViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
        return
    }
}
