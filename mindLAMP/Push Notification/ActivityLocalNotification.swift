// mindLAMP

import Foundation
import UserNotifications
import LAMP
import Combine

class ActivityLocalNotification {
    
    var activitySubscriber: AnyCancellable?
    
//    func demo() {
//        let content = UNMutableNotificationContent()
//        content.body = "eeee test"
//        content.badge = 1
//
//        let deliveryTime = Date().addingTimeInterval(5)
//
//        //let dateComponent = Calendar.current.dateComponents([.minute, .second], from: deliveryTime)
//        //let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponent, repeats: true)
//
//        //let dateComponent = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from:Date().addingTimeInterval(5))
//
//        let thisTime: TimeInterval = 60.0 // 1 minute = 60 seconds
//
//        // Some examples:
//        // 5 minutes = 300.0
//        // 1 hour = 3600.0
//        // 12 hours = 43200.0
//        // 1 day = 86400.0
//        // 1 week = 604800.0
//
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: thisTime, repeats: true)
//
//        let req = UNNotificationRequest(identifier: "eeee", content: content, trigger: trigger)
//
//        let notificationCenter = UNUserNotificationCenter.current()
//        notificationCenter.add(req) { (error) in
//            print(error)
//        }
//
//    }
    
    func listNotification(_ sender: Any) {
        UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: {requests -> () in
            print("\(requests.count) requests -------")
            for request in requests{
                print(request.identifier)
            }
        })
        
        UNUserNotificationCenter.current().getDeliveredNotifications(completionHandler: {deliveredNotifications -> () in
            print("\(deliveredNotifications.count) Delivered notifications-------")
            for notification in deliveredNotifications{
                print(notification.request.identifier)
            }
        })
        
    }
    
    func fetchActivities() {
        
        //todo execute once per day
        guard let authheader = Endpoint.getSessionKey(), let participantId = User.shared.userId else {
            printError("Auth header missing")
            return
        }
        OpenAPIClientAPI.basePath = LampURL.baseURLString
        OpenAPIClientAPI.customHeaders = ["Authorization": "Basic \(authheader)", "Content-Type": "application/json"]
        let publisher = ActivityAPI.activityAllByParticipant(participantId: participantId)
        print("ActivityAPI")
        activitySubscriber = publisher.sink(receiveCompletion: { [weak self] value in
            guard let self = self else { return }
            print("value3 = \(value)")
            switch value {
            case .failure(let ErrorResponse.error(code, data, error)):
                printError("ActivityAPI error code\(code), \(error.localizedDescription)")
                if let data = data {
                    let decoder = JSONDecoder()
                    do {
                        let errResponse = try decoder.decode(ErrResponse.self, from: data)
                        printError("\nActivityAPI errResponse \(String(describing: errResponse.error))")
                    } catch let err {
                        printError("ActivityAPI err = \(err.localizedDescription)")
                    }
                }
            case .failure(let error):
                printError("ActivityAPI error \(error.localizedDescription)")
                if let nsError = error as NSError? {
                    let errorCode = nsError.code
                    /// -1009 is the offline error code
                    /// so log errors other than connection issue
                    if errorCode == -1009 {
                        LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.network_error + " " + nsError.localizedDescription)
                    } else {
                        LMLogsManager.shared.addLogs(level: .error, logs: Logs.Messages.network_error + " " + nsError.localizedDescription)
                    }
                }
            case .finished:
                break
            }
        }, receiveValue: { response in
            let allActivity = response.data
            print("ActivityAPI allActivity = \(allActivity.count)")
            self.scheduleActivities(allActivity)
        })
    }
    

    
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func scheduleActivities(_ allActivity: [Activity]) {
        
        cancelAll()
        allActivity.forEach { (activity) in
            let title = activity.name
            let activityId = activity.id
            activity.schedule?.forEach({ (durationIntervalLegacy) in
                makeLocalNotification(activitySchedule: durationIntervalLegacy, activityId: activityId, title: title)
            })
        }
    }
    
    private func makeLocalNotification(activitySchedule: DurationIntervalLegacy, activityId: String?, title: String?) {

        guard let participantid = User.shared.userId, let activityid = activityId else {return}
        guard let deliveryTime = activitySchedule.time,
              let repeatType = activitySchedule.repeatType, let title = title else { return }
        
        guard let identifierInt = activitySchedule.notificationId?.first else {return}
        let identifier = String(identifierInt)
        //var path = "/participant/{participant_id}/activity/{activityid}"
        let pageURL = "/participant/\(participantid)/activity/\(activityid)"
        
        //Create content for your notification
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = "Local - You have a mindLAMP activity waiting for you: \(title)"
        content.sound = UNNotificationSound.default
        //"expiry": 21600000
        let actionObj = ["name":"Open App", "page":pageURL]
        let actions = [actionObj]
        content.userInfo = ["notificationId": identifier, "page": pageURL, "actions" : actions]
        
        //make different type of notification as per repeat type
        switch repeatType {

        case .custom:
            //trigger daily for all custom times
            activitySchedule.customTimes?.enumerated().forEach({ (i, fireTime) in
                guard let identifierCustomInt = activitySchedule.notificationId?[safe: i] else {return}
                let identifierCustom = String(identifierCustomInt)
                let dateComponent = Calendar.current.dateComponents([.hour, .minute, .second], from:fireTime)
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponent, repeats: true)
                let req = UNNotificationRequest(identifier: identifierCustom, content: content, trigger: trigger)
                let notificationCenter = UNUserNotificationCenter.current()
                notificationCenter.add(req) { (error) in
                    print(error)
                }
            })
            
        case .daily:
            let dateComponent = Calendar.current.dateComponents([.hour, .minute, .second], from:deliveryTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponent, repeats: true)
            let req = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.add(req) { (error) in
                print(error)
            }
        case .hourly:
            let dateComponent = Calendar.current.dateComponents([.minute, .second], from:deliveryTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponent, repeats: true)
            let req = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.add(req) { (error) in
                print(error)
            }
        case .monthly:
            let dateComponent = Calendar.current.dateComponents([.day, .hour, .minute, .second], from:deliveryTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponent, repeats: true)
            let req = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.add(req) { (error) in
                print(error)
            }
        case .none:
            let dateComponent = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from:deliveryTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponent, repeats: false)
            let req = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.add(req) { (error) in
                print(error)
            }
        }
        
    }
}
