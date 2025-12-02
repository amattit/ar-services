//
//  DependencyViewModel.swift
//  ar-services
//
//  Created by OpenHands on 01.12.2025.
//

import Foundation
import SwiftUI

@MainActor
class DependencyViewModel: ObservableObject {
    @Published var dependencies: [DependencyResponse] = []
    @Published var serviceDependencies: [ServiceDependencyResponse] = []
    @Published var filteredServiceDependencies: [ServiceDependencyResponse] = []
    @Published var services: [ServiceResponse] = []
    @Published var dependencyGraph: ServiceDependencyGraphResponse?
    @Published var searchText = ""
    @Published var selectedDependencyType: DependencyType?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared//MockAPIService.shared // Use MockAPIService for testing
    
    // MARK: - Dependencies Management
    
    func loadDependencies() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let dependenciesTask = apiService.fetchDependencies()
            async let servicesTask = apiService.fetchServices()
            
            dependencies = try await dependenciesTask
            services = try await servicesTask
            
            // Load all service dependencies
            await loadAllServiceDependencies()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func loadAllServiceDependencies() async {
        var allServiceDependencies: [ServiceDependencyResponse] = []
        
        for service in services {
            do {
                let serviceDeps = try await apiService.fetchServiceDependencies(serviceId: service.serviceId)
                allServiceDependencies.append(contentsOf: serviceDeps)
            } catch {
                print("Failed to load dependencies for service \(service.name): \(error)")
            }
        }
        
        serviceDependencies = allServiceDependencies
        applyFilters()
    }
    
    func createDependency(_ request: CreateDependencyRequest) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let newDependency = try await apiService.createDependency(request)
            dependencies.append(newDependency)
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func createServiceDependency(serviceId: UUID, dependencyId: UUID, environmentCode: String? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = CreateServiceDependencyRequest(
                dependencyId: dependencyId,
                environmentCode: environmentCode,
                configOverride: [:]
            )
            let newServiceDependency = try await apiService.createServiceDependency(serviceId: serviceId, request: request)
            serviceDependencies.append(newServiceDependency)
            applyFilters()
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func deleteDependency(_ dependency: DependencyResponse) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await apiService.deleteDependency(id: dependency.dependencyId)
            dependencies.removeAll { $0.dependencyId == dependency.dependencyId }
            serviceDependencies.removeAll { $0.dependency.dependencyId == dependency.dependencyId }
            applyFilters()
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func deleteServiceDependency(_ serviceDependency: ServiceDependencyResponse) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await apiService.deleteServiceDependency(
                serviceId: serviceDependency.serviceId,
                dependencyId: serviceDependency.dependency.dependencyId,
                environmentCode: serviceDependency.environmentCode
            )
            serviceDependencies.removeAll { $0.serviceDependencyId == serviceDependency.serviceDependencyId }
            applyFilters()
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func loadDependencyGraph() async {
        isLoading = true
        errorMessage = nil
        
        do {
            dependencyGraph = try await apiService.fetchDependencyGraph()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Filtering and Search
    
    func applyFilters() {
        var filtered = serviceDependencies
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { serviceDep in
                let serviceName = services.first { $0.serviceId == serviceDep.serviceId }?.name ?? ""
                let dependencyName = serviceDep.dependency.name
                let description = serviceDep.dependency.description ?? ""
                
                return serviceName.localizedCaseInsensitiveContains(searchText) ||
                       dependencyName.localizedCaseInsensitiveContains(searchText) ||
                       description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply type filter
        if let selectedType = selectedDependencyType {
            filtered = filtered.filter { $0.dependency.dependencyType == selectedType }
        }
        
        filteredServiceDependencies = filtered
    }
    
    func updateSearchText(_ text: String) {
        searchText = text
        applyFilters()
    }
    
    func updateDependencyTypeFilter(_ type: DependencyType?) {
        selectedDependencyType = type
        applyFilters()
    }
    
    // MARK: - Computed Properties
    
    var groupedServiceDependencies: [String: [ServiceDependencyResponse]] {
        let grouped = Dictionary(grouping: filteredServiceDependencies) { serviceDep in
            services.first { $0.serviceId == serviceDep.serviceId }?.name ?? "Unknown Service"
        }
        return grouped
    }
    
    var dependencyStats: (total: Int, services: Int) {
        let totalDependencies = filteredServiceDependencies.count
        let uniqueServices = Set(filteredServiceDependencies.map { $0.serviceId }).count
        return (total: totalDependencies, services: uniqueServices)
    }
    
    func serviceName(for serviceId: UUID) -> String {
        services.first { $0.serviceId == serviceId }?.name ?? "Unknown Service"
    }
}
