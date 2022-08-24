// mindLAMP

import Foundation
import LAMP
import CoreLocation
import UIKit

struct Diagnostics: Encodable {

    var isLowpowerMode: Bool
    
    var pendingFiles: [FileInfo]?
    
    var locaitonAutorizationStatus: String
    
    var isRunning: Bool
    var isWiFiReachable: Bool
    var isLogin: Bool
    var isAPIInProgress: Bool
    var availableDiskSpace: String
    var configuredSensors: [String]?
    var lastAccessedTime_Sensor: Double?
    var lastAccessedTime_Activity: Double?
    var lastRescheduledTime_Activity: Double?
    
    init() {
        isLowpowerMode = BatteryState.shared.isLowPowerEnabled
        pendingFiles = SensorLogs.shared.getAllPendingFiles()
        locaitonAutorizationStatus = CLLocationManager().authorizationStatus.displayValue
        isRunning = LMSensorManager.shared.isRunning
        isWiFiReachable = LMSensorManager.shared.isReachableViaWiFi
        isLogin = User.shared.isLogin()
        isAPIInProgress = BackgroundServices.shared.isRunning
        var availSpace: String {
            #if os(iOS)
            return UIDevice.current.freeDiskSpaceInGB
            #elseif os(watchOS)
            return ""
            #endif
        }
        availableDiskSpace = availSpace
        if isRunning {
            configuredSensors = LMSensorManager.shared.sensorIdentifiers
        } else {
            if let specsDownloaded = SensorLogs.shared.fetchSensorSpecs(), specsDownloaded.count > 0 {
                configuredSensors = specsDownloaded.compactMap({ $0.spec })
            } else {
                configuredSensors = nil
            }
        }
        lastAccessedTime_Sensor = UserDefaults.standard.sensorAPILastAccessedDate.timeInMilliSeconds
        lastAccessedTime_Activity = UserDefaults.standard.activityAPILastAccessedDate.timeInMilliSeconds
        lastRescheduledTime_Activity = UserDefaults.standard.activityAPILastScheduledDate.timeInMilliSeconds
    }
}

extension CLAuthorizationStatus {
    var displayValue: String {
        switch self {
        
        case .notDetermined:
            return "notDetermined"
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        case .authorizedAlways:
            return "authorizedAlways"
        case .authorizedWhenInUse:
            return "authorizedWhenInUse"
        @unknown default:
            return "unknown"
        }
    }
}

#if os(iOS)
extension UIDevice {
    func MBFormatter(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = ByteCountFormatter.Units.useMB
        formatter.countStyle = ByteCountFormatter.CountStyle.decimal
        formatter.includesUnit = false
        return formatter.string(fromByteCount: bytes) as String
    }
    
    //MARK: Get String Value
    var totalDiskSpaceInGB:String {
       return ByteCountFormatter.string(fromByteCount: totalDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    var freeDiskSpaceInGB:String {
        return ByteCountFormatter.string(fromByteCount: freeDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    var usedDiskSpaceInGB:String {
        return ByteCountFormatter.string(fromByteCount: usedDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    var totalDiskSpaceInMB:String {
        return MBFormatter(totalDiskSpaceInBytes)
    }
    
    var freeDiskSpaceInMB:String {
        return MBFormatter(freeDiskSpaceInBytes)
    }
    
    var usedDiskSpaceInMB:String {
        return MBFormatter(usedDiskSpaceInBytes)
    }
    
    //MARK: Get raw value
    var totalDiskSpaceInBytes:Int64 {
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
            let space = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value else { return 0 }
        return space
    }
    
    /*
     Total available capacity in bytes for "Important" resources, including space expected to be cleared by purging non-essential and cached resources. "Important" means something that the user or application clearly expects to be present on the local system, but is ultimately replaceable. This would include items that the user has explicitly requested via the UI, and resources that an application requires in order to provide functionality.
     Examples: A video that the user has explicitly requested to watch but has not yet finished watching or an audio file that the user has requested to download.
     This value should not be used in determining if there is room for an irreplaceable resource. In the case of irreplaceable resources, always attempt to save the resource regardless of available capacity and handle failure as gracefully as possible.
     */
    var freeDiskSpaceInBytes:Int64 {
        if #available(iOS 11.0, *) {
            if let space = try? URL(fileURLWithPath: NSHomeDirectory() as String).resourceValues(forKeys: [URLResourceKey.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage {
                return space ?? 0
            } else {
                return 0
            }
        } else {
            if let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
            let freeSpace = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.int64Value {
                return freeSpace
            } else {
                return 0
            }
        }
    }
    
    var usedDiskSpaceInBytes:Int64 {
       return totalDiskSpaceInBytes - freeDiskSpaceInBytes
    }

}
#endif
