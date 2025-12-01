//
//  APIService.swift
//  api-registry-descktop
//
//  Created by OpenHands on 01.12.2025.
//

import Foundation

// MARK: - API Service

@MainActor
class APIService: ObservableObject {
    static let shared = APIService()
    
private let baseURL = "http://localhost:8080/api/v1"
    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    private init() {}
    
    // MARK: - Services API
    
    func fetchServices() async throws -> [ServiceResponse] {
        let url = URL(string: "\(baseURL)/services")!
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try decoder.decode([ServiceResponse].self, from: data)
    }
    
    func fetchService(id: UUID) async throws -> ServiceResponse {
        let url = URL(string: "\(baseURL)/services/\(id)")!
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serviceNotFound
        }
        
        return try decoder.decode(ServiceResponse.self, from: data)
    }
    
    func createService(_ request: CreateServiceRequest) async throws -> ServiceResponse {
        let url = URL(string: "\(baseURL)/services")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200, 201:
            return try decoder.decode(ServiceResponse.self, from: data)
        case 409:
            throw APIError.serviceAlreadyExists
        case 400:
            throw APIError.validationError
        default:
            throw APIError.serverError
        }
    }
    
    func updateService(id: UUID, request: UpdateServiceRequest) async throws -> ServiceResponse {
        let url = URL(string: "\(baseURL)/services/\(id)")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PATCH"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try decoder.decode(ServiceResponse.self, from: data)
        case 404:
            throw APIError.serviceNotFound
        case 409:
            throw APIError.serviceAlreadyExists
        case 400:
            throw APIError.validationError
        default:
            throw APIError.serverError
        }
    }
    
    func deleteService(id: UUID) async throws {
        let url = URL(string: "\(baseURL)/services/\(id)")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        
        let (_, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 204:
            return
        case 404:
            throw APIError.serviceNotFound
        default:
            throw APIError.serverError
        }
    }
    
    // MARK: - Dashboard Stats
    
    func fetchDashboardStats() async throws -> DashboardStats {
        let services = try await fetchServices()
        
        let totalServices = services.count
        let activeServices = services.filter { service in
            service.environments?.contains { $0.status == .ACTIVE } ?? false
        }.count
        
        // Для простоты используем заглушки для endpoints и deprecated
        let endpoints = services.reduce(0) { total, service in
            total + (service.environments?.count ?? 0)
        }
        
        let deprecated = services.filter { $0.serviceType == .LIBRARY }.count
        
        return DashboardStats(
            totalServices: totalServices,
            activeServices: activeServices,
            endpoints: endpoints,
            deprecated: deprecated
        )
    }
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidResponse
    case serviceNotFound
    case serviceAlreadyExists
    case validationError
    case serverError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .serviceNotFound:
            return "Сервис не найден"
        case .serviceAlreadyExists:
            return "Сервис с таким именем уже существует"
        case .validationError:
            return "Ошибка валидации данных"
        case .serverError:
            return "Ошибка сервера"
        case .networkError:
            return "Ошибка сети"
        }
    }
}
