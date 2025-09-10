import SwiftUI
import Foundation

// MARK: - Helpers to stash extra fields inside existing models safely
fileprivate struct CourseMeta: Codable {
    var slot: String?
    var classNumber: String?
    var venue: String?
}

fileprivate struct EventExtra: Codable {
    var tag: String
    var courseId: UUID?
    var progress: Int?
}

fileprivate struct TaskExtra: Codable {
    var courseId: UUID?
    var subtext: String?
}

fileprivate func encodeJSON<T: Encodable>(_ value: T) -> String? {
    let encoder = JSONEncoder()
    if let data = try? encoder.encode(value) { return String(data: data, encoding: .utf8) }
    return nil
}

fileprivate func decodeCourseMeta(from course: Course) -> CourseMeta? {
    if let meta = course.files.first(where: { $0.name == "_meta" }), let note = meta.note, let data = note.data(using: .utf8) {
        return try? JSONDecoder().decode(CourseMeta.self, from: data)
    }
    return nil
}

fileprivate func tagColor(_ tag: String) -> Color {
    switch tag.lowercased() {
    case "personal": return .gray
    case "class test": return .orange
    case "exam": return .red
    case "project": return .blue
    case "homework": return .teal
    case "assignment": return .purple
    case "holiday": return .green
    default: return .gray
    }
}

// MARK: - Root
struct AddSheet: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        switch app.addSheetKind {
        case .quick:
            QuickAddForm()
        case .event:
            AddEventForm()
        case .task:
            AddTaskForm()
        case .course:
            AddCourseForm()
        case .file:
            AddClassForm()
        default:
            EmptyView()
        }
    }
}

// MARK: - Shared Header
struct AddHeader: View {
    @EnvironmentObject var app: AppState
    let title: String

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Button(action: { app.addSheetKind = .quick }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.white)
                }
                Spacer()
                Text(title)
                    .foregroundColor(.white)
                    .font(.headline)
                Spacer()
            }
            Divider().background(Color.white.opacity(0.2))
        }
        .padding(.horizontal)
        .padding(.top)
        .background(Color.black)
    }
}


// MARK: - Quick Add
struct QuickAddForm: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Add New Item")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.top)
            VStack(spacing: 12) {
                QuickAddButton(title: "Event", icon: "calendar", action: { app.addSheetKind = .event })
                QuickAddButton(title: "Task", icon: "checkmark.circle", action: { app.addSheetKind = .task })
                QuickAddButton(title: "Course", icon: "books.vertical", action: { app.addSheetKind = .course })
                QuickAddButton(title: "Class Block", icon: "clock", action: { app.addSheetKind = .file })
            }
            .padding(.horizontal)
            Spacer()
            Button("Close") { dismiss() }
                .foregroundColor(.white)
                .padding(.bottom)
        }
        .background(Color.black.ignoresSafeArea())
    }
}

struct QuickAddButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon).foregroundColor(.white).frame(width: 24)
                Text(title).foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.gray).font(.caption)
            }
            .padding()
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Course (with slot/class/venue saved in files meta)
struct AddCourseForm: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) var dismiss
    @State private var code = ""
    @State private var title = ""
    @State private var professor = ""
    @State private var slot = ""
    @State private var classNumber = ""
    @State private var venue = ""

    var body: some View {
        VStack(spacing: 0) {
            AddHeader(title: "Add Course")
            ScrollView {
                VStack(spacing: 16) {
                    BWField("Course Title", text: $title)
                    BWField("Course Code", text: $code)
                    BWField("Professor", text: $professor)
                    BWField("Slot", text: $slot)
                    BWField("Class Number", text: $classNumber)
                    BWField("Venue", text: $venue)
                    Button("Save Course") {
                        var new = Course(
                            semesterId: app.activeSemesterId ?? UUID(),
                            code: code,
                            title: title,
                            instructor: professor,
                            files: []
                        )
                        // attach meta as a hidden CourseFile so we don't change your model
                        let meta = CourseMeta(slot: slot.isEmpty ? nil : slot,
                                              classNumber: classNumber.isEmpty ? nil : classNumber,
                                              venue: venue.isEmpty ? nil : venue)
                        if let json = encodeJSON(meta) {
                            var file = CourseFile(name: "_meta", note: json)
                            new.files.append(file)
                        }
                        app.courses.append(new)
                        app.save()
                        dismiss()
                    }
                    .buttonStyle(BWPrimaryButtonStyle(enabled: !code.isEmpty && !title.isEmpty))
                    .disabled(code.isEmpty || title.isEmpty)
                }
                .padding()
            }
            .background(Color.black)
        }
    }
}

// MARK: - Class Block (shows professor & venue from course meta)
struct AddClassForm: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) var dismiss
    @State private var selectedCourseIndex = 0
    @State private var day = 1
    @State private var start = Date()
    @State private var end = Date()

    var body: some View {
        VStack(spacing: 0) {
            AddHeader(title: "Add Class Block")
            ScrollView {
                VStack(spacing: 16) {
                    if app.coursesInActive().isEmpty {
                        Text("No courses available. Add a course first.")
                            .foregroundColor(.white)
                    } else {
                        Picker("Course", selection: $selectedCourseIndex) {
                            ForEach(Array(app.coursesInActive().enumerated()), id: \.offset) { idx, course in
                                let meta = decodeCourseMeta(from: course)
                                let venueText = meta?.venue ?? "—"
                                Text("\(course.code) • \(course.instructor) • \(venueText)").tag(idx)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundColor(.white)

                        Picker("Day", selection: $day) {
                            ForEach(1...7, id: \.self) { i in
                                Text(Calendar.current.weekdaySymbols[i-1]).tag(i)
                            }
                        }
                        .pickerStyle(.segmented)
                        .foregroundColor(.white)

                        DatePicker("Start Time", selection: $start, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .foregroundColor(.white)
                        DatePicker("End Time", selection: $end, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .foregroundColor(.white)

                        Button("Save Class Block") {
                            let cal = Calendar.current
                            let startMinutes = cal.component(.hour, from: start) * 60 + cal.component(.minute, from: start)
                            let endMinutes = cal.component(.hour, from: end) * 60 + cal.component(.minute, from: end)
                            let selectedCourseId = app.coursesInActive()[selectedCourseIndex].id
                            let new = TimetableSlot(
                                semesterId: app.activeSemesterId ?? UUID(),
                                courseId: selectedCourseId,
                                weekday: day,
                                startMinutes: startMinutes,
                                endMinutes: endMinutes
                            )
                            app.timetable.append(new)
                            app.save()
                            dismiss()
                        }
                        .buttonStyle(BWPrimaryButtonStyle())
                    }
                }
                .padding()
            }
            .background(Color.black)
        }
    }
}

// MARK: - Calendar Event (tags, progress, course link stored in notes)
struct AddEventForm: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var date = Date()
    @State private var selectedTag = "Personal"
    @State private var progress: Double = 0
    @State private var selectedCourseIndex = 0

    private let tags = ["Personal", "Class Test", "Exam", "Project", "Homework", "Assignment", "Holiday"]

    var body: some View {
        VStack(spacing: 0) {
            AddHeader(title: "Add Event")
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    BWField("Event Title", text: $title)

                    DatePicker("Date", selection: $date)
                        .labelsHidden()
                        .foregroundColor(.white)

                    // Tag chips (color coded)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tag").foregroundColor(.white)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    Button(action: { selectedTag = tag }) {
                                        Text(tag)
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(tagColor(tag).opacity(selectedTag == tag ? 0.9 : 0.35), in: Capsule())
                                            .overlay(
                                                Capsule().stroke(Color.white.opacity(selectedTag == tag ? 0.9 : 0.2), lineWidth: 1)
                                            )
                                            .foregroundColor(.white)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    if !app.coursesInActive().isEmpty {
                        Picker("Course", selection: $selectedCourseIndex) {
                            ForEach(Array(app.coursesInActive().enumerated()), id: \.offset) { idx, c in
                                Text(c.title).tag(idx)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundColor(.white)
                    }

                    if ["Project", "Homework", "Assignment"].contains(selectedTag) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Progress: \(Int(progress))%")
                                .foregroundColor(.white)
                            Slider(value: $progress, in: 0...100, step: 1)
                        }
                    }

                    Button("Save Event") {
                        let courseId = app.coursesInActive().isEmpty ? nil : Optional(app.coursesInActive()[selectedCourseIndex].id)
                        let extra = EventExtra(tag: selectedTag, courseId: courseId, progress: ["Project", "Homework", "Assignment"].contains(selectedTag) ? Int(progress) : nil)
                        let notes = encodeJSON(extra)
                        let new = EventItem(
                            semesterId: app.activeSemesterId ?? UUID(),
                            title: title,
                            date: date,
                            isDeadline: false,
                            notes: notes
                        )
                        app.events.append(new)
                        app.save()
                        dismiss()
                    }
                    .buttonStyle(BWPrimaryButtonStyle(enabled: !title.isEmpty))
                    .disabled(title.isEmpty)
                }
                .padding()
            }
            .background(Color.black)
        }
    }
}

// MARK: - ToDo (title, course link, subtext; stored in notes)
struct AddTaskForm: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var subtext = ""
    @State private var selectedCourseIndex = 0

    var body: some View {
        VStack(spacing: 0) {
            AddHeader(title: "Add To-Do")
            ScrollView {
                VStack(spacing: 16) {
                    BWField("Task Title", text: $title)
                    BWField("Subtext", text: $subtext)

                    if !app.coursesInActive().isEmpty {
                        Picker("Course", selection: $selectedCourseIndex) {
                            ForEach(Array(app.coursesInActive().enumerated()), id: \.offset) { idx, c in
                                Text(c.title).tag(idx)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundColor(.white)
                    }

                    Button("Save To-Do") {
                        let courseId = app.coursesInActive().isEmpty ? nil : Optional(app.coursesInActive()[selectedCourseIndex].id)
                        let extra = TaskExtra(courseId: courseId, subtext: subtext.isEmpty ? nil : subtext)
                        let notes = encodeJSON(extra)
                        let new = TaskItem(
                            semesterId: app.activeSemesterId ?? UUID(),
                            title: title,
                            done: false,
                            due: nil,
                            notes: notes
                        )
                        app.tasks.append(new)
                        app.save()
                        dismiss()
                    }
                    .buttonStyle(BWPrimaryButtonStyle(enabled: !title.isEmpty))
                    .disabled(title.isEmpty)
                }
                .padding()
            }
            .background(Color.black)
        }
    }
}

// MARK: - Reusable UI bits
struct BWField: View {
    let placeholder: String
    @Binding var text: String
    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }
    var body: some View {
        TextField(placeholder, text: $text)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct BWPrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background((enabled ? Color.white : Color.white.opacity(0.3)).opacity(configuration.isPressed ? 0.7 : 1.0), in: RoundedRectangle(cornerRadius: 12))
            .foregroundColor(.black)
    }
}
