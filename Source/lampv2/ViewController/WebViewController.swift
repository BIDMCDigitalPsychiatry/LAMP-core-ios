//
//  WebViewController.swift
//  lampv2
//
//  Created by ZCo Engg Dept on 16/01/20.
//  Copyright © 2020 lamp. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController {

    private var webView: WKWebView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    let lampDashboardURL = URL(string: "https://dashboard.lamp.digital")!//http://127.0.0.1:5000/login
    var lampDashboardURLwithToken: URL {
        let urlString = "https://dashboard.lamp.digital/#/?a="
        let base64UserInfo = Endpoint.getSessionKey() ?? ""
        return URL(string: urlString + base64UserInfo)!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        NodeManager.shared.startNodeServer()
//
//        let deadlineTime = DispatchTime.now() + .seconds(2)
//        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
//            NodeManager.shared.getServerStatus()
            if self.isLogin() == true {
                self.loadWebView(with: self.lampDashboardURLwithToken)
            } else {
                self.loadWebView(with: self.lampDashboardURL)
            }
//        }
    }
}

// MARK: - private

private extension WebViewController {
    
    func isLogin() -> Bool {
        return (Endpoint.getSessionKey() != nil) && (UserDefaults.standard.userID != nil)
    }
        
    func loadWebView(with url: URL) {
        
        webView = makeWebView()
        self.containerView.addSubview(webView)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addConstraint(NSLayoutConstraint(item: webView!, attribute: .trailing, relatedBy: .equal, toItem: containerView, attribute: .trailing, multiplier: 1, constant: 0))
        containerView.addConstraint(NSLayoutConstraint(item: webView!, attribute: .leading, relatedBy: .equal, toItem: containerView, attribute: .leading, multiplier: 1, constant: 0))
        
        containerView.addConstraint(NSLayoutConstraint(item: webView!, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .top, multiplier: 1, constant: 0))
        containerView.addConstraint(NSLayoutConstraint(item: webView!, attribute: .bottom, relatedBy: .equal, toItem: containerView, attribute: .bottom, multiplier: 1, constant: 0))
        containerView.setNeedsUpdateConstraints()
        
        self.containerView.bringSubviewToFront(indicator)
        
        webView.load(URLRequest(url: url))
    }

    func makeWebView() -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true

        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.userContentController.add(self, name: ScriptMessageHandler.login.rawValue)
        configuration.userContentController.add(self, name: ScriptMessageHandler.logout.rawValue)
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        
        webView.navigationDelegate = self

        return webView
    }
    
    func performOnLogin() {
        SensorManager.shared.startSensors()
    }
    
    func performOnLogout() {
        Endpoint.setSessionKey(nil)
        UserDefaults.standard.clearAll()
        SensorManager.shared.stopSensors()
    }
}


// MARK: - WKNavigationDelegate

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        indicator.stopAnimating()

    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        indicator.stopAnimating()
    }
}

// MARK: - WKScriptMessageHandler

extension WebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == ScriptMessageHandler.login.rawValue {
            guard let dictBody = message.body as? [String: Any] else {
                printError("Message body not in expected format.")
                return
            }
            //read token
            let token = dictBody["authorizationToken"] as? String
            let base64Token = token?.data(using: .utf8)?.base64EncodedString()
            Endpoint.setSessionKey(base64Token)
            
            let serverAddress = dictBody["serverAddress"] as? String
            UserDefaults.standard.serverAddress = serverAddress

            let idObjectDict = dictBody["identityObject"] as? [String: Any]
            let userID = idObjectDict?["id"] as? String
            UserDefaults.standard.userID = userID
            
            performOnLogin()
        } else if message.name == ScriptMessageHandler.logout.rawValue {
            performOnLogout()
        }
    }
}
