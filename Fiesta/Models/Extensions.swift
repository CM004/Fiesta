import Foundation
import Supabase

// Extension to handle JSON dictionaries in Codable models
extension JSONDecoder {
    func decode<T: Decodable>(_ type: T.Type, from dictionary: [String: Any]) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
        return try decode(type, from: data)
    }
}

// Extension to make Supabase responses easier to decode
extension PostgrestResponse {
    func decoded<T: Decodable>(as type: T.Type) throws -> T {
        // Get data from response, with safe unwrapping
        guard let data = try? self.data else {
            // For array types, return an empty array when no data is available
            if type is [Any].Type {
                return [] as! T
            }
            
            throw NSError(domain: "Supabase", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data in response"])
        }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            // For array types, return empty array on decoding error
            if type is [Any].Type {
                return [] as! T
            }
            
            throw error
        }
    }
}

// Helper to convert between snake_case and camelCase for JSON keys
extension JSONDecoder {
    static let snakeCaseDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}

extension JSONEncoder {
    static let snakeCaseEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
} 