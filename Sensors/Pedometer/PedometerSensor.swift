//
//  PedometerSensor.swift
//  mindLAMP Consortium
//

import CoreMotion

public class PedometerSensor: ISensorController {
    
    public static let TAG = "LAMP::Pedometer"
    public var CONFIG:PedometerSensor.Config = Config()
    
    var pedometer:CMPedometer? = nil
    var timer:Timer? = nil
    var inRecoveryLoop = false
    
    public class Config:SensorConfig {
        
        /**
         * The sensing interval (minute) for step counts. (default = 10 min)
         * This value has to be greater then or equal to 0.
         */
        public var interval:Int = 10 // min
        {
            didSet {
                if self.interval <= 0 {
                    print("[Pedometer][Illegal Parameter]",
                          "The 'interval' value has to be greater than 0.",
                          "This parameter ('\(self.interval)' is ignored.)")
                    self.interval = oldValue
                }
            }
        }
        
        public var sensorObserver:PedometerObserver?
        
        public override init() {
            super.init()
        }
        
        public override func set(config: Dictionary<String, Any>) {
            super.set(config: config)
            if let interval = config["interval"] as? Int{
                self.interval = interval
            }
        }
        
        public func apply(closure:(_ config: PedometerSensor.Config) -> Void) -> Self {
            closure(self)
            return self
        }
    }
    
    public convenience init() {
        self.init(PedometerSensor.Config())
    }
    
    public init(_ config:PedometerSensor.Config) {
        CONFIG = config
    }
    
    public func start() {
        if !CMPedometer.isStepCountingAvailable(){
            print(PedometerSensor.TAG, "Step Counting is not available.")
        }
        
        if !CMPedometer.isPaceAvailable(){
            print(PedometerSensor.TAG, "Pace is not available.")
        }
        
        if !CMPedometer.isCadenceAvailable(){
            print(PedometerSensor.TAG, "Cadence is not available.")
        }
        
        if !CMPedometer.isDistanceAvailable(){
            print(PedometerSensor.TAG, "Distance is not available.")
        }
        
        if !CMPedometer.isFloorCountingAvailable(){
            print(PedometerSensor.TAG, "Floor Counting is not available.")
        }
        
        if !CMPedometer.isPedometerEventTrackingAvailable(){
            print(PedometerSensor.TAG, "Pedometer Event Tracking is not available.")
        }
        
        if pedometer == nil {
            pedometer = CMPedometer()
            if timer == nil {
                timer = Timer.scheduledTimer(withTimeInterval: Double(self.CONFIG.interval), repeats: true, block: { timer in
                    if !self.inRecoveryLoop {
                        self.getPedometerData()
                    }else{
                        if self.CONFIG.debug { print(PedometerSensor.TAG, "skip: a recovery roop is running") }
                    }
                })
                timer?.fire()
                self.notificationCenter.post(name: .actionLampPedometerStart , object: self)
            }
        }
    }
    
    public func stop() {
        if let uwTimer = timer {
            uwTimer.invalidate()
            timer = nil
            self.notificationCenter.post(name: .actionLampPedometerStop , object: self)
        }
    }
    
    public func set(label:String){
        self.CONFIG.label = label
        self.notificationCenter.post(name: .actionLampPedometerSetLabel,
                                     object: self,
                                     userInfo: [PedometerSensor.EXTRA_LABEL:label])
    }
    
    ////////////////////////
    public func getPedometerData() {
        if let uwPedometer = pedometer, let fromDate = self.getLastUpdateDateTime(){
            let now = Date()
            let diffBetweemNowAndFromDate = now.minutes(from: fromDate)
            // if self.CONFIG.debug{ print(PedometerSensor.TAG, "diff: \(diffBetweemNowAndFromDate) min") }
            if diffBetweemNowAndFromDate > Int(CONFIG.interval) {
                let toDate = fromDate.addingTimeInterval( 60.0 * Double(self.CONFIG.interval) )
                uwPedometer.queryPedometerData(from: fromDate, to: toDate) { (pedometerData, error) in
                    
                    // save pedometer data
                    if let pedoData = pedometerData {
                        let data = PedometerData()
                        data.startDate = Int64(fromDate.timeIntervalSince1970 * 1000)
                        data.endDate   = Int64(toDate.timeIntervalSince1970   * 1000)
                        data.numberOfSteps = pedoData.numberOfSteps.intValue
                        
                        if let currentCadence = pedoData.currentCadence{
                            data.currentCadence = currentCadence.doubleValue
                        }
                        if let currentPace = pedoData.currentPace{
                            data.currentPace = currentPace.doubleValue
                        }
                        if let distance = pedoData.distance{
                            data.distance = distance.doubleValue
                        }
                        if let averageActivePace = pedoData.averageActivePace{
                            data.averageActivePace = averageActivePace.doubleValue
                        }
                        if let floorsAscended = pedoData.floorsAscended{
                            data.floorsAscended = floorsAscended.intValue
                        }
                        if let floorsDescended = pedoData.floorsDescended {
                            data.floorsDescended = floorsDescended.intValue
                        }
                        data.label = self.CONFIG.label
                        
                        if self.CONFIG.debug {
                            print(PedometerSensor.TAG, "\(fromDate) - \(toDate) : \(pedoData.numberOfSteps.intValue)" )
                        }
                        
                        if let observer = self.CONFIG.sensorObserver {
                            observer.onPedometerChanged(data: data)
                        }
                        

                        self.setLastUpdateDateTime(toDate)
                        let diffBetweenNowAndToDate = now.minutes(from: toDate)
                        if diffBetweenNowAndToDate > Int(self.CONFIG.interval){
                            self.inRecoveryLoop = true;
                            self.getPedometerData()
                        }else{
                            self.inRecoveryLoop = false;
                        }
                    }
                }
            }else{
                self.inRecoveryLoop = false;
            }
        }
    }
}

public protocol PedometerObserver {
    func onPedometerChanged(data:PedometerData)
}

extension Date {
    /// Returns the amount of minutes from another date
    func minutes(from date: Date) -> Int {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0
    }
}

extension Notification.Name {
    public static let actionLampPedometer = Notification.Name(PedometerSensor.ACTION_LAMP_PEDOMETER)
    public static let actionLampPedometerStart    = Notification.Name(PedometerSensor.ACTION_LAMP_PEDOMETER_START)
    public static let actionLampPedometerStop     = Notification.Name(PedometerSensor.ACTION_LAMP_PEDOMETER_STOP)
    public static let actionLampPedometerSync     = Notification.Name(PedometerSensor.ACTION_LAMP_PEDOMETER_SYNC)
    public static let actionLampPedometerSetLabel = Notification.Name(PedometerSensor.ACTION_LAMP_PEDOMETER_SET_LABEL)
    public static let actionLampPedometerSyncCompletion  = Notification.Name(PedometerSensor.ACTION_LAMP_PEDOMETER_SYNC_COMPLETION)
}

extension PedometerSensor {
    public static let ACTION_LAMP_PEDOMETER       = "com.lampframework.ios.sensor.pedometer"
    public static let ACTION_LAMP_PEDOMETER_START = "com.lampframework.ios.sensor.pedometer.ACTION_LAMP_PEDOMETER_START"
    public static let ACTION_LAMP_PEDOMETER_STOP  = "com.lampframework.ios.sensor.pedometer.ACTION_LAMP_PEDOMETER_STOP"
    public static let ACTION_LAMP_PEDOMETER_SET_LABEL = "com.lampframework.ios.sensor.pedometer.ACTION_LAMP_PEDOMETER_SET_LABEL"
    public static let ACTION_LAMP_PEDOMETER_SYNC  = "com.lampframework.ios.sensor.pedometer.ACTION_LAMP_PEDOMETER_SYNC"
    public static let EXTRA_LABEL = "label"

    
    public static let ACTION_LAMP_PEDOMETER_SYNC_COMPLETION = "com.lampframework.ios.sensor.pedometer.SENSOR_SYNC_COMPLETION"
//    public static let EXTRA_STATUS = "status"
//    public static let EXTRA_ERROR = "error"

}

extension PedometerSensor {
    
    public static let KEY_LAST_UPDATE_DATETIME = "com.lampframework.ios.sensor.pedometer.key.last_update_datetime";
    
    public func getFomattedDateTime(_ date:Date) -> Date?{
        let calendar = Calendar.current
        let year  = calendar.component(.year,   from: date)
        let month = calendar.component(.month,  from: date)
        let day   = calendar.component(.day,    from: date)
        let hour  = calendar.component(.hour,   from: date)
        let min   = calendar.component(.minute, from: date)
        let newDate = calendar.date(from: DateComponents(year:year, month:month, day:day, hour:hour, minute:min))
        return newDate
    }
    
    public func getLastUpdateDateTime() -> Date? {
        if let datetime = UserDefaults.standard.object(forKey: PedometerSensor.KEY_LAST_UPDATE_DATETIME) as? Date {
            return datetime
        }else{
            let date = Date()
            let calendar = Calendar.current
            let year  = calendar.component(.year,   from: date)
            let month = calendar.component(.month,  from: date)
            let day   = calendar.component(.day,    from: date)
            let hour  = calendar.component(.hour,    from: date)
            let newDate = calendar.date(from: DateComponents(year:year, month:month, day:day, hour:hour, minute:0))
            if let uwDate = newDate {
                self.setLastUpdateDateTime(uwDate)
                return uwDate
            }else{
                if self.CONFIG.debug { print(PedometerSensor.TAG, "[Error] KEY_LAST_UPDATE_DATETIME is null." ) }
                return nil
            }
        }
    }
    
    public func setLastUpdateDateTime(_ datetime:Date){
        if let newDateTime = self.getFomattedDateTime(datetime) {
            UserDefaults.standard.set(newDateTime, forKey:PedometerSensor.KEY_LAST_UPDATE_DATETIME)
            UserDefaults.standard.synchronize()
            return
        }
        if self.CONFIG.debug { print(PedometerSensor.TAG, "[Error] Date Time is null.") }
    }
    
}
