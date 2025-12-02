//
//  MockAPIService.swift
//  ar-services
//
//  Created by OpenHands on 01.12.2025.
//

import Foundation

// MARK: - Mock API Service for Testing

@MainActor
class MockAPIService: ObservableObject {
    static let shared = MockAPIService()
    
    private var mockServices: [ServiceResponse] = []
    private var mockDependencies: [DependencyResponse] = []
    private var mockServiceDependencies: [ServiceDependencyResponse] = []
    private var mockServiceToServiceDependencies: [ServiceToServiceDependencyResponse] = []
    
    private init() {
        setupMockData()
    }
    
    // MARK: - Services API
    
    func fetchServices() async throws -> [ServiceResponse] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        return mockServices
    }
    
    func fetchService(id: UUID) async throws -> ServiceResponse {
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard let service = mockServices.first(where: { $0.serviceId == id }) else {
            throw APIError.serviceNotFound
        }
        
        return service
    }
    
    func createService(_ request: CreateServiceRequest) async throws -> ServiceResponse {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Check if service already exists
        if mockServices.contains(where: { $0.name == request.name }) {
            throw APIError.serviceAlreadyExists
        }
        
        let newService = ServiceResponse(
            serviceId: UUID(),
            name: request.name,
            description: request.description,
            owner: request.owner,
            tags: request.tags,
            serviceType: request.serviceType,
            supportsDatabase: request.supportsDatabase,
            proxy: request.proxy,
            createdAt: Date(),
            updatedAt: Date(),
            environments: []
        )
        
        mockServices.append(newService)
        return newService
    }
    
    func updateService(id: UUID, request: UpdateServiceRequest) async throws -> ServiceResponse {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard let index = mockServices.firstIndex(where: { $0.serviceId == id }) else {
            throw APIError.serviceNotFound
        }
        
        let existingService = mockServices[index]
        let updatedService = ServiceResponse(
            serviceId: existingService.serviceId,
            name: request.name ?? existingService.name,
            description: request.description ?? existingService.description,
            owner: request.owner ?? existingService.owner,
            tags: request.tags ?? existingService.tags,
            serviceType: request.serviceType ?? existingService.serviceType,
            supportsDatabase: request.supportsDatabase ?? existingService.supportsDatabase,
            proxy: request.proxy ?? existingService.proxy,
            createdAt: existingService.createdAt,
            updatedAt: Date(),
            environments: existingService.environments
        )
        
        mockServices[index] = updatedService
        return updatedService
    }
    
    func deleteService(id: UUID) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard let index = mockServices.firstIndex(where: { $0.serviceId == id }) else {
            throw APIError.serviceNotFound
        }
        
        mockServices.remove(at: index)
        
        // Also remove related dependencies
        mockDependencies.removeAll { dependency in
            dependency.id == id || dependency.dependencyId == id
        }
    }
    
    // MARK: - Dependencies API
    
    func fetchDependencies() async throws -> [DependencyResponse] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return mockDependencies
    }
    
    func fetchServiceDependencies(serviceId: UUID) async throws -> [ServiceDependencyResponse] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return mockServiceDependencies.filter { $0.serviceId == serviceId }
    }
    
    func createDependency(_ request: CreateDependencyRequest) async throws -> DependencyResponse {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Check if dependency already exists
        if mockDependencies.contains(where: { 
            $0.name == request.name && $0.version == request.version
        }) {
            throw APIError.dependencyAlreadyExists
        }
        
        let newDependency = DependencyResponse(
            dependencyId: UUID(),
            name: request.name,
            description: request.description,
            version: request.version,
            dependencyType: request.dependencyType,
            config: request.config,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        mockDependencies.append(newDependency)
        return newDependency
    }
    
    func createServiceDependency(serviceId: UUID, request: CreateServiceDependencyRequest) async throws -> ServiceDependencyResponse {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Check if service dependency already exists
        if mockServiceDependencies.contains(where: { 
            $0.serviceId == serviceId && 
            $0.dependency.dependencyId == request.dependencyId &&
            $0.environmentCode == request.environmentCode
        }) {
            throw APIError.dependencyAlreadyExists
        }
        
        guard let dependency = mockDependencies.first(where: { $0.dependencyId == request.dependencyId }) else {
            throw APIError.dependencyNotFound
        }
        
        let newServiceDependency = ServiceDependencyResponse(
            serviceDependencyId: UUID(),
            serviceId: serviceId,
            dependency: dependency,
            environmentCode: request.environmentCode,
            configOverride: request.configOverride,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        mockServiceDependencies.append(newServiceDependency)
        return newServiceDependency
    }
    
    func updateDependency(id: UUID, request: UpdateDependencyRequest) async throws -> DependencyResponse {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard let index = mockDependencies.firstIndex(where: { $0.dependencyId == id }) else {
            throw APIError.dependencyNotFound
        }
        
        let existingDependency = mockDependencies[index]
        let updatedDependency = DependencyResponse(
            dependencyId: existingDependency.dependencyId,
            name: request.name ?? existingDependency.name,
            description: request.description ?? existingDependency.description,
            version: request.version ?? existingDependency.version,
            dependencyType: request.dependencyType ?? existingDependency.dependencyType,
            config: request.config ?? existingDependency.config,
            createdAt: existingDependency.createdAt,
            updatedAt: Date()
        )
        
        mockDependencies[index] = updatedDependency
        return updatedDependency
    }
    
    func deleteDependency(id: UUID) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard let index = mockDependencies.firstIndex(where: { $0.dependencyId == id }) else {
            throw APIError.dependencyNotFound
        }
        
        mockDependencies.remove(at: index)
        
        // Also remove related service dependencies
        mockServiceDependencies.removeAll { $0.dependency.dependencyId == id }
    }
    
    func deleteServiceDependency(serviceId: UUID, dependencyId: UUID, environmentCode: String?) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard let index = mockServiceDependencies.firstIndex(where: { 
            $0.serviceId == serviceId && 
            $0.dependency.dependencyId == dependencyId &&
            $0.environmentCode == environmentCode
        }) else {
            throw APIError.dependencyNotFound
        }
        
        mockServiceDependencies.remove(at: index)
    }
    
    func fetchDependencyGraph() async throws -> ServiceDependencyGraphResponse {
        try await Task.sleep(nanoseconds: 800_000_000)
        
        let nodes = mockServices.map { service in
            DependencyNode(
                id: service.serviceId.uuidString,
                name: service.name,
                type: "service",
                serviceType: service.serviceType.rawValue,
                metadata: [
                    "description": AnyCodable(service.description),
                    "owner": AnyCodable(service.owner),
                    "tags": AnyCodable(service.tags)
                ]
            )
        }
        
        let edges = mockServiceDependencies.map { serviceDep in
            DependencyEdge(
                from: serviceDep.serviceId.uuidString,
                to: serviceDep.dependency.dependencyId.uuidString,
                type: "service_dependency",
                metadata: [
                    "dependencyType": AnyCodable(serviceDep.dependency.dependencyType.rawValue),
                    "version": AnyCodable(serviceDep.dependency.version)
                ]
            )
        }
        
        return ServiceDependencyGraphResponse(
            nodes: nodes,
            edges: edges,
            metadata: [
                "totalServices": AnyCodable(mockServices.count),
                "totalDependencies": AnyCodable(edges.count),
                "generatedAt": AnyCodable(ISO8601DateFormatter().string(from: Date()))
            ]
        )
    }
    
    // MARK: - Dashboard Stats
    
    func fetchDashboardStats() async throws -> DashboardStats {
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let totalServices = mockServices.count
        let activeServices = mockServices.filter { service in
            service.environments?.contains { $0.status == .ACTIVE } ?? false
        }.count
        
        let endpoints = mockServices.reduce(0) { total, service in
            total + (service.environments?.count ?? 0)
        }
        
        let deprecated = mockServices.filter { $0.serviceType == .LIBRARY }.count
        
        return DashboardStats(
            totalServices: totalServices,
            activeServices: activeServices,
            endpoints: endpoints,
            deprecated: deprecated
        )
    }
    
    // MARK: - Setup Mock Data
    
    private func setupMockData() {
        // Create mock services
        let userService = ServiceResponse(
            serviceId: UUID(),
            name: "user-service",
            description: "Сервис управления пользователями",
            owner: "backend-team",
            tags: ["users", "authentication", "core"],
            serviceType: .APPLICATION,
            supportsDatabase: true,
            proxy: false,
            createdAt: Calendar.current.date(byAdding: .day, value: -30, to: Date()),
            updatedAt: Date(),
            environments: [
                ServiceEnvironmentResponse(
                    environmentId: UUID(),
                    serviceId: UUID(),
                    code: "prod",
                    displayName: "Production",
                    host: "https://user-service.prod.example.com",
                    config: EnvironmentConfig(timeoutMs: 5000, retries: 3, downstreamOverrides: nil),
                    status: .ACTIVE,
                    createdAt: Date(),
                    updatedAt: Date()
                )
            ]
        )
        
        let authService = ServiceResponse(
            serviceId: UUID(),
            name: "auth-service",
            description: "Сервис аутентификации пользователей",
            owner: "security-team",
            tags: ["auth", "security", "jwt"],
            serviceType: .APPLICATION,
            supportsDatabase: true,
            proxy: false,
            createdAt: Calendar.current.date(byAdding: .day, value: -25, to: Date()),
            updatedAt: Date(),
            environments: [
                ServiceEnvironmentResponse(
                    environmentId: UUID(),
                    serviceId: UUID(),
                    code: "prod",
                    displayName: "Production",
                    host: "https://auth-service.prod.example.com",
                    config: EnvironmentConfig(timeoutMs: 3000, retries: 2, downstreamOverrides: nil),
                    status: .ACTIVE,
                    createdAt: Date(),
                    updatedAt: Date()
                )
            ]
        )
        
        let orderService = ServiceResponse(
            serviceId: UUID(),
            name: "order-service",
            description: "Сервис обработки заказов",
            owner: "commerce-team",
            tags: ["orders", "commerce", "business"],
            serviceType: .APPLICATION,
            supportsDatabase: true,
            proxy: false,
            createdAt: Calendar.current.date(byAdding: .day, value: -20, to: Date()),
            updatedAt: Date(),
            environments: [
                ServiceEnvironmentResponse(
                    environmentId: UUID(),
                    serviceId: UUID(),
                    code: "prod",
                    displayName: "Production",
                    host: "https://order-service.prod.example.com",
                    config: EnvironmentConfig(timeoutMs: 8000, retries: 3, downstreamOverrides: nil),
                    status: .ACTIVE,
                    createdAt: Date(),
                    updatedAt: Date()
                )
            ]
        )
        
        let paymentService = ServiceResponse(
            serviceId: UUID(),
            name: "payment-service",
            description: "Сервис обработки платежей",
            owner: "payments-team",
            tags: ["payments", "billing", "financial"],
            serviceType: .APPLICATION,
            supportsDatabase: true,
            proxy: false,
            createdAt: Calendar.current.date(byAdding: .day, value: -15, to: Date()),
            updatedAt: Date(),
            environments: [
                ServiceEnvironmentResponse(
                    environmentId: UUID(),
                    serviceId: UUID(),
                    code: "prod",
                    displayName: "Production",
                    host: "https://payment-service.prod.example.com",
                    config: EnvironmentConfig(timeoutMs: 10000, retries: 5, downstreamOverrides: nil),
                    status: .ACTIVE,
                    createdAt: Date(),
                    updatedAt: Date()
                )
            ]
        )
        
        mockServices = [userService, authService, orderService, paymentService]
        
        // Create mock dependencies (libraries, external services, etc.)
        let jwtLibrary = DependencyResponse(
            dependencyId: UUID(),
            name: "jwt-library",
            description: "Библиотека для работы с JWT токенами",
            version: "3.2.1",
            dependencyType: .LIBRARY,
            config: ["algorithm": "HS256", "expiration": "24h"],
            createdAt: Calendar.current.date(byAdding: .day, value: -30, to: Date()),
            updatedAt: Date()
        )
        
        let postgresDB = DependencyResponse(
            dependencyId: UUID(),
            name: "postgresql",
            description: "Основная база данных PostgreSQL",
            version: "14.5",
            dependencyType: .DATABASE,
            config: ["host": "localhost", "port": "5432", "ssl": "require"],
            createdAt: Calendar.current.date(byAdding: .day, value: -25, to: Date()),
            updatedAt: Date()
        )
        
        let redisCache = DependencyResponse(
            dependencyId: UUID(),
            name: "redis",
            description: "Кэш и хранилище сессий",
            version: "7.0",
            dependencyType: .DATABASE,
            config: ["host": "localhost", "port": "6379", "ttl": "3600"],
            createdAt: Calendar.current.date(byAdding: .day, value: -20, to: Date()),
            updatedAt: Date()
        )
        
        let rabbitMQ = DependencyResponse(
            dependencyId: UUID(),
            name: "rabbitmq",
            description: "Система очередей сообщений",
            version: "3.11",
            dependencyType: .MESSAGE_QUEUE,
            config: ["host": "localhost", "port": "5672", "vhost": "/"],
            createdAt: Calendar.current.date(byAdding: .day, value: -15, to: Date()),
            updatedAt: Date()
        )
        
        let stripeAPI = DependencyResponse(
            dependencyId: UUID(),
            name: "stripe-api",
            description: "Внешний API для обработки платежей",
            version: "2023-10-16",
            dependencyType: .EXTERNAL_API,
            config: ["base_url": "https://api.stripe.com", "version": "2023-10-16"],
            createdAt: Calendar.current.date(byAdding: .day, value: -10, to: Date()),
            updatedAt: Date()
        )
        
        mockDependencies = [jwtLibrary, postgresDB, redisCache, rabbitMQ, stripeAPI]
        
        // Create mock service dependencies
        let userServiceJWT = ServiceDependencyResponse(
            serviceDependencyId: UUID(),
            serviceId: userService.serviceId,
            dependency: jwtLibrary,
            environmentCode: "prod",
            configOverride: ["expiration": "12h"],
            createdAt: Calendar.current.date(byAdding: .day, value: -15, to: Date()),
            updatedAt: Date()
        )
        
        let userServiceDB = ServiceDependencyResponse(
            serviceDependencyId: UUID(),
            serviceId: userService.serviceId,
            dependency: postgresDB,
            environmentCode: "prod",
            configOverride: ["database": "users_db"],
            createdAt: Calendar.current.date(byAdding: .day, value: -15, to: Date()),
            updatedAt: Date()
        )
        
        let authServiceJWT = ServiceDependencyResponse(
            serviceDependencyId: UUID(),
            serviceId: authService.serviceId,
            dependency: jwtLibrary,
            environmentCode: "prod",
            configOverride: [:],
            createdAt: Calendar.current.date(byAdding: .day, value: -12, to: Date()),
            updatedAt: Date()
        )
        
        let authServiceRedis = ServiceDependencyResponse(
            serviceDependencyId: UUID(),
            serviceId: authService.serviceId,
            dependency: redisCache,
            environmentCode: "prod",
            configOverride: ["database": "1"],
            createdAt: Calendar.current.date(byAdding: .day, value: -12, to: Date()),
            updatedAt: Date()
        )
        
        let orderServiceDB = ServiceDependencyResponse(
            serviceDependencyId: UUID(),
            serviceId: orderService.serviceId,
            dependency: postgresDB,
            environmentCode: "prod",
            configOverride: ["database": "orders_db"],
            createdAt: Calendar.current.date(byAdding: .day, value: -10, to: Date()),
            updatedAt: Date()
        )
        
        let orderServiceQueue = ServiceDependencyResponse(
            serviceDependencyId: UUID(),
            serviceId: orderService.serviceId,
            dependency: rabbitMQ,
            environmentCode: "prod",
            configOverride: ["queue": "order_events"],
            createdAt: Calendar.current.date(byAdding: .day, value: -10, to: Date()),
            updatedAt: Date()
        )
        
        let paymentServiceStripe = ServiceDependencyResponse(
            serviceDependencyId: UUID(),
            serviceId: paymentService.serviceId,
            dependency: stripeAPI,
            environmentCode: "prod",
            configOverride: [:],
            createdAt: Calendar.current.date(byAdding: .day, value: -8, to: Date()),
            updatedAt: Date()
        )
        
        let paymentServiceDB = ServiceDependencyResponse(
            serviceDependencyId: UUID(),
            serviceId: paymentService.serviceId,
            dependency: postgresDB,
            environmentCode: "prod",
            configOverride: ["database": "payments_db"],
            createdAt: Calendar.current.date(byAdding: .day, value: -8, to: Date()),
            updatedAt: Date()
        )
        
        mockServiceDependencies = [
            userServiceJWT, userServiceDB, authServiceJWT, authServiceRedis,
            orderServiceDB, orderServiceQueue, paymentServiceStripe, paymentServiceDB
        ]
        
        // Service-to-Service Dependencies
        let orderToUserAPI = ServiceToServiceDependencyResponse(
            serviceDependencyId: UUID(),
            consumerServiceId: orderService.serviceId,
            providerServiceId: userService.serviceId,
            environmentCode: "prod",
            description: "Получение информации о пользователе для заказов",
            dependencyType: .API_CALL,
            config: [
                "endpoint": "/api/v1/users",
                "timeout": "5s",
                "retries": "3"
            ],
            createdAt: Calendar.current.date(byAdding: .day, value: -12, to: Date()),
            updatedAt: Date()
        )
        
        let orderToAuthAPI = ServiceToServiceDependencyResponse(
            serviceDependencyId: UUID(),
            consumerServiceId: orderService.serviceId,
            providerServiceId: authService.serviceId,
            environmentCode: "prod",
            description: "Проверка токенов аутентификации",
            dependencyType: .AUTHENTICATION,
            config: [
                "endpoint": "/api/v1/auth/verify",
                "timeout": "3s",
                "retries": "2"
            ],
            createdAt: Calendar.current.date(byAdding: .day, value: -12, to: Date()),
            updatedAt: Date()
        )
        
        let paymentToOrderAPI = ServiceToServiceDependencyResponse(
            serviceDependencyId: UUID(),
            consumerServiceId: paymentService.serviceId,
            providerServiceId: orderService.serviceId,
            environmentCode: "prod",
            description: "Получение деталей заказа для обработки платежа",
            dependencyType: .API_CALL,
            config: [
                "endpoint": "/api/v1/orders",
                "timeout": "8s",
                "retries": "3"
            ],
            createdAt: Calendar.current.date(byAdding: .day, value: -10, to: Date()),
            updatedAt: Date()
        )
        
        let userToAuthAPI = ServiceToServiceDependencyResponse(
            serviceDependencyId: UUID(),
            consumerServiceId: userService.serviceId,
            providerServiceId: authService.serviceId,
            environmentCode: "prod",
            description: "Проверка прав доступа пользователей",
            dependencyType: .AUTHENTICATION,
            config: [
                "endpoint": "/api/v1/auth/authorize",
                "timeout": "3s",
                "retries": "2"
            ],
            createdAt: Calendar.current.date(byAdding: .day, value: -15, to: Date()),
            updatedAt: Date()
        )
        
        let orderToPaymentEvent = ServiceToServiceDependencyResponse(
            serviceDependencyId: UUID(),
            consumerServiceId: orderService.serviceId,
            providerServiceId: paymentService.serviceId,
            environmentCode: "prod",
            description: "Подписка на события обработки платежей",
            dependencyType: .EVENT_SUBSCRIPTION,
            config: [
                "topic": "payment.events",
                "consumer_group": "order-service",
                "auto_offset_reset": "earliest"
            ],
            createdAt: Calendar.current.date(byAdding: .day, value: -8, to: Date()),
            updatedAt: Date()
        )
        
        mockServiceToServiceDependencies = [
            orderToUserAPI, orderToAuthAPI, paymentToOrderAPI, userToAuthAPI, orderToPaymentEvent
        ]
    }
    
    // MARK: - Service-to-Service Dependencies API
    
    func fetchServiceToServiceDependencies(serviceId: UUID, environmentCode: String? = nil) async throws -> [ServiceToServiceDependencyResponse] {
        try await Task.sleep(nanoseconds: 300_000_000)
        
        var dependencies = mockServiceToServiceDependencies.filter { $0.consumerServiceId == serviceId }
        
        if let environmentCode = environmentCode {
            dependencies = dependencies.filter { $0.environmentCode == environmentCode }
        }
        
        return dependencies
    }
    
    func createServiceToServiceDependency(consumerServiceId: UUID, request: CreateServiceToServiceDependencyRequest) async throws -> ServiceToServiceDependencyResponse {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Check if dependency already exists
        let exists = mockServiceToServiceDependencies.contains { dependency in
            dependency.consumerServiceId == consumerServiceId &&
            dependency.providerServiceId == request.providerServiceId &&
            dependency.environmentCode == request.environmentCode
        }
        
        if exists {
            throw APIError.dependencyAlreadyExists
        }
        
        // Check if services exist
        guard mockServices.contains(where: { $0.serviceId == consumerServiceId }) else {
            throw APIError.serviceNotFound
        }
        
        guard mockServices.contains(where: { $0.serviceId == request.providerServiceId }) else {
            throw APIError.serviceNotFound
        }
        
        let newDependency = ServiceToServiceDependencyResponse(
            serviceDependencyId: UUID(),
            consumerServiceId: consumerServiceId,
            providerServiceId: request.providerServiceId,
            environmentCode: request.environmentCode,
            description: request.description,
            dependencyType: request.dependencyType,
            config: request.config,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        mockServiceToServiceDependencies.append(newDependency)
        return newDependency
    }
    
    func updateServiceToServiceDependency(serviceId: UUID, dependencyId: UUID, request: UpdateServiceToServiceDependencyRequest) async throws -> ServiceToServiceDependencyResponse {
        try await Task.sleep(nanoseconds: 400_000_000)
        
        guard let index = mockServiceToServiceDependencies.firstIndex(where: { 
            $0.serviceDependencyId == dependencyId && $0.consumerServiceId == serviceId 
        }) else {
            throw APIError.dependencyNotFound
        }
        
        var dependency = mockServiceToServiceDependencies[index]
        
        if let providerServiceId = request.providerServiceId {
            dependency = ServiceToServiceDependencyResponse(
                serviceDependencyId: dependency.serviceDependencyId,
                consumerServiceId: dependency.consumerServiceId,
                providerServiceId: providerServiceId,
                environmentCode: request.environmentCode ?? dependency.environmentCode,
                description: request.description ?? dependency.description,
                dependencyType: request.dependencyType ?? dependency.dependencyType,
                config: request.config ?? dependency.config,
                createdAt: dependency.createdAt,
                updatedAt: Date()
            )
        }
        
        mockServiceToServiceDependencies[index] = dependency
        return dependency
    }
    
    func deleteServiceToServiceDependency(serviceId: UUID, dependencyId: UUID) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard let index = mockServiceToServiceDependencies.firstIndex(where: { 
            $0.serviceDependencyId == dependencyId && $0.consumerServiceId == serviceId 
        }) else {
            throw APIError.dependencyNotFound
        }
        
        mockServiceToServiceDependencies.remove(at: index)
    }
}
