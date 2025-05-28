import SwiftUI

struct SupabaseDiagnosticsView: View {
    @State private var isRunningTests = false
    @State private var diagnosisResults: [String] = []
    @State private var apiKeyStatus: String = "Not Checked"
    @State private var testEmail = "test@example.com"
    @State private var testPassword = "password123"
    @State private var loginTestResult: String = "Not Tested"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Supabase Diagnostics")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                // Configuration Section
                configSection
                
                // Status Section
                statusSection
                
                // Tests Section
                testsSection
                
                // Login Test Section
                loginTestSection
                
                // Results Section
                if !diagnosisResults.isEmpty {
                    resultsSection
                }
            }
            .padding()
        }
        .navigationTitle("Supabase Diagnostics")
    }
    
    private var configSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Configuration")
                .font(.headline)
            
            HStack {
                Text("URL:")
                    .fontWeight(.medium)
                Spacer()
                Text(SupabaseConfig.supabaseURL)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("API Key:")
                    .fontWeight(.medium)
                Spacer()
                Text(SupabaseConfig.supabaseAnonKey.prefix(15) + "..." + SupabaseConfig.supabaseAnonKey.suffix(10))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("API Key Status")
                .font(.headline)
            
            HStack {
                Text("Status:")
                    .fontWeight(.medium)
                Spacer()
                Text(apiKeyStatus)
                    .foregroundColor(apiKeyStatus == "Valid" ? .green : apiKeyStatus == "Invalid" ? .red : .orange)
            }
            
            Button(action: {
                validateApiKey()
            }) {
                Text("Check API Key")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(isRunningTests)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var testsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Diagnostic Tests")
                .font(.headline)
            
            Button(action: {
                runDiagnostics()
            }) {
                Text("Run All Diagnostics")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(isRunningTests)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var loginTestSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Login Test")
                .font(.headline)
            
            TextField("Test Email", text: $testEmail)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            SecureField("Test Password", text: $testPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            HStack {
                Text("Result:")
                    .fontWeight(.medium)
                Spacer()
                Text(loginTestResult)
                    .foregroundColor(loginTestResult.contains("Success") ? .green : loginTestResult == "Not Tested" ? .orange : .red)
            }
            
            Button(action: {
                testLogin()
            }) {
                Text("Test Login")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(isRunningTests)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Diagnosis Results")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(diagnosisResults, id: \.self) { result in
                    HStack(alignment: .top) {
                        Image(systemName: result.contains("No issues") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(result.contains("No issues") ? .green : .orange)
                            .font(.system(size: 16))
                            .frame(width: 20)
                        
                        Text(result)
                            .foregroundColor(result.contains("No issues") ? .green : .primary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Functions
    
    private func validateApiKey() {
        isRunningTests = true
        apiKeyStatus = "Checking..."
        
        Task {
            let (isValid, message) = await SupabaseKeyValidator.validateApiKey()
            
            DispatchQueue.main.async {
                apiKeyStatus = isValid ? "Valid" : "Invalid: \(message ?? "Unknown error")"
                isRunningTests = false
            }
        }
    }
    
    private func runDiagnostics() {
        isRunningTests = true
        diagnosisResults = ["Running diagnostics..."]
        
        Task {
            let issues = await SupabaseKeyValidator.diagnosePotentialIssues()
            
            DispatchQueue.main.async {
                diagnosisResults = issues
                isRunningTests = false
            }
        }
    }
    
    private func testLogin() {
        isRunningTests = true
        loginTestResult = "Testing..."
        
        Task {
            let (success, errorMessage, _) = await SupabaseKeyValidator.testDirectLogin(
                email: testEmail,
                password: testPassword
            )
            
            DispatchQueue.main.async {
                if success {
                    loginTestResult = "Success: Login worked"
                } else {
                    loginTestResult = "Failed: \(errorMessage ?? "Unknown error")"
                }
                isRunningTests = false
            }
        }
    }
}

struct SupabaseDiagnosticsView_Previews: PreviewProvider {
    static var previews: some View {
        SupabaseDiagnosticsView()
    }
} 