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
    @State private var showingGraph = false
    
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
                } else if dependencyViewModel.filteredServiceDependencies.isEmpty {
                    emptyStateView
                } else {
                    dependenciesListView
                }
                
                // Info Section
                infoSectionView
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground))
            .task {
                await dependencyViewModel.loadDependencies()
            }
            .sheet(isPresented: $showingCreateDependency) {
                CreateDependencyView(dependencyViewModel: dependencyViewModel)
            }
            .sheet(isPresented: $showingGraph) {
                DependencyGraphView(dependencyViewModel: dependencyViewModel)
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
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                    Button(action: { showingGraph = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "point.3.connected.trianglepath.dotted")
                            Text("Граф зависимостей")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Button(action: { showingCreateDependency = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("Добавить зависимость")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Search and Filter
    
    private var searchAndFilterView: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Поиск по названию сервиса или описанию...", text: $dependencyViewModel.searchText)
                    .onChange(of: dependencyViewModel.searchText) { newValue in
                        dependencyViewModel.updateSearchText(newValue)
                    }
                
                if !dependencyViewModel.searchText.isEmpty {
                    Button(action: {
                        dependencyViewModel.updateSearchText("")
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Menu {
                Button("Все типы") {
                    dependencyViewModel.updateDependencyTypeFilter(nil)
                }
                
                ForEach(DependencyType.allCases, id: \.self) { type in
                    Button(type.displayName) {
                        dependencyViewModel.updateDependencyTypeFilter(type)
                    }
                }
            } label: {
                HStack {
                    Text(dependencyViewModel.selectedDependencyType?.displayName ?? "Все типы")
                        .font(.system(size: 14))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Stats
    
    private var statsView: some View {
        HStack(spacing: 20) {
            Text("Найдено: \(dependencyViewModel.dependencyStats.total) зависимостей")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Сервисов: \(dependencyViewModel.dependencyStats.services)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Dependencies List
    
    private var dependenciesListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(dependencyViewModel.groupedServiceDependencies.keys.sorted()), id: \.self) { serviceName in
                    if let serviceDependencies = dependencyViewModel.groupedServiceDependencies[serviceName] {
                        ServiceDependencySection(
                            serviceName: serviceName,
                            serviceDependencies: serviceDependencies,
                            dependencyViewModel: dependencyViewModel
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "bolt.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Зависимости не найдены")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Попробуйте изменить критерии поиска")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if dependencyViewModel.searchText.isEmpty && dependencyViewModel.selectedDependencyType == nil {
                Button("Добавить первую зависимость") {
                    showingCreateDependency = true
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Info Section
    
    private var infoSectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("О зависимостях сервисов")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(DependencyType.allCases, id: \.self) { type in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: type.icon)
                            .foregroundColor(.blue)
                            .frame(width: 16)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(type.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(type.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.blue)
                        .frame(width: 16)
                    
                    Text("Отслеживайте зависимости для понимания архитектуры системы")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .underline()
                }
            }
        }
        .padding(16)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Service Dependency Section

struct ServiceDependencySection: View {
    let serviceName: String
    let serviceDependencies: [ServiceDependencyResponse]
    let dependencyViewModel: DependencyViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Service Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Сервис: \(serviceName)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("Зависит от \(serviceDependencies.count) зависимостей")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Dependencies Table
            VStack(spacing: 0) {
                // Table Header
                HStack {
                    Text("ЗАВИСИМОСТЬ")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("ТИП")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    
                    Text("ВЕРСИЯ")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                    
                    Text("ОПИСАНИЕ")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("")
                        .frame(width: 60)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                
                // Table Rows
                ForEach(serviceDependencies) { serviceDependency in
                    ServiceDependencyRow(
                        serviceDependency: serviceDependency,
                        dependencyViewModel: dependencyViewModel
                    )
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Service Dependency Row

struct ServiceDependencyRow: View {
    let serviceDependency: ServiceDependencyResponse
    let dependencyViewModel: DependencyViewModel
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(serviceDependency.dependency.name)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.blue)
                
                if let environmentCode = serviceDependency.environmentCode {
                    Text(environmentCode)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Image(systemName: serviceDependency.dependency.dependencyType.icon)
                    .foregroundColor(colorForDependencyType(serviceDependency.dependency.dependencyType))
                Text(serviceDependency.dependency.dependencyType.displayName)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(colorForDependencyType(serviceDependency.dependency.dependencyType).opacity(0.1))
                    .cornerRadius(4)
            }
            .frame(width: 100, alignment: .leading)
            
            Text(serviceDependency.dependency.version)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(serviceDependency.dependency.description ?? "")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button("Удалить") {
                showingDeleteAlert = true
            }
            .font(.caption)
            .foregroundColor(.red)
            .frame(width: 60)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .alert("Удалить зависимость?", isPresented: $showingDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                Task {
                    await dependencyViewModel.deleteServiceDependency(serviceDependency)
                }
            }
        } message: {
            Text("Вы уверены, что хотите удалить зависимость \(serviceDependency.dependency.name)?")
        }
    }
    
    private func colorForDependencyType(_ type: DependencyType) -> Color {
        switch type {
        case .LIBRARY:
            return .blue
        case .SERVICE:
            return .green
        case .DATABASE:
            return .purple
        case .EXTERNAL_API:
            return .orange
        case .MESSAGE_QUEUE:
            return .red
        }
    }
}

#Preview {
    DependenciesView()
}