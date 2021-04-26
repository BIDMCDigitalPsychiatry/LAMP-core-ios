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
    let lampAPI = NetworkConfig.networkingAPI()
    //var loginSubscriber: AnyCancellable?
    //var isHomePageLoaded = false
    //@IBOutlet weak var containerView: UIView!
    private lazy var indicator: UIActivityIndicatorView  = {
        let progressView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
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
    
    lazy var scheduleHandler: ActivityLocalNotification = {
        return ActivityLocalNotification()
    }()

    override func loadView() {
        
        LeakAvoider.cleanCache()
        self.loadWebView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("mindLAMP Home")
        let appState = UIApplication.shared.applicationState
        if appState != UIApplication.State.background {
            loadWebPage()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(appDidActive(_:)),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
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
        wkWebView.configuration.userContentController.removeScriptMessageHandler(forName: ScriptMessageHandler.login.rawValue)
        wkWebView.configuration.userContentController.removeScriptMessageHandler(forName: ScriptMessageHandler.logout.rawValue)
    }
}

// MARK: - private

private extension HomeViewController {
    
    @objc func appDidActive(_ notification: Notification) {
        
        NotificationHelper.shared.removeAllExpiredNotifications()
        
        if isWebpageLoaded == false {
            printToFile("load page when become active")
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
        isWebpageLoaded = true
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
            let deadlineTime = DispatchTime.now() + .seconds(5)
            DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                self.wkWebView.load(URLRequest(url: LampURL.dashboardDigital))
            }
        }
    }
    
    func makeWebView() -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WebViewStorage.shared.processPool
        configuration.preferences = preferences
        configuration.websiteDataStore = WebViewStorage.shared.dataStore
        //configuration.websiteDataStore = WKWebsiteDataStore.default()
        //configuration.userContentController.add(self, name: ScriptMessageHandler.login.rawValue)
        //configuration.userContentController.add(self, name: ScriptMessageHandler.logout.rawValue)
        
        configuration.userContentController.add(LeakAvoider(delegate:self), name: ScriptMessageHandler.login.rawValue)
        configuration.userContentController.add(LeakAvoider(delegate:self), name: ScriptMessageHandler.logout.rawValue)
        
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
        
        struct EmptyResponse: Decodable {
        }
        //send lamp.analytics for logout
        guard let authheader = Endpoint.getSessionKey(), let participantId = User.shared.userId else {
            NotificationHelper.shared.removeAllNotifications()
            User.shared.logout()
            return
        }
        let tokenInfo = DeviceInfoWithToken(deviceToken: nil, userAgent: UserAgent.defaultAgent, action: SensorType.AnalyticAction.logout.rawValue)
        let event = SensorEvent(timestamp: Date().timeInMilliSeconds, sensor: SensorType.lamp_analytics.lampIdentifier, data: tokenInfo)
        let lampAPI = NetworkConfig.networkingAPI()
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

// MARK: - WKNavigationDelegate


extension HomeViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("naviation fail error = \(error.localizedDescription)")
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
        }
    }
}

