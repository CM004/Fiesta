//import Foundation
//import Supabase
//import Auth
//import SwiftUI
//
//@MainActor
//class SupabaseAuthManager: ObservableObject {
//    static let shared = SupabaseAuthManager()
//    
//    // The real Supabase client
//    private let client: SupabaseClient
//    
//    // Type alias for auth state changes
//    private typealias AuthStateStream = AsyncStream<AuthStateChangeEvent>
//    
//    @Published var currentUser: User?
//    @Published var session: Session?
//    @Published var isAuthenticated = false
//    @Published var isLoading = false
//    @Published var error: Error?
//    
//    private init() {
//        // Initialize Supabase client with real credentials
//        self.client = SupabaseClient(
//            supabaseURL: URL(string: SupabaseConfig.supabaseURL)!,
//            supabaseKey: SupabaseConfig.supabaseAnonKey
//        )
//        
//        print("SupabaseAuthManager: Initialized with URL \(SupabaseConfig.supabaseURL)")
//        
//        // Set up auth state listener
//        Task {
//            await monitorAuthState()
//        }
//    }
//    
//    // MARK: - Auth State Management
//    
//    private func monitorAuthState() async {
//        // Make an initial check for auth state
//        await checkAuthState()
//        
//        // Set up periodic checking only if needed - with a longer interval
//        if !isAuthenticated {
//            startPeriodicAuthCheck()
//        }
//    }
//    
//    private func checkAuthState() async {
//        // If we already have a currentUser, we're authenticated
//        if currentUser != nil {
//            print("SupabaseAuthManager: Already have current user, authenticated")
//            self.isAuthenticated = true
//            return
//        }
//        
//        // Otherwise check for session token in Supabase
//        await checkSupabaseSession()
//    }
//    
//    // Check with Supabase if we have a valid session
//    private func checkSupabaseSession() async {
//        do {
//            // Make a request to the auth/user endpoint to check if we're logged in
//            var request = URLRequest(url: URL(string: "\(SupabaseConfig.supabaseURL)/auth/v1/user")!)
//            
//            // Get auth token from UserDefaults if available (Supabase stores it there)
//            var accessToken: String? = nil
//            
//            // Try multiple possible locations for the token
//            if let token = UserDefaults.standard.string(forKey: "supabase.auth.token") {
//                accessToken = token
//            } else if let token = UserDefaults.standard.string(forKey: "sb-rkfxfoyarguyqckpasjn-auth-token") {
//                accessToken = token
//            } else {
//                // Look for any keys that might contain auth tokens
//                for key in UserDefaults.standard.dictionaryRepresentation().keys {
//                    if key.contains("auth-token") || key.contains("supabase") {
//                        print("SupabaseAuthManager: Found potential token key: \(key)")
//                        if let token = UserDefaults.standard.string(forKey: key) {
//                            accessToken = token
//                            break
//                        }
//                    }
//                }
//            }
//            
//            if accessToken == nil {
//                print("SupabaseAuthManager: No auth token found in UserDefaults")
//                self.isAuthenticated = false
//                self.currentUser = nil
//                return
//            }
//            
//            request.httpMethod = "GET"
//            request.setValue("Bearer \(accessToken ?? "")", forHTTPHeaderField: "Authorization")
//            request.setValue("apikey \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "apikey")
//            
//            let (data, response) = try await URLSession.shared.data(for: request)
//            
//            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
//                // We have a valid session
//                if let userData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//                   let userId = userData["id"] as? String,
//                   let email = userData["email"] as? String {
//                    print("SupabaseAuthManager: Found existing session for user: \(email)")
//                    
//                    // Fetch or create user profile
//                    if let profile = try? await SupabaseManager.shared.fetchUserProfile(id: userId) {
//                        self.currentUser = profile
//                        self.isAuthenticated = true
//                    } else {
//                        // Create a basic user from auth data
//                        let displayName = email.components(separatedBy: "@").first ?? "User"
//                        let user = User(
//                            id: userId,
//                            name: displayName,
//            email: email,
//                            role: .student,
//                            cqScore: 0.0,
//                            createdAt: Date(),
//                            isActive: true,
//                            mealsSaved: 0,
//                            mealsSwapped: 0,
//                            mealsDistributed: 0
//                        )
//                        
//                        self.currentUser = user
//                        self.isAuthenticated = true
//                        
//                        // Try to create profile
//                        try? await SupabaseManager.shared.upsertUserProfile(user: user)
//                    }
//                }
//            } else {
//                print("SupabaseAuthManager: No valid session found")
//                self.isAuthenticated = false
//                self.currentUser = nil
//            }
//        } catch {
//            print("SupabaseAuthManager: Error checking session: \(error.localizedDescription)")
//            self.isAuthenticated = false
//            self.currentUser = nil
//        }
//    }
//    
//    private func getCurrentUserId() -> String? {
//        // Use session if we have it
//        return session?.user.id
//    }
//    
//    private func startPeriodicAuthCheck() {
//        // Create a repeating timer to check auth state - use a much longer interval (30 seconds)
//        // This is only for background session validation, not for active UI updates
//        var timer: Timer?
//        
//        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
//            guard let self = self else { return }
//            
//            // Only check if we're not already authenticated
//            if !self.isAuthenticated {
//                // Check auth on each timer tick
//                Task {
//                    await self.checkAuthState()
//                }
//            } else {
//                // We're authenticated, stop the timer
//                timer?.invalidate()
//            }
//        }
//        
//        // Make sure the timer continues running
//        if let timer = timer {
//            RunLoop.current.add(timer, forMode: .common)
//        }
//    }
//    
//    private func fetchUserProfile(userId: String) async {
//        // Use SupabaseManager to fetch the user profile after auth state changes
//        if let profile = try? await SupabaseManager.shared.fetchUserProfile(id: userId) {
//            self.currentUser = profile
//            print("SupabaseAuthManager: Loaded user profile for \(profile.name)")
//        } else {
//            print("SupabaseAuthManager: No profile found for user \(userId) - will create on next sign-in")
//        }
//    }
//    
//    // MARK: - Authentication Methods
//    
//    // A comprehensive method to verify authentication state after login/signup actions
//    private func verifyAuthState(session: Session) {
//        print("SupabaseAuthManager: Verifying auth state with session \(session.user.id)")
//        
//        // Update state with the newly created session
//        self.session = session
//        self.isAuthenticated = true
//        
//        // Log session details for debugging
//        print("SupabaseAuthManager: User email: \(session.user.email)")
//    }
//    
//    func signUp(email: String, password: String, name: String) async throws {
//        isLoading = true
//        error = nil
//        
//        do {
//            // Check if email already exists
//            if await isEmailRegistered(email: email) {
//                print("SupabaseAuthManager: Email already exists: \(email)")
//                throw NSError(domain: "Auth", code: 409, userInfo: [
//                    NSLocalizedDescriptionKey: "Email already in use. Please use a different email or try logging in."
//                ])
//            }
//            
//            // 1. First directly sign up with Supabase Auth
//            print("SupabaseAuthManager: Creating auth user account for \(email)")
//            
//            // Use a direct API request for consistent behavior
//            var signUpRequest = URLRequest(url: URL(string: "\(SupabaseConfig.supabaseURL)/auth/v1/signup")!)
//            signUpRequest.httpMethod = "POST"
//            signUpRequest.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
//            signUpRequest.setValue("apikey \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "apikey")
//            signUpRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
//            
//            let signUpPayload: [String: Any] = [
//                "email": email.lowercased(), // Ensure consistent email format
//                "password": password,
//                "data": [
//                    "name": name
//                ]
//            ]
//            
//            signUpRequest.httpBody = try JSONSerialization.data(withJSONObject: signUpPayload)
//            
//            print("SupabaseAuthManager: Sending signup request")
//            print("SupabaseAuthManager: Using anon key: \(SupabaseConfig.supabaseAnonKey)")
//            
//            let (responseData, response) = try await URLSession.shared.data(for: signUpRequest)
//            let responseStr = String(data: responseData, encoding: .utf8) ?? ""
//            
//            print("SupabaseAuthManager: Signup response: \(responseStr)")
//            
//            if let httpResponse = response as? HTTPURLResponse {
//                print("SupabaseAuthManager: Signup response code: \(httpResponse.statusCode)")
//                
//                // Handle API key issues specifically
//                if responseStr.contains("Invalid API key") {
//                    print("SupabaseAuthManager: API key issue detected")
//                    throw NSError(domain: "Auth", code: httpResponse.statusCode, userInfo: [
//                        NSLocalizedDescriptionKey: "Server configuration error. Please contact support."
//                    ])
//                }
//                
//                // Parse response to get the user information
//                if let jsonResponse = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
//                   let userId = jsonResponse["id"] as? String {
//                    
//                    print("SupabaseAuthManager: Auth user created with ID: \(userId)")
//                    
//                    // Create the user profile
//                    let newUser = User(
//                        id: userId,
//                        name: name,
//                        email: email.lowercased(),
//                        role: .student,
//                        cqScore: 0.0,
//                        createdAt: Date(),
//                        isActive: true,
//                        mealsSaved: 0,
//                        mealsSwapped: 0,
//                        mealsDistributed: 0
//                    )
//                    
//                    // Set as current user regardless of profile creation result
//                    self.currentUser = newUser
//                    
//                    // Store tokens if they are returned
//                    if let accessToken = jsonResponse["access_token"] as? String,
//                       let refreshToken = jsonResponse["refresh_token"] as? String {
//                        
//                        // Generate the token keys
//                        let tokenKey = "sb-\(SupabaseConfig.supabaseURL.components(separatedBy: "//").last?.components(separatedBy: ".").first ?? "")-auth-token"
//                        
//                        print("SupabaseAuthManager: Storing tokens with key: \(tokenKey)")
//                        
//                        // Store the tokens in the format Supabase expects
//                        UserDefaults.standard.set(accessToken, forKey: "supabase.auth.token")
//                        UserDefaults.standard.set(refreshToken, forKey: "supabase.auth.refresh_token")
//                        
//                        // Also try the project-specific key format
//                        UserDefaults.standard.set(accessToken, forKey: tokenKey)
//                        UserDefaults.standard.set(refreshToken, forKey: "\(tokenKey)-refresh")
//                        
//                        // Save changes immediately
//                        UserDefaults.standard.synchronize()
//                        
//                        self.isAuthenticated = true
//                    }
//                    
//                    print("SupabaseAuthManager: Creating user profile for \(userId)")
//                    
//                    // Try to create the profile but don't fail if it doesn't work
//                    do {
//                        try await SupabaseManager.shared.upsertUserProfile(user: newUser)
//                        print("SupabaseAuthManager: User profile created successfully")
//                    } catch {
//                        print("SupabaseAuthManager: Failed to create user profile: \(error.localizedDescription)")
//                        // Continue anyway, we already have the auth user
//                    }
//                    
//                    print("SupabaseAuthManager: Sign up complete for \(name)")
//                    isLoading = false
//                    
//                    // This signup might require email verification based on your Supabase settings
//                    // If we didn't get a session, throw a special message
//                    if jsonResponse["access_token"] == nil {
//                        throw NSError(domain: "Auth", code: 201, userInfo: [
//                            NSLocalizedDescriptionKey: "Account created! Please check your email for verification."
//                        ])
//                    }
//                    
//                    return
//                } else if !(200...299).contains(httpResponse.statusCode) {
//                    // Something went wrong with the signup
//                    print("SupabaseAuthManager: Signup failed with response: \(responseStr)")
//                    
//                    // Check for specific error messages
//                    if responseStr.contains("already registered") || responseStr.contains("already in use") {
//                        throw NSError(domain: "Auth", code: 409, userInfo: [
//                            NSLocalizedDescriptionKey: "Email already in use. Please use a different email."
//                        ])
//                    } else if responseStr.contains("password") && responseStr.contains("too short") {
//                        throw NSError(domain: "Auth", code: 400, userInfo: [
//                            NSLocalizedDescriptionKey: "Password is too short. Please use at least 6 characters."
//                        ])
//                    } else {
//                        throw NSError(domain: "Auth", code: httpResponse.statusCode, userInfo: [
//                            NSLocalizedDescriptionKey: "Failed to create account: \(responseStr)"
//                        ])
//                    }
//                } else {
//                    // Couldn't parse the successful response
//                    throw NSError(domain: "Auth", code: 500, userInfo: [
//                        NSLocalizedDescriptionKey: "Failed to create user account: couldn't parse response"
//                    ])
//                }
//            }
//            
//            throw NSError(domain: "Auth", code: 500, userInfo: [
//                NSLocalizedDescriptionKey: "Failed to create user in Supabase Auth"
//            ])
//        } catch {
//            isLoading = false
//            self.error = error
//            print("SupabaseAuthManager: Sign up failed: \(error.localizedDescription)")
//            throw error
//        }
//    }
//    
//    func signIn(email: String, password: String) async throws {
//        isLoading = true
//        error = nil
//        
//        do {
//            print("SupabaseAuthManager: Signing in \(email)")
//            
//            // Debug to verify what's being sent
//            print("SupabaseAuthManager: Login attempt with email: \(email) and password length: \(password.count)")
//            
//            // Check if email is registered first
//            if await !isEmailRegistered(email: email) {
//                print("SupabaseAuthManager: Email not registered: \(email)")
//                throw NSError(domain: "Auth", code: 404, userInfo: [
//                    NSLocalizedDescriptionKey: "Account not found. Please sign up first."
//                ])
//            }
//            
//            // Use the simplest and most direct approach to sign in
//            var signInRequest = URLRequest(url: URL(string: "\(SupabaseConfig.supabaseURL)/auth/v1/token?grant_type=password")!)
//            signInRequest.httpMethod = "POST"
//            signInRequest.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
//            signInRequest.setValue("apikey \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "apikey")
//            signInRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
//            
//            let signInPayload: [String: Any] = [
//                "email": email.lowercased(), // ensure consistent email format
//                "password": password
//            ]
//            
//            signInRequest.httpBody = try JSONSerialization.data(withJSONObject: signInPayload)
//            
//            print("SupabaseAuthManager: Sending direct auth request")
//            print("SupabaseAuthManager: Using anon key: \(SupabaseConfig.supabaseAnonKey)")
//            
//            let (responseData, response) = try await URLSession.shared.data(for: signInRequest)
//            let responseStr = String(data: responseData, encoding: .utf8) ?? ""
//            
//            print("SupabaseAuthManager: Sign in response: \(responseStr)")
//            
//            if let httpResponse = response as? HTTPURLResponse {
//                print("SupabaseAuthManager: Sign in response code: \(httpResponse.statusCode)")
//                
//                if !(200...299).contains(httpResponse.statusCode) {
//                    // Detailed error handling based on response
//                    if responseStr.contains("Invalid API key") {
//                        print("SupabaseAuthManager: API key issue detected")
//                        throw NSError(domain: "Auth", code: httpResponse.statusCode, userInfo: [
//                            NSLocalizedDescriptionKey: "Server configuration error. Please contact support."
//                        ])
//                    } else if responseStr.contains("invalid_credentials") || responseStr.contains("Invalid login credentials") {
//                        print("SupabaseAuthManager: Invalid credentials")
//                        throw NSError(domain: "Auth", code: httpResponse.statusCode, userInfo: [
//                            NSLocalizedDescriptionKey: "Incorrect email or password. Please try again."
//                        ])
//                    } else {
//                        print("SupabaseAuthManager: Sign in failed with response: \(responseStr)")
//                        throw NSError(domain: "Auth", code: httpResponse.statusCode, userInfo: [
//                            NSLocalizedDescriptionKey: "Login failed: \(responseStr)"
//                        ])
//                    }
//                }
//                
//                // Parse the response to get the session
//                if let jsonResponse = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
//                   let accessToken = jsonResponse["access_token"] as? String,
//                   let refreshToken = jsonResponse["refresh_token"] as? String,
//                   let userObj = jsonResponse["user"] as? [String: Any],
//                   let userId = userObj["id"] as? String,
//                   let userEmail = userObj["email"] as? String {
//                    
//                    print("SupabaseAuthManager: Successfully parsed auth response")
//                    
//                    // Store tokens in UserDefaults for future sessions
//                    // Try both formats to ensure compatibility
//                    let tokenKey = "sb-\(SupabaseConfig.supabaseURL.components(separatedBy: "//").last?.components(separatedBy: ".").first ?? "")-auth-token"
//                    
//                    print("SupabaseAuthManager: Storing tokens with key: \(tokenKey)")
//                    
//                    // Store the tokens in the format Supabase expects
//                    UserDefaults.standard.set(accessToken, forKey: "supabase.auth.token")
//                    UserDefaults.standard.set(refreshToken, forKey: "supabase.auth.refresh_token")
//                    
//                    // Also try the project-specific key format
//                    UserDefaults.standard.set(accessToken, forKey: tokenKey)
//                    UserDefaults.standard.set(refreshToken, forKey: "\(tokenKey)-refresh")
//                    
//                    // Save changes immediately
//                    UserDefaults.standard.synchronize()
//                    
//                    // Create a manual session object since we're not using the SDK's signIn method
//                    let user = User(
//                        id: userId,
//                        name: userEmail.components(separatedBy: "@").first ?? "User",
//                        email: userEmail,
//                        role: .student,
//                        cqScore: 0.0,
//                        createdAt: Date(),
//                        isActive: true,
//                        mealsSaved: 0,
//                        mealsSwapped: 0,
//                        mealsDistributed: 0
//                    )
//                    
//                    // Try to get an existing profile
//                    print("SupabaseAuthManager: Trying to fetch user profile")
//                    if let profile = try? await SupabaseManager.shared.fetchUserProfile(id: userId) {
//                        self.currentUser = profile
//                        print("SupabaseAuthManager: Loaded user profile for \(profile.name)")
//                    } else {
//                        // No profile exists or couldn't fetch it - use the basic user from auth
//                        print("SupabaseAuthManager: Creating basic user from auth response")
//                        self.currentUser = user
//                        
//                        // Try to create the profile in the background
//                        Task {
//                            try? await SupabaseManager.shared.upsertUserProfile(user: user)
//                        }
//                    }
//                    
//                    // Update auth state
//        self.isAuthenticated = true
//                    
//                    print("SupabaseAuthManager: Sign in successful")
//                    isLoading = false
//                    return
//                } else {
//                    print("SupabaseAuthManager: Failed to parse auth response: \(responseStr)")
//                    throw NSError(domain: "Auth", code: 500, userInfo: [
//                        NSLocalizedDescriptionKey: "Failed to parse authentication response"
//                    ])
//                }
//            }
//            
//            throw NSError(domain: "Auth", code: 500, userInfo: [
//                NSLocalizedDescriptionKey: "Failed to sign in - unknown error"
//            ])
//            
//        } catch {
//            isLoading = false
//            self.error = error
//            print("SupabaseAuthManager: Sign in failed: \(error.localizedDescription)")
//            throw error
//        }
//    }
//    
//    func signOut() async throws {
//        isLoading = true
//        error = nil
//        
//        do {
//            print("SupabaseAuthManager: Signing out...")
//        try await client.auth.signOut()
//            
//            // Clear stored tokens
//            UserDefaults.standard.removeObject(forKey: "supabase.auth.token")
//            UserDefaults.standard.removeObject(forKey: "supabase.auth.refresh_token")
//            
//            // Also try to clear the project-specific tokens
//            let tokenKey = "sb-\(SupabaseConfig.supabaseURL.components(separatedBy: "//").last?.components(separatedBy: ".").first ?? "")-auth-token"
//            UserDefaults.standard.removeObject(forKey: tokenKey)
//            UserDefaults.standard.removeObject(forKey: "\(tokenKey)-refresh")
//            
//            // Search for and remove any other potential auth tokens
//            for key in UserDefaults.standard.dictionaryRepresentation().keys {
//                if key.contains("auth-token") || key.contains("supabase") {
//                    UserDefaults.standard.removeObject(forKey: key)
//                }
//            }
//            
//            // Save changes immediately
//            UserDefaults.standard.synchronize()
//            
//        self.session = nil
//        self.currentUser = nil
//        self.isAuthenticated = false
//            print("SupabaseAuthManager: Sign out successful")
//            
//            isLoading = false
//        } catch {
//            isLoading = false
//            self.error = error
//            print("SupabaseAuthManager: Sign out failed: \(error.localizedDescription)")
//            throw error
//        }
//    }
//    
//    // MARK: - Direct Database Functions
//    
//    /// Direct insertion of user profile using service role key
//    private func createUserProfileDirectly(user: User) async throws {
//        // Try to use proper error handling with specific fallbacks
//        do {
//            try await SupabaseManager.shared.upsertUserProfile(user: user)
//        } catch let error as NSError {
//            print("SupabaseAuthManager: Error creating user profile: \(error.localizedDescription)")
//            
//            // Authentication succeeded but profile creation failed - we need to handle this gracefully
//            // The user can still log in, but may not have a profile
//            // We'll set the current user anyway so the app still functions
//            self.currentUser = user
//            
//            // Only throw the error if it's a critical issue
//            if error.localizedDescription.contains("Invalid API key") {
//                print("SupabaseAuthManager: API key issue detected. Using fallback approach...")
//                
//                // We'll log the error but not throw it to prevent blocking sign-in
//                // The app can try to create the profile again later
//            } else {
//                throw error
//            }
//        }
//    }
//    
//    func resetPassword(email: String) async throws {
//        isLoading = true
//        error = nil
//        
//        do {
//            try await client.auth.resetPasswordForEmail(email: email)
//            print("Auth: Password reset email sent to \(email)")
//            isLoading = false
//        } catch {
//            isLoading = false
//            self.error = error
//            print("Auth: Password reset failed: \(error.localizedDescription)")
//            throw error
//        }
//    }
//    
//    var userId: String? {
//        return currentUser?.id ?? session?.user.id
//    }
//    
//    // Check if the email is already registered with Supabase
//    func isEmailRegistered(email: String) async -> Bool {
//        do {
//            print("SupabaseAuthManager: Checking if email exists: \(email)")
//            
//            // Make a direct API call to check if the email exists
//            var checkRequest = URLRequest(url: URL(string: "\(SupabaseConfig.supabaseURL)/auth/v1/admin/users")!)
//            checkRequest.httpMethod = "GET"
//            checkRequest.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
//            checkRequest.setValue("apikey \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "apikey")
//            
//            // Try to get a response - if the email exists, this will return user data
//            // If we get an invalid permissions error, it means the anon key doesn't have admin rights (expected)
//            // We'll fallback to the sign-up attempt method
//            do {
//                let (responseData, response) = try await URLSession.shared.data(for: checkRequest)
//                let responseStr = String(data: responseData, encoding: .utf8) ?? ""
//                
//                if responseStr.contains("Invalid API key") {
//                    print("SupabaseAuthManager: API key issue during email check")
//                    // Since we can't check directly, we'll attempt a fallback method
//                }
//            } catch {
//                // Expected error if using anon key - continue to fallback method
//            }
//            
//            // Fallback method: Try to sign up with the email but with an invalid password
//            // The most reliable way to check if an email exists is to 
//            // try to sign up with it but with an invalid password
//            // If the error says "User already registered", the email exists
//            do {
//                // Try to sign up with a deliberately wrong/short password
//                // This will fail, but we can check if it fails because the
//                // email already exists or because of the password
//                var signUpRequest = URLRequest(url: URL(string: "\(SupabaseConfig.supabaseURL)/auth/v1/signup")!)
//                signUpRequest.httpMethod = "POST"
//                signUpRequest.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
//                signUpRequest.setValue("apikey \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "apikey")
//                signUpRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
//                
//                let signUpPayload: [String: Any] = [
//                    "email": email.lowercased(),
//                    "password": "x" // Deliberately incorrect password
//                ]
//                
//                signUpRequest.httpBody = try JSONSerialization.data(withJSONObject: signUpPayload)
//                
//                let (responseData, _) = try await URLSession.shared.data(for: signUpRequest)
//                let responseStr = String(data: responseData, encoding: .utf8) ?? ""
//                
//                // Check if the error message indicates the email already exists
//                if responseStr.contains("already registered") || responseStr.contains("already in use") {
//                    print("SupabaseAuthManager: Email \(email) is already registered")
//                    return true
//                } else if responseStr.contains("Invalid API key") {
//                    print("SupabaseAuthManager: API key issue detected during email check")
//                    // If we can't check, we'll assume the email is available to avoid blocking signup
//                    return false
//                } else {
//                    // Error was due to something else (likely the invalid password)
//                    print("SupabaseAuthManager: Email \(email) is available (error was about password)")
//                    return false
//                }
//            } catch let signupError as NSError {
//                // Check if the error message indicates the email already exists
//                let errorMessage = signupError.localizedDescription.lowercased()
//                
//                if errorMessage.contains("already registered") || errorMessage.contains("already in use") {
//                    print("SupabaseAuthManager: Email \(email) is already registered")
//                    return true
//                } else if errorMessage.contains("invalid api key") {
//                    print("SupabaseAuthManager: API key issue detected during email check")
//                    // If we can't check, we'll assume the email is available to avoid blocking signup
//                    return false
//                } else {
//                    // Error was due to something else (likely the invalid password)
//                    print("SupabaseAuthManager: Email \(email) is available (error was about password)")
//                    return false
//                }
//            }
//        } catch {
//            print("SupabaseAuthManager: Error checking email: \(error.localizedDescription)")
//            return false // Default to allowing signup attempt if we can't verify
//        }
//    }
//} 
