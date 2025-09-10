import SwiftUI

struct ContentView: View {
    @EnvironmentObject var app: AppState
    @State private var selectedTab: Tab = .timetable
    @State private var moveFromEdge: Edge = .trailing
    @State private var previousTab: Tab = .timetable

    enum Tab: Int, Hashable { case timetable = 0, calendar, todo, courses, add }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            ZStack {
                if selectedTab == .timetable {
                    TimetableView()
                        .transition(transitionForCurrentTab())
                }
                if selectedTab == .calendar {
                    CalendarView()
                        .transition(transitionForCurrentTab())
                }
                if selectedTab == .courses {
                    CoursesView()
                        .transition(transitionForCurrentTab())
                }
                if selectedTab == .todo {
                    TodoView()
                        .transition(transitionForCurrentTab())
                }
                if selectedTab == .add {
                    Color.clear
                }
            }

            // Custom bottom navigator (image 3 style)
            HStack(spacing: 28) {
                Button { switchTab(.timetable) } label: {
                    Image(systemName: "clock")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(selectedTab == .timetable ? .white : .gray)
                }

                Button { switchTab(.calendar) } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(selectedTab == .calendar ? .white : .gray)
                }

                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle().stroke(Color.black, lineWidth: 4)
                        )
                        .offset(y: -12)
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        app.showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .offset(y: -12)
                }

                Button { switchTab(.todo) } label: {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(selectedTab == .todo ? .white : .gray)
                }

                Button { switchTab(.courses) } label: {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(selectedTab == .courses ? .white : .gray)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 16)
            .frame(height: 72)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
            .shadow(color: .black.opacity(0.6), radius: 12, x: 0, y: -2)
        }
        .sheet(isPresented: $app.showAddSheet) {
            AddSheet()
                .presentationDetents([.medium, .large])
                .presentationBackground(.ultraThinMaterial)
        }
    }
    
    private func switchTab(_ tab: Tab) {
        guard tab != selectedTab else { return }
        if tab != .add {
            moveFromEdge = tab.rawValue > selectedTab.rawValue ? .trailing : .leading
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85, blendDuration: 0.15)) {
            selectedTab = tab
        }
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    private func transitionForCurrentTab() -> AnyTransition {
        .asymmetric(
            insertion: .move(edge: moveFromEdge).combined(with: .opacity),
            removal: .move(edge: moveFromEdge == .leading ? .trailing : .leading).combined(with: .opacity)
        )
    }
}
