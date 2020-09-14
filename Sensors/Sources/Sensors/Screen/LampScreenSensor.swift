//  mindLAMP Consortium

#if !os(watchOS)
import Foundation
import UIKit

public class LampScreenSensor {
 
    public var latestScreenStateData: ScreenStateData?
    public func fetchScreenState() {
        latestScreenStateData = nil
        DispatchQueue.main.async { [weak self] in
            if UIApplication.shared.isProtectedDataAvailable {
                
                if UIScreen.main.brightness == 0.0 {
                    self?.latestScreenStateData = ScreenStateData(screenState: .screen_off)
                } else {
                    self?.latestScreenStateData = ScreenStateData(screenState: .screen_on)
                }
                //ScreenStateData(screenState: .screen_unlocked)
            } else {
                self?.latestScreenStateData = ScreenStateData(screenState: .screen_locked)
            }
        }
    }
    public init() {}
    public func start() {
        
    }
    public func stop() {
        
    }
}

public enum ScreenState: Int {
    
    case screen_on
    case screen_off
    case screen_locked
    case screen_unlocked
}

extension ScreenState: TextPresentation {
    public var stringValue: String? {
    switch self {
    
    case .screen_on:
        return "Screen On"
    case .screen_off:
        return "Screen Off"
    case .screen_locked:
        return "Screen Locked"
    case .screen_unlocked:
        return "Screen Unlocked"
        }
    }
}

public struct ScreenStateData {
    
    public var screenState: ScreenState = .screen_on
    public var timestamp: Double = Date().timeInMilliSeconds
}
#endif
