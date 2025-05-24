import Foundation
import Supabase

@MainActor
class SupabaseManager {
    static let shared = SupabaseManager()
    
    private let client: SupabaseClient
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.supabaseURL)!,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
    }
    
    // MARK: - Generic Database Operations
    
    func fetch<T: Decodable>(
        from table: String,
        query: PostgrestQueryBuilder? = nil
    ) async throws -> [T] {
        var queryBuilder = client.database.from(table).select()
        if let customQuery = query {
            queryBuilder = customQuery
        }
        return try await queryBuilder.execute().value
    }
    
    func insert<T: Encodable>(
        into table: String,
        value: T
    ) async throws {
        try await client.database
            .from(table)
            .insert(value)
            .execute()
    }
    
    func update<T: Encodable>(
        table: String,
        value: T,
        match: [String: Any]
    ) async throws {
        try await client.database
            .from(table)
            .update(value)
            .match(match)
            .execute()
    }
    
    func delete(
        from table: String,
        match: [String: Any]
    ) async throws {
        try await client.database
            .from(table)
            .delete()
            .match(match)
            .execute()
    }
    
    // MARK: - Storage Operations
    
    func uploadFile(
        bucket: String,
        path: String,
        file: Data,
        contentType: String
    ) async throws -> String {
        try await client.storage
            .from(bucket)
            .upload(
                path: path,
                file: file,
                options: FileOptions(contentType: contentType)
            )
    }
    
    func downloadFile(
        bucket: String,
        path: String
    ) async throws -> Data {
        try await client.storage
            .from(bucket)
            .download(path: path)
    }
    
    func deleteFile(
        bucket: String,
        path: String
    ) async throws {
        try await client.storage
            .from(bucket)
            .remove(paths: [path])
    }
    
    // MARK: - Real-time Subscriptions
    
    func subscribe(
        to table: String,
        callback: @escaping (RealtimeMessage) -> Void
    ) -> RealtimeChannel {
        return client.realtime
            .channel(.table(table))
            .on(.all) { message in
                callback(message)
            }
            .subscribe()
    }
} 