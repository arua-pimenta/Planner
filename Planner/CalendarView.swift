import SwiftUI
import EventKit

struct CalendarView: View {
    @EnvironmentObject var app: AppState
    @State private var selectedDate: Date = Date()
    @State private var phoneEvents: [EKEvent] = []
    @State private var authStatus: EKAuthorizationStatus = .notDetermined
    // NEW: visible month (always the first-of-month for the currently displayed month)
    @State private var visibleMonthStart: Date = {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: Date())
        return cal.date(from: comps)!
    }()
    // NEW: visible week (always the first day of the currently displayed week)
    @State private var visibleWeekStart: Date = {
        let cal = Calendar(identifier: .iso8601)
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        return cal.date(from: comps)!
    }()
    @State private var mode: Mode = .week

    private let ekStore = EKEventStore()
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    enum Mode: String, CaseIterable, Identifiable {
        case day = "Day", week = "Week", month = "Month"
        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .day: return "calendar"
            case .week: return "calendar.badge.clock"
            case .month: return "calendar.circle"
            }
        }
        var order: Int {
            switch self {
            case .day: return 0
            case .week: return 1
            case .month: return 2
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) { // Back to reasonable spacing
                // Header with mode picker and month text
                HStack {
                    // Left icons (fixed container so icons never shift)
                    HStack(spacing: 16) {
                        ForEach(Mode.allCases) { m in
                            Button {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                switchMode(m)
                            } label: {
                                Image(systemName: m.iconName)
                                    .font(.title3)
                                    .frame(width: 36, height: 36) // icon fixed size
                                    .foregroundColor(mode == m ? .white : .gray)
                                    .background(mode == m ? Color.white.opacity(0.2) : Color.clear)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(width: 160, alignment: .leading) // FIXED container width
                    .offset(x: 8) // Move icons slightly to the right

                    Spacer()

                    // Right header (fixed container so title never pushes icons)
                    Text(currentHeaderTitle())
                        .font(.title3.weight(.semibold))
                        .frame(width: 210, alignment: .trailing) // Slightly reduced for minimal spacing
                        .offset(x: -20) // Move title slightly to the left
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)

                // Animated mode view with smooth transition
                ZStack {
                    modeView(for: mode, date: currentPeriodDate())
                        .transition(modeTransition)
                }
            }
            .padding(.horizontal, 16) // Reduced back to a comfortable amount
            .padding(.top, 4) // Minimal top padding
            .padding(.bottom, 8) // Minimal bottom padding
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            // set visibleMonthStart to match selectedDate on initial task run, then load events
            .task { visibleMonthStart = startOfMonth(for: selectedDate); await requestAndLoadEvents() }
            .onChange(of: selectedDate) { newValue in
                // Animate day change (handled in DayModeView for localMoveFromEdge)
                refreshEventsForVisibleRange()
            }
            .onChange(of: visibleWeekStart) { newValue in
                // Animate week change (handled in WeekModeView for localMoveFromEdge)
                refreshEventsForVisibleRange()
            }
            .onChange(of: visibleMonthStart) { newValue in
                // Animate month change (handled in MonthModeView for localMoveFromEdge)
                refreshEventsForVisibleRange()
            }
            .onChange(of: mode) { newMode in
                // This is now handled in switchMode(_:)
                if newMode == .month { visibleMonthStart = startOfMonth(for: selectedDate) }
                if newMode == .week { visibleWeekStart = startOfWeek(for: selectedDate) }
                refreshEventsForVisibleRange()
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let horizontal = value.translation.width
                        if horizontal < -50 {
                            moveForward()
                        } else if horizontal > 50 {
                            moveBackward()
                        }
                    }
            )
        }
    }

    // Track last mode for transition direction
    @State private var lastMode: Mode = .week
    @State private var modeTransition: AnyTransition = .identity

    private func switchMode(_ newMode: Mode) {
        guard newMode != mode else { return }
        let oldMode = mode
        // Determine direction: forward = right-to-left, backward = left-to-right
        let direction: Edge = (newMode.order > oldMode.order) ? .trailing : .leading
        modeTransition = .asymmetric(
            insertion: .move(edge: direction),
            removal: .move(edge: direction == .trailing ? .leading : .trailing)
        )
        withAnimation(.spring(response:0.5, dampingFraction:0.7)) {
            lastMode = mode
            mode = newMode
        }
    }



    // Helper to get previous and next mode for interactive swipe
    private func prevMode() -> Mode? {
        let idx = Mode.allCases.firstIndex(of: mode)!
        if idx > 0 { return Mode.allCases[idx - 1] }
        return nil
    }

    private func nextMode() -> Mode? {
        let idx = Mode.allCases.firstIndex(of: mode)!
        if idx < Mode.allCases.count - 1 { return Mode.allCases[idx + 1] }
        return nil
    }

    // Returns the view for a given mode and date, using the correct state bindings
    @ViewBuilder
    private func modeView(for m: Mode, date: Date) -> some View {
        switch m {
        case .day:
            CalendarTimelineView()
                .id("day-\(date)")
        case .week:
            WeekModeView(
                selectedDate: $selectedDate,
                visibleWeekStart: .constant(startOfWeek(for: date)),
                phoneEvents: phoneEvents,
                appEvents: app.eventsInActive()
            )
            .id("week-\(startOfWeek(for: date))")
        case .month:
            MonthModeView(
                selectedDate: $selectedDate,
                visibleMonthStart: .constant(startOfMonth(for: date)),
                phoneEvents: phoneEvents,
                appEvents: app.eventsInActive()
            )
            .id("month-\(startOfMonth(for: date))")
        }
    }

    // Returns the date representing the current period depending on mode
    private func currentPeriodDate() -> Date {
        switch mode {
        case .day: return selectedDate
        case .week: return visibleWeekStart
        case .month: return visibleMonthStart
        }
    }

    // Returns the date representing the adjacent period (previous or next) depending on mode and direction
    private func adjacentDate(for mode: Mode, forward: Bool) -> Date {
        let value = forward ? 1 : -1
        switch mode {
        case .day:
            return calendar.date(byAdding: .day, value: value, to: selectedDate) ?? currentPeriodDate()
        case .week:
            return calendar.date(byAdding: .weekOfYear, value: value, to: visibleWeekStart) ?? currentPeriodDate()
        case .month:
            return calendar.date(byAdding: .month, value: value, to: visibleMonthStart) ?? currentPeriodDate()
        }
    }

    private func requestAndLoadEvents() async {
        let status = EKEventStore.authorizationStatus(for: .event)
        self.authStatus = status
        if status == .notDetermined {
            do {
                let granted = try await ekStore.requestFullAccessToEvents()
                if granted { await loadForVisibleRange() }
            } catch { }
        } else if status == .authorized || status == .fullAccess { // iOS 17+
            await loadForVisibleRange()
        }
    }

    @MainActor private func loadForVisibleRange() async {
        let (start, end) = visibleRange()
        let predicate = ekStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        let events = ekStore.events(matching: predicate)
        self.phoneEvents = events
    }

    private func refreshEventsForVisibleRange() {
        Task { await loadForVisibleRange() }
    }

    private func startOfWeek(for date: Date) -> Date {
        var iso = Calendar(identifier: .iso8601) // Monday-based weeks
        iso.timeZone = calendar.timeZone
        iso.locale = calendar.locale
        let comps = iso.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return iso.date(from: comps) ?? date
    }

    private func startOfMonth(for date: Date) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: comps) ?? date
    }

    private func visibleRange() -> (Date, Date) {
        switch mode {
        case .day:
            let start = calendar.startOfDay(for: selectedDate)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, end)
        case .week:
            let start = visibleWeekStart
            let end = calendar.date(byAdding: .day, value: 7, to: start)!
            return (start, end)
        case .month:
            // IMPORTANT: use visibleMonthStart (not selectedDate) for the calendar's visible month
            let start = visibleMonthStart
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return (start, end)
        }
    }

    private func currentHeaderTitle() -> String {
        switch mode {
        case .day: return selectedDate.formatted(.dateTime.month(.wide).day().year())
        case .week:
            let s = startOfWeek(for: selectedDate)
            let e = calendar.date(byAdding: .day, value: 6, to: s)!
            let f = DateFormatter(); f.dateFormat = "MMM d"
            return "\(f.string(from: s)) – \(f.string(from: e))"
        case .month:
            // header should reflect visible month
            return visibleMonthStart.formatted(.dateTime.month(.wide).year())
        }
    }

    // Navigation helpers for swipe, with directional animation
    private func moveForward() {
        switch mode {
        case .day:
            if let d = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
                selectedDate = d
            }
        case .week:
            if let d = calendar.date(byAdding: .weekOfYear, value: 1, to: visibleWeekStart) {
                visibleWeekStart = d
            }
        case .month:
            if let d = calendar.date(byAdding: .month, value: 1, to: visibleMonthStart) {
                visibleMonthStart = d
            }
        }
    }

    private func moveBackward() {
        switch mode {
        case .day:
            if let d = calendar.date(byAdding: .day, value: -1, to: selectedDate) {
                selectedDate = d
            }
        case .week:
            if let d = calendar.date(byAdding: .weekOfYear, value: -1, to: visibleWeekStart) {
                visibleWeekStart = d
            }
        case .month:
            if let d = calendar.date(byAdding: .month, value: -1, to: visibleMonthStart) {
                visibleMonthStart = d
            }
        }
    }
}


// MARK: - New Day View Implementation

struct CalendarEvent: Identifiable, Hashable {
    let id: UUID
    let title: String
    let startDate: Date
    let endDate: Date
    let color: Color
    let details: String
}


struct CalendarTimelineView: View {
    @Environment(\.calendar) private var calendar
    @EnvironmentObject var app: AppState
    @State private var selectedEvent: CalendarEvent? = nil
    @State private var phoneEvents: [EKEvent] = []
    private let hours = Array(0..<24)

    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(hours, id: \.self) { hour in
                            ZStack(alignment: .topLeading) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: 1)
                                HStack {
                                    Text(hourLabel(for: hour))
                                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                                        .frame(width: 48, alignment: .trailing)
                                        .foregroundColor(.secondary)
                                        .padding(.trailing, 8)
                                    Spacer()
                                }
                                .padding(.top, hour == 0 ? 2 : 0)
                            }
                            .frame(height: 60)
                            .id(hour)
                        }
                    }
                    .background(Color.clear)
                    .overlay(
                        ZStack {
                            ForEach(phoneEvents, id: \.eventIdentifier) { event in
                                let (y, height) = eventBlockPosition(event: event)
                                Button {
                                    // Optionally: show details for EKEvent if needed
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(event.title ?? "")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text(timeRange(event.startDate, event.endDate))
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 7)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(.ultraThinMaterial)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color(event.calendar.cgColor).opacity(0.22))
                                            )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color(event.calendar.cgColor).opacity(0.8), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                .frame(width: UIScreen.main.bounds.width * 0.65, alignment: .leading)
                                .position(x: UIScreen.main.bounds.width * 0.65 / 2 + 56, y: y + height / 2)
                                .frame(height: height)
                            }
                        }
                    )
                }
                .onAppear {
                    let hour = Calendar.current.component(.hour, from: Date())
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        proxy.scrollTo(hour, anchor: .top)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 0)
        }
        .task {
            await requestAndLoadEvents()
        }
        .onChange(of: app.eventsInActive()) { _ in
            Task { await requestAndLoadEvents() }
        }
    }

    private func hourLabel(for hour: Int) -> String {
        let f = DateFormatter()
        f.dateFormat = "ha"
        let d = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return f.string(from: d).lowercased()
    }

    private func eventBlockPosition(event: EKEvent) -> (CGFloat, CGFloat) {
        let startOfDay = calendar.startOfDay(for: event.startDate)
        let secondsFromStart = event.startDate.timeIntervalSince(startOfDay)
        let secondsToEnd = event.endDate.timeIntervalSince(startOfDay)
        let startHour = CGFloat(secondsFromStart / 3600)
        let endHour = CGFloat(secondsToEnd / 3600)
        let y: CGFloat = startHour * 60
        let height: CGFloat = max((endHour - startHour) * 60, 20)
        return (y, height)
    }

    private func timeRange(_ s: Date, _ e: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short
        return "\(f.string(from: s)) – \(f.string(from: e))"
    }

    private func requestAndLoadEvents() async {
        let ekStore = EKEventStore()
        let status = EKEventStore.authorizationStatus(for: .event)
        if status == .notDetermined {
            do {
                let granted = try await ekStore.requestFullAccessToEvents()
                if granted { await loadForToday(ekStore: ekStore) }
            } catch { }
        } else if status == .authorized || status == .fullAccess {
            await loadForToday(ekStore: ekStore)
        }
    }

    @MainActor private func loadForToday(ekStore: EKEventStore) async {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        let predicate = ekStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        self.phoneEvents = ekStore.events(matching: predicate)
    }
}

struct EventDetailsView: View {
    let event: CalendarEvent
    let onClose: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(event.title)
                    .font(.title2.bold())
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            Text(event.details)
                .font(.body)
            HStack {
                Image(systemName: "clock")
                Text(eventTimeRange)
            }
            .font(.callout)
            .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var eventTimeRange: String {
        let f = DateFormatter(); f.timeStyle = .short
        return "\(f.string(from: event.startDate)) – \(f.string(from: event.endDate))"
    }
}

// Optimized timeline column with vertical scroll and limited event calculation

// Each column for a single day, with timeline and events stacked vertically, full width, vertical scroll
private struct DayTimelineColumnFullWidth: View {
    let date: Date
    let isSelected: Bool
    let phoneEvents: [EKEvent]
    let appEvents: [EventItem]
    let showCurrentTime: Bool
    let geoHeight: CGFloat
    let initialScrollHour: Int
    @Binding var verticalScrollProxy: ScrollViewProxy?
    private let calendar = Calendar.current
    private let hourRowHeight: CGFloat = 68
    @State private var now: Date = Date()
    @State private var timer: Timer? = nil
    @State private var didInitialScroll: Bool = false

    var body: some View {
        let merged = mergedEvents()
        GeometryReader { geo in
            ScrollViewReader { vProxy in
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .top) {
                        // Timeline grid
                        VStack(spacing: 0) {
                            ZStack(alignment: .top) {
                                // Vertical timeline line
                                Rectangle()
                                    .fill(Color.white.opacity(0.16))
                                    .frame(width: 2)
                                    .frame(height: hourRowHeight * 24)
                                    .offset(x: 0, y: 0)
                                    .zIndex(0)
                                // Hour horizontal dividers
                                VStack(spacing: 0) {
                                    ForEach(0..<24, id: \.self) { _ in
                                        Rectangle()
                                            .fill(Color.white.opacity(0.10))
                                            .frame(height: 1)
                                            .frame(maxWidth: .infinity)
                                        Spacer()
                                            .frame(height: hourRowHeight - 1)
                                    }
                                }
                                .zIndex(0)
                                // Event blocks (liquid glass)
                                ForEach(merged) { event in
                                    TimelineEventBlockLiquidGlass(
                                        event: event,
                                        hourStart: calendar.startOfDay(for: date),
                                        hourEnd: calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))!,
                                        hourRowHeight: hourRowHeight
                                    )
                                    .zIndex(1)
                                }
                                // Current time indicator (if today)
                                if showCurrentTime {
                                    LiveCurrentTimeIndicator(now: now)
                                        .zIndex(2)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: hourRowHeight * 24, maxHeight: hourRowHeight * 24)
                            .padding(.vertical, 0)
                        }
                    }
                    .background(isSelected ? Color.white.opacity(0.06) : Color.clear)
                    .cornerRadius(14)
                    .onAppear {
                        verticalScrollProxy = vProxy
                        if !didInitialScroll {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                vProxy.scrollTo(initialScrollHour, anchor: .top)
                                didInitialScroll = true
                            }
                        }
                        updateTimer()
                    }
                    .onDisappear {
                        timer?.invalidate()
                        timer = nil
                    }
                    .onChange(of: isSelected) { newSelected in
                        // When this column becomes selected, scroll to correct hour
                        if newSelected {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                vProxy.scrollTo(initialScrollHour, anchor: .top)
                            }
                        }
                    }
                    // Add hour IDs for scrolling
                    .overlay(
                        VStack(spacing: 0) {
                            ForEach(0..<24, id: \.self) { hour in
                                Color.clear
                                    .frame(height: hourRowHeight)
                                    .id(hour)
                            }
                        }
                        .allowsHitTesting(false)
                    )
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private func mergedEvents() -> [TimelineDisplayEvent] {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        let phone = phoneEvents.filter { $0.startDate < dayEnd && $0.endDate > dayStart }
            .map { e in
                TimelineDisplayEvent(
                    id: e.eventIdentifier,
                    title: e.title,
                    start: e.startDate < dayStart ? dayStart : e.startDate,
                    end: e.endDate > dayEnd ? dayEnd : e.endDate,
                    color: Color(e.calendar.cgColor)
                )
            }
        let local = appEvents.filter { calendar.isDate($0.date, inSameDayAs: date) }
            .map { e in
                TimelineDisplayEvent(
                    id: e.id.uuidString,
                    title: e.title,
                    start: e.date,
                    end: calendar.date(byAdding: .minute, value: 30, to: e.date) ?? e.date,
                    color: .white
                )
            }
        return (phone + local)
    }

    private func updateTimer() {
        now = Date()
        timer?.invalidate()
        let nextMinute = Calendar.current.nextDate(after: now, matching: DateComponents(second: 0), matchingPolicy: .nextTime) ?? Date().addingTimeInterval(60)
        let interval = nextMinute.timeIntervalSince(now)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            now = Date()
            timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                now = Date()
            }
        }
    }
}

// Each column for a single day, with timeline and events stacked vertically
private struct DayTimelineColumn: View {
    let date: Date
    let isSelected: Bool
    let phoneEvents: [EKEvent]
    let appEvents: [EventItem]
    let showCurrentTime: Bool
    let geoHeight: CGFloat
    private let calendar = Calendar.current
    private let hourRowHeight: CGFloat = 68

    @State private var now: Date = Date()
    @State private var timer: Timer? = nil

    var body: some View {
        let merged = mergedEvents()
        ZStack(alignment: .top) {
            // Timeline grid
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    // Vertical timeline line
                    Rectangle()
                        .fill(Color.white.opacity(0.16))
                        .frame(width: 2)
                        .frame(height: hourRowHeight * 24)
                        .offset(x: 0, y: 0)
                        .zIndex(0)
                    // Hour horizontal dividers
                    VStack(spacing: 0) {
                        ForEach(0..<24, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.white.opacity(0.10))
                                .frame(height: 1)
                                .frame(maxWidth: .infinity)
                            Spacer()
                                .frame(height: hourRowHeight - 1)
                        }
                    }
                    .zIndex(0)
                    // Event blocks (liquid glass)
                    ForEach(merged) { event in
                        TimelineEventBlockLiquidGlass(
                            event: event,
                            hourStart: calendar.startOfDay(for: date),
                            hourEnd: calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))!,
                            hourRowHeight: hourRowHeight
                        )
                        .zIndex(1)
                    }
                    // Current time indicator (if today)
                    if showCurrentTime {
                        LiveCurrentTimeIndicator(now: now)
                            .zIndex(2)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: hourRowHeight * 24, maxHeight: hourRowHeight * 24)
                .padding(.vertical, 0)
            }
        }
        .background(isSelected ? Color.white.opacity(0.06) : Color.clear)
        .cornerRadius(14)
        .onAppear {
            updateTimer()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private func mergedEvents() -> [TimelineDisplayEvent] {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        let phone = phoneEvents.filter { $0.startDate < dayEnd && $0.endDate > dayStart }
            .map { e in
                TimelineDisplayEvent(
                    id: e.eventIdentifier,
                    title: e.title,
                    start: e.startDate < dayStart ? dayStart : e.startDate,
                    end: e.endDate > dayEnd ? dayEnd : e.endDate,
                    color: Color(e.calendar.cgColor)
                )
            }
        let local = appEvents.filter { calendar.isDate($0.date, inSameDayAs: date) }
            .map { e in
                TimelineDisplayEvent(
                    id: e.id.uuidString,
                    title: e.title,
                    start: e.date,
                    end: calendar.date(byAdding: .minute, value: 30, to: e.date) ?? e.date,
                    color: .white
                )
            }
        return (phone + local)
    }

    private func updateTimer() {
        now = Date()
        timer?.invalidate()
        let nextMinute = Calendar.current.nextDate(after: now, matching: DateComponents(second: 0), matchingPolicy: .nextTime) ?? Date().addingTimeInterval(60)
        let interval = nextMinute.timeIntervalSince(now)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            now = Date()
            timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                now = Date()
            }
        }
    }
}

// One day's timeline row with hour labels, events, vertical separator, and current-time indicator
private struct DayTimelineRow: View {
    let date: Date
    let isSelected: Bool
    let phoneEvents: [EKEvent]
    let appEvents: [EventItem]
    let showHourLabels: Bool
    let geoWidth: CGFloat
    private let calendar = Calendar.current
    static let hourRowHeight: CGFloat = 68

    // For current time indicator
    @State private var now: Date = Date()
    @State private var timer: Timer? = nil

    var body: some View {
        let merged = mergedEvents()
        ZStack(alignment: .topLeading) {
            HStack(alignment: .top, spacing: 0) {
                // Hour labels
                VStack(spacing: 0) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(hourLabel(for: hour))
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .frame(width: 48, height: DayTimelineRow.hourRowHeight, alignment: .trailing)
                            .foregroundColor(.secondary)
                            .padding(.trailing, 8)
                            .padding(.top, hour == 0 ? 2 : 0)
                    }
                }
                // Timeline with vertical separator and events
                ZStack(alignment: .topLeading) {
                    // Vertical line for the day
                    Rectangle()
                        .fill(Color.white.opacity(0.16))
                        .frame(width: 2)
                        .frame(height: DayTimelineRow.hourRowHeight * 24)
                        .offset(x: 0, y: 0)
                    // Hour horizontal dividers
                    VStack(spacing: 0) {
                        ForEach(0..<24, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.white.opacity(0.10))
                                .frame(height: 1)
                                .frame(maxWidth: .infinity)
                                .padding(.leading, 0)
                            Spacer()
                                .frame(height: DayTimelineRow.hourRowHeight - 1)
                        }
                    }
                    // Event blocks (liquid glass)
                    ForEach(merged) { event in
                        TimelineEventBlockLiquidGlass(
                            event: event,
                            hourStart: calendar.startOfDay(for: date),
                            hourEnd: calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))!,
                            hourRowHeight: DayTimelineRow.hourRowHeight
                        )
                    }
                    // Current time indicator (if today)
                    if calendar.isDateInToday(date) {
                        LiveCurrentTimeIndicator(now: now)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: DayTimelineRow.hourRowHeight * 24, maxHeight: DayTimelineRow.hourRowHeight * 24)
                .padding(.vertical, 0)
            }
        }
        .background(isSelected ? Color.white.opacity(0.03) : Color.clear)
        .onAppear {
            updateTimer()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private func hourLabel(for hour: Int) -> String {
        let f = DateFormatter()
        f.dateFormat = "ha"
        let d = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date)!
        return f.string(from: d).lowercased()
    }

    private func mergedEvents() -> [TimelineDisplayEvent] {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        let phone = phoneEvents.filter { $0.startDate < dayEnd && $0.endDate > dayStart }
            .map { e in
                TimelineDisplayEvent(
                    id: e.eventIdentifier,
                    title: e.title,
                    start: e.startDate < dayStart ? dayStart : e.startDate,
                    end: e.endDate > dayEnd ? dayEnd : e.endDate,
                    color: Color(e.calendar.cgColor)
                )
            }
        let local = appEvents.filter { calendar.isDate($0.date, inSameDayAs: date) }
            .map { e in
                TimelineDisplayEvent(
                    id: e.id.uuidString,
                    title: e.title,
                    start: e.date,
                    end: calendar.date(byAdding: .minute, value: 30, to: e.date) ?? e.date, // 30 min block for local event
                    color: .white
                )
            }
        return (phone + local)
    }

    private func updateTimer() {
        now = Date()
        timer?.invalidate()
        let nextMinute = Calendar.current.nextDate(after: now, matching: DateComponents(second: 0), matchingPolicy: .nextTime) ?? Date().addingTimeInterval(60)
        let interval = nextMinute.timeIntervalSince(now)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            now = Date()
            // After first fire, start repeating every 60 seconds
            timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                now = Date()
            }
        }
    }
}

// Live horizontal current-time line (moves across the timeline)
private struct LiveCurrentTimeIndicator: View {
    let now: Date
    private let calendar = Calendar.current
    static let hourRowHeight: CGFloat = 68

    var body: some View {
        let startOfDay = calendar.startOfDay(for: now)
        let seconds = now.timeIntervalSince(startOfDay)
        let yOffset = CGFloat(seconds / 3600) * LiveCurrentTimeIndicator.hourRowHeight
        return
            VStack {
                Spacer().frame(height: yOffset)
                HStack(spacing: 0) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                        .shadow(color: .red.opacity(0.5), radius: 3, x: 0, y: 1)
                    Rectangle()
                        .fill(Color.red)
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                        .shadow(color: .red.opacity(0.3), radius: 0.5, x: 0, y: 0)
                }
                .frame(height: 12)
                Spacer()
            }
            .allowsHitTesting(false)
    }
}

// TimelineScrollView wraps the vertical timeline and allows programmatic scroll to hour 8am when date changes
private struct TimelineScrollView: View {
    @Binding var selectedDate: Date
    let phoneEvents: [EKEvent]
    let appEvents: [EventItem]
    private let calendar = Calendar.current
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var lastSelectedDate: Date = Date()

    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                VerticalTimelineView(date: selectedDate, phoneEvents: phoneEvents, appEvents: appEvents, scrollProxy: proxy)
                    .onAppear {
                        scrollProxy = proxy
                        lastSelectedDate = selectedDate
                        // On appear, scroll to current hour if today, else 8am
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            if calendar.isDateInToday(selectedDate) {
                                let hour = Calendar.current.component(.hour, from: Date())
                                proxy.scrollTo(hour, anchor: .top)
                            } else {
                                proxy.scrollTo(8, anchor: .top)
                            }
                        }
                    }
                    .onChange(of: selectedDate) { newDate in
                        // On selectedDate change, scroll to 8am (or current hour if today)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            if calendar.isDateInToday(newDate) {
                                let hour = Calendar.current.component(.hour, from: Date())
                                proxy.scrollTo(hour, anchor: .top)
                            } else {
                                proxy.scrollTo(8, anchor: .top)
                            }
                        }
                        lastSelectedDate = newDate
                    }
            }
            .scrollIndicators(.hidden)
        }
    }
}

// MARK: - Vertical Timeline View for Day Mode
private struct VerticalTimelineView: View {
    let date: Date
    let phoneEvents: [EKEvent]
    let appEvents: [EventItem]
    var scrollProxy: ScrollViewProxy? = nil
    private let calendar = Calendar.current

    // For current time indicator
    @State private var now: Date = Date()
    @State private var timer: Timer? = nil

    var body: some View {
        let merged = mergedEvents()
        GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    // Timeline grid as base layer
                    VStack(spacing: 0) {
                        ForEach(0..<24, id: \.self) { hour in
                            TimelineHourRow(
                                hour: hour,
                                date: date,
                                events: []
                            )
                            .id(hour)
                        }
                    }

                    // Overlay all event blocks on top of the timeline
                    VStack(spacing: 0) {
                        ForEach(0..<24, id: \.self) { hour in
                            TimelineEventRowOverlay(
                                hour: hour,
                                date: date,
                                events: merged
                            )
                        }
                    }
                    // Make event blocks liquid glass
                    .allowsHitTesting(false)

                    // Moving red line for current time (only if today)
                    if calendar.isDateInToday(date) {
                        // Pass total timeline height for accurate offset
                        CurrentTimeIndicator(now: now, geoHeight: 68 * 24)
                            .allowsHitTesting(false)
                    }
                }
                .padding(.vertical, 12)
                .frame(minHeight: geo.size.height)
            }
            .scrollIndicators(.hidden)
            .onAppear {
                updateTimer()
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
    }

    private func mergedEvents() -> [TimelineDisplayEvent] {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        let phone = phoneEvents.filter { $0.startDate < dayEnd && $0.endDate > dayStart }
            .map { e in
                TimelineDisplayEvent(
                    id: e.eventIdentifier,
                    title: e.title,
                    start: e.startDate < dayStart ? dayStart : e.startDate,
                    end: e.endDate > dayEnd ? dayEnd : e.endDate,
                    color: Color(e.calendar.cgColor)
                )
            }
        let local = appEvents.filter { calendar.isDate($0.date, inSameDayAs: date) }
            .map { e in
                TimelineDisplayEvent(
                    id: e.id.uuidString,
                    title: e.title,
                    start: e.date,
                    end: calendar.date(byAdding: .minute, value: 30, to: e.date) ?? e.date, // 30 min block for local event
                    color: .white
                )
            }
        return (phone + local)
    }

    private func updateTimer() {
        // Update now immediately and every minute
        now = Date()
        timer?.invalidate()
        let nextMinute = Calendar.current.nextDate(after: now, matching: DateComponents(second: 0), matchingPolicy: .nextTime) ?? Date().addingTimeInterval(60)
        let interval = nextMinute.timeIntervalSince(now)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            now = Date()
            // After first fire, start repeating every 60 seconds
            timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                now = Date()
            }
        }
    }
}

// ZStack overlay for event blocks, one row per hour
private struct TimelineEventRowOverlay: View {
    let hour: Int
    let date: Date
    let events: [TimelineDisplayEvent]
    private let calendar = Calendar.current

    // Use the new increased hour row height
    static let hourRowHeight: CGFloat = 68

    var body: some View {
        let hourStart = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: calendar.startOfDay(for: date))!
        let hourEnd = calendar.date(byAdding: .hour, value: 1, to: hourStart)!
        let eventsInHour = events
            .filter { $0.start < hourEnd && $0.end > hourStart }
        ZStack(alignment: .topLeading) {
            ForEach(eventsInHour) { event in
                TimelineEventBlockLiquidGlass(
                    event: event,
                    hourStart: hourStart,
                    hourEnd: hourEnd,
                    hourRowHeight: TimelineEventRowOverlay.hourRowHeight
                )
            }
        }
        .frame(height: TimelineEventRowOverlay.hourRowHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Event block with liquid glass style
private struct TimelineEventBlockLiquidGlass: View {
    let event: TimelineDisplayEvent
    let hourStart: Date
    let hourEnd: Date
    var hourRowHeight: CGFloat = 68
    private let calendar = Calendar.current

    var body: some View {
        // The parent timeline's start of day and end of day
        let startOfDay = calendar.startOfDay(for: hourStart)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let totalHours: CGFloat = 24
        let totalTimelineHeight = hourRowHeight * totalHours

        // Clamp event times to the visible day
        let eventStart = max(event.start, startOfDay)
        let eventEnd = min(event.end, endOfDay)

        let startSeconds = eventStart.timeIntervalSince(startOfDay)
        let endSeconds = eventEnd.timeIntervalSince(startOfDay)
        let eventStartHour = CGFloat(startSeconds / 3600)
        let eventEndHour = CGFloat(endSeconds / 3600)
        let eventDurationHours = max(eventEndHour - eventStartHour, 0.15) // minimum visual height

        let yOffset = eventStartHour * hourRowHeight
        let blockHeight = eventDurationHours * hourRowHeight

        // Horizontal positioning (same as before)
        let minWidth: CGFloat = 60
        let totalWidth: CGFloat = UIScreen.main.bounds.width - 48 - 32 // hour label + padding fudge
        let blockWidth = max(totalWidth * 0.65, minWidth * 0.6)
        // Time label
        let timeText = timeRange(event.start, event.end)
        return
            VStack {
                Spacer().frame(height: yOffset)
                HStack(alignment: .top, spacing: 0) {
                    Spacer().frame(width: 0)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                            .foregroundColor(.white)
                        Text(timeText)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ultraThinMaterial)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(event.color.opacity(0.22))
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(event.color.opacity(0.8), lineWidth: 1)
                    )
                    .frame(width: blockWidth, alignment: .leading)
                    Spacer()
                }
                .frame(height: blockHeight, alignment: .top)
                Spacer(minLength: 0)
            }
    }

    private func timeRange(_ s: Date, _ e: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short
        return "\(f.string(from: s)) – \(f.string(from: e))"
    }
}

// Moving red line for current time
private struct CurrentTimeIndicator: View {
    let now: Date
    let geoHeight: CGFloat
    private let calendar = Calendar.current

    var body: some View {
        // Calculate vertical offset for current time
        let startOfDay = calendar.startOfDay(for: now)
        let seconds = now.timeIntervalSince(startOfDay)
        // Use correct hour row height (68)
        let hourHeight: CGFloat = 68
        let yOffset = CGFloat(seconds / 3600) * hourHeight
        return
            VStack {
                Spacer().frame(height: yOffset)
                HStack(spacing: 0) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                        .shadow(color: .red.opacity(0.5), radius: 3, x: 0, y: 1)
                    Rectangle()
                        .fill(Color.red)
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                        .shadow(color: .red.opacity(0.3), radius: 0.5, x: 0, y: 0)
                }
                .frame(height: 12)
                Spacer()
            }
            .allowsHitTesting(false)
    }
}

private struct TimelineDisplayEvent: Identifiable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let color: Color
}

private struct TimelineHourRow: View {
    let hour: Int
    let date: Date
    let events: [TimelineDisplayEvent]
    private let calendar = Calendar.current
    static let hourRowHeight: CGFloat = 68

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Hour label
            Text(hourLabel(for: hour))
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .frame(width: 48, alignment: .trailing)
                .foregroundColor(.secondary)
                .padding(.trailing, 8)
                .padding(.top, 2)
            ZStack(alignment: .topLeading) {
                // Hour divider line
                Rectangle()
                    .fill(Color.white.opacity(0.13))
                    .frame(height: 1)
                    .offset(y: 0)
            }
            .frame(height: TimelineHourRow.hourRowHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 0)
        .background(Color.clear)
    }

    private func hourLabel(for hour: Int) -> String {
        let f = DateFormatter()
        f.dateFormat = "ha"
        let d = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date)!
        return f.string(from: d).lowercased()
    }
}


// (Old TimelineEventBlock is now unused in liquid glass theme)

private struct WeekModeView: View {
    @Binding var selectedDate: Date
    @Binding var visibleWeekStart: Date
    let phoneEvents: [EKEvent]
    let appEvents: [EventItem]
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var lastSelectedDate: Date = Date()
    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 14) {
            WeekStrip(selectedDate: $selectedDate, weekStart: visibleWeekStart)
            ScrollViewReader { proxy in
                ListForWeekSelectable(weekStart: visibleWeekStart, phoneEvents: phoneEvents, appEvents: appEvents, selectedDate: $selectedDate)
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .scrollIndicators(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .onAppear {
                        scrollProxy = proxy
                        lastSelectedDate = selectedDate
                        // On appear, scroll to selectedDate's day section
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            let idx = calendar.dateComponents([.day], from: visibleWeekStart, to: selectedDate).day ?? 0
                            if idx >= 0 && idx < 7 {
                                proxy.scrollTo("day-\(idx)", anchor: .top)
                            }
                        }
                    }
                    .onChange(of: selectedDate) { newDate in
                        // Scroll to the new selected date's section if it's in this week
                        let idx = calendar.dateComponents([.day], from: visibleWeekStart, to: newDate).day ?? 0
                        if idx >= 0 && idx < 7 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                proxy.scrollTo("day-\(idx)", anchor: .top)
                            }
                        }
                        lastSelectedDate = newDate
                    }
            }
            .scrollIndicators(.hidden)
        }
    }
}

// ListForWeekSelectable: like ListForWeek, but allows selecting a day when a section header is tapped
struct ListForWeekSelectable: View {
    let weekStart: Date
    let phoneEvents: [EKEvent]
    let appEvents: [EventItem]
    @Binding var selectedDate: Date
    private let calendar = Calendar.current

    var body: some View {
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
        return List {
            ForEach(Array(days.enumerated()), id: \.1) { idx, day in
                Section(header:
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .medium); impact.impactOccurred()
                        selectedDate = day
                    }) {
                        HStack {
                            Text(day.formatted(.dateTime.weekday(.wide).day()))
                                .fontWeight(selectedDate.isSameDay(as: day) ? .bold : .regular)
                                .foregroundColor(selectedDate.isSameDay(as: day) ? .black : .white)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(selectedDate.isSameDay(as: day) ? Color.white : Color.clear)
                                )
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                ) {
                    ListForDay(date: day, phoneEvents: phoneEvents, appEvents: appEvents)
                        .listRowInsets(EdgeInsets())
                }
                .listRowBackground(Color.clear)
                .id("day-\(idx)")
            }
        }
        .scrollIndicators(.hidden)
    }
}

private struct MonthModeView: View {
    @Binding var selectedDate: Date
    @Binding var visibleMonthStart: Date
    let phoneEvents: [EKEvent]
    let appEvents: [EventItem]

    var body: some View {
        VStack(spacing: 14) {
            MonthGrid(selectedDate: $selectedDate, visibleMonthStart: $visibleMonthStart, phoneEvents: phoneEvents, appEvents: appEvents)
            ListForDay(date: selectedDate, phoneEvents: phoneEvents, appEvents: appEvents)
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .scrollIndicators(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
    }
}

// MARK: - Week Strip
struct WeekStrip: View {
    @Binding var selectedDate: Date
    var weekStart: Date
    private let calendar = Calendar.current

    var body: some View {
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
        HStack(spacing: 8) {
            ForEach(days, id: \.self) { day in
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium); impact.impactOccurred()
                    selectedDate = day
                } label: {
                    VStack(spacing: 6) {
                        Text(day.formatted(.dateTime.weekday(.narrow)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(day.formatted(.dateTime.day()))
                            .font(.body.weight(.semibold))
                            .frame(width: 36, height: 36)
                            .background(selectedDate.isSameDay(as: day) ? Color.white : Color.white.opacity(0.08))
                            .foregroundColor(selectedDate.isSameDay(as: day) ? .black : .white)
                            .clipShape(Circle())
                    }
                    .padding(6) // Back to original padding
                }
                .buttonStyle(.plain)
            }
        }
        // Removed extra horizontal padding that was causing overflow
    }
}

// MARK: - Event List
struct ListForDay: View {
    let date: Date
    let phoneEvents: [EKEvent]
    let appEvents: [EventItem]
    private let calendar = Calendar.current

    var body: some View {
        let merged = mergedEvents()
        return List {
            if merged.isEmpty {
                Text("No events")
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
                    .padding(.horizontal, 4) // Minimal padding
            } else {
                ForEach(merged, id: \.id) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Circle().fill(item.color).frame(width: 8, height: 8).padding(.top, 6)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title).font(.body)
                            if let time = item.timeText { Text(time).font(.caption).foregroundStyle(.secondary) }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8) // Back to original
                    .padding(.horizontal, 4) // Minimal horizontal padding
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden) // hides all dividers
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func mergedEvents() -> [DisplayEvent] {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        let phone = phoneEvents.filter { $0.startDate < end && $0.endDate > start }
            .map { e in
                DisplayEvent(id: e.eventIdentifier, title: e.title, timeText: timeRange(e.startDate, e.endDate), color: Color(e.calendar.cgColor))
            }
        let local = appEvents.filter { calendar.isDate($0.date, inSameDayAs: date) }
            .map { e in
                DisplayEvent(id: e.id.uuidString, title: e.title, timeText: nil, color: .white)
            }
        return (phone + local).sorted { ($0.timeText ?? "") < ($1.timeText ?? "") }
    }

    private func timeRange(_ s: Date, _ e: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short
        return "\(f.string(from: s)) – \(f.string(from: e))"
    }
}

struct DisplayEvent: Identifiable {
    let id: String
    let title: String
    let timeText: String?
    let color: Color
}

extension Date {
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
}

// MARK: - Week list renderer
struct ListForWeek: View {
    let weekStart: Date
    let phoneEvents: [EKEvent]
    let appEvents: [EventItem]
    private let calendar = Calendar.current

    var body: some View {
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
        return List {
            ForEach(days, id: \.self) { day in
                Section(day.formatted(.dateTime.weekday(.wide).day())) {
                    ListForDay(date: day, phoneEvents: phoneEvents, appEvents: appEvents)
                        .listRowInsets(EdgeInsets())
                }
                .listRowBackground(Color.clear)
            }
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Month Grid
struct MonthGrid: View {
    @Binding var selectedDate: Date
    @Binding var visibleMonthStart: Date
    let phoneEvents: [EKEvent]
    let appEvents: [EventItem]

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        // IMPORTANT: use visibleMonthStart (first of month for the visible month)
        let start = visibleMonthStart
        let range = calendar.range(of: .day, in: .month, for: start) ?? Range(1...30)
        let firstWeekday = calendar.component(.weekday, from: start)
        let eventsByDay = eventsByDayInMonth(start: start)

        VStack(spacing: 10) { // Back to original spacing
            HStack {
                let symbols = calendar.veryShortWeekdaySymbols
                let startIdx = calendar.firstWeekday - 1 // 0-based index of the first weekday for the current locale
                let ordered = Array(symbols[startIdx...] + symbols[..<startIdx])
                ForEach(ordered, id: \.self) { d in
                    Text(d).frame(maxWidth: .infinity).foregroundStyle(.secondary)
                }
            }
            .font(.footnote)
            // Removed extra padding that was causing issues

            LazyVGrid(columns: columns, spacing: 8) { // Back to original spacing
                let daysInMonth = calendar.range(of: .day, in: .month, for: start)?.count ?? 30
                let weekdayOfFirst = calendar.component(.weekday, from: start) - 1 // 0...6 (Sun=0)
                let firstColumn = calendar.firstWeekday - 1 // 0...6, locale-aware first weekday
                let leading = (7 + weekdayOfFirst - firstColumn) % 7

                let totalCells = ((leading + daysInMonth + 6) / 7) * 7 // round up to full weeks (35 or 42)
                let prevMonth = calendar.date(byAdding: .month, value: -1, to: start)!
                let nextMonth = calendar.date(byAdding: .month, value: 1, to: start)!
                let daysInPrev = calendar.range(of: .day, in: .month, for: prevMonth)!.count

                ForEach(0..<totalCells, id: \.self) { idx in
                    let cell: (date: Date, day: Int, inCurrent: Bool) = {
                        if idx < leading {
                            let day = daysInPrev - leading + idx + 1
                            let d = calendar.date(byAdding: .day, value: day - 1, to: prevMonth)!
                            return (d, day, false)
                        } else if idx < leading + daysInMonth {
                            let day = idx - leading + 1
                            let d = calendar.date(byAdding: .day, value: day - 1, to: start)!
                            return (d, day, true)
                        } else {
                            let day = idx - (leading + daysInMonth) + 1
                            let d = calendar.date(byAdding: .day, value: day - 1, to: nextMonth)!
                            return (d, day, false)
                        }
                    }()

                    // Highlight only when this cell is the exact selected date AND the visible month is the selectedDate's month
                    let isSelected = cell.inCurrent &&
                        calendar.isDate(cell.date, inSameDayAs: selectedDate) &&
                        calendar.isDate(start, equalTo: selectedDate, toGranularity: .month)

                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .medium); impact.impactOccurred()
                        selectedDate = cell.date
                        // when user taps a day, ensure visible month shows that day/month (useful for tapping a prev/next-month day)
                        if let newStart = calendar.date(from: calendar.dateComponents([.year, .month], from: cell.date)) {
                            visibleMonthStart = newStart
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text("\(cell.day)")
                                .frame(maxWidth: .infinity)
                                .opacity(cell.inCurrent ? 1 : 0.4)

                            if cell.inCurrent, let count = eventsByDay[calendar.component(.day, from: cell.date)], count > 0 {
                                Capsule().fill(Color.white).frame(width: 12, height: 4)
                            } else {
                                Spacer().frame(height: 4)
                            }
                        }
                        .padding(6) // Back to original
                        .frame(height: 40) // Back to original
                        .background(
                            RoundedRectangle(cornerRadius: 8).fill(
                                isSelected ? Color.white : Color.white.opacity(0.06)
                            )
                        )
                        .foregroundColor(isSelected ? .black : .white)
                    }
                    .buttonStyle(.plain)
                }
            }
            // Removed extra grid padding that was causing overflow
        }
    }

    private func startOfMonth(for date: Date) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: comps) ?? date
    }

    private func eventsByDayInMonth(start: Date) -> [Int: Int] {
        var dict: [Int: Int] = [:]
        let end = calendar.date(byAdding: .month, value: 1, to: start)!
        let phoneInRange = phoneEvents.filter { $0.startDate < end && $0.endDate > start }
        let localInRange = appEvents.filter { $0.date >= start && $0.date < end }
        for e in phoneInRange { let d = calendar.component(.day, from: e.startDate); dict[d, default: 0] += 1 }
        for e in localInRange { let d = calendar.component(.day, from: e.date); dict[d, default: 0] += 1 }
        return dict
    }
}


struct MonthMiniGrid: View {
    @Binding var selectedDate: Date
    let monthStart: Date
    let phoneEvents: [EKEvent]
    let appEvents: [EventItem]
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        let weekdayOfFirst = calendar.component(.weekday, from: monthStart) - 1
        let firstColumn = calendar.firstWeekday - 1
        let leading = (7 + weekdayOfFirst - firstColumn) % 7
        let totalCells = ((leading + daysInMonth + 6) / 7) * 7

        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(0..<totalCells, id: \.self) { idx in
                let cell: (date: Date, day: Int, inCurrent: Bool) = {
                    if idx < leading {
                        let prevMonth = calendar.date(byAdding: .month, value: -1, to: monthStart)!
                        let daysInPrev = calendar.range(of: .day, in: .month, for: prevMonth)!.count
                        let day = daysInPrev - leading + idx + 1
                        let d = calendar.date(byAdding: .day, value: day - 1, to: prevMonth)!
                        return (d, day, false)
                    } else if idx < leading + daysInMonth {
                        let day = idx - leading + 1
                        let d = calendar.date(byAdding: .day, value: day - 1, to: monthStart)!
                        return (d, day, true)
                    } else {
                        let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart)!
                        let day = idx - (leading + daysInMonth) + 1
                        let d = calendar.date(byAdding: .day, value: day - 1, to: nextMonth)!
                        return (d, day, false)
                    }
                }()

                let isSelected = cell.inCurrent && calendar.isDate(cell.date, inSameDayAs: selectedDate)

                if cell.inCurrent {
                    Text("\(cell.day)")
                        .font(.system(size: 10))
                        .frame(maxWidth: .infinity)
                        .padding(2)
                        .background(
                            Circle().fill(isSelected ? Color.white : Color.clear)
                        )
                        .foregroundColor(isSelected ? .black : .white)
                        .onTapGesture {
                            selectedDate = cell.date
                        }
                } else {
                    Text("")
                        .font(.system(size: 10))
                        .frame(maxWidth: .infinity)
                        .padding(2)
                }
            }
        }
    }
}

struct BlurCell: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
            .padding(.vertical, 4)
    }
}

// MARK: - Shared Helpers
fileprivate func startOfWeek(for date: Date) -> Date {
    var iso = Calendar(identifier: .iso8601) // Monday-based weeks
    iso.timeZone = Calendar.current.timeZone
    iso.locale = Calendar.current.locale
    let comps = iso.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
    return iso.date(from: comps) ?? date
}
