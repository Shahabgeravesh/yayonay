import Foundation
import MySQLKit
import MySQLNIO
import NIO
import os.log

class MySQLManager {
    static let shared = MySQLManager()
    private let eventLoopGroup: EventLoopGroup
    private let pool: EventLoopGroupConnectionPool<MySQLConnectionSource>
    private let logger = Logger(subsystem: "com.yayonay", category: "MySQLManager")
    
    private init() {
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)
        
        let configuration = MySQLConfiguration(
            hostname: "localhost",
            port: 3306,
            username: "root",
            password: "password",
            database: "yayonay",
            tlsConfiguration: nil
        )
        
        let source = MySQLConnectionSource(configuration: configuration)
        let poolConfiguration = ConnectionPoolConfiguration(maxConnections: 8)
        self.pool = EventLoopGroupConnectionPool(
            source: source,
            on: eventLoopGroup,
            poolConfiguration: poolConfiguration
        )
    }
    
    func cleanup() {
        try? pool.syncShutdownGracefully()
        try? eventLoopGroup.syncShutdownGracefully()
    }
    
    // MARK: - Query Execution
    
    private func executeQuery<T: Decodable>(_ query: String, parameters: [MySQLData] = []) async throws -> [T] {
        try await pool.withConnection { connection in
            let rows = try await connection.query(query, parameters).get()
            return try rows.map { row in
                let dict = try row.decode(column: 0, as: [String: Any].self)
                let data = try JSONSerialization.data(withJSONObject: dict)
                return try JSONDecoder().decode(T.self, from: data)
            }
        }
    }
    
    private func executeUpdate(_ query: String, parameters: [MySQLData] = []) async throws {
        try await pool.withConnection { connection in
            _ = try await connection.query(query, parameters).get()
        }
    }
    
    // MARK: - User Operations
    
    func createUser(_ user: User) async throws {
        let query = """
            INSERT INTO users (id, email, name, created_at, updated_at)
            VALUES (?, ?, ?, NOW(), NOW())
        """
        let parameters: [MySQLData] = [
            .init(string: user.id),
            .init(string: user.email),
            .init(string: user.name)
        ]
        try await executeUpdate(query, parameters: parameters)
    }
    
    func authenticateUser(email: String, password: String) async throws -> User? {
        let query = "SELECT * FROM users WHERE email = ?"
        let parameters: [MySQLData] = [.init(string: email)]
        let users: [User] = try await executeQuery(query, parameters: parameters)
        return users.first
    }
    
    func getUser(id: String) async throws -> User? {
        let query = "SELECT * FROM users WHERE id = ?"
        let parameters: [MySQLData] = [.init(string: id)]
        let users: [User] = try await executeQuery(query, parameters: parameters)
        return users.first
    }
    
    func updateUser(_ user: User) async throws {
        let query = """
            UPDATE users
            SET email = ?, name = ?, updated_at = NOW()
            WHERE id = ?
        """
        let parameters: [MySQLData] = [
            .init(string: user.email),
            .init(string: user.name),
            .init(string: user.id)
        ]
        try await executeUpdate(query, parameters: parameters)
    }
    
    // MARK: - Vote Operations
    
    func createVote(_ vote: Vote) async throws {
        let query = """
            INSERT INTO votes (id, user_id, category_id, sub_category_id, topic_id, vote_type, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW())
        """
        let parameters: [MySQLData] = [
            .init(string: vote.id),
            .init(string: vote.userId),
            .init(string: vote.categoryId),
            .init(string: vote.subCategoryId),
            .init(string: vote.topicId),
            .init(bool: vote.voteType == .yay)
        ]
        try await executeUpdate(query, parameters: parameters)
    }
    
    func getVotes(categoryId: String, subCategoryId: String) async throws -> [Vote] {
        let query = """
            SELECT v.*, t.*
            FROM votes v
            LEFT JOIN topics t ON v.topic_id = t.id
            WHERE v.category_id = ? AND v.sub_category_id = ?
            ORDER BY v.created_at DESC
        """
        let parameters: [MySQLData] = [
            .init(string: categoryId),
            .init(string: subCategoryId)
        ]
        return try await executeQuery(query, parameters: parameters)
    }
    
    // MARK: - Comment Operations
    
    func createComment(_ comment: Comment) async throws {
        let query = """
            INSERT INTO comments (id, user_id, topic_id, content, created_at, updated_at)
            VALUES (?, ?, ?, ?, NOW(), NOW())
        """
        let parameters: [MySQLData] = [
            .init(string: comment.id),
            .init(string: comment.userId),
            .init(string: comment.topicId),
            .init(string: comment.content)
        ]
        try await executeUpdate(query, parameters: parameters)
    }
    
    func getComments(topicId: String) async throws -> [Comment] {
        let query = """
            SELECT * FROM comments
            WHERE topic_id = ?
            ORDER BY created_at DESC
        """
        let parameters: [MySQLData] = [.init(string: topicId)]
        return try await executeQuery(query, parameters: parameters)
    }
    
    func deleteComment(id: String) async throws {
        let query = "DELETE FROM comments WHERE id = ?"
        let parameters: [MySQLData] = [.init(string: id)]
        try await executeUpdate(query, parameters: parameters)
    }
    
    // MARK: - Topic Operations
    
    func createTopic(_ topic: Topic) async throws {
        let query = """
            INSERT INTO topics (id, title, description, user_id, category_id, sub_category_id, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW())
        """
        let parameters: [MySQLData] = [
            .init(string: topic.id),
            .init(string: topic.title),
            .init(string: topic.description),
            .init(string: topic.userId),
            .init(string: topic.categoryId),
            .init(string: topic.subCategoryId)
        ]
        try await executeUpdate(query, parameters: parameters)
    }
    
    func getTopics(categoryId: String, subCategoryId: String) async throws -> [Topic] {
        let query = """
            SELECT * FROM topics
            WHERE category_id = ? AND sub_category_id = ?
            ORDER BY created_at DESC
        """
        let parameters: [MySQLData] = [
            .init(string: categoryId),
            .init(string: subCategoryId)
        ]
        return try await executeQuery(query, parameters: parameters)
    }
    
    // MARK: - Category Operations
    func getCategories() async throws -> [Category] {
        let query = """
            SELECT id, name, description, created_at
            FROM categories
            ORDER BY name
        """
        return try await executeQuery(query)
    }
    
    func getCategory(id: String) async throws -> Category {
        let query = """
            SELECT id, name, description, created_at
            FROM categories
            WHERE id = ?
        """
        let parameters: [MySQLData] = [.init(string: id)]
        let categories: [Category] = try await executeQuery(query, parameters: parameters)
        
        guard let category = categories.first else {
            throw DatabaseError.notFound
        }
        return category
    }
    
    // MARK: - SubCategory Operations
    func getSubCategories(categoryId: String) async throws -> [SubCategory] {
        let query = """
            SELECT id, category_id, name, description, created_at
            FROM sub_categories
            WHERE category_id = ?
            ORDER BY name
        """
        let parameters: [MySQLData] = [.init(string: categoryId)]
        return try await executeQuery(query, parameters: parameters)
    }
    
    // MARK: - Question Operations
    func createQuestion(userId: String, content: String) async throws -> Question {
        let query = """
            INSERT INTO questions (user_id, content, created_at)
            VALUES (?, ?, NOW())
            RETURNING id, user_id, content, created_at
        """
        let parameters: [MySQLData] = [
            .init(string: userId),
            .init(string: content)
        ]
        let questions: [Question] = try await executeQuery(query, parameters: parameters)
        guard let question = questions.first else {
            throw DatabaseError.insertFailed
        }
        return question
    }
    
    func getQuestions() async throws -> [Question] {
        let query = """
            SELECT id, user_id, content, created_at
            FROM questions
            ORDER BY created_at DESC
        """
        return try await executeQuery(query)
    }
    
    // MARK: - Share Operations
    func trackShare(userId: String, itemId: String, itemType: String, platform: String) async throws {
        let query = """
            INSERT INTO shares (user_id, item_id, item_type, platform, created_at)
            VALUES (?, ?, ?, ?, NOW())
        """
        let parameters: [MySQLData] = [
            .init(string: userId),
            .init(string: itemId),
            .init(string: itemType),
            .init(string: platform)
        ]
        try await executeUpdate(query, parameters: parameters)
    }
    
    func getShareStats(userId: String) async throws -> ShareStats {
        let query = """
            SELECT 
                COUNT(*) as total_shares,
                COUNT(DISTINCT item_id) as unique_items_shared,
                GROUP_CONCAT(DISTINCT platform) as platforms_used
            FROM shares
            WHERE user_id = ?
        """
        let parameters: [MySQLData] = [.init(string: userId)]
        let stats: [ShareStats] = try await executeQuery(query, parameters: parameters)
        
        guard let stat = stats.first else {
            return ShareStats(totalShares: 0, uniqueItemsShared: 0, platformsUsed: [])
        }
        return stat
    }
    
    func getShareCount(itemId: String, itemType: String) async throws -> Int {
        let query = """
            SELECT COUNT(*) as count
            FROM shares
            WHERE item_id = ? AND item_type = ?
        """
        let parameters: [MySQLData] = [
            .init(string: itemId),
            .init(string: itemType)
        ]
        let counts: [ShareCount] = try await executeQuery(query, parameters: parameters)
        return counts.first?.count ?? 0
    }
}

// MARK: - Supporting Types
struct ShareCount: Codable {
    let count: Int
}

enum DatabaseError: Error {
    case connectionFailed
    case insertFailed
    case updateFailed
    case notFound
    case authenticationFailed
} 