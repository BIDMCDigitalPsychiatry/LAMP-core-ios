//
//  HomeViewController.swift
//  mindLAMP Consortium
//
//  Created by ZCo Engg Dept on 16/01/20.
//

import UIKit
import WebKit

class HomeViewController: UIViewController {

    private var wkWebView: WKWebView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!

    var lampDashboardURLwithToken: URL {
        let urlString = LampURL.dashboardDigitalWithToken
        let base64UserInfo = Endpoint.getSessionKey() ?? ""
        return URL(string: urlString + base64UserInfo)!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("mindLAMP Home")
        //check dashboard is offline available
        if UserDefaults.standard.version == nil {
            if User.shared.isLogin() == true {
                self.loadWebView(with: self.lampDashboardURLwithToken)
            } else {
                self.loadWebView(with: LampURL.dashboardDigital)
            }
        } else {
            // Do any additional setup after loading the view.
            //ToDO: NodeManager.shared.startNodeServer()

            let deadlineTime = DispatchTime.now() + .seconds(5)
            DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                //NodeManager.shared.getServerStatus()
                self.loadWebView(with: LampURL.dashboardDigital)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateWatchOS(_:)),
        name: UIApplication.didBecomeActiveNotification, object: nil)

    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Show the navigation bar on other view controllers
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
        
}

// MARK: - private

private extension HomeViewController {
    
    @objc func updateWatchOS(_ notification: Notification) {
        
        if User.shared.isLogin() == true, let loginInfo = User.shared.loginInfo {
            let messageInfo: [String: Any] = [IOSCommands.login : loginInfo, "timestamp" : Date().timeInMilliSeconds]
            WatchSessionManager.shared.updateApplicationContext(applicationContext: messageInfo)
        } else {
            let messageInfo: [String: Any] = [IOSCommands.logout : true]
            WatchSessionManager.shared.updateApplicationContext(applicationContext: messageInfo)
        }
    }
      
    func loadWebView(with url: URL) {
        
        let webView = makeWebView()
        self.containerView.addSubview(webView)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addConstraint(NSLayoutConstraint(item: webView, attribute: .trailing, relatedBy: .equal, toItem: containerView, attribute: .trailing, multiplier: 1, constant: 0))
        containerView.addConstraint(NSLayoutConstraint(item: webView, attribute: .leading, relatedBy: .equal, toItem: containerView, attribute: .leading, multiplier: 1, constant: 0))
        
        containerView.addConstraint(NSLayoutConstraint(item: webView, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .top, multiplier: 1, constant: 0))
        containerView.addConstraint(NSLayoutConstraint(item: webView, attribute: .bottom, relatedBy: .equal, toItem: containerView, attribute: .bottom, multiplier: 1, constant: 0))
        containerView.setNeedsUpdateConstraints()
        
        self.containerView.bringSubviewToFront(indicator)
        
        webView.load(URLRequest(url: url))
        wkWebView = webView
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
        LMSensorManager.shared.startSensors()
        
        //update device token after login
        guard let deviceToken = UserDefaults.standard.deviceToken else { return }
        let tokenInfo = DeviceInfoWithToken(deviceToken: deviceToken, userAgent: UserAgent.defaultAgent)
        let tokenRerquest = PushNotification.UpdateTokenRequest(deviceInfoWithToken: tokenInfo)
        let lampAPI = NotificationAPI(NetworkConfig.networkingAPI())
        
        lampAPI.sendDeviceToken(request: tokenRerquest) {_ in }
    }
    
    func performOnLogout() {
        User.shared.logout()
        LMSensorManager.shared.stopSensors()
    }
}


// MARK: - WKNavigationDelegate


extension HomeViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("didFinish navigation")
        indicator.stopAnimating()

    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("error = \(error.localizedDescription)")
        indicator.stopAnimating()
    }
}

// MARK: - WKScriptMessageHandler

extension HomeViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == ScriptMessageHandler.login.rawValue {
            guard let dictBody = message.body as? [String: Any] else {
                printError("Message body not in expected format.")
                return
            }
            print("dictBody = \(dictBody)\n")
            //read token
            let token = (dictBody["authorizationToken"] as? String) ?? "U3998365801:12345"
            let base64Token = token.data(using: .utf8)?.base64EncodedString()
            Endpoint.setSessionKey(base64Token)
            
            let serverAddress = dictBody["serverAddress"] as? String//"https://dashboard-staging.lamp.digital"//TODO:
            
            let idObjectDict = dictBody["identityObject"] as? [String: Any]
            
            guard let userID = idObjectDict?["id"] as? String else {return}
            
            User.shared.login(userID: userID, serverAddress: serverAddress)
            
            //Inform watch the login info
            if let dictInfo = User.shared.loginInfo {
                let messageInfo: [String: Any] = [IOSCommands.login: dictInfo, "timestamp" : Date().timeInMilliSeconds]
                WatchSessionManager.shared.updateApplicationContext(applicationContext: messageInfo)
            }
            performOnLogin()
        } else if message.name == ScriptMessageHandler.logout.rawValue {
            let messageInfo: [String: Any] = [IOSCommands.logout: true, "timestamp" : Date().timeInMilliSeconds]
            WatchSessionManager.shared.updateApplicationContext(applicationContext: messageInfo)
            performOnLogout()
        }
    }
}
