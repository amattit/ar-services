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

// MARK: - Dependency Models

struct DependencyResponse: Decodable, Identifiable {
    let dependencyId: UUID
    let name: String
    let description: String?
    let version: String
    let dependencyType: DependencyType
    let config: [String: String]
    let createdAt: Date?
    let updatedAt: Date?
    
    var id: UUID { dependencyId }
}

struct CreateDependencyRequest: Encodable {
    let name: String
    let description: String?
    let version: String
    let dependencyType: DependencyType
    let config: [String: String]
}

struct UpdateDependencyRequest: Encodable {
    let name: String?
    let description: String?
    let version: String?
    let dependencyType: DependencyType?
    let config: [String: String]?
}

struct ServiceDependencyResponse: Decodable, Identifiable {
    let serviceDependencyId: UUID
    let serviceId: UUID
    let dependency: DependencyResponse
    let environmentCode: String?
    let configOverride: [String: String]
    let createdAt: Date?
    let updatedAt: Date?
    
    var id: UUID { serviceDependencyId }
}

struct CreateServiceDependencyRequest: Encodable {
    let dependencyId: UUID
    let environmentCode: String?
    let configOverride: [String: String]
}

// MARK: - Service-to-Service Dependency Models

struct ServiceToServiceDependencyResponse: Decodable, Identifiable {
    let id: UUID
    let consumerService: ServiceSummary
    let providerService: ServiceSummary
    let environmentCode: String?
    let description: String?
    let dependencyType: ServiceDependencyType
    let config: [String: String]
    let createdAt: Date?
    let updatedAt: Date?
}

struct ServiceSummary: Decodable {
    let id: UUID
    let name: String
    let description: String?
    let serviceType: ServiceType
    let owner: String
}


struct CreateServiceToServiceDependencyRequest: Encodable {
    let providerServiceId: UUID
    let environmentCode: String?
    let description: String?
    let dependencyType: ServiceDependencyType
    let config: [String: String]
}

struct UpdateServiceToServiceDependencyRequest: Encodable {
    let providerServiceId: UUID?
    let environmentCode: String?
    let description: String?
    let dependencyType: ServiceDependencyType?
    let config: [String: String]?
}

enum DependencyType: String, Codable, CaseIterable {
    case LIBRARY = "LIBRARY"
    case SERVICE = "SERVICE"
    case DATABASE = "DATABASE"
    case EXTERNAL_API = "EXTERNAL_API"
    case MESSAGE_QUEUE = "MESSAGE_QUEUE"
    
    var displayName: String {
        switch self {
        case .LIBRARY:
            return "Библиотека"
        case .SERVICE:
            return "Сервис"
        case .DATABASE:
            return "База данных"
        case .EXTERNAL_API:
            return "Внешний API"
        case .MESSAGE_QUEUE:
            return "Очередь сообщений"
        }
    }
    
    var description: String {
        switch self {
        case .LIBRARY:
            return "программная библиотека или пакет"
        case .SERVICE:
            return "другой микросервис в системе"
        case .DATABASE:
            return "база данных или хранилище"
        case .EXTERNAL_API:
            return "внешний API или веб-сервис"
        case .MESSAGE_QUEUE:
            return "система очередей сообщений"
        }
    }
    
    var icon: String {
        switch self {
        case .LIBRARY:
            return "books.vertical"
        case .SERVICE:
            return "cube"
        case .DATABASE:
            return "cylinder"
        case .EXTERNAL_API:
            return "network"
        case .MESSAGE_QUEUE:
            return "tray.2"
        }
    }
}

enum ServiceDependencyType: String, Codable, CaseIterable {
    case API_CALL = "API_CALL"
    case EVENT_SUBSCRIPTION = "EVENT_SUBSCRIPTION"
    case DATA_SHARING = "DATA_SHARING"
    case AUTHENTICATION = "AUTHENTICATION"
    case PROXY = "PROXY"
    case LIBRARY_USAGE = "LIBRARY_USAGE"
    
    var displayName: String {
        switch self {
        case .API_CALL:
            return "Вызовы API"
        case .EVENT_SUBSCRIPTION:
            return "Подписка на события"
        case .DATA_SHARING:
            return "Совместное использование данных"
        case .AUTHENTICATION:
            return "Аутентификация"
        case .PROXY:
            return "Проксирование запросов"
        case .LIBRARY_USAGE:
            return "Использование библиотек"
        }
    }
    
    var description: String {
        switch self {
        case .API_CALL:
            return "прямые HTTP вызовы между сервисами"
        case .EVENT_SUBSCRIPTION:
            return "подписка на события других сервисов"
        case .DATA_SHARING:
            return "совместное использование данных"
        case .AUTHENTICATION:
            return "аутентификация через другой сервис"
        case .PROXY:
            return "проксирование запросов через сервис"
        case .LIBRARY_USAGE:
            return "использование библиотек другого сервиса"
        }
    }
    
    var icon: String {
        switch self {
        case .API_CALL:
            return "arrow.right.circle"
        case .EVENT_SUBSCRIPTION:
            return "bell.fill"
        case .DATA_SHARING:
            return "square.and.arrow.up.on.square"
        case .AUTHENTICATION:
            return "key.fill"
        case .PROXY:
            return "arrow.triangle.swap"
        case .LIBRARY_USAGE:
            return "book.closed.fill"
        }
    }
}

// MARK: - Dependency Graph Models

struct ServiceDependencyGraphResponse: Decodable {
    let nodes: [DependencyNode]
    let edges: [DependencyEdge]
    let metadata: [String: AnyCodable]
}

struct DependencyNode: Decodable, Identifiable {
    let id: String
    let name: String
    let type: String
    let serviceType: String?
    let metadata: [String: AnyCodable]
    
    var uuid: UUID {
        UUID(uuidString: id) ?? UUID()
    }
    
    var displayName: String { name }
}

struct DependencyEdge: Decodable, Identifiable {
    let from: String
    let to: String
    let type: String
    let metadata: [String: AnyCodable]
    
    var id: String { "\(from)-\(to)" }
    
    var fromUUID: UUID {
        UUID(uuidString: from) ?? UUID()
    }
    
    var toUUID: UUID {
        UUID(uuidString: to) ?? UUID()
    }
}

// MARK: - Endpoint Models

enum EndpointMethod: String, Codable, CaseIterable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
    case HEAD = "HEAD"
    case OPTIONS = "OPTIONS"
    
    var displayName: String {
        return rawValue
    }
    
    var color: String {
        switch self {
        case .GET:
            return "blue"
        case .POST:
            return "green"
        case .PUT:
            return "orange"
        case .PATCH:
            return "purple"
        case .DELETE:
            return "red"
        case .HEAD:
            return "gray"
        case .OPTIONS:
            return "gray"
        }
    }
}

enum CallType: String, Codable, CaseIterable {
    case SYNC = "SYNC"
    case ASYNC = "ASYNC"
    case CALLBACK = "CALLBACK"
    
    var displayName: String {
        switch self {
        case .SYNC:
            return "Синхронный"
        case .ASYNC:
            return "Асинхронный"
        case .CALLBACK:
            return "Обратный вызов"
        }
    }
}

enum OperationType: String, Codable, CaseIterable {
    case read = "READ"
    case write = "WRITE"
    case readWrite = "READ_WRITE"
    
    var displayName: String {
        switch self {
        case .read:
            return "Чтение"
        case .write:
            return "Запись"
        case .readWrite:
            return "Чтение/Запись"
        }
    }
}

struct EndpointResponse: Decodable, Identifiable {
    let endpointId: UUID
    let serviceId: UUID
    let method: EndpointMethod
    let path: String
    let summary: String
    let requestSchema: [String: AnyCodable]?
    let responseSchemas: [String: AnyCodable]?
    let auth: [String: AnyCodable]?
    let rateLimit: [String: AnyCodable]?
    let metadata: [String: AnyCodable]?
    let calls: [EndpointCallResponse]?
    let databases: [EndpointDatabaseResponse]?
    let createdAt: Date
    let updatedAt: Date
    
    var id: UUID { endpointId }
    
    var fullPath: String {
        return "\(method.rawValue) \(path)"
    }
}

struct EndpointCallResponse: Decodable, Identifiable {
    let dependencyId: UUID
    let callType: CallType
    let config: [String: AnyCodable]?
    let dependency: DependencyResponse
    
    var id: UUID { dependencyId }
}

struct EndpointDatabaseResponse: Decodable, Identifiable {
    let databaseId: UUID
    let operationType: OperationType
    let tableNames: [String]?
    let config: [String: AnyCodable]?
    let database: DatabaseResponse
    
    var id: UUID { databaseId }
}

struct DatabaseResponse: Decodable, Identifiable {
    let databaseId: UUID
    let name: String
    let description: String?
    let databaseType: String
    let host: String
    let port: Int
    let databaseName: String
    let config: [String: AnyCodable]?
    let createdAt: Date?
    let updatedAt: Date?
    
    var id: UUID { databaseId }
}

struct AnyCodable: Codable {
    let value: Any
    
    init<T>(_ value: T?) {
        self.value = value ?? ()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.value = ()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is Void:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded")
            throw EncodingError.invalidValue(value, context)
        }
    }
}
