// mindLAMP
//https://medium.com/@litoarias/watchos-5-communication-between-iphone-and-apple-watch-and-vice-versa-on-swift-part-4-394df1d47644
//https://developer.apple.com/documentation/watchconnectivity/using_watch_connectivity_to_communicate_between_your_apple_watch_app_and_iphone_app

import WatchConnectivity

extension Notification.Name {
    static let userLogined = Notification.Name("userLogined")
    static let userLogOut = Notification.Name("userLogOut")
    static let sensorDataPosted = Notification.Name("sensorDataPosted")
    static let activationDidComplete = Notification.Name("ActivationDidComplete")
    static let reachabilityDidChange = Notification.Name("ReachabilityDidChange")
}


//Encapsulating in a tuple for don't duplicate code
typealias MessageReceived = (session: WCSession, message: [String : Any], replyHandler: (([String : Any]) -> Void)?)
//Same that before, but to manage ApplicationContextReceived
typealias ApplicationContextReceived = (session: WCSession, applicationContext: [String : Any])

//Protocol for manage all watchOS delegations
protocol WatchOSDelegate: AnyObject {
    func messageReceived(tuple: MessageReceived)
    func applicationContextReceived(tuple: ApplicationContextReceived)
}

//Protocol for manage all iOS delegations
protocol iOSDelegate: AnyObject {
    func messageReceived(tuple: MessageReceived)
    func applicationContextReceived(tuple: ApplicationContextReceived)
}

class WatchSessionManager: NSObject {

    //Singleton for manage only one instance
    static let shared = WatchSessionManager()
    
    //Delegates for each platform
    weak var watchOSDelegate: WatchOSDelegate?
    weak var iOSDelegate: iOSDelegate?

    //Getting session if we want get it, if not return nil
    fileprivate let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    
    //If device it's avaliable
    var validSession: WCSession? {
        
        // paired - the user has to have their device paired to the watch
        // watchAppInstalled - the user must have your watch app installed
        
        // Note: if the device is paired, but your watch app is not installed
        // consider prompting the user to install it for a better experience
        
        #if os(iOS)
        if let session = session, session.isPaired && session.isWatchAppInstalled {
            print("session is paired")
            return session
        }
        print("session is not paired or not installed")
        return nil
        #elseif os(watchOS)
        return session
        #endif
    }
    
    //Method for start session and set this class with a delegate
    func startSession() {
        session?.delegate = self
        session?.activate()
    }
    
    private override init() {}

}

// MARK: WCSessionDelegate
extension WatchSessionManager: WCSessionDelegate {
    
    // Called when WCSession activation state is changed.
    //
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activationDidCompleteWith \(activationState)")
        //postNotificationOnMainQueueAsync(name: .activationDidComplete)
    }
    
    // Called when WCSession reachability is changed.
    //
    func sessionReachabilityDidChange(_ session: WCSession) {
        //postNotificationOnMainQueueAsync(name: .reachabilityDidChange)
    }

    
    //Only for iOS OS
    #if os(iOS)
    /**
     * Called when the session can no longer be used to modify or add any new transfers and,
     * all interactive messages will be cancelled, but delegate callbacks for background transfers can still occur.
     * This will happen when the selected watch is being changed.
     */
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("sessionDidBecomeInactive: \(session)")
    }
    
    /**
     * Called when all delegate callbacks for the previously selected watch has occurred.
     * The session can be re-activated for the now selected watch using activateSession.
     */
    func sessionDidDeactivate(_ session: WCSession) {
        print("sessionDidDeactivate: \(session)")
        /**
         * This is to re-activate the session on the phone when the user has switched from one
         * paired watch to second paired one. Calling it like this assumes that you have no other
         * threads/part of your code that needs to be given time before the switch occurs.
         */
        self.session?.activate()
    }
    #endif

}

//MARK: Interactive Messaging
extension WatchSessionManager {
    
    //Live messaging! App has to be reachable
    private var validReachableSession: WCSession? {
        if let session = validSession { //, session.isReachable
            return session
        } else {
            if validSession?.isReachable == false {
                print("Not reachale")
            } else {
                print("no valid session")
            }
            
        }
        return nil
    }
    
    //Sender
    func sendMessage(message: [String : Any], replyHandler: (([String : Any]) -> Void)? = nil, errorHandler: ((Error) -> Void)? = nil) {
        print("sending message .. \(message)")
        if WCSession.isSupported() == false {
            print("sending message not supported sssion")
        }
        /* The following trySendingMessageToWatch sometimews fails with
        Error Domain=WCErrorDomain Code=7007 "WatchConnectivity session on paired device is not reachable."
        In this case, the transfer is retried a number of times.
        */
        let maxNrRetries = 5
        var availableRetries = maxNrRetries

        func trySendingMessage(_ message: [String: Any]) {
            validReachableSession?.sendMessage(message,
                                                  replyHandler: replyHandler,
                                                  errorHandler: { error in
                                                                  print("sending message to watch failed: error: \(error)")
                                                                  let nsError = error as NSError
                                                                  if nsError.domain == "WCErrorDomain" && nsError.code == 7007 && availableRetries > 0 {
                                                                     availableRetries = availableRetries - 1
                                                                     let randomDelay = Double.random(min: 0.3, max: 1.0)
                                                                     DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay, execute: {
                                                                        trySendingMessage(message)
                                                                     })
                                                                   } else {
                                                                     errorHandler?(error)
                                                                   }
            })
        } // trySendingMessageToWatch

        trySendingMessage(message)
        
        //validReachableSession?.sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
    }
    
    func sendMessageData(data: Data, replyHandler: ((Data) -> Void)? = nil, errorHandler: ((Error) -> Void)? = nil) {
        validReachableSession?.sendMessageData(data, replyHandler: replyHandler, errorHandler: errorHandler)
    }
    // end Sender
    
    //Receiver
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleSession(session, didReceiveMessage: message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        handleSession(session, didReceiveMessage: message, replyHandler: replyHandler)
    }
    // end Receiver
    
    //Helper Method
    func handleSession(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: (([String : Any]) -> Void)? = nil) {
        // handle receiving message
        print("handle receiving message \(message)")
        #if os(iOS)
        iOSDelegate?.messageReceived(tuple: (session, message, replyHandler))
        #elseif os(watchOS)
        watchOSDelegate?.messageReceived(tuple: (session, message, replyHandler))
        #endif
    }
    
   
}

// 4: New extension for manage didReceiveApplicationContext()
// MARK: Application Context
// use when your app needs only the latest information
// if the data was not sent, it will be replaced
extension WatchSessionManager {
    
    //Sender
    func updateApplicationContext(applicationContext: [String : Any]) {
        if let session = validSession {
            do {
                try session.updateApplicationContext(applicationContext)
                print("update context")
            } catch let error {
                print("update context error \(error.localizedDescription)")
            }
        }
    }
    
    //Receiver
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("didReceiveApplicationContext = \(applicationContext)")
        #if os(iOS)
        iOSDelegate?.applicationContextReceived(tuple: (session, applicationContext))
        #elseif os(watchOS)
        watchOSDelegate?.applicationContextReceived(tuple: (session, applicationContext))
        #endif
    }
    
}
public extension Double {

    /// Returns a random floating point number between 0.0 and 1.0, inclusive.
    static var random: Double {
        return Double(arc4random()) / 0xFFFFFFFF
    }

    /// Random double between 0 and n-1.
    ///
    /// - Parameter n:  Interval max
    /// - Returns:      Returns a random double point number between 0 and n max
    static func random(min: Double, max: Double) -> Double {
        return Double.random * (max - min) + min
    }
}
