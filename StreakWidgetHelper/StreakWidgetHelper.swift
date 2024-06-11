// mindLAMP

import Foundation
//import LAMP

public class StreakWidgetHelper {
    
    public init(){
        
        StreakWidgetHelper.cachedEntry = (UserDefaults.standard.streakDataCurrentShared, UserDefaults.standard.streakDataMaxShared)
    }
    struct ActivityEvent: Decodable {
        let activity: String
        let timestamp: TimeInterval
    }
    
    struct ActivityEventResponse: Decodable {
        var data: [ActivityEvent]?
        
        var dates: [Date]? {
            data?.map({ Date(timeIntervalSince1970: $0.timestamp/1000.0) })
        }
    }
    static var cachedEntry:(Int, Int) = (0, 0)
    public func fetchActivityEvents(participantId: String?, completion: (([Date]?) -> Void)?) {
        
        guard let participantId else {
            completion?(nil)
            return
        }
        //todo execute once per day

        //update server
        
        let task = URLSession.shared.dataTask(with: urlRequest(participantId: participantId)) { [weak self] data, response, error in
            
            if let data, let urlResponse = response as? HTTPURLResponse {
             
                print("data jj = \(String(data: data, encoding: .utf8))")
                let decoder = JSONDecoder()
                let formatter = ISO8601DateFormatter()
                decoder.dateDecodingStrategy = .formatted(formatter)
                do {
                    let responseData = try decoder.decode(ActivityEventResponse.self, from: data)
                    
                    let reslut = self?.findCurentAndLongestStreak(dates: responseData.dates ?? [])
                    UserDefaults.standard.streakDataCurrentShared = reslut?.0 ?? 0
                    UserDefaults.standard.streakDataMaxShared = reslut?.1 ?? 0

                    if let reslut {
                        StreakWidgetHelper.cachedEntry = reslut
                    }
                    
                    completion?(responseData.dates)
                    
                    
                } catch (let err) {
                    completion?(nil)
                }
            } else {
                completion?(nil)
            }
        }
        task.resume()
        
//        let lampAPI = NetworkConfig.networkingAPI()
//        let endPoint = String(format: Endpoint.activityEvent.rawValue, participantId)
//        let data = RequestData(endpoint: endPoint, requestTye: HTTPMethodType.get)
//        lampAPI.makeWebserviceCall(with: data) { (response: Result<ActivityEventResponse>) in
//            
//            switch response {
//            case .failure(let error):
//                if let nsError = error as NSError? {
//                    let errorCode = nsError.code
//                    /// -1009 is the offline error code
//                    /// so log errors other than connection issue
//                    if errorCode == -1009 {
//                        LMLogsManager.shared.addLogs(level: .warning, logs: Logs.Messages.network_error + " " + nsError.localizedDescription)
//                    } else {
//                        LMLogsManager.shared.addLogs(level: .error, logs: Logs.Messages.network_error + " " + nsError.localizedDescription)
//                    }
//                    print("ActivityAPI error = \( nsError.localizedDescription)")
//                    completion?(nil)
//                }
//            case .success(let response):
//                //let allActivityEvents = response.data
//                //guard let self = self else { return }
//                completion?(response.dates)
//            }
//        }
    }
    
    func urlRequest(participantId: String) -> URLRequest {
        
        let endPoint = String(format: Endpoint.activityEvent.rawValue, participantId)
        
        let baseURL = URL(string: LampURL.baseURLString)!
        var request = URLRequest(url: baseURL.appendingPathComponent(endPoint))
        request.httpMethod = "GET"
        var requestHeaders = [String: String]()
        requestHeaders["Content-Type"] = "application/json"
        
        if let userId = UserDefaults.standard.userIDShared, 
            let pass = UserDefaults.standard.passwordShared {
            
            let base64token = Data("\(userId):\(pass)".utf8).base64EncodedString()
            requestHeaders["Authorization"] = "Basic \(base64token)"
        }
        request.allHTTPHeaderFields = requestHeaders
        return request
    }
    
    // Helper function to check if two dates are consecutive
    private func areDatesConsecutive(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        if let nextDay = calendar.date(byAdding: .day, value: 1, to: date1) {
            return calendar.isDate(nextDay, inSameDayAs: date2)
        }
        return false
    }
    
    public func findCurrentStreak(from dates: [Date]) -> Int {
        
        var currentStreak = 0
        var tempStreak = 1
        guard dates.count > 0 else {
            return currentStreak
        }
        let uniqueDays = uniqueDays(from: dates)
        let sortedDatesDesc = uniqueDays.sorted(by: { date1, date2 in
            date1 > date2
        })
        
        let today = Date()
        let calendar = Calendar.current
        let previousDay = calendar.date(byAdding: .day, value: -1, to: today)!
        if calendar.isDate(today, inSameDayAs: sortedDatesDesc[0]) ||
            calendar.isDate(previousDay, inSameDayAs: sortedDatesDesc[0]) {
            for i in 1..<sortedDatesDesc.count {
                if areDatesConsecutive(sortedDatesDesc[i], sortedDatesDesc[i-1]) {
                    tempStreak += 1
                } else {
                    break
                }
            }
            currentStreak = tempStreak
        }
        return currentStreak
        
    }
    
    // Function to extract unique days from an array of dates
    func uniqueDays(from dates: [Date]) -> [Date] {
        var uniqueDaysSet = Set<String>()
        var uniqueDaysArray = [Date]()
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for date in dates {
            let dayString = dateFormatter.string(from: date)
            if !uniqueDaysSet.contains(dayString) {
                uniqueDaysSet.insert(dayString)
                uniqueDaysArray.append(dateFormatter.date(from: dayString)!)
            }
        }
        
        return uniqueDaysArray
    }


    public func findCurentAndLongestStreak(dates: [Date]) -> (Int, Int) {
        
        guard dates.count > 0 else {
            return (0, 0)
        }
        let sortedDates = dates.sorted()
        
        //filter duplicates?
        
        // Initialize variables
        var tempStreak = 1
        var maxStreak = 1
        var currentStreak = 0
        
        let today = Date()
        
        // Iterate through the sorted dates
        for i in 1..<sortedDates.count {
            if areDatesConsecutive(sortedDates[i-1], sortedDates[i]) {
                tempStreak += 1
            } else {
                tempStreak = 1
            }
            maxStreak = max(maxStreak, tempStreak)
        }
        
        let j = sortedDates.count - 1
        let calendar = Calendar.current
        let previousDay = calendar.date(byAdding: .day, value: -1, to: today)!
        if calendar.isDate(today, inSameDayAs: sortedDates[j]) ||
            calendar.isDate(previousDay, inSameDayAs: sortedDates[j]) {
            currentStreak = tempStreak
        }
        
        return (currentStreak, maxStreak)
    }
}

class ISO8601DateFormatter: DateFormatter {
    static let withoutSeconds: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter
    }()

    private func setup() {
        calendar = Calendar(identifier: .iso8601)
        locale = Locale(identifier: "en_US_POSIX")
        timeZone = TimeZone(secondsFromGMT: 0)
        dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    }

    public override init() {
        super.init()
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override public func date(from string: String) -> Date? {
        if let result = super.date(from: string) {
            return result
        }
        return ISO8601DateFormatter.withoutSeconds.date(from: string)
    }
}
