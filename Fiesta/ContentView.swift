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
        DispatchQueue.main.async {
            // This is a backup - dataController already cleared the user
            if dataController.currentUser != nil {
                dataController.logout()
            }
        }
    }
    
    private func handleLogin() {
        // For demo purposes, we'll automatically log in with the first user
        // In a real app, this would validate credentials against a backend
        if dataController.login(email: email, password: password) {
            isAuthenticated = true
        } else {
            errorMessage = "Invalid email or password"
            showingError = true
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
    @State private var isEmailFocused = false
    @State private var isPasswordFocused = false
    @State private var isLoading = false
    let login: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("FiestaPrimary").opacity(0.1),
                        Color.white
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 35) {
                        // Logo and Title Section
                        VStack(spacing: 15) {
                            Image(systemName: "leaf.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120, height: 120)
                                .foregroundColor(Color("FiestaPrimary"))
                                .shadow(color: Color("FiestaPrimary").opacity(0.3), radius: 10)
                                .padding(.top, 50)
                            
                            Text("Fiesta")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(Color("FiestaPrimary"))
                            
                            Text("Reduce Food Waste, Together")
                                .font(.title3)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Login Form
                        VStack(spacing: 25) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding(.leading, 4)
                                
                                TextField("", text: $email)
                                    .textFieldStyle(CustomTextFieldStyle(isFocused: $isEmailFocused))
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .onTapGesture { isEmailFocused = true }
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding(.leading, 4)
                                
                                SecureField("", text: $password)
                                    .textFieldStyle(CustomTextFieldStyle(isFocused: $isPasswordFocused))
                                    .onTapGesture { isPasswordFocused = true }
                            }
                            
                            // Login Button
                            Button(action: {
                                withAnimation {
                                    isLoading = true
                                    login()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        isLoading = false
                                    }
                                }
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color("FiestaPrimary"))
                                        .frame(height: 55)
                                        .shadow(color: Color("FiestaPrimary").opacity(0.3), radius: 5)
                                    
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Log In")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .disabled(isLoading)
                            
                            // Demo Account Button
                            Button(action: {
                                email = "student1@test.com"
                                password = "password"
                                login()
                            }) {
                                Text("Use Demo Account")
                                    .font(.subheadline)
                                    .foregroundColor(Color("FiestaPrimary"))
                                    .padding(.vertical, 8)
                            }
                            
                            // Forgot Password
                            Button(action: {
                                // Forgot password action
                            }) {
                                Text("Forgot Password?")
                                    .font(.subheadline)
                                    .foregroundColor(Color("FiestaPrimary"))
                            }
                        }
                        .padding(.horizontal, 25)
                        
                        Spacer()
                        
                        // Sign Up Section
                        VStack(spacing: 20) {
                            Divider()
                                .padding(.horizontal)
                            
                            HStack(spacing: 5) {
                                Text("Don't have an account?")
                                    .foregroundColor(.gray)
                                
                                Button(action: {
                                    withAnimation {
                                        showingSignup = true
                                    }
                                }) {
                                    Text("Sign Up")
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color("FiestaPrimary"))
                                }
                            }
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
            .alert(isPresented: $showingError) {
                Alert(
                    title: Text("Login Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

// Custom TextField Style
struct CustomTextFieldStyle: TextFieldStyle {
    @Binding var isFocused: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isFocused ? Color("FiestaPrimary") : Color.clear, lineWidth: 2)
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
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
    @State private var showingOnboarding = false
    
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
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    // Signup button
                    Button(action: handleSignup) {
                        Text("Sign Up")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("FiestaPrimary"))
                            .cornerRadius(10)
                    }
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
                        showOnboarding()
                    }
                }
            )
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView(onComplete: {
                // Only pass true to onSignupComplete to finalize registration
                // after onboarding is complete
                onSignupComplete(true)
                presentationMode.wrappedValue.dismiss()
            })
            .environmentObject(dataController)
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
        let success = dataController.registerUser(name: name, email: email, password: password)
        
        if success {
            registrationSuccess = true
            // Show onboarding immediately instead of showing alert first
            showOnboarding()
        } else {
            showAlert(title: "Registration Failed", message: "This email may already be registered.")
        }
    }
    
    private func showOnboarding() {
        showingOnboarding = true
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
