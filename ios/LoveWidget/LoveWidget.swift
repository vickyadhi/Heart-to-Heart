import WidgetKit
import SwiftUI

private let appGroupId = "group.com.example.h2h"

struct WidgetData: Decodable {
    let partnerName: String
    let statusMessage: String
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), partnerName: "Partner", statusMessage: "No taps yet 🥺")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = getEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = getEntry()
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
    
    private func getEntry() -> SimpleEntry {
        let userDefaults = UserDefaults(suiteName: appGroupId)
        let partnerName = userDefaults?.string(forKey: "partner_name") ?? "Partner"
        let statusMessage = userDefaults?.string(forKey: "status_message") ?? "No taps yet 🥺"
        return SimpleEntry(date: Date(), partnerName: partnerName, statusMessage: statusMessage)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let partnerName: String
    let statusMessage: String
}

struct LoveWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            // Premium Romantic Gradient matching app theme
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 255/255, green: 213/255, blue: 213/255), 
                    Color(red: 255/255, green: 249/255, blue: 250/255), 
                    Color(red: 232/255, green: 219/255, blue: 255/255)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomRight
            )
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Cute pulsating heart icon in widget
                    Text("💖")
                        .font(.title2)
                    Spacer()
                    Text("h2h")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 243/255, green: 77/255, blue: 95/255).opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(10)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.partnerName)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 44/255, green: 37/255, blue: 37/255))
                    
                    Text(entry.statusMessage)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 122/255, green: 110/255, blue: 112/255))
                        .lineLimit(2)
                }
            }
            .padding(14)
        }
    }
}

@main
struct LoveWidget: Widget {
    let kind: String = "LoveWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LoveWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("h2h Love Widget")
        .description("Keep track of your partner's taps and status in real-time.")
        .supportedFamilies([.systemSmall])
    }
}
