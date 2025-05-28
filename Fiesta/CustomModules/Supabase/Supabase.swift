import Foundation

// This is a minimal implementation of the Supabase API to make your code compile
// Replace this with the actual Supabase library when possible

// MARK: - Shared Data Store (For mock persistence)

// A singleton to share data between auth and database components in the mock implementation
class SupabaseDataStore {
    static let shared = SupabaseDataStore()
    
    // Authentication data - stores login credentials and user identity
    var authUsers: [String: SupabaseUser] = [
        // Add default test account
        "student1@test.com": SupabaseUser(id: "1", email: "student1@test.com")
    ]
    
    // Auth credentials
    var authCredentials: [String: String] = [
        // email: password
        "student1@test.com": "password"
    ]
    
    // Database tables - stores user profile information
    var userProfiles: [String: [String: Any]] = [
        // Default test account profile
        "1": [
            "id": "1",
            "name": "Student One",
            "email": "student1@test.com",
            "role": "student",
            "cq_score": 85.0,
            "is_active": true,
            "meals_saved": 12,
            "meals_swapped": 15,
            "meals_distributed": 3,
            "created_at": ISO8601DateFormatter().string(from: Date())
        ]
    ]
    
    private init() {}
    
    // Helper function to simulate how Supabase creates a new user in auth system
    func createAuthUser(email: String, password: String) -> SupabaseUser {
        let userId = UUID().uuidString
        let user = SupabaseUser(id: userId, email: email)
        
        // Store in auth table
        authUsers[email.lowercased()] = user
        authCredentials[email.lowercased()] = password
        
        // Create minimal entry in users table (will be expanded later)
        let timestamp = ISO8601DateFormatter().string(from: Date())
        userProfiles[userId] = [
            "id": userId,
            "email": email,
            "created_at": timestamp
        ]
        
        print("SupabaseDataStore: Created new auth user with ID: \(userId)")
        return user
    }
    
    // Helper function to verify credentials
    func verifyCredentials(email: String, password: String) -> SupabaseUser? {
        guard let correctPassword = authCredentials[email.lowercased()],
              correctPassword == password,
              let user = authUsers[email.lowercased()] else {
            return nil
        }
        return user
    }
}

// MARK: - Auth Features

public struct Session {
    public let accessToken: String
    public let refreshToken: String
    public let user: SupabaseUser
    
    public init(accessToken: String, refreshToken: String, user: SupabaseUser) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.user = user
    }
}

public struct SupabaseUser {
    public let id: String
    public let email: String
    
    public init(id: String, email: String) {
        self.id = id
        self.email = email
    }
}

public class AuthStateChangeEvent {
    public let session: Session?
    
    public init(session: Session?) {
        self.session = session
    }
}

public class AuthResponse {
    public let user: SupabaseUser?
    public let session: Session?
    
    public init(user: SupabaseUser?, session: Session?) {
        self.user = user
        self.session = session
    }
}

public class Auth {
    private var dataStore = SupabaseDataStore.shared
    private var currentSession: Session? = nil
    
    public var authStateChanges: AsyncStream<AuthStateChangeEvent> {
        AsyncStream { continuation in
            // Send the current state when requested
            continuation.yield(AuthStateChangeEvent(session: currentSession))
            continuation.finish()
        }
    }
    
    public func signUp(email: String, password: String) async throws -> AuthResponse {
        // Check if email is already registered
        if dataStore.authUsers[email.lowercased()] != nil {
            print("Auth: Signup failed - email already registered: \(email)")
            throw NSError(domain: "Auth", code: 400, userInfo: [
                NSLocalizedDescriptionKey: "Email already registered"
            ])
        }
        
        // Create new user with UUID in the auth system
        let user = dataStore.createAuthUser(email: email, password: password)
        
        print("Auth: Successfully created user in auth system: \(user.id) / \(user.email)")
        
        // Create session
        let session = Session(
            accessToken: "mock-token-\(user.id)",
            refreshToken: "mock-refresh-\(user.id)",
            user: user
        )
        
        // Store the current session
        currentSession = session
        
        return AuthResponse(user: user, session: session)
    }
    
    public func signIn(email: String, password: String) async throws -> AuthResponse {
        // Check credentials using the data store
        guard let user = dataStore.verifyCredentials(email: email, password: password) else {
            print("Auth: Sign in failed - invalid credentials for: \(email)")
            throw NSError(domain: "Auth", code: 400, userInfo: [
                NSLocalizedDescriptionKey: "Invalid credentials"
            ])
        }
        
        print("Auth: Sign in successful for user: \(user.id) / \(user.email)")
        
        // Create session
        let session = Session(
            accessToken: "mock-token-\(user.id)",
            refreshToken: "mock-refresh-\(user.id)",
            user: user
        )
        
        // Store the current session
        currentSession = session
        
        return AuthResponse(user: user, session: session)
    }
    
    public func signOut() async throws {
        currentSession = nil
        print("Auth: User signed out")
    }
    
    public func resetPasswordForEmail(email: String) async throws {
        // Just check if the email exists
        guard dataStore.authUsers[email.lowercased()] != nil else {
            throw NSError(domain: "Auth", code: 400, userInfo: [
                NSLocalizedDescriptionKey: "Email not found"
            ])
        }
        
        // In a real implementation, this would send a password reset email
    }
}

// MARK: - Database Features

public class PostgrestResponse {
    private let jsonData: Data?
    
    init(data: Data?) {
        self.jsonData = data
    }
    
    // Mock data property to make Extensions.swift work
    public var data: Data? {
        return jsonData ?? "[]".data(using: .utf8)
    }
}

public class PostgrestBuilder {
    private var tableName: String
    private var filters: [(String, String, Any)] = []
    private let dataStore = SupabaseDataStore.shared
    
    init(tableName: String) {
        self.tableName = tableName
    }
    
    public func execute() async throws -> PostgrestResponse {
        // This is where we would generate a response based on the query
        
        // For simple implementation, return data based on table name
        if tableName == "users" {
            // Return all user profiles
            do {
                let usersArray = Array(dataStore.userProfiles.values)
                let jsonData = try JSONSerialization.data(withJSONObject: usersArray)
                return PostgrestResponse(data: jsonData)
            } catch {
                print("Database error: \(error.localizedDescription)")
                return PostgrestResponse(data: nil)
            }
        }
        
        // Default empty response
        return PostgrestResponse(data: nil)
    }
}

public class PostgrestTable {
    private let name: String
    
    public init(_ name: String) {
        self.name = name
    }
    
    public func select(_ columns: String = "*") -> PostgrestBuilder {
        // Create a builder that will eventually execute the query
        return PostgrestBuilder(tableName: name)
    }
}

public class PostgrestClient {
    private let dataStore = SupabaseDataStore.shared
    
    public func from(_ table: String) -> PostgrestTable {
        return PostgrestTable(table)
    }
}

// MARK: - Storage Features

public struct FileOptions {
    public let contentType: String
    
    public init(contentType: String) {
        self.contentType = contentType
    }
}

public class StorageBucket {
    private let name: String
    
    public init(_ name: String) {
        self.name = name
    }
}

public class StorageClient {
    public func from(_ bucket: String) -> StorageBucket {
        return StorageBucket(bucket)
    }
}

// MARK: - Realtime Features

public enum RealtimeChannelType {
    case table(String)
    case presence(String)
    case broadcast(String)
}

public enum RealtimeEventType {
    case insert
    case update
    case delete
    case all
}

public struct RealtimeMessage {
    public let event: String
    public let payload: [String: Any]
    
    public init(event: String, payload: [String: Any]) {
        self.event = event
        self.payload = payload
    }
}

public class RealtimeChannel {
    public func on(_ eventType: RealtimeEventType, callback: @escaping (RealtimeMessage) -> Void) -> RealtimeChannel {
        return self // For chaining
    }
    
    public func subscribe() -> RealtimeChannel {
        return self // Return self for consistent API
    }
}

public class RealtimeClient {
    public func channel(_ type: RealtimeChannelType) -> RealtimeChannel {
        return RealtimeChannel()
    }
}

// MARK: - Main Client

public class SupabaseClient {
    public let auth: Auth
    public let database: PostgrestClient
    public let storage: StorageClient
    public let realtime: RealtimeClient
    
    public init(supabaseURL: URL, supabaseKey: String) {
        self.auth = Auth()
        self.database = PostgrestClient()
        self.storage = StorageClient()
        self.realtime = RealtimeClient()
    }
} 