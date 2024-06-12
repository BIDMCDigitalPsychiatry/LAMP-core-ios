// ActivityWidget

import WidgetKit
import SwiftUI
//https://swiftsenpai.com/development/widget-load-remote-data/
struct Provider: TimelineProvider {
    
    let helper = StreakWidgetHelper()
    //var lastEntry = SimpleEntry(date: Date(), currentStreak: 0, longestStreak: 0)
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), currentStreak: StreakWidgetHelper.cachedEntry.0, longestStreak: StreakWidgetHelper.cachedEntry.1)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
//        guard let reslut = UserDefaults.standard.streakDataCurrentAndMaxShared else {
//            return
//        }
        let entry = SimpleEntry(date: Date(), currentStreak: StreakWidgetHelper.cachedEntry.0, longestStreak: StreakWidgetHelper.cachedEntry.1)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {

        helper.fetchActivityEvents(participantId: UserDefaults.standard.participantIdShared) { dates in
            guard let dates else {
                return
            }
            let reslut = (UserDefaults.standard.streakDataCurrentShared, UserDefaults.standard.streakDataMaxShared)
            
            let entry = SimpleEntry(date: Date(), currentStreak: reslut.0, longestStreak: reslut.1)
            
            //Next fetch happens 15 minutes later
            let nextUpdate = Calendar.current.date(
                byAdding: DateComponents(hour: 4),
                to: Date()
            )!
            
            let timeline = Timeline(
                entries: [entry],
                policy: .after(nextUpdate)
            )
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let currentStreak: Int
    let longestStreak: Int
}

struct StreakWidgetEntryView : View {
    
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40)
            
            let daysText1: String = entry.currentStreak == 1 ? "day" : "days"
            Text("Current streak: \(entry.currentStreak) \(daysText1)")
                .font(.system(size: 12))
                .fontWeight(.black)

            let daysText: String = entry.longestStreak == 1 ? "day" : "days"
            Text("Longest Streak: \(entry.longestStreak) \(daysText)")
                .font(.system(size: 12))
                .fontWeight(.black)
            
            Text("Way To Go!")
                .font(.system(size: 14))
                .fontWeight(.bold)
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
