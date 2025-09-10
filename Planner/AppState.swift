import SwiftUI

final class AppState: ObservableObject {
    @Published var semesters: [Semester] = []
    @Published var courses: [Course] = []
    @Published var events: [EventItem] = []
    @Published var tasks: [TaskItem] = []
    @Published var timetable: [TimetableSlot] = []

    @Published var activeSemesterId: UUID? = nil
    @Published var isSidePanelOpen: Bool = false
    @Published var showAddSheet: Bool = false
    @Published var addSheetKind: AddKind = .quick

    enum AddKind { case quick, event, task, course, file }

    private let store = SimpleStore()

    init() {
        load()
        if semesters.isEmpty {
        }
    }

    // MARK: - Persistence (simple JSON in UserDefaults)
    func load() {
        if let snapshot: Snapshot = store.load(key: "snapshot") {
            semesters = snapshot.semesters
            courses = snapshot.courses
            events = snapshot.events
            tasks = snapshot.tasks
            timetable = snapshot.timetable
            activeSemesterId = snapshot.activeSemesterId ?? semesters.first?.id
        }
    }

    func save() {
        let snap = Snapshot(semesters: semesters,
                            courses: courses,
                            events: events,
                            tasks: tasks,
                            timetable: timetable,
                            activeSemesterId: activeSemesterId)
        store.save(snap, key: "snapshot")
    }

    struct Snapshot: Codable {
        var semesters: [Semester]
        var courses: [Course]
        var events: [EventItem]
        var tasks: [TaskItem]
        var timetable: [TimetableSlot]
        var activeSemesterId: UUID?
    }

    // MARK: - Delete Methods
    func deleteAllData() {
        semesters.removeAll()
        courses.removeAll()
        events.removeAll()
        tasks.removeAll()
        timetable.removeAll()
        activeSemesterId = nil
        save()
    }
    
    func deleteAllEvents() {
        events.removeAll()
        save()
    }
    
    func deleteAllTasks() {
        tasks.removeAll()
        save()
    }
    
    func deleteAllCourses() {
        courses.removeAll()
        timetable.removeAll() // Also delete timetable slots since they reference courses
        save()
    }
    
    func deleteAllTimetable() {
        timetable.removeAll()
        save()
    }
    
    func deleteActiveSemesterData() {
        guard let activeId = activeSemesterId else { return }
        events.removeAll { $0.semesterId == activeId }
        tasks.removeAll { $0.semesterId == activeId }
        courses.removeAll { $0.semesterId == activeId }
        timetable.removeAll { $0.semesterId == activeId }
        save()
    }

    // Helpers
    func activeSemester() -> Semester? { semesters.first(where: { $0.id == activeSemesterId }) }
    func coursesInActive() -> [Course] { courses.filter { $0.semesterId == activeSemesterId } }
    func tasksInActive() -> [TaskItem] { tasks.filter { $0.semesterId == activeSemesterId } }
    func eventsInActive() -> [EventItem] { events.filter { $0.semesterId == activeSemesterId } }
    func timetableInActive() -> [TimetableSlot] { timetable.filter { $0.semesterId == activeSemesterId } }
}

// Tiny JSON store
final class SimpleStore {
    func save<T: Codable>(_ value: T, key: String) {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        if let data = try? enc.encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    func load<T: Codable>(key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return try? dec.decode(T.self, from: data)
    }
}
