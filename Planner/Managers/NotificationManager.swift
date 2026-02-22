import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized: Bool = false
    
    private init() {
        checkAuthorization()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
            if let error = error {
                print("Erro ao solicitar permissão de notificações: \(error.localizedDescription)")
            }
        }
    }
    
    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func scheduleTaskReminder(for tarefaId: UUID, title: String, date: Date) {
        // Remove alertas antigos caso exista
        cancelNotification(for: tarefaId.uuidString)
        
        // Alerta 1 hora antes (se estiver no futuro)
        let alertDate = date.addingTimeInterval(-3600)
        guard alertDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Lembrete de Tarefa"
        content.body = "\(title) expira em 1 hora!"
        content.sound = UNNotificationSound.default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alertDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: tarefaId.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erro ao agendar notificação: \(error)")
            }
        }
    }
    
    func scheduleExamReminder(for provaId: UUID, title: String, date: Date) {
        cancelNotification(for: provaId.uuidString)
        
        // Alerta na noite anterior (20h)
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        guard let diaAnterior = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.date(from: components)!) else { return }
        
        var alertComponents = Calendar.current.dateComponents([.year, .month, .day], from: diaAnterior)
        alertComponents.hour = 20
        alertComponents.minute = 0
        
        guard let alertDate = Calendar.current.date(from: alertComponents), alertDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Prova Amanhã!"
        content.body = "Você tem prova de \(title) amanhã. Revise o conteúdo!"
        content.sound = UNNotificationSound.default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: alertComponents, repeats: false)
        let request = UNNotificationRequest(identifier: provaId.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelNotification(for identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
