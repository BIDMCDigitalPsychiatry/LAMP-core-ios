// ActivityWidget

import WidgetKit
import SwiftUI
/// Shows the streak the app saved (see StreakWidgetHelper); never calls the server
struct Provider: TimelineProvider {
    
    let helper = StreakWidgetHelper()
    
    func placeholder(in context: Context) -> SimpleEntry {
        entry(on: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(entry(on: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // The app reloads the widget after it saves a new streak. Midnight gets
        // its own entry, so a missed day shows as a broken streak
        let now = Date()
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now)!)
        completion(Timeline(entries: [entry(on: now), entry(on: midnight)], policy: .atEnd))
    }
    
    private func entry(on date: Date) -> SimpleEntry {
        let streak = helper.savedStreak(on: date)
        return SimpleEntry(date: date, currentStreak: streak.current, longestStreak: streak.longest)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let currentStreak: Int
    let longestStreak: Int
}

struct StreakWidgetEntryView : View {
    
    var entry: Provider.Entry
    @SwiftUI.Environment(\.widgetFamily) var family

    @ViewBuilder
    var body: some View {
        
        switch family {
        case .systemSmall:
            VStack(alignment: .center, spacing: 5) {
                
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36)
                
                let daysText1: String = entry.currentStreak == 1 ? "day" : "days"
                Text("Current streak: \(entry.currentStreak) \(daysText1)")
                    .font(.system(size: 10))
                    .fontWeight(.medium)
                
                let daysText: String = entry.longestStreak == 1 ? "day" : "days"
                Text("Longest Streak: \(entry.longestStreak) \(daysText)")
                    .font(.system(size: 10))
                    .fontWeight(.medium)
                
                Text("Way To Go!")
                    .font(.system(size: 11))
                    .fontWeight(.medium)
            }
        default:
            VStack(alignment: .center, spacing: 5) {
                
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40)
                
                let daysText1: String = entry.currentStreak == 1 ? "day" : "days"
                Text("Current streak: \(entry.currentStreak) \(daysText1)")
                    .font(.system(size: 14))
                    .fontWeight(.medium)
                
                let daysText: String = entry.longestStreak == 1 ? "day" : "days"
                Text("Longest Streak: \(entry.longestStreak) \(daysText)")
                    .font(.system(size: 14))
                    .fontWeight(.medium)
                
                Text("Way To Go!")
                    .font(.system(size: 15))
                    .fontWeight(.medium)
            }
        }
    }
}

struct StreakWidget: Widget {
    let kind: String = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                StreakWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                StreakWidgetEntryView(entry: entry)
                    .padding()
                    //.background()
            }
        }
        //.supportedFamilies([WidgetFamily.systemLarge])
        .configurationDisplayName("My Activity Streak")
//        .description("This is an example widget.")
        //.supportedFamilies([.systemSmall])
        .supportedFamilies([
                    .systemSmall,
                    .systemMedium,
                    .systemLarge,
                ])
    }
}

//#Preview(as: .systemSmall) {
//    StreakWidget()
//} timeline: {
//    SimpleEntry(date: Date(), currentStreak: 0, longestStreak: 0)
//    SimpleEntry(date: Date(), currentStreak: 0, longestStreak: 0)
//}
