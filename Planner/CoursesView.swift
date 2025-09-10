import SwiftUI

struct CoursesView: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        NavigationStack {
            List {
                ForEach(app.coursesInActive()) { c in
                    NavigationLink(value: c) {
                        GlassRow {
                            VStack(alignment: .leading) {
                                Text("\(c.code) – \(c.title)").font(.body)
                                Text(c.instructor).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                    })
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
            .navigationDestination(for: Course.self) { c in
                CourseDetailView(course: c)
            }
            .navigationTitle("Courses")
        }
    }
}

struct CourseDetailView: View {
    @EnvironmentObject var app: AppState
    let course: Course

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GlassRow {
                VStack(alignment: .leading, spacing: 6) {
                    Text(course.title).font(.headline)
                    Text("\(course.code) • \(course.instructor)").font(.footnote).foregroundStyle(.secondary)
                }
            }

            Text("Files").font(.headline).padding(.top, 8)
            if !course.files.isEmpty {
                ForEach(course.files) { f in
                    GlassRow { Text(f.name) }
                        .simultaneousGesture(TapGesture().onEnded {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                        })
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Course")
    }
}
