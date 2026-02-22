# 📈 Vitas (MedPlanner) - Histórico de Versões e Lançamentos (Changelog)

Este documento registra toda a linha do tempo de evolução do aplicativo, desde a nossa versão base (um repositório open-source inicial) até a última grande funcionalidade desenvolvida. 
> *Você pode copiar o conteúdo de cada versão abaixo para postar oficialmente na aba de **Releases** do GitHub!*

---

### 🎉 v1.3.7 - The "Glass & Intelligence" Update! (LATEST)
- **Aggressive Xcode Cleanup**: Removed all duplicate compile sources, leading to lightning-fast build times.
- **Syntax Modernization**: Eradicated strict macOS 14 deprecation warnings.
- **Smart Agenda (UX Redesign)**: The Calendar and Event view (`AgendaView`) received a massive **"Glass Dark Mode"** visual overhaul.
- **Semester Sovereignity**: The agenda is now *Reactive*. The monthly view and the daily task list intelligently filter out past/future data, showing ONLY the tasks/exams that belong to the Active Semester chosen in the top Toolbar!
- **Community Addendum (Custom Calendar)**: Replaced the natively small Apple DatePicker with a custom-built, full-window, animated Calendar grid Engine (`CustomCalendarView`) that fills the screen and breathes with the app.

---

### v1.3.6 - Entities and Preferences Refinement
- **Professors Module**: Added fields for title, phone contacts (Native WhatsApp and iMessage integration), Specialty, and Office location. Also added support for uploading the educator's photo/avatar via the native `PhotosPicker` and injecting it into lists.
- **Holidays Module**: Refactored the model to include "Holiday Types" and visual support for Recurring events that either block or don't block classes. Inserted a Menu Bar action to Auto-Import all National Holidays (fixed and variable) from Paraguay.
- **Settings/AppStorage**: Reconstructed the Options Interface into a three-part `TabView` (General, Institutional, and Backup tabs). Added `@AppStorage` injection for "Dynamic Attendance and Grading Scales".
- **Reverse JSON Compatibility**: The Backup Manager parsing logic was rewritten to ensure backward compatibility when importing older backups.

---

### v1.3.5 - Advanced Attendance Module (Hourly Based)
- Built for colleges that require counting attendance in "Class Hours". The individual attendance registry now stores a "weight" of how many hours the student missed, rather than a passive (x1) count.
- The Attendance List computes the discipline's margin and visually fills the limit. 
- A Dashboard Widget scans all disciplines in the *Active Semester* and displays dynamic alerts ("Warning: Attendance - Risk") if the total absences reach 75% or more of the allowed threshold for failure. 100% compartmentalized to the currently selected Semester.

---

### v1.3.4 - Special Events Panel (Tasks and Exams)
- `Exam` model now hosts a formal `ExamType` property: `Theoretical (Multiple Choice)`, `Practical (Lab)`, `OSCE`, `Seminar`, and `Written Paper`.
- The `ExamRow` interface automatically adopts specific iconography based on the type (e.g., Stethoscope for OSCE).
- The main screens for Tasks and Exams (Pending/Completed) and the Agenda (Monthly Calendar) are purely filtered based on the Sovereign `Semester` allocated in the Toolbar.

---

### v1.3.3 - Master Semester System
- **Batch Generation**: A vital innovation. The user inputs "My medical course is 6 years long", and the app automatically injects all 12 semesters.
- **Sovereign Global Selector**: A Dropdown in the navigation Toolbar lets the user inject an Active Semester into the local environment via lightweight `@AppStorage`.
- The heart of MedPlanner — the Dashboard (`PainelView`) — was remade using filtered Computed Properties so that *ALL* queries react solely to that semester's data.

---

### v1.3.2 - Physical Directory Configuration
- System where the user selects a centralized repository via `NSOpenPanel` for heavy attachments outside the App Container, saved with persistence for iCloud file saving.

---

### v1.3.1 - SwiftUI and SwiftData Relationship
- An advanced ecosystem linking `Discipline` with `Semesters` based on a `Cascade` hierarchy.

---

### v1.3 - Dynamic Dashboards via Swift Charts
- **General Panel (Dashboard)**: Replaced massive plain text lists of Tasks with a Donut Chart listing the exact proportion of Pending vs. Completed tasks, automatically generating the bottom legend.
- **Analytical Report Card**: Built on top of grades to assemble a dynamic Y-scale Bar chart. Grades are colored according to approval status and rest against a constant dotted line on the *7.0* Average axis, visually demonstrating performance.

---

### v1.2 - Ecosystem and Persistence
- **Local Backup System (JSON)**: Asynchronous JSON export mapping all SwiftData subclasses and extracting their UUIDs via shielded DTOs, generating the file using native Mac save panels protecting complex relational integrity.
- **Menu Bar Micro-App (`MenuBarExtra`)**: A visual helper residing in the system's top bar that natively injects unresolved `Tasks` from the `ModelContainer` for instant access.

---

### v1.1 - System Refinements
- **Integrated Global Search (`⌘F`)**: Dynamic `.searchable` implementation connected to major lists.
- **Flow Micro-Shortcuts (`⌘1` to `⌘9`)**: Interconnection of Enums and SwiftUI KeyboardShortcuts in the sidebar.
- **Glass Design Multi-Theme (`Dark/Light`)**: Reactive conversion of translucent borders that adapt perfectly to the OS window scheme. `.ultraThickMaterial` and `.ultraThinMaterial` switch natively for readability.

---

### v1.0 - Core Release
- **Central Dashboard (`PainelView`)**: Widgets counting critical absences, daily classes, upcoming tasks, and global weighted average.
- **Professores and Feriados Entitites**: Integrated globally into disciplines and calendars.
- **System PDF Export**: Dynamic system (`ImageRenderer`) that transforms hidden views into A4 PDFs to export the user's Academic Report Card natively.

---

### MVP v0.3 - Study Notebook and Absences
- `Absence` model tied to `Discipline` with global thresholds.
- **Markdown Notebook**: Left-list navigation with right-side `TextEditor` featuring native Markdown rendering and reactive saving.
- **Report Card Module**: `Evaluation` model with customizable decimal weights, and global automatic average calculation.

---

### MVP v0.2 - Routine and Calendar Management
- **Tasks and Exams**: Tabbed visual with Segmented Control for Pending/Completed Tasks and Exams.
- **Agenda / Calendar**: Multi-column layout with a clickable `DatePicker` graph and chronological event lists.
- **Notification Manager**: Customized system that warns the user 1 Hour before a Task expires and the night before any registered Exam using native `UNUserNotificationCenter` on macOS.

---

### MVP v0.1 - A Fundação Original (Base Planner)
- **Semente do Projeto**: O código inicial foi base do repositório *Planner* open-source, servindo como nossa viga de apoio técnica.
- **Trabalho do Zero**: A partir dessa base sólida, passamos semanas re-escrevendo toda a arquitetura focando nas necessidades diárias, cansativas e complexas do workflow de um Estudante de Medicina (MedPlanner). Nós moldamos o design e injetamos dezenas de Models extras (Anotações, Professores, Feriados) que não constavam no App original. Tudo partiu dessa semente 🌟!
