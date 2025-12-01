//
//  ContentView.swift
//  api-registry-descktop
//
//  Created by seregin-ma on 01.12.2025.
//

import SwiftUI
struct ARServicesMainView: View {
    @StateObject private var serviceViewModel = ServiceViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .environmentObject(serviceViewModel)
                .tabItem {
                    Label("Дашборд", systemImage: "house")
                }
                .tag(0)
            
            ServicesListView()
                .environmentObject(serviceViewModel)
                .tabItem {
                    Label("Сервисы", systemImage: "cube")
                }
                .tag(1)
            
            DependenciesView()
                .tabItem {
                    Label("Зависимости", systemImage: "arrow.triangle.branch")
                }
                .tag(2)
            
            Text("Базы данных")
                .tabItem {
                    Label("Базы данных", systemImage: "cylinder")
                }
                .tag(3)
        }
        .frame(minWidth: 900, minHeight: 700)
    }
}

// MARK: - Services List View

struct ServicesListView: View {
    @EnvironmentObject private var serviceViewModel: ServiceViewModel
    @State private var showingCreateService = false
    @State private var selectedService: ServiceResponse?
    @State private var searchText = ""
    
    var filteredServices: [ServiceResponse] {
        if searchText.isEmpty {
            return serviceViewModel.services
        } else {
            return serviceViewModel.services.filter { service in
                service.name.localizedCaseInsensitiveContains(searchText) ||
                service.owner.localizedCaseInsensitiveContains(searchText) ||
                service.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Сервисы")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button("Новый сервис") {
                        showingCreateService = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Поиск сервисов...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                .padding(.horizontal)
                
                // Services List
                if serviceViewModel.isLoading {
                    Spacer()
                    ProgressView("Загрузка сервисов...")
                    Spacer()
                } else if filteredServices.isEmpty {
                    Spacer()
                    if searchText.isEmpty {
                        EmptyStateView()
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            
                            Text("Ничего не найдено")
                                .font(.headline)
                            
                            Text("Попробуйте изменить поисковый запрос")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredServices) { service in
                                ServiceRowView(service: service)
                                    .onTapGesture {
                                        selectedService = service
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .refreshable {
                await serviceViewModel.loadServices()
            }
            .task {
                await serviceViewModel.loadServices()
            }
            .sheet(isPresented: $showingCreateService) {
                CreateServiceView()
                    .environmentObject(serviceViewModel)
            }
            .sheet(item: $selectedService) { service in
                EditServiceView(service: service)
                    .environmentObject(serviceViewModel)
            }
            .alert("Ошибка", isPresented: .constant(serviceViewModel.errorMessage != nil)) {
                Button("OK") {
                    serviceViewModel.errorMessage = nil
                }
            } message: {
                Text(serviceViewModel.errorMessage ?? "")
            }
        }
    }
}

#Preview {
    ARServicesMainView()
}
