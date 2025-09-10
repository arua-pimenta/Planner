import SwiftUI

struct SidePanel: View {
    @EnvironmentObject var app: AppState
    @State private var newSemesterName: String = ""
    @State private var showDeleteOptions = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        Image(systemName: "graduationcap.fill")
                            .font(.title2)
                        Text("Semesters")
                            .font(.title3.weight(.semibold))
                    }
                    .padding(.top, 12)

                    // Active + list
                    if let active = app.activeSemester() {
                        Text("Active: \(active.name)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(app.semesters) { s in
                                Button {
                                    app.activeSemesterId = s.id
                                    app.save()
                                    withAnimation { app.isSidePanelOpen = false }
                                } label: {
                                    HStack {
                                        Text(s.name)
                                        if s.id == app.activeSemesterId {
                                            Image(systemName: "checkmark")
                                        }
                                        Spacer()
                                    }
                                    .padding(10)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                        .padding(.top, 8)
                    }

                    // Add semester
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Semester").font(.footnote).foregroundStyle(.secondary)
                        HStack {
                            TextField("e.g. Semester 2", text: $newSemesterName)
                                .textFieldStyle(.plain)
                                .padding(10)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                            Button {
                                guard !newSemesterName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                                let s = Semester(name: newSemesterName, startDate: Date(), endDate: Date().addingTimeInterval(120*24*3600))
                                app.semesters.append(s)
                                app.activeSemesterId = s.id
                                newSemesterName = ""
                                app.save()
                            } label: {
                                Image(systemName: "plus")
                                    .padding(10)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }

                    Spacer()

                    // Bottom: account + settings
                    VStack(spacing: 8) {
                        Divider().opacity(0.2)
                        HStack {
                            Image(systemName: "person.crop.circle")
                            Text("Account")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding(10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))

                        Button {
                            showDeleteOptions = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                Text("Delete Data")
                                    .foregroundColor(.red)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding(10)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(.bottom, 24)

                }
                .padding(16)
                .frame(maxWidth: 320)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

                Spacer()
            }

            // top-right settings icon inside panel (as requested)
            Button {
                showDeleteOptions = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.headline)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding(.top, 10)
            .padding(.trailing, 10)
        }
        .sheet(isPresented: $showDeleteOptions) {
            DeleteOptionsView()
                .presentationDetents([.medium, .large])
                .presentationBackground(.ultraThinMaterial)
        }
    }
}

struct DeleteOptionsView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteAllConfirmation = false
    @State private var showDeleteActiveConfirmation = false
    @State private var deleteType: DeleteType = .all

    enum DeleteType {
        case all, events, tasks, courses, timetable, active
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Delete Data")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top)
            
            VStack(spacing: 12) {
                DeleteButton(title: "Delete All Data", icon: "trash.fill", color: .red) {
                    deleteType = .all
                    showDeleteAllConfirmation = true
                }
                
                if app.activeSemester() != nil {
                    DeleteButton(title: "Delete Active Semester Data", icon: "calendar.badge.minus", color: .orange) {
                        deleteType = .active
                        showDeleteActiveConfirmation = true
                    }
                }
                
                DeleteButton(title: "Delete All Events", icon: "calendar", color: .blue) {
                    deleteType = .events
                    showDeleteAllConfirmation = true
                }
                
                DeleteButton(title: "Delete All Tasks", icon: "checkmark.circle", color: .green) {
                    deleteType = .tasks
                    showDeleteAllConfirmation = true
                }
                
                DeleteButton(title: "Delete All Courses", icon: "books.vertical", color: .purple) {
                    deleteType = .courses
                    showDeleteAllConfirmation = true
                }
                
                DeleteButton(title: "Delete All Timetable", icon: "clock", color: .indigo) {
                    deleteType = .timetable
                    showDeleteAllConfirmation = true
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button("Cancel") {
                dismiss()
            }
            .padding(.bottom)
        }
        .background(Color.black.ignoresSafeArea())
        .alert("Confirm Delete", isPresented: $showDeleteAllConfirmation) {
            Button("Delete", role: .destructive) {
                performDelete()
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(deleteMessage)
        }
        .alert("Confirm Delete", isPresented: $showDeleteActiveConfirmation) {
            Button("Delete", role: .destructive) {
                app.deleteActiveSemesterData()
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will delete all events, tasks, courses, and timetable slots for the active semester. This action cannot be undone.")
        }
    }
    
    private var deleteMessage: String {
        switch deleteType {
        case .all:
            return "This will delete ALL data including semesters, courses, events, tasks, and timetable. This action cannot be undone."
        case .events:
            return "This will delete all events. This action cannot be undone."
        case .tasks:
            return "This will delete all tasks. This action cannot be undone."
        case .courses:
            return "This will delete all courses and their associated timetable slots. This action cannot be undone."
        case .timetable:
            return "This will delete all timetable slots. This action cannot be undone."
        case .active:
            return "This will delete all data for the active semester. This action cannot be undone."
        }
    }
    
    private func performDelete() {
        switch deleteType {
        case .all:
            app.deleteAllData()
        case .events:
            app.deleteAllEvents()
        case .tasks:
            app.deleteAllTasks()
        case .courses:
            app.deleteAllCourses()
        case .timetable:
            app.deleteAllTimetable()
        case .active:
            app.deleteActiveSemesterData()
        }
    }
}

struct DeleteButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)
                Text(title)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
