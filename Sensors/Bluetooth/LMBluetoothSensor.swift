//
//  LMBluetoothSensor.swift
//  mindLAMP Consortium
//
//  Created by Zco Engineer on 12/03/20.
//

import CoreBluetooth
import Foundation

public class LMBluetoothSensor: NSObject {
        
    // MARK: Variables
    var centralManager: CBCentralManager!
    public var arrDiscoveredDevices = [LMBluetoothData]()
    
    // MARK: Methods
    public func start() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    public func stop() {
        centralManager.stopScan()
    }
    
    private func scanBluetooth() {
        let arrCBUUID: [CBUUID]? = nil //targetServiceUUIDs()
        centralManager.scanForPeripherals(withServices: arrCBUUID, options: nil)
    }
    
    public func latestData() -> LMBluetoothData? {
        let latest = arrDiscoveredDevices.last
        resetDevicesArray()
        return latest
    }
    
    private func resetDevicesArray() {
        arrDiscoveredDevices.removeAll()
    }
    
    private func targetServiceUUIDs() -> [CBUUID] {
        return [CBUUID(string: BLEDevice.ServiceUuid.BATTERY_SERVICE),
                CBUUID(string: BLEDevice.ServiceUuid.USER_DATA),
                CBUUID(string: BLEDevice.ServiceUuid.MEASUREMENT),
                CBUUID(string: BLEDevice.ServiceUuid.BODY_COMPOSITION_SERIVCE),
                CBUUID(string: BLEDevice.ServiceUuid.DEVICE_INFORMATION),
                CBUUID(string: BLEDevice.ServiceUuid.ENVIRONMENTAL_SENSING),
                CBUUID(string: BLEDevice.ServiceUuid.GENERIC_ACCESS),
                CBUUID(string: BLEDevice.ServiceUuid.GENERIC_ATTRIBUTE),
                CBUUID(string: BLEDevice.ServiceUuid.MANUFACTURER_NAME),
                CBUUID(string: BLEDevice.ServiceUuid.HEART_RATE_UUID),
                CBUUID(string: BLEDevice.ServiceUuid.HTTP_PROXY_UUID),
                CBUUID(string: BLEDevice.ServiceUuid.HUMAN_INTERFACE_DEVICE),
                CBUUID(string: BLEDevice.ServiceUuid.INDOOR_POSITIONING),
                CBUUID(string: BLEDevice.ServiceUuid.LOCATION_NAVIGATION),
                CBUUID(string: BLEDevice.ServiceUuid.PHONE_ALERT_STATUS),
                CBUUID(string: BLEDevice.ServiceUuid.REFERENCE_TIME),
                CBUUID(string: BLEDevice.ServiceUuid.SCAN_PARAMETERS),
                CBUUID(string: BLEDevice.ServiceUuid.TRANSPORT_DISCOVERY),
                CBUUID(string: BLEDevice.ServiceUuid.CURRENT_TIME_SERVICE),
                CBUUID(string: BLEDevice.ServiceUuid.BODY_LOCATION),
                CBUUID(string: BLEDevice.ServiceUuid.UNDEFINED)]
    }
}

extension LMBluetoothSensor: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            scanBluetooth()
        default:
            break
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        var data = LMBluetoothData()
        data.address = peripheral.identifier.uuidString
        data.name = peripheral.name
        data.rssi = Int(truncating: RSSI)
        arrDiscoveredDevices.append(data)
    }
}

