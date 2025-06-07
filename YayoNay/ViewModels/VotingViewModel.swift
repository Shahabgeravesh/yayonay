import Foundation
import FirebaseAuth
import SwiftUI

@MainActor
class VotingViewModel: ObservableObject {
    @Published var topics: [Topic] = []
    @Published var votes: [Vote] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkManager = NetworkManager.shared
    private let mysqlManager = MySQLManager.shared
    private let authManager = AuthManager.shared
    
    init() {
        loadTopics()
    }
    
    func loadTopics() {
        Task {
            do {
                let topics = try await networkManager.getTopics(categoryId: nil)
                self.topics = topics
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func loadVotes(categoryId: String, subCategoryId: String) async {
        await MainActor.run { isLoading = true }
        
        do {
            let loadedVotes = try await mysqlManager.getVotes(categoryId: categoryId, subCategoryId: subCategoryId)
            await MainActor.run {
                self.votes = loadedVotes
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func createVote(
        topicId: String,
        voteType: VoteType,
        categoryId: String,
        subCategoryId: String,
        itemName: String,
        categoryName: String
    ) async {
        guard let userId = authManager.currentUser?.id else { return }
        
        await MainActor.run { isLoading = true }
        
        do {
            let vote = Vote(
                id: UUID().uuidString,
                userId: userId,
                categoryId: categoryId,
                subCategoryId: subCategoryId,
                topicId: topicId,
                voteType: voteType,
                timestamp: Date(),
                itemName: itemName,
                imageURL: nil,
                categoryName: categoryName,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            try await mysqlManager.createVote(vote)
            await MainActor.run {
                self.votes.append(vote)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
} 