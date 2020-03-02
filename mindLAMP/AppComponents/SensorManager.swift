//
//  SensorManager.swift
//  lampv2
//
//  Created by ZCo Engineer on 14/01/20.
//

import Foundation

class SensorManager {
    
    
    static let shared: SensorManager = SensorManager()

    
    // MARK: - VARIABLES
    var sensor_accelerometer: Accelerometer?
    var sensor_bluetooth: Bluetooth?
    var sensor_calls: Calls?
    var sensor_gravity: Gravity?
    var sensor_gyro: Gyroscope?
    var sensor_healthKit: AWAREHealthKit?
    var sensor_location: Locations?
    var sensor_magneto: Magnetometer?
    var sensor_rotation: Rotation?
    var sensor_screen: Screen?
    var sensor_wifi: SensorWifi?
    var sensor_pedometer: Pedometer?

    var sensorApiTimer: Timer?
    
    private init() { }
    
    private func initiateSensors() {
        setupAccelerometerSensor()
        setupBluetoothSensor()
        setupCallsSensor()
        setuGravitySensor()
        setupGyroscopeSensor()
        setupHealthKitSensor()
        setupLocationSensor()
        setupMagnetometerSensor()
        setupPedometerSensor()
        setupRotationSensor()
        setupScreenSensor()
        setupWifiSensor()
    }
    
    private func deinitSensors() {
        sensor_accelerometer = nil
        sensor_bluetooth = nil
        sensor_calls = nil
        sensor_gravity = nil
        sensor_gyro = nil
        sensor_healthKit = nil
        sensor_location = nil
        sensor_magneto = nil
        sensor_pedometer = nil
        sensor_rotation = nil
        sensor_screen = nil
        sensor_wifi = nil
    }


    private func startAllSensors() {

        sensor_accelerometer?.startSensor()
        sensor_bluetooth?.startSensor()
        sensor_calls?.startSensor()
        sensor_gravity?.startSensor()
        sensor_gyro?.startSensor()
        sensor_healthKit?.startSensor()
        sensor_location?.startSensor()
        sensor_magneto?.startSensor()
        sensor_pedometer?.startSensor()
        sensor_rotation?.startSensor()
        sensor_screen?.startSensor()
        sensor_wifi?.startSensor()
    }
    
    private func stopAllSensors() {
        sensor_accelerometer?.stopSensor()
        sensor_bluetooth?.stopSensor()
        sensor_calls?.stopSensor()
        sensor_gravity?.stopSensor()
        sensor_gyro?.stopSensor()
        sensor_healthKit?.stopSensor()
        sensor_location?.stopSensor()
        sensor_magneto?.stopSensor()
        sensor_pedometer?.stopSensor()
        sensor_rotation?.stopSensor()
        sensor_screen?.stopSensor()
        sensor_wifi?.stopSensor()
    }
    
    private func refreshAllSensors() {
        stopAllSensors()
        startAllSensors()
    }
    
    
    private func startTimer() {
        Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(postSensorData), userInfo: nil, repeats: false)
        sensorApiTimer = Timer.scheduledTimer(timeInterval: 10*60, target: self, selector: #selector(postSensorData), userInfo: nil, repeats: true)
    }

    private func stopTimer() {
        sensorApiTimer?.invalidate()
    }
    
    @objc func postSensorData() {
        refreshAllSensors()
        BackgroundServices.shared.performTasks()
    }
    
    /// To start sensors observing.
    func startSensors() {
        initiateSensors()
        startAllSensors()
        startTimer()
    }
    
    /// To stop sensors observing.
    func stopSensors() {
        stopTimer()
        stopAllSensors()
        deinitSensors()
    }
    
    // MARK: - SENSOR SETUP METHODS
    
    func setupAccelerometerSensor() {
        sensor_accelerometer = Accelerometer()
        AWARESensorManager.shared().add(sensor_accelerometer!)
    }
    
    func setupBluetoothSensor() {
        sensor_bluetooth = Bluetooth()
        AWARESensorManager.shared().add(sensor_bluetooth!)
    }
    
    func setupCallsSensor() {
        sensor_calls = Calls()
        AWARESensorManager.shared().add(sensor_calls!)
    }
    
    func setuGravitySensor() {
        sensor_gravity = Gravity()
        AWARESensorManager.shared().add(sensor_gravity!)
    }
    
    func setupGyroscopeSensor() {
        sensor_gyro = Gyroscope()
        AWARESensorManager.shared().add(sensor_gyro!)
    }
    
    func setupHealthKitSensor() {
        sensor_healthKit = AWAREHealthKit()
        AWARESensorManager.shared().add(sensor_healthKit!)
    }

    func setupLocationSensor() {
        sensor_location = Locations()
        AWARESensorManager.shared().add(sensor_location!)
    }
    
    func setupMagnetometerSensor() {
        sensor_magneto = Magnetometer()
        AWARESensorManager.shared().add(sensor_magneto!)
    }
    
    func setupPedometerSensor() {
        sensor_pedometer = Pedometer()
        AWARESensorManager.shared().add(sensor_pedometer!)
    }
    
    func setupRotationSensor() {
        sensor_rotation = Rotation()
        AWARESensorManager.shared().add(sensor_rotation!)
    }
    
    func setupScreenSensor() {
        sensor_screen = Screen()
        AWARESensorManager.shared().add(sensor_screen!)
    }
    
    func setupWifiSensor() {
        sensor_wifi = SensorWifi()
        AWARESensorManager.shared().add(sensor_wifi!)
    }
}

extension SensorManager {
        
    func fetchSensorDataRequest() -> [SensorData.Request] {
        var arraySensorRequest = [SensorData.Request]()
        
        if let data = fetchAccelerometerData() {
            arraySensorRequest.append(data)
        }
        if let data = fetchAccelerometerMotionData() {
            arraySensorRequest.append(data)
        }
        if let data = fetchGyroscopeData() {
            arraySensorRequest.append(data)
        }
        if let data = fetchMagnetometerData() {
            arraySensorRequest.append(data)
        }
        if let data = fetchHeartRateData() {
            arraySensorRequest.append(data)
        }
        if let data = fetchSleepData() {
            arraySensorRequest.append(data)
        }
        if let data = fetchStepsData() {
            arraySensorRequest.append(data)
        }
        if let data = fetchFlightsData() {
            arraySensorRequest.append(data)
        }
        if let data = fetchDistanceData() {
            arraySensorRequest.append(data)
        }
        if let data = fetchGPSContextualData() {
            arraySensorRequest.append(data)
        }
        if let data = fetchGPSData() {
            arraySensorRequest.append(data)
        }
        if let data = fetchBluetoothData() {
            arraySensorRequest.append(data)
        }
        if let data = fetchScreenStateData() {
            arraySensorRequest.append(data)
        }
        if let data = fetchCallsData() {
            arraySensorRequest.append(data)
        }
        if let data = fetchWiFiData() {
            arraySensorRequest.append(data)
        }
        if let data = fetchWorkoutSegmentData() {
            arraySensorRequest.append(data)
        }
        if let data = fetchHealthKitQuantityData() {
            arraySensorRequest.append(contentsOf: data)
        }

        return arraySensorRequest
    }
    
    private func fetchTriaxialData(for sensor: AWARESensor?) -> (x: Double?, y: Double?, z: Double?, timeStamp: Double?)? {
        guard let dict = sensor?.getLatestData() as? [String: Any] else {
            return nil
        }
        let x = dict["double_values_0"] as? Double
        let y = dict["double_values_1"] as? Double
        let z = dict["double_values_2"] as? Double
        let timeStamp = dict["timestamp"] as? Double
        return (x, y, z, timeStamp)
    }
    
    private func fetchAccelerometerData() -> SensorData.Request? {
        guard let data = fetchTriaxialData(for: sensor_accelerometer) else {
            return nil
        }
        var model = SensorDataModel()
        model.x = data.x
        model.y = data.y
        model.z = data.z
        
        let timeStamp = data.timeStamp ?? Date.currentTimeSince1970()
        return SensorData.Request(timestamp: timeStamp, sensor: SensorType.lamp_accelerometer, data: model)
    }
    
    private func fetchAccelerometerMotionData() -> SensorData.Request? {
        var model = SensorDataModel()

        if let data = fetchTriaxialData(for: sensor_accelerometer) {
            var motion = Motion()
            motion.x = data.x
            motion.y = data.y
            motion.z = data.z
            
            model.motion = motion
        }
        if let data = fetchTriaxialData(for: sensor_gravity) {
            var gravity = Gravitational()
            gravity.x = data.x
            gravity.y = data.y
            gravity.z = data.z
            
            model.gravity = gravity
        }
        if let data = fetchTriaxialData(for: sensor_rotation) {
            var rotation = Rotational()
            rotation.x = data.x
            rotation.y = data.y
            rotation.z = data.z
            
            model.rotation = rotation
        }
        if let data = fetchTriaxialData(for: sensor_magneto) {
            var magnetic = Magnetic()
            magnetic.x = data.x
            magnetic.y = data.y
            magnetic.z = data.z
            
            model.magnetic = magnetic
        }
        let timeStamp = Date.currentTimeSince1970()
        return SensorData.Request(timestamp: timeStamp, sensor: SensorType.lamp_accelerometer_motion, data: model)
    }
    
    private func fetchGyroscopeData() -> SensorData.Request? {
        guard let data = fetchTriaxialData(for: sensor_gyro) else {
            return nil
        }
        var model = SensorDataModel()
        model.x = data.x
        model.y = data.y
        model.z = data.z

        let timeStamp = data.timeStamp ?? Date.currentTimeSince1970()
        return SensorData.Request(timestamp: timeStamp, sensor: SensorType.lamp_gyroscope, data: model)
    }
    
    private func fetchMagnetometerData() -> SensorData.Request? {
        guard let data = fetchTriaxialData(for: sensor_magneto) else {
            return nil
        }
        var model = SensorDataModel()
        model.x = data.x
        model.y = data.y
        model.z = data.z

        let timeStamp = data.timeStamp ?? Date.currentTimeSince1970()
        return SensorData.Request(timestamp: timeStamp, sensor: SensorType.lamp_magnetometer, data: model)
    }
    
    private func fetchHeartRateData() -> SensorData.Request? {
        guard let dict = sensor_healthKit?.awareHKHeartRate.getLatestData() as? [String: Any] else {
            return nil
        }
        var model = SensorDataModel()
        model.unit = dict["unit"] as? String
        model.value = dict["value"] as? Double

        return sensorDataRequest(with: dict, sensor: SensorType.lamp_heart_rate, dataModel: model)
    }
    
    private func fetchSleepData() -> SensorData.Request? {
        guard let dict = sensor_healthKit?.awareHKSleep.getLatestData() as? [String: Any] else {
            return nil
        }
        var model = SensorDataModel()
        model.value = dict["value"] as? Double

        return sensorDataRequest(with: dict, sensor: SensorType.lamp_sleep, dataModel: model)
    }
        
    private func fetchStepsData() -> SensorData.Request? {
        guard let dict = sensor_pedometer?.getLatestData() as? [String: Any] else {
            return nil
        }
        var model = SensorDataModel()
        model.steps = dict["number_of_steps"] as? Int

        return sensorDataRequest(with: dict, sensor: SensorType.lamp_steps, dataModel: model)
    }
    
    private func fetchFlightsData() -> SensorData.Request? {
        guard let dict = sensor_pedometer?.getLatestData() as? [String: Any] else {
            return nil
        }
        var model = SensorDataModel()
        model.flights_climbed = dict["floors_ascended"] as? Int

        return sensorDataRequest(with: dict, sensor: SensorType.lamp_flights, dataModel: model)
    }
    
    private func fetchDistanceData() -> SensorData.Request? {
        guard let dict = sensor_pedometer?.getLatestData() as? [String: Any] else {
            return nil
        }
        var model = SensorDataModel()
        model.distance = dict["distance"] as? Double

        return sensorDataRequest(with: dict, sensor: SensorType.lamp_distance, dataModel: model)
    }
    
    private func fetchGPSContextualData() -> SensorData.Request? {
        guard let dict = sensor_location?.getLatestData() as? [String: Any] else {
            return nil
        }
        var model = SensorDataModel()
        model.longitude = dict["double_longitude"] as? Double
        model.latitude = dict["double_latitude"] as? Double

        return sensorDataRequest(with: dict, sensor: SensorType.lamp_gps_contextual, dataModel: model)
    }
    
    private func fetchGPSData() -> SensorData.Request? {
        guard let dict = sensor_location?.getLatestData() as? [String: Any] else {
            return nil
        }
        var model = SensorDataModel()
        model.longitude = dict["double_longitude"] as? Double
        model.latitude = dict["double_latitude"] as? Double
        model.altitude = dict["double_altitude"] as? Double

        return sensorDataRequest(with: dict, sensor: SensorType.lamp_gps, dataModel: model)
    }
    
    private func fetchBluetoothData() -> SensorData.Request? {
        guard let dict = sensor_bluetooth?.getLatestData() as? [String: Any] else {
            return nil
        }
        var model = SensorDataModel()
        model.bt_address = dict["bt_address"] as? String
        model.bt_name = dict["bt_name"] as? String
        model.bt_rssi = dict["bt_rssi"] as? Int

        return sensorDataRequest(with: dict, sensor: SensorType.lamp_bluetooth, dataModel: model)
    }
    
    private func fetchWiFiData() -> SensorData.Request? {
        guard let dict = sensor_wifi?.storage?.fetchTodaysData().last as? [String: Any] else {
            return nil
        }
        var model = SensorDataModel()
        model.bssid = dict["bssid"] as? String
        model.ssid = dict["ssid"] as? String

        return sensorDataRequest(with: dict, sensor: SensorType.lamp_wifi, dataModel: model)
    }
    
    private func fetchScreenStateData() -> SensorData.Request? {
        guard let dict = sensor_screen?.getLatestData() as? [String: Any] else {
            return nil
        }
        var model = SensorDataModel()
        model.state = dict["screen_status"] as? Int

        return sensorDataRequest(with: dict, sensor: SensorType.lamp_screen_state, dataModel: model)
    }
    
    private func fetchCallsData() -> SensorData.Request? {
        guard let dict = sensor_calls?.getLatestData() as? [String: Any] else {
            return nil
        }
        var model = SensorDataModel()
        model.call_type = dict["call_type"] as? Int
        model.call_duration = dict["call_duration"] as? Double
        model.call_trace = dict["trace"] as? String

        return sensorDataRequest(with: dict, sensor: SensorType.lamp_calls, dataModel: model)
    }
    
    private func fetchWorkoutSegmentData() -> SensorData.Request? {
        guard let arrData = sensor_healthKit?.awareHKWorkout.storage?.fetchTodaysData() as? [[String: Any]] else {
            return nil
        }
        guard let dict = arrData.max(by: {($0["timestamp"] as? Double) ?? 0 < ($1["timestamp"] as? Double) ?? 0 }) else {
            return nil
        }
        var model = SensorDataModel()
        model.workout_type = dict["activity_type_name"] as? String
        model.workout_durtion = dict["duration"] as? Double
        
        return sensorDataRequest(with: dict, sensor: SensorType.lamp_segment, dataModel: model)
    }
}

extension SensorManager {
    
    func sensorDataRequest(with dict: [String: Any], sensor: SensorType, dataModel: SensorDataModel) -> SensorData.Request {
        let timeStamp = dict["timestamp"] as? Double ?? Date.currentTimeSince1970()
        return SensorData.Request(timestamp: timeStamp, sensor: sensor, data: dataModel)
    }
    
    func fetchHealthKitQuantityData() -> [SensorData.Request]? {
        guard let arrData = sensor_healthKit?.awareHKQuantity.storage?.fetchTodaysData() as? [[String: Any]] else {
            return nil
        }
        var arrayRequest = [SensorData.Request]()
        //get latest Weight
        if let dict = latestData(for: HKIdentifiers.weight.rawValue, in: arrData) {
            var model = SensorDataModel()
            model.unit = dict["unit"] as? String
            model.value = dict["value"] as? Double
            
            arrayRequest.append(sensorDataRequest(with: dict, sensor: SensorType.lamp_weight, dataModel: model))
        }
        //get latest Height
        if let dict = latestData(for: HKIdentifiers.height.rawValue, in: arrData) {
            var model = SensorDataModel()
            model.unit = dict["unit"] as? String
            model.value = dict["value"] as? Double
            
            arrayRequest.append(sensorDataRequest(with: dict, sensor: SensorType.lamp_height, dataModel: model))
        }
        //get latest BloodPressure
        if let dictDiastolic = latestData(for: HKIdentifiers.bloodpressure_diastolic.rawValue, in: arrData), let dictSystolic = latestData(for: HKIdentifiers.bloodpressure_systolic.rawValue, in: arrData) {
            var model = SensorDataModel()
            model.unit = dictDiastolic["unit"] as? String
            model.bp_diastolic = dictDiastolic["value"] as? Int
            model.bp_systolic = dictSystolic["value"] as? Int

            arrayRequest.append(sensorDataRequest(with: dictDiastolic, sensor: SensorType.lamp_blood_pressure, dataModel: model))
        }
        //get latest Respiratory rate
        if let dict = latestData(for: HKIdentifiers.respiratory_rate.rawValue, in: arrData) {
            var model = SensorDataModel()
            model.unit = dict["unit"] as? String
            model.value = dict["value"] as? Double
            
            arrayRequest.append(sensorDataRequest(with: dict, sensor: SensorType.lamp_respiratory_rate, dataModel: model))
        }
        return arrayRequest
    }
    
    func latestData(for hkIdentifier: String, in array: [[String: Any]]) -> [String: Any]? {
        return array.filter({ ($0["type"] as? String) == hkIdentifier }).max(by: {($0["timestamp"] as? Double) ?? 0 < ($1["timestamp"] as? Double) ?? 0 })
    }
}
