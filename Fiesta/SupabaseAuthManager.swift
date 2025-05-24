import Foundation
import Supabase

@MainActor
class SupabaseAuthManager: ObservableObject {
    static let shared = SupabaseAuthManager()
    
    private let client: SupabaseClient
    
    @Published var currentUser: User?
    @Published var session: Session?
    @Published var isAuthenticated = false
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.supabaseURL)!,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
        
        Task {
            await setupAuthStateListener()
        }
    }
    
    private func setupAuthStateListener() async {
        for await update in await client.auth.authStateChanges {
            self.session = update.session
            self.currentUser = update.session?.user
            self.isAuthenticated = update.session != nil
        }
    }
    
    func signUp(email: String, password: String) async throws {
        let authResponse = try await client.auth.signUp(
            email: email,
            password: password
        )
        self.session = authResponse.session
        self.currentUser = authResponse.user
        self.isAuthenticated = authResponse.session != nil
    }
    
    func signIn(email: String, password: String) async throws {
        let authResponse = try await client.auth.signIn(
            email: email,
            password: password
        )
        self.session = authResponse.session
        self.currentUser = authResponse.user
        self.isAuthenticated = true
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
        self.session = nil
        self.currentUser = nil
        self.isAuthenticated = false
    }
    
    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }
    
    var userId: String? {
        currentUser?.id
    }
} 