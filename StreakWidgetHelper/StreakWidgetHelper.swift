// mindLAMP

import Foundation
//import LAMP

/// Streak numbers for the widget. The app fetches activity events with its own
/// login and saves the streak here; the widget only reads what was saved, so it
/// never calls the server or holds credentials
public class StreakWidgetHelper {
    
    public init() {}

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
    
    func longestStreakFor(participantId: String) -> Int {
        let dict: [String: Int]? = UserDefaults.standard.object(forKey: "longestActivityStreak") as? [String: Int]
        return dict?[participantId] ?? 0
    }
    
    func setLongestStreak(streak: Int, participantId: String) {
        let dict: [String: Int] = [participantId: streak]
        UserDefaults.standard.setValue(dict, forKey: "longestActivityStreak")
    }
    
    /// A year of activity events the first time, then 3 months
    func fetchStartDate(participantId: String) -> Date {
        if longestStreakFor(participantId: participantId) <= 0 {
            return Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        }
        return Calendar.current.date(byAdding: .month, value: -3, to: Date())!
    }
    
    /// Called by the app after it fetches activity events
    func saveStreak(dates: [Date], participantId: String) {
        let streak = findCurentAndLongestStreak(dates: dates)
        UserDefaults.standard.streakDataCurrentShared = streak.0
        UserDefaults.standard.streakDataMaxShared = streak.1
        UserDefaults.standard.streakLastActiveDayShared = uniqueDays(from: dates).max()
        setLongestStreak(streak: streak.1, participantId: participantId)
    }
    
    /// The saved streak as it stands on `date`: the current streak has ended
    /// if the last active day was before yesterday
    func savedStreak(on date: Date) -> (current: Int, longest: Int) {
        let defaults = UserDefaults.standard
        // Saved by an older app version: show it as saved until the app refreshes it
        guard let lastActiveDay = defaults.streakLastActiveDayShared else {
            return (defaults.streakDataCurrentShared, defaults.streakDataMaxShared)
        }
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: date)!
        let ongoing = calendar.isDate(lastActiveDay, inSameDayAs: date) || calendar.isDate(lastActiveDay, inSameDayAs: yesterday)
        return (ongoing ? defaults.streakDataCurrentShared : 0, defaults.streakDataMaxShared)
    }
    
    // Helper function to check if two dates are consecutive
    private func areDatesConsecutive(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        if let nextDay = calendar.date(byAdding: .day, value: 1, to: date1) {
            return calendar.isDate(nextDay, inSameDayAs: date2)
        }
        return false
    }
    
    
    // Function to extract unique days from an array of dates
    func uniqueDays(from dates: [Date]) -> [Date] {
        var uniqueDaysSet = Set<String>()
        var uniqueDaysArray = [Date]()
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
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

    public func findCurentAndLongestStreak(dates: [Date]) -> (Int, Int) {
        
        guard dates.count > 0 else {
            return (0, 0)
        }
        let uniqueDays = uniqueDays(from: dates)
        let sortedDatesDesc = uniqueDays.sorted()
        
        //filter duplicates?
        
        // Initialize variables
        var tempStreak = 1
        var maxStreak = 1
        var currentStreak = 0
        
        let today = Date()
        
        // Iterate through the sorted dates
        for i in 1..<sortedDatesDesc.count {
            if areDatesConsecutive(sortedDatesDesc[i-1], sortedDatesDesc[i]) {
                tempStreak += 1
            } else {
                tempStreak = 1
            }
            maxStreak = max(maxStreak, tempStreak)
        }
        
        let j = sortedDatesDesc.count - 1
        let calendar = Calendar.current
        let previousDay = calendar.date(byAdding: .day, value: -1, to: today)!
        if calendar.isDate(today, inSameDayAs: sortedDatesDesc[j]) ||
            calendar.isDate(previousDay, inSameDayAs: sortedDatesDesc[j]) {
            currentStreak = tempStreak
        }
        
        return (currentStreak, maxStreak)
    }
}
