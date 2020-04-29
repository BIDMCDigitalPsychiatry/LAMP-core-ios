//
//  CallsSensor.swift
//  com.aware.ios.sensor.calls
//
//  Created by Yuuki Nishiyama on 2018/10/24.
//

import UIKit
import CallKit

extension Notification.Name {
    public static let actionAwareCalls   = Notification.Name(CallsSensor.ACTION_AWARE_CALLS)
    public static let actionAwareCallsStart    = Notification.Name(CallsSensor.ACTION_AWARE_CALLS_START)
    public static let actionAwareCallsStop    = Notification.Name(CallsSensor.ACTION_AWARE_CALLS_STOP)
    public static let actionAwareCallsSync    = Notification.Name(CallsSensor.ACTION_AWARE_CALLS_SYNC)
    public static let actionAwareCallsSyncCompletion = Notification.Name(CallsSensor.ACTION_AWARE_CALLS_SYNC_COMPLETION)
    public static let actionAwareCallsSetLabel = Notification.Name(CallsSensor.ACTION_AWARE_CALLS_SET_LABEL)
    
    // TODO: check all of actions
    public static let actionAwareCallAccepted = Notification.Name(CallsSensor.ACTION_AWARE_CALL_ACCEPTED)        // o
    public static let actionAwareCallRinging = Notification.Name(CallsSensor.ACTION_AWARE_CALL_RINGING)          // o
    public static let actionAwareCallMissed = Notification.Name(CallsSensor.ACTION_AWARE_CALL_MISSED)            // ?
    public static let actionAwareCallVoiceMailed = Notification.Name(CallsSensor.ACTION_AWARE_CALL_VOICE_MAILED) // x
    public static let actionAwareCallRejected = Notification.Name(CallsSensor.ACTION_AWARE_CALL_REJECTED)        // x
    public static let actionAwareCallBlocked = Notification.Name(CallsSensor.ACTION_AWARE_CALL_BLOCKED)          // ?
    public static let actionAwareCallMade = Notification.Name(CallsSensor.ACTION_AWARE_CALL_MADE)                // o
    public static let actionAwareCallUserInCall = Notification.Name(CallsSensor.ACTION_AWARE_USER_IN_CALL)       // o
    public static let actionAwareCallUserNoInCall = Notification.Name(CallsSensor.ACTION_AWARE_USER_NOT_IN_CALL) // o
}

public protocol CallsObserver {
    /**
     * Callback when a call event is recorded (received, made, missed)
     *
     * @param data
     */
    func onCall(data: CallsData)
    
    /**
     * Callback when the phone is ringing
     *
     * @param number
     */
    func onRinging(number: String?)
    
    /**
     * Callback when the user answered and is busy with a call
     *
     * @param number
     */
    func onBusy(number: String?)
    
    /**
     * Callback when the user hangup an ongoing call and is now free
     *
     * @param number
     */
    func onFree(number: String?)
}

public class CallsSensor: AwareSensor {

    public static let TAG = "AWARE::Calls"
    
    /**
     * Fired event: call accepted by the user
     */
    public static let ACTION_AWARE_CALL_ACCEPTED = "ACTION_AWARE_CALL_ACCEPTED"
    
    /**
     * Fired event: phone is ringing
     */
    public static let ACTION_AWARE_CALL_RINGING = "ACTION_AWARE_CALL_RINGING"
    
    /**
     * Fired event: call unanswered
     */
    public static let ACTION_AWARE_CALL_MISSED = "ACTION_AWARE_CALL_MISSED"
    
    /**
     * Fired event: call got voice mailed.
     * Only available after SDK 21
     */
    public static let ACTION_AWARE_CALL_VOICE_MAILED = "ACTION_AWARE_CALL_VOICE_MAILED"
    
    /**
     * Fired event: call got rejected by the callee
     * Only available after SDK 24
     */
    public static let ACTION_AWARE_CALL_REJECTED = "ACTION_AWARE_CALL_REJECTED"
    
    /**
     * Fired event: call got blocked.
     * Only available after SDK 24
     */
    public static let ACTION_AWARE_CALL_BLOCKED = "ACTION_AWARE_CALL_BLOCKED"
    
    /**
     * Fired event: call attempt by the user
     */
    public static let ACTION_AWARE_CALL_MADE = "ACTION_AWARE_CALL_MADE"
    
    /**
     * Fired event: user IS in a call at the moment
     */
    public static let ACTION_AWARE_USER_IN_CALL = "ACTION_AWARE_USER_IN_CALL"
    
    /**
     * Fired event: user is NOT in a call
     */
    public static let ACTION_AWARE_USER_NOT_IN_CALL = "ACTION_AWARE_USER_NOT_IN_CALL"
    
    public static let ACTION_AWARE_CALLS = "com.awareframework.ios.sensor.calls"
    public static let ACTION_AWARE_CALLS_START = "com.awareframework.ios.sensor.calls.SENSOR_START"
    public static let ACTION_AWARE_CALLS_STOP = "com.awareframework.ios.sensor.calls.SENSOR_STOP"
    
    public static let ACTION_AWARE_CALLS_SET_LABEL = "com.awareframework.ios.sensor.calls.SET_LABEL"
    public static let EXTRA_LABEL = "label"
    
    public static let ACTION_AWARE_CALLS_SYNC = "com.awareframework.ios.sensor.calls.SENSOR_SYNC"
    public static let ACTION_AWARE_CALLS_SYNC_COMPLETION = "com.awareframework.ios.sensor.calls.SENSOR_SYNC_COMPLETION"
    public static let EXTRA_STATUS = "status"
    public static let EXTRA_ERROR = "error"
    
    public enum CallEventType: Int {
        case incoming  = 1
        case outgoing  = 2
        case missed    = 3
        case voiceMail = 4
        case rejected  = 5
        case blocked   = 6
        case answeredExternally = 7
    }
    
    public var CONFIG = Config()
    
    var callObserver: CXCallObserver? = nil
    
    var lastCallEvent:CXCall? = nil
    var lastCallEventTime:Date? = nil
    var lastCallEventType:Int? = nil
    
    public class Config:SensorConfig {
        public var sensorObserver:CallsObserver?
        
        public override init(){
            super.init()
            dbPath = "aware_calls"
        }
        
        public func apply(closure:(_ config: CallsSensor.Config) -> Void) -> Self {
            closure(self)
            return self
        }
    }
    
    public override convenience init(){
        self.init(CallsSensor.Config())
    }
    
    public init(_ config:CallsSensor.Config){
        super.init()
        CONFIG = config
        initializeDbEngine(config: config)
    }
    
    public override func start() {
        if callObserver == nil {
            callObserver = CXCallObserver()
            callObserver!.setDelegate(self, queue: nil)
            self.notificationCenter.post(name: .actionAwareCallsStart, object: self)
        }
    }
    
    public override func stop() {
        if callObserver != nil {
            callObserver = nil
            self.notificationCenter.post(name: .actionAwareCallsStop, object: self)
        }
    }
    
    public override func sync(force: Bool = false) {
        self.notificationCenter.post(name: .actionAwareCallsSync, object: self)
    }
    
    public override func set(label:String){
        self.CONFIG.label = label
        self.notificationCenter.post(name: .actionAwareCallsSetLabel,
                                     object: self,
                                     userInfo: [CallsSensor.EXTRA_LABEL:label])
    }
}

/**
 * INCOMING_TYPE = 1
 * OUTGOING_TYPE = 2
 * MISSED_TYPE = 3
 * VOICEMAIL_TYPE = 4
 * REJECTED_TYPE = 5
 * BLOCKED_TYPE = 6
 * ANSWERED_EXTERNALLY_TYPE = 7
 */

extension CallsSensor: CXCallObserverDelegate {
    /**
     * http://www.yuukinishiyama.com/2018/10/25/handling-phone-call-events-on-ios-using-swift-4/
     * https://stackoverflow.com/questions/36014975/detect-phone-calls-on-ios-with-ctcallcenter-swift
     */
    public func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        print(call.isOutgoing, call.isOnHold, call.hasEnded, call.hasConnected)
        if call.hasEnded   == true && call.isOutgoing == false || // in-coming end
           call.hasEnded   == true && call.isOutgoing == true {   // out-going end
            if self.CONFIG.debug { print("Disconnected") }
            if let observer = self.CONFIG.sensorObserver{
                observer.onFree(number: call.uuid.uuidString)
            }
            self.notificationCenter.post(name: .actionAwareCallUserNoInCall, object: self)
            self.save(call:call)
        }

        if call.isOutgoing == true && call.hasConnected == false && call.hasEnded == false {
            if self.CONFIG.debug { print("Dialing") }
            if let observer = self.CONFIG.sensorObserver{
                observer.onRinging(number: call.uuid.uuidString)
            }
            self.notificationCenter.post(name: .actionAwareCallMade, object: self)
            lastCallEventType = CallEventType.outgoing.rawValue
        }
        
        if call.isOutgoing == false && call.hasConnected == false && call.hasEnded == false {
            if self.CONFIG.debug { print("Incoming") }
            if let observer = self.CONFIG.sensorObserver{
                observer.onRinging(number: call.uuid.uuidString)
            }
            self.notificationCenter.post(name: .actionAwareCallRinging, object: self)
            lastCallEventType = CallEventType.incoming.rawValue
        }
        
        if call.hasConnected == true && call.hasEnded == false {
            if self.CONFIG.debug { print("Connected") }
            if let observer = self.CONFIG.sensorObserver{
                observer.onBusy(number: call.uuid.uuidString)
            }
            self.notificationCenter.post(name: .actionAwareCallAccepted, object: self)
            self.notificationCenter.post(name: .actionAwareCallUserInCall, object: self)
            lastCallEvent = call
            lastCallEventTime = Date()
            if call.isOutgoing {
                lastCallEventType = CallEventType.outgoing.rawValue
            }else{
                lastCallEventType = CallEventType.incoming.rawValue
            }
        }
    }
    
    public func save(call:CXCall){
        if let uwLastCallEvent = self.lastCallEvent,
           let uwLastCallEventTime = self.lastCallEventTime,
           let uwLastCallEventType = self.lastCallEventType{
            let now = Date()
            let data = CallsData()
            data.trace = uwLastCallEvent.uuid.uuidString
            data.eventTimestamp = Int64( now.timeIntervalSince1970*1000 )
            data.duration = Int64(now.timeIntervalSince1970 - uwLastCallEventTime.timeIntervalSince1970)
            data.type = uwLastCallEventType
            data.label = self.CONFIG.label
            if let engine = self.dbEngine {
                engine.save(data)
            }
            if let observer = self.CONFIG.sensorObserver {
                observer.onCall(data: data)
            }
            self.notificationCenter.post(name: .actionAwareCalls, object: self)
            // data.type = eventType
            self.lastCallEvent = nil
            lastCallEventTime = nil
            lastCallEventType = nil
        }
    }
}

//func onCall(data: CallData)
//func onRinging(number: String?)
//func onBusy(number: String?)
//func onFree(number: String?)


/**
 * Callback when a call event is recorded (received, made, missed)
 * Callback when the phone is ringing
 * Callback when the user answered and is busy with a call
 * Callback when the user hangup an ongoing call and is now free
 */
