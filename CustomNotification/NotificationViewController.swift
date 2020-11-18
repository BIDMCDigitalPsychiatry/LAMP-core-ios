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
        
        // Do any required interface initialization here.
        let webConfiguration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webConfiguration.dataDetectorTypes =  WKDataDetectorTypes.all
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //webContainerHeight.constant = webContainer.frame.size.width - 35
        
    }
    
    func didReceive(_ notification: UNNotification) {
        let content = notification.request.content
        guard let urlImageString = content.userInfo["page"] as? String, let url = URL(string: urlImageString) else {
            return
        }
        wkWebView.load(URLRequest(url: url))
    }
    
}

// MARK: - UIWebViewDelegate
extension NotificationViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("webView finish")
        activityIndicator.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("webView err")
        activityIndicator.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
        return
    }
}
