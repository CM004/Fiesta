import Foundation
import SwiftUI

@MainActor
class LocalAuthManager: ObservableObject {
    static let shared = LocalAuthManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: Error?
    
    private let userDefaultsKey = "fiesta_users"
    private let currentUserIdKey = "fiesta_current_user_id"
    
    init() {
        // Try to restore user session
        restoreSession()
    }
    
    private func restoreSession() {
        if let userId = UserDefaults.standard.string(forKey: currentUserIdKey),
           let user = getUser(id: userId) {
            self.currentUser = user
            self.isAuthenticated = true
            print("LocalAuthManager: Restored session for user: \(user.name)")
        } else {
            print("LocalAuthManager: No session to restore")
        }
    }
    
    // Get all users from UserDefaults
    private func getUsers() -> [User] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([User].self, from: data)
        } catch {
            print("LocalAuthManager: Error decoding users: \(error)")
            return []
        }
    }
    
    // Get a specific user by ID
    private func getUser(id: String) -> User? {
        return getUsers().first { $0.id == id }
    }
    
    // Get a specific user by email
    private func getUser(email: String) -> User? {
        return getUsers().first { $0.email.lowercased() == email.lowercased() }
    }
    
    // Save users to UserDefaults
    private func saveUsers(_ users: [User]) {
        do {
            let data = try JSONEncoder().encode(users)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("LocalAuthManager: Error encoding users: \(error)")
        }
    }
    
    // MARK: - Public Methods
    
    func signUp(name: String, email: String, password: String) async throws {
        isLoading = true
        error = nil
        
        // Check if email is already registered
        if getUser(email: email) != nil {
            isLoading = false
            throw NSError(domain: "Auth", code: 409, userInfo: [
                NSLocalizedDescriptionKey: "Email already in use. Please use a different email."
            ])
        }
        
        // Create new user
        let newUser = User(
            id: UUID().uuidString,
            name: name,
            email: email.lowercased(),
            role: .student,
            cqScore: 0.0,
            createdAt: Date(),
            isActive: true,
            mealsSaved: 0,
            mealsSwapped: 0,
            mealsDistributed: 0
        )
        
        // Save user password securely in keychain (simplified to UserDefaults for now)
        UserDefaults.standard.set(password, forKey: "password_\(newUser.id)")
        
        // Add user to list
        var users = getUsers()
        users.append(newUser)
        saveUsers(users)
        
        // Set as current user
        self.currentUser = newUser
        self.isAuthenticated = true
        UserDefaults.standard.set(newUser.id, forKey: currentUserIdKey)
        
        isLoading = false
        print("LocalAuthManager: Created user: \(newUser.name)")
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        error = nil
        
        // Find user by email
        guard let user = getUser(email: email) else {
            isLoading = false
            throw NSError(domain: "Auth", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "User not found. Please check your email or sign up."
            ])
        }
        
        // Check password
        let savedPassword = UserDefaults.standard.string(forKey: "password_\(user.id)")
        guard password == savedPassword else {
            isLoading = false
            throw NSError(domain: "Auth", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "Incorrect password. Please try again."
            ])
        }
        
        // Set as current user
        self.currentUser = user
        self.isAuthenticated = true
        UserDefaults.standard.set(user.id, forKey: currentUserIdKey)
        
        isLoading = false
        print("LocalAuthManager: Logged in user: \(user.name)")
    }
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: currentUserIdKey)
        self.currentUser = nil
        self.isAuthenticated = false
        print("LocalAuthManager: User logged out")
    }
    
    func updateUserProfile(user: User) {
        var users = getUsers()
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = user
            saveUsers(users)
            self.currentUser = user
            print("LocalAuthManager: Updated profile for user: \(user.name)")
        }
    }
} 