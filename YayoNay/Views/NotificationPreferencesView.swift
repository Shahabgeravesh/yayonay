import SwiftUI

struct NotificationPreferencesView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var notificationsGeneral: Bool = true
    @State private var notificationsVotes: Bool = true
    @State private var notificationsReminders: Bool = true
    @State private var isLoading = true
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Push Notifications")) {
                    Toggle(isOn: $notificationsGeneral) {
                        Text("General Updates")
                    }
                    .disabled(isLoading)
                    Toggle(isOn: $notificationsVotes) {
                        Text("Votes & Results")
                    }
                    .disabled(isLoading)
                    Toggle(isOn: $notificationsReminders) {
                        Text("Reminders")
                    }
                    .disabled(isLoading)
                }
            }
            .overlay {
                if isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.05))
                }
            }
            .navigationTitle("Notification Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePreferences()
                    }
                    .disabled(isLoading || isSaving)
                }
            }
            .onAppear {
                loadPreferences()
            }
        }
    }
    
    private func loadPreferences() {
        isLoading = true
        Task {
            if let prefs = await userManager.fetchNotificationPreferences() {
                notificationsGeneral = prefs.general
                notificationsVotes = prefs.votes
                notificationsReminders = prefs.reminders
            }
            isLoading = false
        }
    }
    
    private func savePreferences() {
        isSaving = true
        Task {
            await userManager.updateNotificationPreferences(
                general: notificationsGeneral,
                votes: notificationsVotes,
                reminders: notificationsReminders
            )
            isSaving = false
            dismiss()
        }
    }
}

#Preview {
    NotificationPreferencesView().environmentObject(UserManager())
} 