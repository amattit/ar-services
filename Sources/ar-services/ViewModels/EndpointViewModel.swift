//
//  EndpointViewModel.swift
//  ar-services
//
//  Created by OpenHands on 02.12.2025.
//

import Foundation
import SwiftUI

@MainActor
class EndpointViewModel: ObservableObject {
    @Published var endpoints: [EndpointResponse] = []
    @Published var selectedEndpoint: EndpointResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    // MARK: - Endpoints
    
    func loadEndpoints(for serviceId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            endpoints = try await apiService.fetchServiceEndpoints(serviceId: serviceId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadEndpoint(serviceId: UUID, endpointId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            selectedEndpoint = try await apiService.fetchEndpoint(serviceId: serviceId, endpointId: endpointId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func getEndpoint(by id: UUID) -> EndpointResponse? {
        return endpoints.first { $0.endpointId == id }
    }
    
    func clearSelection() {
        selectedEndpoint = nil
    }
    
    // MARK: - Filtering and Searching
    
    func filteredEndpoints(searchText: String, selectedMethod: EndpointMethod?) -> [EndpointResponse] {
        var filtered = endpoints
        
        // Filter by method
        if let method = selectedMethod {
            filtered = filtered.filter { $0.method == method }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { endpoint in
                endpoint.path.localizedCaseInsensitiveContains(searchText) ||
                endpoint.summary.localizedCaseInsensitiveContains(searchText) ||
                endpoint.method.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.sorted { $0.path < $1.path }
    }
    
    // MARK: - Statistics
    
    var endpointStats: EndpointStats {
        let methodCounts = Dictionary(grouping: endpoints, by: { $0.method })
            .mapValues { $0.count }
        
        return EndpointStats(
            total: endpoints.count,
            methodCounts: methodCounts,
            withAuth: endpoints.filter { $0.auth != nil }.count,
            withRateLimit: endpoints.filter { $0.rateLimit != nil }.count,
            withDependencies: endpoints.filter { !($0.calls?.isEmpty ?? true) }.count,
            withDatabases: endpoints.filter { !($0.databases?.isEmpty ?? true) }.count
        )
    }
}

// MARK: - Endpoint Statistics

struct EndpointStats {
    let total: Int
    let methodCounts: [EndpointMethod: Int]
    let withAuth: Int
    let withRateLimit: Int
    let withDependencies: Int
    let withDatabases: Int
    
    func count(for method: EndpointMethod) -> Int {
        return methodCounts[method] ?? 0
    }
}