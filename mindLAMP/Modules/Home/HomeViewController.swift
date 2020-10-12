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
    private var loadingObservation: NSKeyValueObservation?
    //@IBOutlet weak var containerView: UIView!
    private lazy var indicator: UIActivityIndicatorView  = {
        let progressView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
        progressView.hidesWhenStopped = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()
    
    var lampDashboardURLwithToken: URL {
        let urlString = LampURL.dashboardDigitalURLText
        if let base64token = Endpoint.getURLToken() {
            return URL(string: urlString + "?a=" + base64token)!
        }
        return LampURL.dashboardDigital
    }
    
    override func loadView() {
        
        cleanCache()
        self.loadWebView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("mindLAMP Home")
        
        loadWebPage()
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        printError("Stopping sensors for a while due to memory warning")
        LMSensorManager.shared.stopSensors(false)
        DispatchQueue.global().asyncAfter(deadline: .now() + 300) {
            LMSensorManager.shared.checkIsRunning()
        }
    }
    
}

// MARK: - private

private extension HomeViewController {
    
    func cleanCache() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        print("[WebCacheCleaner] All cookies deleted")
        
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
                print("[WebCacheCleaner] Record \(record) deleted")
            }
        }
        
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let date = Date(timeIntervalSince1970: 0)
        if let webData = websiteDataTypes as? Set<String> {
            WKWebsiteDataStore.default().removeData(ofTypes: webData, modifiedSince: date, completionHandler:{ })
        }
        
    }
    
    @objc func updateWatchOS(_ notification: Notification) {
        
        if User.shared.isLogin() == true, let loginInfo = User.shared.loginInfo {
            let messageInfo: [String: Any] = [IOSCommands.login : loginInfo, "timestamp" : Date().timeInMilliSeconds]
            WatchSessionManager.shared.updateApplicationContext(applicationContext: messageInfo)
        } else {
            let messageInfo: [String: Any] = [IOSCommands.logout : true]
            WatchSessionManager.shared.updateApplicationContext(applicationContext: messageInfo)
        }
    }
    
    func loadWebView() {
        
        wkWebView = makeWebView()
        
        wkWebView.navigationDelegate = self
        
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
    
    func loadWebPage() {
        //check dashboard is offline available
        if UserDefaults.standard.version == nil {
            if User.shared.isLogin() == true {
                print("self.lampDashboardURLwithToken = \(self.lampDashboardURLwithToken)")
                wkWebView.load(URLRequest(url: self.lampDashboardURLwithToken))
            } else {
                print("LampURL.dashboardDigital = \(LampURL.dashboardDigital)")
                wkWebView.load(URLRequest(url: LampURL.dashboardDigital))
            }
        } else {
            // Do any additional setup after loading the view.
            //ToDO: NodeManager.shared.startNodeServer()
            let deadlineTime = DispatchTime.now() + .seconds(5)
            DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                //NodeManager.shared.getServerStatus()
                self.wkWebView.load(URLRequest(url: LampURL.dashboardDigital))
            }
        }
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
        return webView
    }
    
    func performOnLogin() {
        LMSensorManager.shared.checkIsRunning()
        
        //update device token after login
        guard let deviceToken = UserDefaults.standard.deviceToken else {
            printError("return ..no device token")
            return }
        let tokenInfo = DeviceInfoWithToken(deviceToken: deviceToken, userAgent: UserAgent.defaultAgent)
        let tokenRerquest = PushNotification.UpdateTokenRequest(deviceInfoWithToken: tokenInfo)
        let lampAPI = NotificationAPI(NetworkConfig.networkingAPI())
        
        lampAPI.sendDeviceToken(request: tokenRerquest) {_ in }
    }
    
    func performOnLogout() {
        User.shared.logout()
        LMSensorManager.shared.stopSensors(true)
    }
}


// MARK: - WKNavigationDelegate


extension HomeViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("didFinish navigation")
        //indicator.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("error = \(error.localizedDescription)")
        //indicator.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        
        let alert = UIAlertController(title: "alert.lamp.title".localized, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "alert.button.cancel".localized, style: .cancel, handler: { action in
           }))
        alert.addAction(UIAlertAction(title: "alert.button.retry".localized, style: .default, handler: { action in
            self.loadWebPage()
        }))
        self.present(alert, animated: true, completion: nil)
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
            //read token. it will be inthe format of UserName:Password
            guard let token = (dictBody[ScriptMessageKey.authorizationToken.rawValue] as? String),
                let idObjectDict = dictBody[ScriptMessageKey.identityObject.rawValue] as? [String: Any],
                let userID = idObjectDict["id"] as? String  else { return }
            
            let serverAddress = dictBody[ScriptMessageKey.serverAddress.rawValue] as? String
            
            let base64Token = token.data(using: .utf8)?.base64EncodedString()
            Endpoint.setSessionKey(base64Token)
            
            var serverAddressValue = serverAddress ?? ""
            
            let withOutHttp = serverAddressValue.cleanHostName()

            //store url token to load dashboarn on next launch
            let uRLToken = "\(token):\(withOutHttp)"//UserName:Password:ServerAddress
            let base64URLToken = uRLToken.data(using: .utf8)?.base64EncodedString()
            Endpoint.setURLToken(base64URLToken)

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

