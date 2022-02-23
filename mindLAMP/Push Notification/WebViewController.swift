//
//  WebViewController.swift
//  mindLAMP Consortium


import UIKit
import WebKit

class WebViewController: UIViewController {
    
    var wkWebView: WKWebView!
    private var loadingObservation: NSKeyValueObservation?
    var isLoaded = false
    //@IBOutlet weak var containerView: UIView!
    private lazy var indicator: UIActivityIndicatorView  = {
        let progressView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        progressView.hidesWhenStopped = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()
    
    var pageURL: URL!
    
    override func loadView() {
        //LeakAvoider.cleanCache()
        loadWebView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(false, animated: false)
        //+20210119
        if Environment.isDiigApp {
            let infoButton = UIBarButtonItem(image: UIImage(named: "icn-info"), style: .plain, target: self, action: #selector(infoButtonTapped))
            self.navigationItem.rightBarButtonItem = infoButton
        }
        
        wkWebView.uiDelegate = self
        wkWebView.load(URLRequest(url: pageURL))
    }
        
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//
//
//        let alert = UIAlertController(title: "alert.lamp.title".localized, message: pageURL.absoluteString, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "alert.button.ok".localized, style: .destructive, handler: { action in
//           }))
//        present(alert, animated: true, completion: nil)
//    }

}

extension WebViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil && navigationAction.request.url != nil {
            UIApplication.shared.open(navigationAction.request.url!)
        }
        return nil
    }
}

extension WebViewController {
    
    @objc
    func infoButtonTapped() {
        let alert = UIAlertController(title: "", message: title, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "alert.button.ok".localized, style: .default, handler: { action in
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func loadWebView() {
       
        wkWebView = makeWebView()
        
        self.view = UIView()
        self.view.backgroundColor = .systemBackground
        
        self.view.addSubview(wkWebView)
        wkWebView.scrollView.backgroundColor = .systemBackground
        wkWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            wkWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wkWebView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            wkWebView.rightAnchor.constraint(equalTo: view.rightAnchor),
            wkWebView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)])
        wkWebView.addSubview(indicator)

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
                strongSelf.wkWebView.bringSubviewToFront(strongSelf.indicator)
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
}
