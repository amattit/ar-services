//
//  EndpointsView.swift
//  ar-services
//
//  Created by OpenHands on 02.12.2025.
//

import SwiftUI

struct EndpointsView: View {
    let service: ServiceResponse
    @StateObject private var endpointViewModel = EndpointViewModel()
    @State private var searchText = ""
    @State private var selectedMethod: EndpointMethod?
    @State private var selectedEndpoint: EndpointResponse?
    @State private var showingEndpointDetail = false
    
    var filteredEndpoints: [EndpointResponse] {
        endpointViewModel.filteredEndpoints(searchText: searchText, selectedMethod: selectedMethod)
    }
    
    var body: some View {
        ScrollView {
//        VStack(spacing: 0) {
            // Header with stats
            EndpointStatsView(stats: endpointViewModel.endpointStats)
                .padding()
            
            Divider()
            
            // Filters and Search
            VStack(spacing: 12) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Поиск endpoints...", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button("Очистить") {
                            searchText = ""
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                
                // Method filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        MethodFilterButton(
                            method: nil,
                            isSelected: selectedMethod == nil,
                            count: endpointViewModel.endpointStats.total
                        ) {
                            selectedMethod = nil
                        }
                        
                        ForEach(EndpointMethod.allCases, id: \.self) { method in
                            let count = endpointViewModel.endpointStats.count(for: method)
                            if count > 0 {
                                MethodFilterButton(
                                    method: method,
                                    isSelected: selectedMethod == method,
                                    count: count
                                ) {
                                    selectedMethod = selectedMethod == method ? nil : method
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            
            Divider()
            
            // Endpoints List
            if endpointViewModel.isLoading {
                Spacer()
                ProgressView("Загрузка endpoints...")
                Spacer()
            } else if filteredEndpoints.isEmpty {
                Spacer()
                EmptyEndpointsView(hasEndpoints: !endpointViewModel.endpoints.isEmpty)
                Spacer()
            } else {
//                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredEndpoints) { endpoint in
                            NavigationLink {
                                EndpointDetailView(endpoint: endpoint, service: service)
                            } label: {
                                EndpointRowView(endpoint: endpoint)
                            }

//                            EndpointRowView(endpoint: endpoint)
//                                .onTapGesture {
//                                    selectedEndpoint = endpoint
//                                    showingEndpointDetail = true
//                                }
                        }
                    }
                    .padding()
//                }
            }
        }
        .navigationTitle("Endpoints")
        .navigationSubtitle(service.name)
        .task {
            await endpointViewModel.loadEndpoints(for: service.serviceId)
        }
        .refreshable {
            await endpointViewModel.loadEndpoints(for: service.serviceId)
        }
        .sheet(isPresented: $showingEndpointDetail) {
            if let endpoint = selectedEndpoint {
                EndpointDetailView(endpoint: endpoint, service: service)
            }
        }
        .alert("Ошибка", isPresented: .constant(endpointViewModel.errorMessage != nil)) {
            Button("OK") {
                endpointViewModel.errorMessage = nil
            }
        } message: {
            Text(endpointViewModel.errorMessage ?? "")
        }
    }
}

// MARK: - Endpoint Stats View

struct EndpointStatsView: View {
    let stats: EndpointStats
    
    var body: some View {
        HStack(spacing: 24) {
            StatItem(title: "Всего", value: "\(stats.total)", icon: "list.bullet")
            StatItem(title: "С авторизацией", value: "\(stats.withAuth)", icon: "lock")
            StatItem(title: "С ограничениями", value: "\(stats.withRateLimit)", icon: "speedometer")
            StatItem(title: "С зависимостями", value: "\(stats.withDependencies)", icon: "arrow.triangle.branch")
            StatItem(title: "С БД", value: "\(stats.withDatabases)", icon: "cylinder")
        }
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Method Filter Button

struct MethodFilterButton: View {
    let method: EndpointMethod?
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let method = method {
                    Text(method.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : colorForMethod(method))
                } else {
                    Text("ВСЕ")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : .primary)
                }
                
                Text("(\(count))")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? backgroundColorForMethod(method) : Color(NSColor.controlBackgroundColor))
            )
        }
        .buttonStyle(.plain)
    }
    
    private func colorForMethod(_ method: EndpointMethod) -> Color {
        switch method.color {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .red
        default: return .gray
        }
    }
    
    private func backgroundColorForMethod(_ method: EndpointMethod?) -> Color {
        guard let method = method else { return .accentColor }
        return colorForMethod(method)
    }
}

// MARK: - Endpoint Row View

struct EndpointRowView: View {
    let endpoint: EndpointResponse
    
    var body: some View {
        HStack(spacing: 12) {
            // Method badge
            Text(endpoint.method.rawValue)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorForMethod(endpoint.method))
                )
            
            // Path and summary
            VStack(alignment: .leading, spacing: 4) {
                Text(endpoint.path)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                
                Text(endpoint.summary)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Indicators
            HStack(spacing: 8) {
                if endpoint.auth != nil {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.orange)
                        .help("Требует авторизацию")
                }
                
                if endpoint.rateLimit != nil {
                    Image(systemName: "speedometer")
                        .foregroundColor(.red)
                        .help("Есть ограничения скорости")
                }
                
                if !(endpoint.calls?.isEmpty ?? true) {
                    Image(systemName: "arrow.triangle.branch")
                        .foregroundColor(.blue)
                        .help("Имеет зависимости")
                }
                
                if !(endpoint.databases?.isEmpty ?? true) {
                    Image(systemName: "cylinder.fill")
                        .foregroundColor(.green)
                        .help("Использует базы данных")
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
    }
    
    private func colorForMethod(_ method: EndpointMethod) -> Color {
        switch method.color {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .red
        default: return .gray
        }
    }
}

// MARK: - Empty Endpoints View

struct EmptyEndpointsView: View {
    let hasEndpoints: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasEndpoints ? "magnifyingglass" : "list.bullet.rectangle")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text(hasEndpoints ? "Ничего не найдено" : "Нет endpoints")
                .font(.headline)
            
            Text(hasEndpoints ? "Попробуйте изменить фильтры или поисковый запрос" : "У этого сервиса пока нет endpoints")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    NavigationView {
        EndpointsView(service: ServiceResponse(
            serviceId: UUID(),
            name: "Test Service",
            description: "Test Description",
            owner: "Test Owner",
            tags: ["test"],
            serviceType: .APPLICATION,
            supportsDatabase: true,
            proxy: false,
            createdAt: Date(),
            updatedAt: Date(),
            environments: nil
        ))
    }
}
