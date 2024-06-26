//
//  CoreApiClient.swift
//  sumato
//
//  Created by Nazarii Klymok on 27.04.2024.
//

import Foundation
import Auth0

class CoreAPIClient {
    private let baseURL = "http://172.20.10.11:8080/api/student/"
    static let shared = CoreAPIClient()
    
    func makeRequest<T: Decodable>(urlSuffix: String, method: String, requestBody: [String: Any]? = nil, completion: @escaping (Result<T, Error>) -> Void) async {
        do {
            guard let url = URL(string: baseURL + urlSuffix) else {
                completion(.failure(NetworkError.invalidURL))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = method
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let credentials = try await credentials();
            request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
            
            if let requestBody = requestBody {
                
                let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
                request.httpBody = jsonData
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    completion(.failure(error ?? NetworkError.unknownError))
                    return
                }
                
                do {
                    let decodedObject = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decodedObject))
                } catch {
                    completion(.failure(error))
                }
            }.resume()
        } catch {
            completion(.failure(error))
            return
        }
    }
    
    private func credentials() async throws -> Credentials {
        let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
        
        return try await withCheckedThrowingContinuation { continuation in
            credentialsManager.credentials { result in
                switch result {
                case .success(let credentials):
                    continuation.resume(returning: credentials)
                    break
                    
                case .failure(let reason):
                    continuation.resume(throwing: reason)
                    break
                }
            }
        }
    }
    
    
}
