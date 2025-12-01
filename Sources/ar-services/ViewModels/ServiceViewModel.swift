//
//  ServiceViewModel.swift
//  api-registry-descktop
//
//  Created by OpenHands on 01.12.2025.
//

import Foundation
import SwiftUI

@MainActor
class ServiceViewModel: ObservableObject {
    @Published var services: [ServiceResponse] = []
    @Published var dashboardStats = DashboardStats(totalServices: 0, activeServices: 0, endpoints: 0, deprecated: 0)
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    // MARK: - Dashboard
    
    func loadDashboard() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let servicesTask = apiService.fetchServices()
            async let statsTask = apiService.fetchDashboardStats()
            
            services = try await servicesTask
            dashboardStats = try await statsTask
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Services
    
    func loadServices() async {
        isLoading = true
        errorMessage = nil
        
        do {
            services = try await apiService.fetchServices()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createService(_ request: CreateServiceRequest) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let newService = try await apiService.createService(request)
            services.append(newService)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    func updateService(id: UUID, request: UpdateServiceRequest) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedService = try await apiService.updateService(id: id, request: request)
            if let index = services.firstIndex(where: { $0.serviceId == id }) {
                services[index] = updatedService
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    func deleteService(id: UUID) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await apiService.deleteService(id: id)
            services.removeAll { $0.serviceId == id }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    func getService(by id: UUID) -> ServiceResponse? {
        return services.first { $0.serviceId == id }
    }
}

// MARK: - Create Service Form Data

@MainActor
class CreateServiceFormData: ObservableObject {
    @Published var name = ""
    @Published var description = ""
    @Published var owner = ""
    @Published var tags = ""
    @Published var serviceType: ServiceType = .APPLICATION
    @Published var supportsDatabase = false
    @Published var proxy = false
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !owner.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var tagsArray: [String] {
        tags.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    func toCreateRequest() -> CreateServiceRequest {
        return CreateServiceRequest(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
            owner: owner.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: tagsArray,
            serviceType: serviceType,
            supportsDatabase: supportsDatabase,
            proxy: proxy
        )
    }
    
    func reset() {
        name = ""
        description = ""
        owner = ""
        tags = ""
        serviceType = .APPLICATION
        supportsDatabase = false
        proxy = false
    }
    
    func populate(from service: ServiceResponse) {
        name = service.name
        description = service.description ?? ""
        owner = service.owner
        tags = service.tags.joined(separator: ", ")
        serviceType = service.serviceType
        supportsDatabase = service.supportsDatabase
        proxy = service.proxy
    }
    
    func toUpdateRequest() -> UpdateServiceRequest {
        return UpdateServiceRequest(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
            owner: owner.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: tagsArray,
            serviceType: serviceType,
            supportsDatabase: supportsDatabase,
            proxy: proxy
        )
    }
}