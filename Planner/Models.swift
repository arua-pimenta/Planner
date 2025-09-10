import Foundation

struct Semester: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var name: String
    var startDate: Date
    var endDate: Date
}

struct Course: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var semesterId: UUID
    var code: String
    var title: String
    var instructor: String
    var files: [CourseFile] = []
}

struct CourseFile: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var name: String
    var note: String?
    // Later: add local URL / iCloud URL
}

struct EventItem: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var semesterId: UUID
    var title: String
    var date: Date
    var isDeadline: Bool
    var notes: String?
}

struct TaskItem: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var semesterId: UUID
    var title: String
    var done: Bool = false
    var due: Date?
    var notes: String?
}

struct TimetableSlot: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var semesterId: UUID
    var courseId: UUID
    var weekday: Int       // 1=Sun ... 7=Sat (Calendar.current)
    var startMinutes: Int  // minutes from 00:00
    var endMinutes: Int
}
