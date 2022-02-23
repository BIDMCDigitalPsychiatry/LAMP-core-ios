// mindLAMP

import Foundation
import UserNotifications
import LAMP
//import Combine
//
extension Activity: Equatable {
    public static func ==(lhs: Activity, rhs: Activity) -> Bool {
        // Using "identifier" property for comparison
        return lhs.id == rhs.id && lhs.spec == rhs.spec && lhs.name == rhs.name && lhs.schedule == rhs.schedule
    }
}
extension DurationIntervalLegacy: Equatable {
    public static func ==(lhs: DurationIntervalLegacy, rhs: DurationIntervalLegacy) -> Bool {
        return lhs.repeatType == rhs.repeatType && lhs.startDate == rhs.startDate && lhs.time == rhs.time && lhs.customTimes == rhs.customTimes && lhs.notificationId == rhs.notificationId
    }
}

class ActivityLocalNotification {
    
    //var activitySubscriber: AnyCancellable?
    var allActivitiesScheduled: [Activity] = []
    let intervalToFetchActivity = 40.0 * 60.0 //for 1 hour
    let intervalToScheduleActivity = 12.0 * 60.0 * 60.0 //for 12 hour
    
    func refreshActivities() {
        if Date().timeIntervalSince(UserDefaults.standard.activityAPILastAccessedDate) > intervalToFetchActivity {
            fetchActivities()
        }
    }
   
    func listNotification() {
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
    
    private func fetchActivities() {
        
//        struct Params: Encodable {
//            var ignore_binary = true
//        }
        
        //todo execute once per day
        guard let participantId = User.shared.userId else {
            printError("Auth header missing")
            return
        }
        //update server
        let lampAPI = NetworkConfig.networkingAPI()
        let endPoint = String(format: Endpoint.activity.rawValue, participantId)
        let data = RequestData(endpoint: endPoint, requestTye: HTTPMethodType.get)
        lampAPI.makeWebserviceCall(with: data) { [weak self] (response: Result<ActivityAPI.Response>) in
            
            switch response {
            case .failure(let error):
                if let nsError = error as NSError? {
                    let errorCode = nsError.code
                    /// -1009 is the offline error code
                    /// so log errors other than connection issue
                    if errorCode == -1009 {
                        LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.network_error + " " + nsError.localizedDescription)
                    } else {
                        LMLogsManager.shared.addLogs(level: .error, logs: Logs.Messages.network_error + " " + nsError.localizedDescription)
                    }
                    print("ActivityAPI error = \( nsError.localizedDescription)")
                }
            case .success(let response):
                let allActivity = response.data
                print("ActivityAPI allActivity = \(allActivity.count)")
                guard let self = self else { return }
                print("ActivityAPI same? = \(self.allActivitiesScheduled == allActivity)")
                if self.allActivitiesScheduled != allActivity || Date().timeIntervalSince(UserDefaults.standard.activityAPILastScheduledDate) > self.intervalToScheduleActivity {
                    print("scheduling")
                    self.scheduleActivities(allActivity)
                }
            }
            UserDefaults.standard.activityAPILastAccessedDate = Date()
        }
        
        /*
        guard let authheader = Endpoint.getSessionKey(), let participantId = User.shared.userId else {
            printError("Auth header missing")
            return
        }
        OpenAPIClientAPI.basePath = LampURL.baseURLString
        OpenAPIClientAPI.customHeaders = ["Authorization": "Basic \(authheader)", "Content-Type": "application/json"]
        let publisher = ActivityAPI.activityAllByParticipant(participantId: participantId)
        print("ActivityAPI")
        activitySubscriber = publisher.sink(receiveCompletion: { value in
            print("value activity = \(value)")
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
                UserDefaults.standard.activityAPILastAccessedDate = Date()
                break
            }
        }, receiveValue: { response in
            let allActivity = response.data
            print("ActivityAPI allActivity = \(allActivity.count)")
            self.scheduleActivities(allActivity)
        })
         */
    }
    
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func scheduleActivities(_ allActivity: [Activity]) {
        
        //we have to handle the datetime received as the local time of the user.
        let localActivities: [Activity] = allActivity.map { activity in
            let schedules: [DurationIntervalLegacy]? = activity.schedule?.map { interval in
                let cudtomTimes: [Date]? = interval.customTimes?.compactMap({$0.toLocal})
                return DurationIntervalLegacy(repeatType: interval.repeatType, startDate: interval.startDate?.toLocal, time: interval.time?.toLocal, customTimes: cudtomTimes, notificationId: interval.notificationId)
            }
            return Activity(id: activity.id, spec: activity.spec, name: activity.name, schedule: schedules)
        }

        allActivitiesScheduled = allActivity
        UserDefaults.standard.activityAPILastScheduledDate = Date()
        cancelAll()
        localActivities.forEach { (activity) in
            let title = activity.name
            let activityId = activity.id
            activity.schedule?.forEach({ (durationIntervalLegacy) in
                makeLocalNotification(activitySchedule: durationIntervalLegacy, activityId: activityId, title: title)
            })
        }
    }
    
    let queue = DispatchQueue(label: "NotificationTimer", qos: .background, attributes: .concurrent)
    private func makeLocalNotification(activitySchedule: DurationIntervalLegacy, activityId: String?, title: String?) {

        guard let participantid = User.shared.userId, let activityid = activityId else {return}
        guard let deliveryTime = activitySchedule.time, let scheduleStartDate = activitySchedule.startDate,
              let repeatType = activitySchedule.repeatType, let title = title else { return }
        
        //return if start-time greater than curent time
        guard let identifierInt = activitySchedule.notificationId?.first else {return}
        let identifier = String(identifierInt)
        
        let pageURL = "/participant/\(participantid)/activity/\(activityid)"
        
        //Create content for your notification
        let content = UNMutableNotificationContent()
        //content.title = title
        content.body = "You have a mindLAMP activity waiting for you: \(title)"
        content.sound = UNNotificationSound.default
        //"expiry": 21600000
        let actionObj = ["name":"Open App", "page":pageURL]
        let actions = [actionObj]
        content.userInfo = ["notificationId": identifier, "page": pageURL, "actions" : actions]
        //extract startDay
        let dateComponentStartDay = Calendar.current.dateComponents([.year, .month, .day, .weekday], from: scheduleStartDate)
        let startDay = Calendar.current.date(from: dateComponentStartDay)
        //make different type of notification as per repeat type
        switch repeatType {

        case .biweekly:
            if let startDate = startDay, startDate > Date() { return }
            //if we set local notification on every Tuesday and Thursday, then we need two identifiers. But here we have to meet this with same identifier, then only the Tuesday alert will replaced by Thursday alert. So we are not creating a recurrent alert. Instead we will find upcoming date of alert and will schedule. There is no effect it is recurrent or not.
            let weekdaySet = IndexSet([3, 5]) // Tuesday 3 and Thursday 5
            schedulteNextWeekDay(weekdaySet: weekdaySet, deliveryTime: deliveryTime, identifier: identifier, content: content)
        case .triweekly:
            if let startDate = startDay, startDate > Date() { return }
            //Every Monday, Wednesday, and Friday. 2, 4, 6
            let weekdaySet = IndexSet([2, 4, 6])
            schedulteNextWeekDay(weekdaySet: weekdaySet, deliveryTime: deliveryTime, identifier: identifier, content: content)
        case .bimonthly:
            
            if let startDate = startDay, startDate > Date() { return }
            //As we have to use same identifier for both alert, we can't create both alert. So we will find upcoming alert date and will create one.  There is no effect it is recurrent or not.
            let daySet = IndexSet([10, 20])
            
            let dayToday =  Calendar.current.component(.day, from: Date())
            let timeComponent = Calendar.current.dateComponents([.hour, .minute], from:deliveryTime)
            //check today is 10 or 20
            if daySet.contains(dayToday) {
                let dateComponentToDay = Calendar.current.dateComponents([.year, .month, .day], from:Date())
                let components = DateComponents(year: dateComponentToDay.year, month: dateComponentToDay.month, day: dateComponentToDay.day, hour: timeComponent.hour, minute: timeComponent.minute)
                if let schedulteTime = Calendar.current.date(from: components), schedulteTime > Date() {
                    addNoticiationOn(identifier: identifier, content: content, dateComponent: components)
                    return
                }
            }
            guard let nextDate = nextDay(daySet: daySet) else { return }
            let dateComponentNotificationDay = Calendar.current.dateComponents([.year, .month, .day], from: nextDate)
            let components = DateComponents(year: dateComponentNotificationDay.year, month: dateComponentNotificationDay.month, day: dateComponentNotificationDay.day, hour: timeComponent.hour, minute: timeComponent.minute)
            addNoticiationOn(identifier: identifier, content: content, dateComponent: components)

        case .every3h:
            if let startDate = startDay, startDate > Date() { return }
            let hours = 3
            schduleforEveryHour(hours: hours, deliveryTime: deliveryTime, identifier: identifier, content: content)
        case .every6h:
            if let startDate = startDay, startDate > Date() { return }
            let hours = 6
            schduleforEveryHour(hours: hours, deliveryTime: deliveryTime, identifier: identifier, content: content)
        case .every12h:
            if let startDate = startDay, startDate > Date() { return }
            let hours = 12
            schduleforEveryHour(hours: hours, deliveryTime: deliveryTime, identifier: identifier, content: content)
        case .weekly:
            //week day of start day
            
            let timeComponent = Calendar.current.dateComponents([.hour, .minute], from: deliveryTime)
            let components = DateComponents(hour: timeComponent.hour, minute: timeComponent.minute, weekday: dateComponentStartDay.weekday)
            addNoticiationOn(identifier: identifier, content: content, dateComponent: components)
        case .custom:
            if let startDate = startDay, startDate > Date() { return }
            //trigger daily for all custom times
            activitySchedule.customTimes?.enumerated().forEach({ (i, fireTime) in
                guard let identifierCustomInt = activitySchedule.notificationId?[safe: i] else {return}
                let identifierCustom = String(identifierCustomInt)
                let dateComponent = Calendar.current.dateComponents([.hour, .minute], from:fireTime)
                addNoticiationOn(identifier: identifierCustom, content: content, dateComponent: dateComponent)
            })
        case .daily:
            if let startDate = startDay, startDate > Date() { return }
            let dateComponent = Calendar.current.dateComponents([.hour, .minute], from:deliveryTime)
            addNoticiationOn(identifier: identifier, content: content, dateComponent: dateComponent)
        case .hourly:
            if let startDate = startDay, startDate > Date() { return }
            let dateComponent = Calendar.current.dateComponents([.minute], from:deliveryTime)
            addNoticiationOn(identifier: identifier, content: content, dateComponent: dateComponent)
        case .monthly:
            let timeComponent = Calendar.current.dateComponents([.hour, .minute], from: deliveryTime)
            let components = DateComponents(day: dateComponentStartDay.day, hour: timeComponent.hour, minute: timeComponent.minute)
            addNoticiationOn(identifier: identifier, content: content, dateComponent: components)
        case .fortnightly:
            if let startDate = startDay, startDate > Date() { return }
            let hours = 14 * 24 //every two weeeks +roll 1 to 14
            schduleforEveryHour(hours: hours, deliveryTime: deliveryTime, identifier: identifier, content: content)
        case .none:
            let dateComponentTime = Calendar.current.dateComponents([.hour, .minute], from:deliveryTime)
            let triggerOncecomponents = DateComponents(year: dateComponentStartDay.year, month: dateComponentStartDay.month, day: dateComponentStartDay.day, hour: dateComponentTime.hour, minute: dateComponentTime.minute)
            
            addNoticiationOn(identifier: identifier, content: content, dateComponent: triggerOncecomponents, repeats: false)
        }
    }
    
    struct ComponentIntervals {
        var dateComponent: DateComponents
        var intervals: TimeInterval
        init(_ dateComponent: DateComponents) {
            self.dateComponent = dateComponent
            self.intervals = Calendar.current.date(from: dateComponent)?.timeIntervalSince(Date()) ?? -1
        }
    }
    
    private func schedulteNextWeekDay(weekdaySet: IndexSet, deliveryTime: Date, identifier: String, content: UNMutableNotificationContent) {
        let weekdayToday =  Calendar.current.component(.weekday, from: Date())
        let timeComponent = Calendar.current.dateComponents([.hour, .minute], from:deliveryTime)
        if weekdaySet.contains(weekdayToday) {
            let dateComponentToDay = Calendar.current.dateComponents([.year, .month, .day], from:Date())
            let components = DateComponents(year: dateComponentToDay.year, month: dateComponentToDay.month, day: dateComponentToDay.day, hour: timeComponent.hour, minute: timeComponent.minute)
            if let schedulteTime = Calendar.current.date(from: components), schedulteTime > Date() {
                addNoticiationOn(identifier: identifier, content: content, dateComponent: components)
                return
            }
        }
        //if not scheduled today
        guard let nextDate = nextWeekDay(weekdaySet: weekdaySet) else { return }
        let dateComponentNotificationDay = Calendar.current.dateComponents([.year, .month, .day], from: nextDate)
        let components = DateComponents(year: dateComponentNotificationDay.year, month: dateComponentNotificationDay.month, day: dateComponentNotificationDay.day, hour: timeComponent.hour, minute: timeComponent.minute)
        addNoticiationOn(identifier: identifier, content: content, dateComponent: components)
    }
    
    //schedule a non-repeat notification on 'deliveryTime' and scheule repeating interval notification at the tie of first 'deliveryTime'
    private func schduleforEveryHour(hours: Int, deliveryTime: Date, identifier: String, content: UNMutableNotificationContent) {
        guard let intervalToStart = timeIntervaForImmediateFutureDate(everyXhours: hours, fireTime: deliveryTime) else { return }
        //schedule for first
        let dateComponent = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date().addingTimeInterval(intervalToStart))
        addNoticiationOn(identifier: identifier, content: content, dateComponent: dateComponent, repeats: false)
        //self.addIntervalNoticiationOn(identifier: identifier, content: content, interval: intervalToStart, isRepeat: false)
        //schedule for next and repeat
        queue.async {
            let currentRunLoop = RunLoop.current
            let timer = Timer.scheduledTimer(withTimeInterval: intervalToStart, repeats: false) { (timer) in
                self.addIntervalNoticiationOn(identifier: identifier, content: content, interval: Double(hours) * 60.0 * 60.0)
                timer.invalidate()
            }
            currentRunLoop.add(timer, forMode: .common)
            currentRunLoop.run()
        }
    }
    
    //This function used to execute the notitifation when it matched the datecomponent
    private func addNoticiationOn(identifier: String, content: UNNotificationContent, dateComponent: DateComponents, repeats: Bool = true) {
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponent, repeats: repeats)
        let req = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(req) { (_) in
        }
    }
    
    //This function used to execute the the notitifation after x seconds
    private func addIntervalNoticiationOn(identifier: String, content: UNNotificationContent, interval: TimeInterval, isRepeat: Bool = true) {
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: isRepeat)
        let req = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(req) { (_) in
        }
    }

    //find the next weekday from the weekday set. //This excludes today's weekday checking.
    func nextWeekDay(weekdaySet: IndexSet) -> Date? {

        // Get the current calendar and the weekday from today
        let calendar = Calendar.current
        var weekday =  calendar.component(.weekday, from: Date())

        // Calculate the next index
        if let nextWeekday = weekdaySet.integerGreaterThan(weekday) {
            weekday = nextWeekday
        } else {
            weekday = weekdaySet.first!
        }

        // Get the next day matching this weekday
        let components = DateComponents(weekday: weekday)
        return calendar.nextDate(after: Date(), matching: components, matchingPolicy: .nextTime)
    }
    
    //find the next from the day set. //This excludes today checking.
    func nextDay(daySet: IndexSet) -> Date? {

        let calendar = Calendar.current
        var day =  calendar.component(.day, from: Date())

        // Calculate the next index
        if let nextday = daySet.integerGreaterThan(day) {
            day = nextday
        } else {
            day = daySet.first!
        }

        // Get the next day matching this weekday
        let components = DateComponents(day: day)
        return calendar.nextDate(after: Date(), matching: components, matchingPolicy: .nextTime)
    }

    //fireTime - is the time to start the everyXhour notifications.
    //This function is used to find the next upcoming notification data. case 1. current time is 10 am, and the fire time is 8 am, then the next notification time is 11am, so this function returns 1*60*60 seconds.
    //case 2. current time is 10 am and the fire time is 2 pm, then this function returns 1*60*60 seconds for the next notification time of 11 am.
    func timeIntervaForImmediateFutureDate(everyXhours: Int, fireTime: Date) -> TimeInterval? {
        //this is the assumption that, if everyhour is greater than 24 then it should be multiple of 24
        var everyXhour = everyXhours
        if everyXhour >= 24 {
            everyXhour = 24
        }
        let dateComponentDay = Calendar.current.dateComponents([.year, .month, .day], from:Date())
        let dateComponentTime = Calendar.current.dateComponents([.hour, .minute, .second], from:fireTime)
        guard let todayDay = dateComponentDay.day else {return 0}
        
        let tempDaycomponents = DateComponents(year: dateComponentDay.year, month: dateComponentDay.month, day: todayDay, hour: dateComponentTime.hour, minute: dateComponentTime.minute, second: dateComponentTime.second)
        guard let tempDate = Calendar.current.date(from: tempDaycomponents) else { return 0 }

        var isMoveForward = false
        if tempDate < Date() {
            isMoveForward = true
        }
        
        let n = 24 / everyXhour
        for i in 0..<n {
            
            guard let dHour = dateComponentTime.hour else { continue }
            let incrementedHour = (dHour + (i * everyXhour))
            let h = incrementedHour % 24
            let day = isMoveForward ? (Int(incrementedHour / 24) + todayDay) : todayDay
            let daycomponents = DateComponents(year: dateComponentDay.year, month: dateComponentDay.month, day: day, hour: h, minute: dateComponentTime.minute, second: dateComponentTime.second)
            guard let fireDate = Calendar.current.date(from: daycomponents) else { continue }
            print("fireDate = \(fireDate)")
            let timeInterval = fireDate.timeIntervalSince(Date())
            if timeInterval > 0 && timeInterval < (Double(everyXhour) * 60.0 * 60.0) {
                return timeInterval
            } else {
                continue
            }
        }
        return 0
    }

    
}
