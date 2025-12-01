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
            dependency.serviceId == id || dependency.dependsOnServiceId == id
        }
    }
    
    // MARK: - Dependencies API
    
    func fetchDependencies() async throws -> [DependencyResponse] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return mockDependencies
    }
    
    func fetchServiceDependencies(serviceId: UUID) async throws -> [DependencyResponse] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return mockDependencies.filter { $0.serviceId == serviceId }
    }
    
    func createDependency(_ request: CreateDependencyRequest) async throws -> DependencyResponse {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Check if dependency already exists
        if mockDependencies.contains(where: { 
            $0.serviceId == request.serviceId && 
            $0.dependsOnServiceId == request.dependsOnServiceId 
        }) {
            throw APIError.dependencyAlreadyExists
        }
        
        let serviceName = mockServices.first { $0.serviceId == request.serviceId }?.name
        let dependsOnServiceName = mockServices.first { $0.serviceId == request.dependsOnServiceId }?.name
        
        let newDependency = DependencyResponse(
            dependencyId: UUID(),
            serviceId: request.serviceId,
            dependsOnServiceId: request.dependsOnServiceId,
            dependencyType: request.dependencyType,
            description: request.description,
            createdAt: Date(),
            updatedAt: Date(),
            serviceName: serviceName,
            dependsOnServiceName: dependsOnServiceName,
            serviceVersion: "v1.0.0",
            dependsOnServiceVersion: "v1.0.0"
        )
        
        mockDependencies.append(newDependency)
        return newDependency
    }
    
    func updateDependency(id: UUID, request: UpdateDependencyRequest) async throws -> DependencyResponse {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard let index = mockDependencies.firstIndex(where: { $0.dependencyId == id }) else {
            throw APIError.dependencyNotFound
        }
        
        let existingDependency = mockDependencies[index]
        let updatedDependency = DependencyResponse(
            dependencyId: existingDependency.dependencyId,
            serviceId: existingDependency.serviceId,
            dependsOnServiceId: existingDependency.dependsOnServiceId,
            dependencyType: request.dependencyType ?? existingDependency.dependencyType,
            description: request.description ?? existingDependency.description,
            createdAt: existingDependency.createdAt,
            updatedAt: Date(),
            serviceName: existingDependency.serviceName,
            dependsOnServiceName: existingDependency.dependsOnServiceName,
            serviceVersion: existingDependency.serviceVersion,
            dependsOnServiceVersion: existingDependency.dependsOnServiceVersion
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
    }
    
    func fetchDependencyGraph() async throws -> DependencyGraph {
        try await Task.sleep(nanoseconds: 800_000_000)
        
        let nodes = mockServices.map { service in
            let dependencyCount = mockDependencies.filter { $0.serviceId == service.serviceId }.count
            let dependentCount = mockDependencies.filter { $0.dependsOnServiceId == service.serviceId }.count
            
            return DependencyNode(
                id: service.serviceId,
                name: service.name,
                serviceType: service.serviceType,
                dependencyCount: dependencyCount,
                dependentCount: dependentCount
            )
        }
        
        let edges = mockDependencies.map { dependency in
            DependencyEdge(
                id: dependency.dependencyId,
                fromNodeId: dependency.serviceId,
                toNodeId: dependency.dependsOnServiceId,
                dependencyType: dependency.dependencyType,
                description: dependency.description
            )
        }
        
        return DependencyGraph(nodes: nodes, edges: edges)
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
        
        // Create mock dependencies
        let dependency1 = DependencyResponse(
            dependencyId: UUID(),
            serviceId: userService.serviceId,
            dependsOnServiceId: authService.serviceId,
            dependencyType: .SYNCHRONOUS,
            description: "Аутентификация пользователей",
            createdAt: Calendar.current.date(byAdding: .day, value: -15, to: Date()),
            updatedAt: Date(),
            serviceName: userService.name,
            dependsOnServiceName: authService.name,
            serviceVersion: "v1.2.0",
            dependsOnServiceVersion: "v1.0.0"
        )
        
        let dependency2 = DependencyResponse(
            dependencyId: UUID(),
            serviceId: orderService.serviceId,
            dependsOnServiceId: userService.serviceId,
            dependencyType: .ASYNCHRONOUS,
            description: "Получение информации о пользователе",
            createdAt: Calendar.current.date(byAdding: .day, value: -10, to: Date()),
            updatedAt: Date(),
            serviceName: orderService.name,
            dependsOnServiceName: userService.name,
            serviceVersion: "v2.1.0",
            dependsOnServiceVersion: "v1.2.0"
        )
        
        let dependency3 = DependencyResponse(
            dependencyId: UUID(),
            serviceId: orderService.serviceId,
            dependsOnServiceId: paymentService.serviceId,
            dependencyType: .SYNCHRONOUS,
            description: "Обработка платежей за заказы",
            createdAt: Calendar.current.date(byAdding: .day, value: -8, to: Date()),
            updatedAt: Date(),
            serviceName: orderService.name,
            dependsOnServiceName: paymentService.name,
            serviceVersion: "v2.1.0",
            dependsOnServiceVersion: "v1.0.0"
        )
        
        let dependency4 = DependencyResponse(
            dependencyId: UUID(),
            serviceId: paymentService.serviceId,
            dependsOnServiceId: userService.serviceId,
            dependencyType: .DATABASE,
            description: "Общая база данных пользователей",
            createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()),
            updatedAt: Date(),
            serviceName: paymentService.name,
            dependsOnServiceName: userService.name,
            serviceVersion: "v1.0.0",
            dependsOnServiceVersion: "v1.2.0"
        )
        
        mockDependencies = [dependency1, dependency2, dependency3, dependency4]
    }
}