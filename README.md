# 🩺 Vitas: The Specialized Medical Planner (v1.3.7)

<div align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-black?style=for-the-badge&logo=apple" alt="macOS 14.0+" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=for-the-badge&logo=swift" alt="Swift 5.9" />
  <img src="https://img.shields.io/badge/SwiftUI-Native-blue?style=for-the-badge" alt="SwiftUI" />
  <img src="https://img.shields.io/badge/Architecture-SwiftData-purple?style=for-the-badge" alt="SwiftData" />
  <img src="https://img.shields.io/github/v/release/arua-pimenta/planner?style=for-the-badge&color=success" alt="Latest Release" />
</div>

<br/>

> **An elegant, robust, and native macOS application designed from the ground up for the exhaustive workflow of Medical Students.**
> 
> *Built with Glass Design, SwiftData persistence, and intelligent Semester tracking.*

---

## 🌟 Inspired by the Best, Built for the Hardest
This project was deeply inspired by productivity paradigms but adapted, enhanced, and transformed into a specialized tool for the strenuous workflow of Medical School. From dynamic attendance tracking to custom exam types (OSCE, Practical, Seminars).

## 🤝 We Need Your Brains! (Contributions Welcome)
We are fully open to the Open Source community! Whether you are a senior Swift developer or a medical student with killer feature ideas, we want you! 

**How you can help:**
- 🐛 **Bug Hunting:** Find issues and report them.
- 💡 **Feature Requests:** Give us ideas on how to make this the ultimate Med Student companion.
- 💻 **Code Contributions:** Open Pull Requests for new features, iOS/iPadOS adaptations, or UI tweaks!

Check our issues tab to find *"Good First Issues"* and jump right in!

## 🚀 How to Download and Run
Since this app is built entirely natively using **Swift**, **SwiftUI**, and **SwiftData** with the latest Apple technologies, you will need **Xcode 15+** to run it.

1. Clone this repository: `git clone https://github.com/arua-pimenta/planner.git`
2. Open the `Planner.xcodeproj` file in Xcode (macOS).
3. Build and Run (`Cmd + R`).

---

## 📈 Version History & Features (Changelog)

### 🎉 v1.3.7 - The "Glass & Intelligence" Update! (LATEST)
- **Aggressive Xcode Cleanup**: Removed all duplicate compile sources, leading to lightning-fast build times.
- **Syntax Modernization (macOS 14)**: Eradicated strict Swift 5.9 deprecation warnings.
- **Smart Agenda (UX Redesign)**: The Calendar and Event view (`AgendaView`) received a massive **"Glass Dark Mode"** visual overhaul.
- **Semester Sovereignity**: The agenda is now *Reactive*. The monthly view and the daily task list intelligently filter out past/future data, showing ONLY the tasks/exams that belong to the Active Semester chosen in the top Toolbar!
- **Community Addendum (Custom Calendar)**: Replaced the natively small Apple DatePicker with a custom-built, full-window, animated Calendar grid Engine (`CustomCalendarView`) that fills the screen and breathes with the app.


### v1.3.6 - Entities and Preferences Refinement
- **Professors Module**: Added fields for title, phone contacts (Native WhatsApp and iMessage integration), Specialty, and Office location. Also added support for uploading the educator's photo/avatar via the native `PhotosPicker` and injecting it into lists.
- **Holidays Module**: Refactored the model to include "Holiday Types" and visual support for Recurring events that either block or don't block classes. Inserted a Menu Bar action to Auto-Import all National Holidays (fixed and variable) from Paraguay.
- **Settings/AppStorage**: Reconstructed the Options Interface into a three-part `TabView` (General, Institutional, and Backup tabs). Added `@AppStorage` injection for "Dynamic Attendance and Grading Scales".
- **Reverse JSON Compatibility**: The Backup Manager parsing logic was rewritten to ensure backward compatibility when importing older backups.

### v1.3.5 - Advanced Attendance Module (Hourly Based)
- Built for colleges that require counting attendance in "Class Hours". The individual attendance registry now stores a "weight" of how many hours the student missed, rather than a passive (x1) count.
- The Attendance List computes the discipline's margin and visually fills the limit. 
- A Dashboard Widget scans all disciplines in the *Active Semester* and displays dynamic alerts ("Warning: Attendance - Risk") if the total absences reach 75% or more of the allowed threshold for failure. 100% compartmentalized to the currently selected Semester.

### v1.3.4 - Special Events Panel (Tasks and Exams)
- `Exam` model now hosts a formal `ExamType` property: `Theoretical (Multiple Choice)`, `Practical (Lab)`, `OSCE`, `Seminar`, and `Written Paper`.
- The `ExamRow` interface automatically adopts specific iconography based on the type (e.g., Stethoscope for OSCE).
- The main screens for Tasks and Exams (Pending/Completed) and the Agenda (Monthly Calendar) are purely filtered based on the Sovereign `Semester` allocated in the Toolbar.

### v1.3.3 - Master Semester System
- **Batch Generation**: A vital innovation. The user inputs "My medical course is 6 years long", and the app automatically injects all 12 semesters.
- **Sovereign Global Selector**: A Dropdown in the navigation Toolbar lets the user inject an Active Semester into the local environment via lightweight `@AppStorage`.
- The heart of MedPlanner — the Dashboard (`PainelView`) — was remade using filtered Computed Properties so that *ALL* queries react solely to that semester's data.

### v1.3.2 - Physical Directory Configuration
- System where the user selects a centralized repository via `NSOpenPanel` for heavy attachments outside the App Container, saved with persistence for iCloud file saving.

### v1.3.1 - SwiftUI and SwiftData Relationship
- An advanced ecosystem linking `Discipline` with `Semesters` based on a `Cascade` hierarchy.

### v1.3 - Dynamic Dashboards via Swift Charts
- **General Panel (Dashboard)**: Replaced massive plain text lists of Tasks with a Donut Chart listing the exact proportion of Pending vs. Completed tasks, automatically generating the bottom legend.
- **Analytical Report Card**: Built on top of grades to assemble a dynamic Y-scale Bar chart. Grades are colored according to approval status and rest against a constant dotted line on the *7.0* Average axis, visually demonstrating performance.

### v1.2 - Ecosystem and Persistence
- **Local Backup System (JSON)**: Asynchronous JSON export mapping all SwiftData subclasses and extracting their UUIDs via shielded DTOs, generating the file using native Mac save panels protecting complex relational integrity.
- **Menu Bar Micro-App (`MenuBarExtra`)**: A visual helper residing in the system's top bar that natively injects unresolved `Tasks` from the `ModelContainer` for instant access.

### v1.1 - System Refinements
- **Integrated Global Search (`⌘F`)**: Dynamic `.searchable` implementation connected to major lists.
- **Flow Micro-Shortcuts (`⌘1` to `⌘9`)**: Interconnection of Enums and SwiftUI KeyboardShortcuts in the sidebar.
- **Glass Design Multi-Theme (`Dark/Light`)**: Reactive conversion of translucent borders that adapt perfectly to the OS window scheme. `.ultraThickMaterial` and `.ultraThinMaterial` switch natively for readability.

### v1.0 - Core Release
- **Central Dashboard (`PainelView`)**: Widgets counting critical absences, daily classes, upcoming tasks, and global weighted average.
- **Professores and Feriados Entitites**: Integrated globally into disciplines and calendars.
- **System PDF Export**: Dynamic system (`ImageRenderer`) that transforms hidden views into A4 PDFs to export the user's Academic Report Card natively.

### MVP v0.3 - Study Notebook and Absences
- `Absence` model tied to `Discipline` with global thresholds.
- **Markdown Notebook**: Left-list navigation with right-side `TextEditor` featuring native Markdown rendering and reactive saving.
- **Report Card Module**: `Evaluation` model with customizable decimal weights, and global automatic average calculation.

### MVP v0.2 - Routine and Calendar Management
- **Tasks and Exams**: Tabbed visual with Segmented Control for Pending/Completed Tasks and Exams.
- **Agenda / Calendar**: Multi-column layout with a clickable `DatePicker` graph and chronological event lists.
- **Notification Manager**: Customized system that warns the user 1 Hour before a Task expires and the night before any registered Exam using native `UNUserNotificationCenter` on macOS.

---
*Built with ❤️ for those who spend their lives studying human health.*
