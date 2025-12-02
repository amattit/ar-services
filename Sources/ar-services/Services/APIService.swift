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
    
    // MARK: - Dependencies API
    
    func fetchDependencies() async throws -> [DependencyResponse] {
        let url = URL(string: "\(baseURL)/dependencies")!
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try decoder.decode([DependencyResponse].self, from: data)
    }
    
    func fetchServiceDependencies(serviceId: UUID) async throws -> [ServiceDependencyResponse] {
        let url = URL(string: "\(baseURL)/services/\(serviceId)/dependencies")!
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try decoder.decode([ServiceDependencyResponse].self, from: data)
    }
    
    func createDependency(_ request: CreateDependencyRequest) async throws -> DependencyResponse {
        let url = URL(string: "\(baseURL)/dependencies")!
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
            return try decoder.decode(DependencyResponse.self, from: data)
        case 409:
            throw APIError.dependencyAlreadyExists
        case 400:
            throw APIError.validationError
        default:
            throw APIError.serverError
        }
    }
    
    func createServiceDependency(serviceId: UUID, request: CreateServiceDependencyRequest) async throws -> ServiceDependencyResponse {
        let url = URL(string: "\(baseURL)/services/\(serviceId)/dependencies")!
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
            return try decoder.decode(ServiceDependencyResponse.self, from: data)
        case 409:
            throw APIError.dependencyAlreadyExists
        case 400:
            throw APIError.validationError
        default:
            throw APIError.serverError
        }
    }
    
    func updateDependency(id: UUID, request: UpdateDependencyRequest) async throws -> DependencyResponse {
        let url = URL(string: "\(baseURL)/dependencies/\(id)")!
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
            return try decoder.decode(DependencyResponse.self, from: data)
        case 404:
            throw APIError.dependencyNotFound
        case 400:
            throw APIError.validationError
        default:
            throw APIError.serverError
        }
    }
    
    func deleteDependency(id: UUID) async throws {
        let url = URL(string: "\(baseURL)/dependencies/\(id)")!
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
            throw APIError.dependencyNotFound
        default:
            throw APIError.serverError
        }
    }
    
    func deleteServiceDependency(serviceId: UUID, dependencyId: UUID, environmentCode: String?) async throws {
        var url = URL(string: "\(baseURL)/services/\(serviceId)/dependencies/\(dependencyId)")!
        
        if let environmentCode = environmentCode {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            components.queryItems = [URLQueryItem(name: "environmentCode", value: environmentCode)]
            url = components.url!
        }
        
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
            throw APIError.dependencyNotFound
        default:
            throw APIError.serverError
        }
    }
    
    func fetchDependencyGraph() async throws -> ServiceDependencyGraphResponse {
        let url = URL(string: "\(baseURL)/dependency-graph/services")!
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try decoder.decode(ServiceDependencyGraphResponse.self, from: data)
    }
    
    // MARK: - Service-to-Service Dependencies
    
    func fetchServiceToServiceDependencies(serviceId: UUID, environmentCode: String? = nil) async throws -> [ServiceToServiceDependencyResponse] {
        var urlComponents = URLComponents(string: "\(baseURL)/services/\(serviceId)/service-dependencies")!
        if let environmentCode = environmentCode {
            urlComponents.queryItems = [URLQueryItem(name: "environmentCode", value: environmentCode)]
        }
        
        let (data, response) = try await session.data(from: urlComponents.url!)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try decoder.decode([ServiceToServiceDependencyResponse].self, from: data)
    }
    
    func createServiceToServiceDependency(consumerServiceId: UUID, request: CreateServiceToServiceDependencyRequest) async throws -> ServiceToServiceDependencyResponse {
        let url = URL(string: "\(baseURL)/services/\(consumerServiceId)/service-dependencies")!
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
            return try decoder.decode(ServiceToServiceDependencyResponse.self, from: data)
        case 409:
            throw APIError.dependencyAlreadyExists
        case 400:
            throw APIError.validationError
        default:
            throw APIError.serverError
        }
    }
    
    func updateServiceToServiceDependency(serviceId: UUID, dependencyId: UUID, request: UpdateServiceToServiceDependencyRequest) async throws -> ServiceToServiceDependencyResponse {
        let url = URL(string: "\(baseURL)/services/\(serviceId)/service-dependencies/\(dependencyId)")!
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
            return try decoder.decode(ServiceToServiceDependencyResponse.self, from: data)
        case 404:
            throw APIError.dependencyNotFound
        case 400:
            throw APIError.validationError
        default:
            throw APIError.serverError
        }
    }
    
    func deleteServiceToServiceDependency(serviceId: UUID, dependencyId: UUID) async throws {
        let url = URL(string: "\(baseURL)/services/\(serviceId)/service-dependencies/\(dependencyId)")!
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
            throw APIError.dependencyNotFound
        default:
            throw APIError.serverError
        }
    }
    
    func fetchServiceDependencyGraph(serviceId: UUID, environmentCode: String? = nil) async throws -> ServiceDependencyGraphResponse {
        var urlComponents = URLComponents(string: "\(baseURL)/services/\(serviceId)/dependency-graph")!
        if let environmentCode = environmentCode {
            urlComponents.queryItems = [URLQueryItem(name: "environmentCode", value: environmentCode)]
        }
        
        let (data, response) = try await session.data(from: urlComponents.url!)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try decoder.decode(ServiceDependencyGraphResponse.self, from: data)
    }
    
    func fetchGlobalDependencyGraph(environmentCode: String? = nil) async throws -> ServiceDependencyGraphResponse {
        var urlComponents = URLComponents(string: "\(baseURL)/dependency-graph")!
        if let environmentCode = environmentCode {
            urlComponents.queryItems = [URLQueryItem(name: "environmentCode", value: environmentCode)]
        }
        
        let (data, response) = try await session.data(from: urlComponents.url!)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try decoder.decode(ServiceDependencyGraphResponse.self, from: data)
    }
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidResponse
    case serviceNotFound
    case serviceAlreadyExists
    case dependencyNotFound
    case dependencyAlreadyExists
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
        case .dependencyNotFound:
            return "Зависимость не найдена"
        case .dependencyAlreadyExists:
            return "Зависимость уже существует"
        case .validationError:
            return "Ошибка валидации данных"
        case .serverError:
            return "Ошибка сервера"
        case .networkError:
            return "Ошибка сети"
        }
    }
}
