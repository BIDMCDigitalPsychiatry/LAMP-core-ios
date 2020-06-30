//  mindLAMP Consortium

import Foundation
import UIKit

class LampScreenSensor {
 
    var latestScreenStateData: ScreenStateData?
    func fetchScreenState() {
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
            printToFile("fetched sceenstate")
        }
    }
    func start() {
        
    }
    func stop() {
        
    }
}
