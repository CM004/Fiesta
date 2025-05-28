//
//  ContentView.swift
//  Fiesta
//
//  Created by Chandramohan on 22/05/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var dataController = DataController()
    @State private var isAuthenticated: Bool = false
    @State private var email = ""
    @State private var password = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        Group {
            if isAuthenticated || dataController.currentUser != nil {
                // Main app interface
                MainTabView()
                    .environmentObject(dataController)
                    .onAppear {
                        // Set up notification observer for logout
                        setupLogoutObserver()
                    }
            } else {
                // Login view
                LoginView(
                    isAuthenticated: $isAuthenticated,
                    email: $email,
                    password: $password,
                    showingError: $showingError,
                    errorMessage: $errorMessage,
                    login: handleLogin
                )
                .environmentObject(dataController)
            }
        }
        .onAppear {
            // Debug info about session state
            if let user = dataController.currentUser {
                print("Session restored for: \(user.name) (\(user.email))")
                isAuthenticated = true
            } else {
                print("No active session found")
            }
            
            // Set up notification observer for logout
            setupLogoutObserver()
        }
    }
    
    private func setupLogoutObserver() {
        // Remove any existing observers to avoid duplicates
        NotificationCenter.default.removeObserver(self)
        
        // Add observer for logout notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("LogoutUser"),
            object: nil,
            queue: .main) { _ in
                handleLogout()
            }
    }
    
    private func handleLogout() {
        // Clear the authentication state
        isAuthenticated = false
        
        // Force UI refresh
        Task {
            // This is a backup - dataController already cleared the user
            if dataController.currentUser != nil {
                await dataController.logout()
            }
        }
    }
    
    private func handleLogin() {
        // For demo purposes, we'll automatically log in with the first user
        // In a real app, this would validate credentials against a backend
        Task {
            if await dataController.login(email: email, password: password) {
                isAuthenticated = true
            } else {
                errorMessage = "Invalid email or password"
                showingError = true
            }
        }
    }
}

struct LoginView: View {
    @EnvironmentObject private var dataController: DataController
    @Binding var isAuthenticated: Bool
    @Binding var email: String
    @Binding var password: String
    @Binding var showingError: Bool
    @Binding var errorMessage: String
    @State private var showingSignup = false
    @State private var isLoggingIn = false
    let login: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Logo
                    VStack {
                        Image(systemName: "leaf.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(Color("FiestaPrimary"))
                        
                        Text("Fiesta")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Reduce Food Waste, Together")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 50)
                    
                    // Login Form
                    VStack(spacing: 20) {
                        TextField("Email", text: $email)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        Button(action: {
                            login()
                        }) {
                            if isLoggingIn {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Log In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("FiestaPrimary"))
                        .cornerRadius(10)
                        .disabled(isLoggingIn)
                        
                        Button(action: {
                            // Use demo credentials
                            email = "student1@test.com"
                            password = "password"
                            login()
                        }) {
                            Text("Use Demo Account")
                                .fontWeight(.medium)
                                .foregroundColor(Color("FiestaPrimary"))
                        }
                        .disabled(isLoggingIn)
                        
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                // Forgot password action
                            }) {
                                Text("Forgot Password?")
                                    .fontWeight(.medium)
                                    .foregroundColor(Color("FiestaPrimary"))
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Create account link
        VStack {
                        Divider()
                            .padding(.vertical)
                        
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                showingSignup = true
                            }) {
                                Text("Sign Up")
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color("FiestaPrimary"))
                            }
                        }
                    }
                }
                .padding()
            }
            .alert(isPresented: $showingError) {
                Alert(
                    title: Text("Login Failed"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showingSignup) {
                SignupView(onSignupComplete: { success in
                    if success {
                        isAuthenticated = true
                    }
                })
                .environmentObject(dataController)
            }
        }
    }
}

// Define SignupView right in this file to ensure it's accessible
struct SignupView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var dataController: DataController
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var registrationSuccess = false
    @State private var isRegistering = false
    
    // Binding to notify parent view after successful registration
    var onSignupComplete: (Bool) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                // Registration form
                VStack(spacing: 15) {
                    TextField("Full Name", text: $name)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .autocapitalization(.words)
                        .disabled(isRegistering)
                    
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disabled(isRegistering)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .disabled(isRegistering)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .disabled(isRegistering)
                    
                    // Signup button
                    Button(action: handleSignup) {
                        if isRegistering {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign Up")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("FiestaPrimary"))
                    .cornerRadius(10)
                    .disabled(isRegistering)
                    .padding(.top)
                }
                .padding(.horizontal)
                
                // Back to login
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Back to Login")
                    }
                    .foregroundColor(Color("FiestaPrimary"))
                }
                .padding(.top)
                
                Spacer()
        }
        .padding()
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if registrationSuccess {
                        onSignupComplete(true)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
    }
    
    private func handleSignup() {
        // Input validation
        if name.isEmpty {
            showAlert(title: "Name Required", message: "Please enter your name.")
            return
        }
        
        if email.isEmpty {
            showAlert(title: "Email Required", message: "Please enter your email.")
            return
        }
        
        if !isValidEmail(email) {
            showAlert(title: "Invalid Email", message: "Please enter a valid email address.")
            return
        }
        
        if password.isEmpty {
            showAlert(title: "Password Required", message: "Please enter a password.")
            return
        }
        
        if password.count < 6 {
            showAlert(title: "Password Too Short", message: "Password should be at least 6 characters.")
            return
        }
        
        if password != confirmPassword {
            showAlert(title: "Passwords Don't Match", message: "Please make sure your passwords match.")
            return
        }
        
        // Attempt registration
        isRegistering = true
        Task {
            do {
                let success = await dataController.registerUser(name: name, email: email, password: password)
                
                // Update UI on the main thread
                isRegistering = false
                
                if success {
                    registrationSuccess = true
                    showAlert(title: "Registration Success", message: "Your account has been created successfully!")
                } else {
                    // Check if there's a specific error message from the data controller
                    if let error = dataController.error {
                        showAlert(title: "Registration Failed", message: error.localizedDescription)
                    } else {
                        showAlert(title: "Registration Failed", message: "Unable to create your account. The email may already be registered or there might be a connection issue.")
                    }
                }
            } catch {
                isRegistering = false
                showAlert(title: "Registration Failed", message: error.localizedDescription)
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        // Basic email validation
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

#Preview {
    ContentView()
}
