//
//  ContentView.swift
//  Fiesta
//
//  Created by Chandramohan on 22/05/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var dataController = DataController()
    @State private var isAuthenticated = false
    @State private var email = ""
    @State private var password = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        if isAuthenticated {
            // Main app interface
            MainTabView()
                .environmentObject(dataController)
                .onAppear {
                    // Set up notification observer for logout
                    NotificationCenter.default.addObserver(
                        forName: Notification.Name("LogoutUser"),
                        object: nil,
                        queue: .main) { _ in
                            isAuthenticated = false
                    }
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
                            .foregroundColor(Color("PrimaryColor"))
                        
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
                            Text("Log In")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("PrimaryColor"))
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            // Use demo credentials
                            email = "student1@test.com"
                            password = "password"
                            login()
                        }) {
                            Text("Use Demo Account")
                                .fontWeight(.medium)
                                .foregroundColor(Color("PrimaryColor"))
                        }
                        
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                // Forgot password action
                            }) {
                                Text("Forgot Password?")
                                    .fontWeight(.medium)
                                    .foregroundColor(Color("PrimaryColor"))
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
                                    .foregroundColor(Color("PrimaryColor"))
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
                            .background(Color("PrimaryColor"))
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
                    .foregroundColor(Color("PrimaryColor"))
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
        let success = dataController.registerUser(name: name, email: email, password: password)
        
        if success {
            registrationSuccess = true
            showAlert(title: "Registration Success", message: "Your account has been created successfully!")
        } else {
            showAlert(title: "Registration Failed", message: "This email may already be registered.")
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
