//
//  DashboardView.swift
//  api-registry-descktop
//
//  Created by seregin-ma on 01.12.2025.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = ServiceViewModel()
    @State private var showingCreateService = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Registry")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Центральный реестр микросервисов и API эндпоинтов")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Быстрые действия")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            ActionButton(
                                title: "Новый сервис",
                                icon: "plus",
                                color: .blue
                            ) {
                                showingCreateService = true
                            }
                            
                            ActionButton(
                                title: "Все сервисы",
                                icon: "list.bullet",
                                color: .gray
                            ) {
                                // TODO: Navigate to services list
                            }
                            
                            ActionButton(
                                title: "Зависимости",
                                icon: "arrow.triangle.branch",
                                color: .purple
                            ) {
                                // TODO: Navigate to dependencies
                            }
                            
                            ActionButton(
                                title: "Базы данных",
                                icon: "cylinder",
                                color: .green
                            ) {
                                // TODO: Navigate to databases
                            }
                        }
                    }
                    
                    // Statistics
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Статистика")
                            .font(.headline)
                        
                        HStack(spacing: 16) {
                            StatCard(
                                title: "Всего сервисов",
                                value: "\(viewModel.dashboardStats.totalServices)",
                                icon: "cube",
                                color: .blue
                            )
                            
                            StatCard(
                                title: "Активных",
                                value: "\(viewModel.dashboardStats.activeServices)",
                                icon: "checkmark.circle",
                                color: .green
                            )
                            
                            StatCard(
                                title: "Эндпоинтов",
                                value: "\(viewModel.dashboardStats.endpoints)",
                                icon: "link",
                                color: .purple
                            )
                            
                            StatCard(
                                title: "Устаревших",
                                value: "\(viewModel.dashboardStats.deprecated)",
                                icon: "exclamationmark.triangle",
                                color: .orange
                            )
                        }
                    }
                    
                    // Recent Services
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Последние сервисы")
                                .font(.headline)
                            Spacer()
                            Button("Посмотреть все") {
                                // TODO: Navigate to all services
                            }
                            .foregroundColor(.blue)
                        }
                        
                        if viewModel.services.isEmpty {
                            EmptyStateView()
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(Array(viewModel.services.prefix(5))) { service in
                                    ServiceRowView(service: service)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .refreshable {
                await viewModel.loadDashboard()
            }
            .task {
                await viewModel.loadDashboard()
            }
            .sheet(isPresented: $showingCreateService) {
                CreateServiceView()
                    .environmentObject(viewModel)
            }
            .alert("Ошибка", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    DashboardView()
        .environmentObject(ServiceViewModel())
}
