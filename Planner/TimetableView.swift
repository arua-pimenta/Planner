import SwiftUI

struct TimetableView: View {
    @EnvironmentObject var app: AppState
    @State private var expandedWeekdays: Set<Int> = []
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(2...6, id: \.self) { weekday in // Mon-Fri
                            let collapsedHeight: CGFloat = 56 // slight gap between days
                            VStack(alignment: .leading, spacing: 6) {
                                Button {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                                        if expandedWeekdays.contains(weekday) {
                                            expandedWeekdays.remove(weekday)
                                        } else {
                                            expandedWeekdays.insert(weekday)
                                        }
                                    }
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                } label: {
                                    Text(weekdayName(weekday).uppercased())
                                        .font(.system(size: 46, weight: .heavy))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                if expandedWeekdays.contains(weekday) {
                                    let daySlots = app.timetableInActive().filter { $0.weekday == weekday }
                                    if daySlots.isEmpty {
                                        Text("No periods")
                                            .foregroundStyle(.secondary)
                                            .font(.footnote)
                                    } else {
                                        VStack(spacing: 8) {
                                            ForEach(daySlots) { slot in
                                                if let course = app.courses.first(where: { $0.id == slot.courseId }) {
                                                    GlassRow {
                                                        HStack {
                                                            VStack(alignment: .leading) {
                                                                Text(course.code).font(.subheadline.bold())
                                                                Text(course.title).font(.footnote).foregroundStyle(.secondary)
                                                            }
                                                            Spacer()
                                                            Text(timeRange(slot.startMinutes, slot.endMinutes))
                                                                .font(.footnote)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            .frame(minHeight: expandedWeekdays.contains(weekday) ? nil : collapsedHeight, alignment: .top)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            // Removed boxes for cleaner look
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .frame(minHeight: geo.size.height, alignment: .center) // center vertically
                    .offset(y: -40) // nudge a bit more upward
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.black.ignoresSafeArea())
        }
    }

    func weekdayName(_ i: Int) -> String {
        let names = Calendar.current.weekdaySymbols // Sun..Sat
        return names[(i-1) % 7]
    }
    func timeRange(_ s: Int, _ e: Int) -> String {
        func fmt(_ m: Int) -> String {
            let h = m/60, mm = m%60
            let date = Calendar.current.date(bySettingHour: h, minute: mm, second: 0, of: Date())!
            let f = DateFormatter(); f.timeStyle = .short
            return f.string(from: date)
        }
        return "\(fmt(s))–\(fmt(e))"
    }
}

struct GlassRow<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        HStack {
            content
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.08)))
    }
}
