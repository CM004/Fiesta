import Foundation

/// Utility class to validate Supabase API keys and diagnose connection issues
class SupabaseKeyValidator {
    /// Validates the Supabase API key by making a simple health check request
    /// - Returns: A tuple containing (isValid, errorMessage)
    static func validateApiKey() async -> (isValid: Bool, errorMessage: String?) {
        let url = URL(string: "\(SupabaseConfig.supabaseURL)/auth/v1/health")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("apikey \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "apikey")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let responseString = String(data: data, encoding: .utf8) ?? ""
                print("Health check response: \(responseString)")
                
                if (200...299).contains(httpResponse.statusCode) {
                    print("API key validation successful")
                    return (true, nil)
                } else if responseString.contains("Invalid API key") {
                    print("API key is invalid")
                    return (false, "Invalid API key. Please check your Supabase configuration.")
                } else {
                    print("API health check failed with status code: \(httpResponse.statusCode)")
                    return (false, "API health check failed: \(responseString)")
                }
            }
            
            return (false, "Could not validate API key")
        } catch {
            print("API key validation error: \(error.localizedDescription)")
            return (false, "Connection error: \(error.localizedDescription)")
        }
    }
    
    /// Tests a direct login request to diagnose authentication issues
    /// - Parameters:
    ///   - email: Test email to use
    ///   - password: Test password to use
    /// - Returns: A tuple containing (success, errorMessage, responseData)
    static func testDirectLogin(email: String, password: String) async -> (success: Bool, errorMessage: String?, responseData: [String: Any]?) {
        var request = URLRequest(url: URL(string: "\(SupabaseConfig.supabaseURL)/auth/v1/token?grant_type=password")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("apikey \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            let responseString = String(data: data, encoding: .utf8) ?? ""
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Direct login test response code: \(httpResponse.statusCode)")
                print("Response: \(responseString)")
                
                if let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if (200...299).contains(httpResponse.statusCode) {
                        return (true, nil, jsonResponse)
                    } else if responseString.contains("Invalid API key") {
                        return (false, "Invalid API key. Please check your Supabase configuration.", jsonResponse)
                    } else if responseString.contains("invalid_credentials") {
                        return (false, "Invalid credentials", jsonResponse)
                    } else {
                        return (false, "Login failed: \(responseString)", jsonResponse)
                    }
                } else {
                    return (false, "Failed to parse response: \(responseString)", nil)
                }
            }
            
            return (false, "Unknown error", nil)
        } catch {
            print("Direct login test error: \(error.localizedDescription)")
            return (false, "Connection error: \(error.localizedDescription)", nil)
        }
    }
    
    /// Diagnoses common Supabase connection and authentication issues
    static func diagnosePotentialIssues() async -> [String] {
        var issues: [String] = []
        
        // 1. Check if URL is valid
        guard let url = URL(string: SupabaseConfig.supabaseURL) else {
            issues.append("Invalid Supabase URL format: \(SupabaseConfig.supabaseURL)")
            return issues
        }
        
        // 2. Check if API key is empty or malformed
        if SupabaseConfig.supabaseAnonKey.isEmpty {
            issues.append("Supabase API key is empty")
        } else if !SupabaseConfig.supabaseAnonKey.contains(".") {
            issues.append("Supabase API key appears to be malformed (should be a JWT token)")
        }
        
        // 3. Validate the key with a health check
        let (isValid, errorMessage) = await validateApiKey()
        if !isValid, let message = errorMessage {
            issues.append(message)
        }
        
        // 4. Check network connectivity
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse, 
               !(200...299).contains(httpResponse.statusCode) {
                issues.append("Supabase server returned status code \(httpResponse.statusCode)")
            }
        } catch {
            issues.append("Network connectivity issue: \(error.localizedDescription)")
        }
        
        return issues.isEmpty ? ["No issues detected"] : issues
    }
} 