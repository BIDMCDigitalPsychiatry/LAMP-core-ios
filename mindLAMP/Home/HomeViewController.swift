//
//  HomeViewController.swift
//  mindLAMP Consortium
//
//  Created by ZCo Engg Dept on 16/01/20.
//

import UIKit
import WebKit
import LAMP
//import Combine

class HomeViewController: UIViewController {
    
    private var wkWebView: WKWebView!
    private var loadingObservation: NSKeyValueObservation?
    private var isWebpageLoaded = false
    private lazy var lampAPI: NetworkingAPI = {
        return NetworkConfig.networkingAPI()
    }()
    
    var feedURLToLoad: URL?
    //var loginSubscriber: AnyCancellable?
    //var isHomePageLoaded = false
    //@IBOutlet weak var containerView: UIView!
    private lazy var indicator: UIActivityIndicatorView  = {
        let progressView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        progressView.hidesWhenStopped = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()
    
    private var lampDashboardURLwithToken: URL {
        let urlString = LampURL.dashboardDigitalURLText
        if let base64token = Endpoint.getURLToken() {
            return URL(string: urlString + "?a=" + base64token)!
        }
        return LampURL.dashboardDigital
    }
    
    lazy var scheduleHandler: ActivityLocalNotification = {
        return ActivityLocalNotification()
    }()
    var tappedActivityURL: URL? {
        didSet {
            guard let pageURL = tappedActivityURL else {return}
            wkWebView.endEditing(true)
            indicator.startAnimating()
            view.bringSubviewToFront(indicator)
            DispatchQueue.main.async {
                self.wkWebView.load(URLRequest(url: pageURL))
            }
            
        }
    }
    
    func tappedWidget() {
        
        guard let participantId = User.shared.userId else {
            return
        }
        let urlstring = String(format: "https://dashboard-staging.lamp.digital/#/participant/%@/feed", participantId)
        
        guard isWebpageLoaded == true else {
            feedURLToLoad = URL(string: urlstring)
            return
        }
        wkWebView.evaluateJavaScript("window.location.href='\(urlstring)';") { obbj ,error in
            self.wkWebView.evaluateJavaScript("window.location.reload()")
        }

//        guard let pageURL = URL(string: urlstring) else {return}
//        wkWebView.endEditing(true)
//        indicator.startAnimating()
//        view.bringSubviewToFront(indicator)
//        DispatchQueue.main.async {
//            self.wkWebView.load(URLRequest(url: pageURL))
//        }
    }
    
    override func loadView() {
        super.loadView()
        self.loadWebView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appState = UIApplication.shared.applicationState
        if appState != UIApplication.State.background {
            loadWebPage()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(appDidActive(_:)),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: NSNotification.Name(rawValue: "Reachability"), object: nil)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scheduleHandler.refreshActivities()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Show the navigation bar on other view controllers
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        printError("Stopping sensors for a while due to memory warning")
    }

    deinit {
        wkWebView.stopLoading()
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "Reachability"), object: nil)
        
        wkWebView.configuration.userContentController.removeScriptMessageHandler(forName: ScriptMessageHandler.login.rawValue)
        wkWebView.configuration.userContentController.removeScriptMessageHandler(forName: ScriptMessageHandler.logout.rawValue)
    }
    
    @objc func reachabilityChanged(note: Notification) {
        if isWebpageLoaded == false && !indicator.isAnimating {
            loadWebPage()
        }
    }
}

// MARK: - private

private extension HomeViewController {
    
    @objc func appDidActive(_ notification: Notification) {
        
        NotificationHelper.shared.removeAllExpiredNotifications()
        if isWebpageLoaded == false && !indicator.isAnimating {
            loadWebPage()
        }
        
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
        wkWebView.uiDelegate = self
        
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
        //wkWebView.scrollView.contentInsetAdjustmentBehavior = .never
        //wkWebView.addSubview(indicator)
        self.view.addSubview(indicator)
        NSLayoutConstraint.activate([indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                     indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
        //To show activity indicator when webview is Loading..
        loadingObservation = wkWebView.observe(\.isLoading, options: [.new, .old]) { [weak self] (_, change) in
            guard let strongSelf = self else { return }
            
            let new = change.newValue!
            let old = change.oldValue!
            
            if new && !old {
                // strongSelf.view.addSubview(strongSelf.indicator)
                strongSelf.indicator.startAnimating()
                //NSLayoutConstraint.activate([strongSelf.indicator.centerXAnchor.constraint(equalTo: strongSelf.view.centerXAnchor),
                //                             strongSelf.indicator.centerYAnchor.constraint(equalTo: strongSelf.view.centerYAnchor)])
                //strongSelf.wkWebView.bringSubviewToFront(strongSelf.indicator)
                strongSelf.view.bringSubviewToFront(strongSelf.indicator)
            }
            else if !new && old {
                strongSelf.indicator.stopAnimating()
                // strongSelf.indicator.removeFromSuperview() we should not remove because we have to show again when reload
            }
        }
        
    }
    
    func loadWebPage() {
        if User.shared.isLogin() == true {
            if let feedURL = feedURLToLoad {
                wkWebView.load(URLRequest(url: feedURL))
                feedURLToLoad = nil
            } else {
                wkWebView.load(URLRequest(url: self.lampDashboardURLwithToken))
            }
        } else {
            wkWebView.load(URLRequest(url: LampURL.dashboardDigital))
        }
    }
    
    func makeWebView() -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        
        
        let configuration = WebConfiguration.getWebViewConfiguration()
        configuration.processPool = WebViewStorage.shared.processPool
        configuration.preferences = preferences
        configuration.websiteDataStore = WebViewStorage.shared.dataStore
        //configuration.websiteDataStore = WKWebsiteDataStore.default()
        //configuration.userContentController.add(self, name: ScriptMessageHandler.login.rawValue)
        //configuration.userContentController.add(self, name: ScriptMessageHandler.logout.rawValue)
        
        configuration.userContentController.add(LeakAvoider(delegate:self), name: ScriptMessageHandler.login.rawValue)
        configuration.userContentController.add(LeakAvoider(delegate:self), name: ScriptMessageHandler.logout.rawValue)
        
        configuration.userContentController.add(LeakAvoider(delegate:self), name: "loadchecker")
        let source = """
function captureDivs() {
    var divs = document.getElementsByTagName("div");
    window.webkit.messageHandlers.loadchecker.postMessage(divs.length);
}
window.onload = captureDivs;
"""
        let userScript = WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        configuration.userContentController.addUserScript(userScript)
        
//        //to read console logs
//        // inject JS to capture console.log output and send to iOS
//        let source = "function captureLog(msg) { window.webkit.messageHandlers.logHandler.postMessage(msg); } window.console.log = captureLog;"
//        let script = WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false)
//        configuration.userContentController.addUserScript(script)
//        // register the bridge script that listens for the output
//        configuration.userContentController.add(self, name: "logHandler")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }
    
    func performOnLogin() {
        
        printToFile("\nperformOnLogin")
        LMSensorManager.shared.checkIsRunning()
        
        //call lamp.analytics for login
        let deviceToken = UserDefaults.standard.deviceToken
        guard let participantId = User.shared.userId else { return }
        
        let tokenInfo = DeviceInfoWithToken(deviceToken: deviceToken, userAgent: UserAgent.defaultAgent, action: SensorType.AnalyticAction.login.rawValue)
        let event = SensorEvent(timestamp: Date().timeInMilliSeconds, sensor: SensorType.lamp_analytics.lampIdentifier, data: tokenInfo)
        
        let endPoint =  String(format: Endpoint.participantSensorEvent.rawValue, participantId)
        let data = RequestData(endpoint: endPoint, requestTye: HTTPMethodType.post, data: event)
        lampAPI.makeWebserviceCall(with: data) { (response: Result<EmptyResponse>) in
            switch response {
            case .failure(let error):
                printError("loginSensorEventCreate error \(error.localizedDescription)")
            case .success:
                break
            }
            self.scheduleHandler.refreshActivities()
        }
  
        /* let deviceToken = UserDefaults.standard.deviceToken
        guard let authheader = Endpoint.getSessionKey(), let participantId = User.shared.userId else {
            return
        }
        OpenAPIClientAPI.basePath = LampURL.baseURLString
        OpenAPIClientAPI.customHeaders = ["Authorization": "Basic \(authheader)", "Content-Type": "application/json"]
        let tokenInfo = DeviceInfoWithToken(deviceToken: deviceToken, userAgent: UserAgent.defaultAgent, action: SensorType.AnalyticAction.login.rawValue)
       
        let event = SensorEvent(timestamp: Date().timeInMilliSeconds, sensor: SensorType.lamp_analytics.lampIdentifier, data: tokenInfo)
        let publisher = SensorEventAPI.sensorEventCreate(participantId: participantId, sensorEvent: event, apiResponseQueue: DispatchQueue.global())
        loginSubscriber = publisher.sink { value in
            switch value {
            case .failure(let error):
                printError("loginSensorEventCreate error \(error.localizedDescription)")
            case .finished:
                break
            }
            self.scheduleHandler.refreshActivities()
        } receiveValue: { (stringValue) in
            print("login receiveValue = \(stringValue)")
        }*/
    }
    
    func performOnLogout() {
        
        LeakAvoider.cleanCache()
        //send lamp.analytics for logout
        guard let _ = Endpoint.getSessionKey(), let participantId = User.shared.userId else {
            NotificationHelper.shared.removeAllNotifications()
            User.shared.logout()
            return
        }
        let tokenInfo = DeviceInfoWithToken(deviceToken: nil, userAgent: UserAgent.defaultAgent, action: SensorType.AnalyticAction.logout.rawValue)
        let event = SensorEvent(timestamp: Date().timeInMilliSeconds, sensor: SensorType.lamp_analytics.lampIdentifier, data: tokenInfo)
        let endPoint =  String(format: Endpoint.participantSensorEvent.rawValue, participantId)
        let data = RequestData(endpoint: endPoint, requestTye: HTTPMethodType.post, data: event)
        lampAPI.makeWebserviceCall(with: data) { (response: Result<EmptyResponse>) in
            NotificationHelper.shared.removeAllNotifications()
            User.shared.logout()
        }
/*
        guard let authheader = Endpoint.getSessionKey(), let participantId = User.shared.userId else {
            NotificationHelper.shared.removeAllNotifications()
            User.shared.logout()
            return
        }
        OpenAPIClientAPI.basePath = LampURL.baseURLString
        OpenAPIClientAPI.customHeaders = ["Authorization": "Basic \(authheader)", "Content-Type": "application/json"]
        let tokenInfo = DeviceInfoWithToken(deviceToken: nil, userAgent: UserAgent.defaultAgent, action: SensorType.AnalyticAction.logout.rawValue)
        let event = SensorEvent(timestamp: Date().timeInMilliSeconds, sensor: SensorType.lamp_analytics.lampIdentifier, data: tokenInfo)
        let publisher = SensorEventAPI.sensorEventCreate(participantId: participantId, sensorEvent: event, apiResponseQueue: DispatchQueue.global())
        loginSubscriber = publisher.sink { _ in
            NotificationHelper.shared.removeAllNotifications()
            User.shared.logout()
        } receiveValue: { (stringValue) in
            print("login receiveValue = \(stringValue)")
        }*/
    }
    
}

extension HomeViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil && navigationAction.request.url != nil {
            UIApplication.shared.open(navigationAction.request.url!)
        }
        return nil
    }
}
// MARK: - WKNavigationDelegate


extension HomeViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // we are getting this call back even if the page is not loaded. we can reproduce it by on/off the wifi frequently while loading page.#651
        indicator.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        indicator.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == -999 { return }
        let msg: String
        if (error as NSError).code == -1001 { // TIMED OUT:
            // CODE to handle TIMEOUT
            msg = "error.network.timeout".localized
        } else if (error as NSError).code == -1003 { // SERVER CANNOT BE FOUND
            // CODE to handle SERVER not found
            msg = "error.server.notresponding".localized
        } else if (error as NSError).code == -1100 { // URL NOT FOUND ON SERVER
            // CODE to handle URL not found
            msg = "error.invalid.url".localized
        } else {
            msg = "error.network.generic".localized
        }
        
        let alert = UIAlertController(title: "alert.lamp.title".localized, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "alert.button.cancel".localized, style: .cancel, handler: { action in
           }))
        alert.addAction(UIAlertAction(title: "alert.button.retry".localized, style: .default, handler: { action in
            self.loadWebPage()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        if let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else{
            completionHandler(.useCredential, nil)
        }
    }
}

// MARK: - WKScriptMessageHandler

extension HomeViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
//        if message.name == "logHandler" {
//            print("CONSOLE LOG: \(message.body)")
//        }
        if message.name == ScriptMessageHandler.login.rawValue {
            isWebpageLoaded = true // we will get this event, not only while login but also when relaunch the app (login will happen when launch home page with authToken). so this is the safe place to set the flag. Only issue is, if user is with login pagewhich is handled seperatly using div count. #651
            
            guard let dictBody = message.body as? [String: Any] else {
                printError("Message body not in expected format.")
                return
            }
            print("dictBody = \(dictBody)\n")
            //read token. it will be inthe format of UserName:Password
            guard let token = (dictBody[ScriptMessageKey.authorizationToken.rawValue] as? String),
                let idObjectDict = dictBody[ScriptMessageKey.identityObject.rawValue] as? [String: Any],
                let userID = idObjectDict["id"] as? String  else { return }
            
            //read langiuage
//            let script = "localStorage.getItem(\"\(key)\")"
//            wkWebView.evaluateJavaScript(script) { (jsonText, error) in
//                if let error = error {
//                    print ("localStorage.getitem('token') failed due to \(error)")
//                    assertionFailure()
//                }
//                print("localStorage jsonText = \(jsonText)")
//            }
            
            
            let serverAddress = dictBody[ScriptMessageKey.serverAddress.rawValue] as? String
            
            let base64Token = token.data(using: .utf8)?.base64EncodedString()
            Endpoint.setSessionKey(base64Token)
            
            let serverAddressValue = serverAddress ?? ""
            
            let withOutHttp = serverAddressValue.cleanHostName()

            //store url token to load dashboarn on next launch
            let uRLToken = "\(token):\(withOutHttp)"//UserName:Password:ServerAddress
            let base64URLToken = uRLToken.data(using: .utf8)?.base64EncodedString()
            Endpoint.setURLToken(base64URLToken)

            let (username, password) = token.makeTwoPiecesUsing(seperator: ":")
            User.shared.login(userID: userID, username: username, password: password, serverAddress: serverAddress)
            
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
        } else if message.name == "loadchecker" { //#651
            guard let divCount = message.body as? Int else {
                return
            }
            if divCount > 0 {
                isWebpageLoaded = true
            }
        }
    }
}

