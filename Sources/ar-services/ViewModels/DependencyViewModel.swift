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
    @Published var services: [ServiceResponse] = []
    @Published var dependencyGraph: DependencyGraph?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = MockAPIService.shared // Use MockAPIService for testing
    
    // MARK: - Dependencies Management
    
    func loadDependencies() async {
        isLoading = true
        errorMessage = nil
        
        do {
            dependencies = try await apiService.fetchDependencies()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadServices() async {
        do {
            services = try await apiService.fetchServices()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func createDependency(_ request: CreateDependencyRequest) async -> Bool {
        do {
            let newDependency = try await apiService.createDependency(request)
            dependencies.append(newDependency)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    func deleteDependency(_ dependency: DependencyResponse) async -> Bool {
        do {
            try await apiService.deleteDependency(id: dependency.dependencyId)
            dependencies.removeAll { $0.dependencyId == dependency.dependencyId }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    func updateDependency(id: UUID, request: UpdateDependencyRequest) async -> Bool {
        do {
            let updatedDependency = try await apiService.updateDependency(id: id, request: request)
            if let index = dependencies.firstIndex(where: { $0.dependencyId == id }) {
                dependencies[index] = updatedDependency
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Graph Management
    
    func loadDependencyGraph() async {
        do {
            dependencyGraph = try await apiService.fetchDependencyGraph()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Helper Methods
    
    func serviceName(for serviceId: UUID) -> String {
        services.first { $0.serviceId == serviceId }?.name ?? "Неизвестный сервис"
    }
    
    func serviceVersion(for serviceId: UUID) -> String {
        // В будущем можно добавить версионирование
        services.first { $0.serviceId == serviceId }?.environments?.first?.displayName ?? ""
    }
    
    func groupedDependencies() -> [String: [DependencyResponse]] {
        Dictionary(grouping: dependencies) { dependency in
            dependency.serviceName ?? serviceName(for: dependency.serviceId)
        }
    }
    
    func filteredDependencies(searchText: String, selectedType: DependencyType?) -> [DependencyResponse] {
        var filtered = dependencies
        
        // Фильтрация по типу
        if let selectedType = selectedType {
            filtered = filtered.filter { $0.dependencyType == selectedType }
        }
        
        // Фильтрация по поисковому запросу
        if !searchText.isEmpty {
            filtered = filtered.filter { dependency in
                let serviceName = dependency.serviceName ?? serviceName(for: dependency.serviceId)
                let dependsOnServiceName = dependency.dependsOnServiceName ?? serviceName(for: dependency.dependsOnServiceId)
                let description = dependency.description ?? ""
                
                return serviceName.localizedCaseInsensitiveContains(searchText) ||
                       dependsOnServiceName.localizedCaseInsensitiveContains(searchText) ||
                       description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    func dependencyStats() -> (total: Int, services: Int) {
        let total = dependencies.count
        let uniqueServices = Set(dependencies.map { $0.serviceId }).count
        return (total: total, services: uniqueServices)
    }
}