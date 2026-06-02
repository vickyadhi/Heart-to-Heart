import WidgetKit
import SwiftUI

private let appGroupId = "group.com.example.h2h"

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), partnerName: "Partner", statusMessage: "No taps yet 🥺", receivedNote: "No notes yet")
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
        let receivedNote = userDefaults?.string(forKey: "received_note") ?? ""
        return SimpleEntry(date: Date(), partnerName: partnerName, statusMessage: statusMessage, receivedNote: receivedNote)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let partnerName: String
    let statusMessage: String
    let receivedNote: String
}

struct LoveWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

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
            
            if family == .systemMedium {
                mediumLayout
            } else {
                smallLayout
            }
        }
    }
    
    // Compact 2x2 layout
    var smallLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
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
        .widgetURL(URL(string: "homewidget://send_love?type=love_tap"))
    }
    
    // Large 4x2 layout showing details + sticky notes + interactive quick-emojis
    var mediumLayout: some View {
        HStack(spacing: 12) {
            // Left column: Info & Emojis
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Text("💖")
                        .font(.system(size: 18))
                    Text(entry.partnerName)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 44/255, green: 37/255, blue: 37/255))
                        .lineLimit(1)
                    Spacer()
                }
                
                Text(entry.statusMessage)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 122/255, green: 110/255, blue: 112/255))
                    .lineLimit(1)
                    .padding(.top, 2)
                
                Spacer()
                
                // Quick emoji buttons row
                HStack(spacing: 6) {
                    emojiLink(type: "miss_you", icon: "🥺")
                    emojiLink(type: "sad", icon: "😢")
                    emojiLink(type: "excited", icon: "🤩")
                    emojiLink(type: "thinking", icon: "💭")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Right column: Yellow Sticky Note
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("📌")
                        .font(.system(size: 10))
                    Text("Note from Partner")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 160/255, green: 120/255, blue: 0/255))
                }
                
                Text(entry.receivedNote.isEmpty ? "No notes yet" : entry.receivedNote)
                    .font(.system(size: 11, design: .serif))
                    .foregroundColor(Color(red: 44/255, green: 37/255, blue: 37/255))
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
                    .frame(maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(10)
            .frame(width: 160, maxHeight: .infinity)
            .background(Color(red: 254/255, green: 247/255, blue: 205/255))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1.5)
        }
        .padding(12)
    }
    
    // Helper to generate quick-send emoji links
    private func emojiLink(type: String, icon: String) -> some View {
        Link(destination: URL(string: "homewidget://send_love?type=\(type)")!) {
            Text(icon)
                .font(.system(size: 18))
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(0.75))
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
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
        .description("Keep track of your partner's status and sticky notes in real-time.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
