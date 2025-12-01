//
//  DependenciesView.swift
//  ar-services
//
//  Created by OpenHands on 01.12.2025.
//

import SwiftUI

struct DependenciesView: View {
    @StateObject private var dependencyViewModel = DependencyViewModel()
    @State private var showingCreateDependency = false
    @State private var searchText = ""
    @State private var selectedDependencyType: DependencyType? = nil
    @State private var showingGraph = false
    
    private var filteredDependencies: [DependencyResponse] {
        dependencyViewModel.filteredDependencies(searchText: searchText, selectedType: selectedDependencyType)
    }
    
    private var groupedDependencies: [String: [DependencyResponse]] {
        Dictionary(grouping: filteredDependencies) { dependency in
            dependency.serviceName ?? dependencyViewModel.serviceName(for: dependency.serviceId)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Search and Filter
                searchAndFilterView
                
                // Stats
                statsView
                
                // Content
                if dependencyViewModel.isLoading {
                    Spacer()
                    ProgressView("Загрузка зависимостей...")
                    Spacer()
                } else if filteredDependencies.isEmpty {
                    emptyStateView
                } else {
                    dependenciesListView
                }
                
                // Info Section
                infoSectionView
            }
            .refreshable {
                await loadData()
            }
            .task {
                await loadData()
            }
            .sheet(isPresented: $showingCreateDependency) {
                CreateDependencyView()
                    .environmentObject(dependencyViewModel)
            }
            .sheet(isPresented: $showingGraph) {
                DependencyGraphView()
                    .environmentObject(dependencyViewModel)
            }
            .alert("Ошибка", isPresented: .constant(dependencyViewModel.errorMessage != nil)) {
                Button("OK") {
                    dependencyViewModel.errorMessage = nil
                }
            } message: {
                Text(dependencyViewModel.errorMessage ?? "")
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Зависимости сервисов")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Граф зависимостей между микросервисами")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button("Граф зависимостей") {
                    showingGraph = true
                }
                .buttonStyle(.bordered)
                
                Button("+ Добавить зависимость") {
                    showingCreateDependency = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
    
    // MARK: - Search and Filter View
    
    private var searchAndFilterView: some View {
        HStack(spacing: 12) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Поиск по названию сервиса или описанию...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            
            // Filter
            Menu {
                Button("Все типы") {
                    selectedDependencyType = nil
                }
                
                ForEach(DependencyType.allCases, id: \.self) { type in
                    Button(type.displayName) {
                        selectedDependencyType = type
                    }
                }
            } label: {
                HStack {
                    Text(selectedDependencyType?.displayName ?? "Все типы")
                    Image(systemName: "chevron.down")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
            }
            .menuStyle(.borderlessButton)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Stats View
    
    private var statsView: some View {
        let stats = dependencyViewModel.dependencyStats()
        
        return HStack {
            Text("Найдено: \(filteredDependencies.count) зависимостей")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("Сервисов: \(groupedDependencies.keys.count)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Dependencies List View
    
    private var dependenciesListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(groupedDependencies.keys.sorted(), id: \.self) { serviceName in
                    ServiceDependencySection(
                        serviceName: serviceName,
                        dependencies: groupedDependencies[serviceName] ?? [],
                        onDelete: { dependency in
                            Task {
                                await dependencyViewModel.deleteDependency(dependency)
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            if searchText.isEmpty && selectedDependencyType == nil {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 48))
                    .foregroundColor(.gray)
                
                Text("Зависимости не найдены")
                    .font(.headline)
                
                Text("Добавьте первую зависимость между сервисами")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button("Добавить зависимость") {
                    showingCreateDependency = true
                }
                .buttonStyle(.borderedProminent)
            } else {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(.gray)
                
                Text("Зависимости не найдены")
                    .font(.headline)
                
                Text("Попробуйте изменить критерии поиска")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Info Section View
    
    private var infoSectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("О зависимостях сервисов")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(DependencyType.allCases, id: \.self) { type in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.blue)
                            .fontWeight(.bold)
                        
                        Text("\(type.displayName)")
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        
                        Text("- \(type.description)")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
                
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                    
                    Text("Отслеживайте зависимости для понимания архитектуры системы")
                        .foregroundColor(.blue)
                        .underline()
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
        )
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func loadData() async {
        await dependencyViewModel.loadServices()
        await dependencyViewModel.loadDependencies()
    }
}

// MARK: - Service Dependency Section

struct ServiceDependencySection: View {
    let serviceName: String
    let dependencies: [DependencyResponse]
    let onDelete: (DependencyResponse) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Service Header
            HStack {
                Text("Сервис: \(serviceName)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("Зависит от \(dependencies.count) сервисов")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Dependencies Table
            VStack(spacing: 0) {
                // Table Header
                HStack {
                    Text("ЗАВИСИМЫЙ СЕРВИС")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("ТИП")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(width: 120, alignment: .leading)
                    
                    Text("СТАТУС")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                    
                    Text("ОПИСАНИЕ")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("СОЗДАНО")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    
                    Text("")
                        .frame(width: 60)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                
                // Table Rows
                ForEach(dependencies) { dependency in
                    DependencyRowView(dependency: dependency, onDelete: onDelete)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
        }
    }
}

// MARK: - Dependency Row View

struct DependencyRowView: View {
    let dependency: DependencyResponse
    let onDelete: (DependencyResponse) -> Void
    
    private var dependsOnServiceName: String {
        dependency.dependsOnServiceName ?? "Неизвестный сервис"
    }
    
    private var dependsOnServiceVersion: String {
        dependency.dependsOnServiceVersion ?? ""
    }
    
    private var formattedDate: String {
        guard let createdAt = dependency.createdAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: createdAt)
    }
    
    var body: some View {
        HStack {
            // Service Name
            VStack(alignment: .leading, spacing: 2) {
                Text(dependsOnServiceName)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.blue)
                
                if !dependsOnServiceVersion.isEmpty {
                    Text(dependsOnServiceVersion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Dependency Type
            dependencyTypeBadge
                .frame(width: 120, alignment: .leading)
            
            // Status
            statusBadge
                .frame(width: 80, alignment: .leading)
            
            // Description
            Text(dependency.description ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Created Date
            Text(formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            // Delete Button
            Button("Удалить") {
                onDelete(dependency)
            }
            .foregroundColor(.red)
            .font(.caption)
            .frame(width: 60)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
    
    private var dependencyTypeBadge: some View {
        Text(dependency.dependencyType.displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(dependencyTypeColor.opacity(0.2))
            )
            .foregroundColor(dependencyTypeColor)
    }
    
    private var statusBadge: some View {
        Text("Активный")
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.green.opacity(0.2))
            )
            .foregroundColor(.green)
    }
    
    private var dependencyTypeColor: Color {
        switch dependency.dependencyType {
        case .SYNCHRONOUS:
            return .blue
        case .ASYNCHRONOUS:
            return .orange
        case .DATABASE:
            return .purple
        }
    }
}

#Preview {
    DependenciesView()
}