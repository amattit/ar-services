//
//  ServiceModels.swift
//  api-registry-descktop
//
//  Created by OpenHands on 01.12.2025.
//

import Foundation

// MARK: - Service Models

struct CreateServiceRequest: Encodable {
    let name: String
    let description: String?
    let owner: String
    let tags: [String]
    let serviceType: ServiceType
    let supportsDatabase: Bool
    let proxy: Bool
}

struct UpdateServiceRequest: Encodable {
    let name: String?
    let description: String?
    let owner: String?
    let tags: [String]?
    let serviceType: ServiceType?
    let supportsDatabase: Bool?
    let proxy: Bool?
}

struct ServiceResponse: Decodable, Identifiable {
    let serviceId: UUID
    let name: String
    let description: String?
    let owner: String
    let tags: [String]
    let serviceType: ServiceType
    let supportsDatabase: Bool
    let proxy: Bool
    let createdAt: Date?
    let updatedAt: Date?
    let environments: [ServiceEnvironmentResponse]?
    
    var id: UUID { serviceId }
}

enum ServiceType: String, Codable, CaseIterable {
    case APPLICATION = "APPLICATION"
    case LIBRARY = "LIBRARY"
    case JOB = "JOB"
    case PROXY = "PROXY"
    
    var displayName: String {
        switch self {
        case .APPLICATION:
            return "Приложение"
        case .LIBRARY:
            return "Библиотека"
        case .JOB:
            return "Задача"
        case .PROXY:
            return "Прокси"
        }
    }
}

// MARK: - Environment Models

struct ServiceEnvironmentResponse: Decodable, Identifiable {
    let environmentId: UUID
    let serviceId: UUID
    let code: String
    let displayName: String
    let host: String
    let config: EnvironmentConfig?
    let status: EnvironmentStatus
    let createdAt: Date?
    let updatedAt: Date?
    
    var id: UUID { environmentId }
}

struct EnvironmentConfig: Codable {
    let timeoutMs: Int?
    let retries: Int?
    let downstreamOverrides: [String: String]?
}

enum EnvironmentStatus: String, Codable, CaseIterable {
    case ACTIVE = "ACTIVE"
    case INACTIVE = "INACTIVE"
    
    var displayName: String {
        switch self {
        case .ACTIVE:
            return "Активное"
        case .INACTIVE:
            return "Неактивное"
        }
    }
}

// MARK: - Dashboard Models

struct DashboardStats {
    let totalServices: Int
    let activeServices: Int
    let endpoints: Int
    let deprecated: Int
}