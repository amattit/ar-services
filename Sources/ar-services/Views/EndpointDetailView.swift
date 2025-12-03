//
//  EndpointDetailView.swift
//  ar-services
//
//  Created by OpenHands on 02.12.2025.
//

import SwiftUI

struct EndpointDetailView: View {
    let endpoint: EndpointResponse
    let service: ServiceResponse
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
//        NavigationView {
            ScrollView {
                // Header
                EndpointHeaderView(endpoint: endpoint, service: service)
                    .padding()
                
                Divider()
                
                // Tab View
                TabView(selection: $selectedTab) {
                    // Overview Tab
                    EndpointOverviewTab(endpoint: endpoint)
                        .tabItem {
                            Label("Обзор", systemImage: "info.circle")
                        }
                        .tag(0)
                    
                    // Schema Tab
                    EndpointSchemaTab(endpoint: endpoint)
                        .tabItem {
                            Label("Схемы", systemImage: "doc.text")
                        }
                        .tag(1)
                    
                    // Dependencies Tab
                    EndpointDependenciesTab(endpoint: endpoint)
                        .tabItem {
                            Label("Зависимости", systemImage: "arrow.triangle.branch")
                        }
                        .tag(2)
                    
                    // Security Tab
                    EndpointSecurityTab(endpoint: endpoint)
                        .tabItem {
                            Label("Безопасность", systemImage: "lock")
                        }
                        .tag(3)
                }
            }
            .navigationTitle("Детали Endpoint")
//            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
//        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

// MARK: - Endpoint Header View

struct EndpointHeaderView: View {
    let endpoint: EndpointResponse
    let service: ServiceResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Method and Path
            HStack(spacing: 12) {
                Text(endpoint.method.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(colorForMethod(endpoint.method))
                    )
                
                Text(endpoint.path)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            // Summary
            Text(endpoint.summary)
                .font(.headline)
                .foregroundColor(.secondary)
            
            // Service info
            HStack {
                Text("Сервис:")
                    .foregroundColor(.secondary)
                Text(service.name)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("Обновлен:")
                    .foregroundColor(.secondary)
                Text(endpoint.updatedAt, style: .date)
                    .fontWeight(.medium)
            }
            .font(.subheadline)
        }
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

// MARK: - Overview Tab

struct EndpointOverviewTab: View {
    let endpoint: EndpointResponse
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Basic Info
                InfoSection(title: "Основная информация") {
                    InfoRow(label: "ID", value: endpoint.endpointId.uuidString)
                    InfoRow(label: "Метод", value: endpoint.method.rawValue)
                    InfoRow(label: "Путь", value: endpoint.path)
                    InfoRow(label: "Описание", value: endpoint.summary)
                    InfoRow(label: "Создан", value: endpoint.createdAt.formatted())
                    InfoRow(label: "Обновлен", value: endpoint.updatedAt.formatted())
                }
                
                // Features
                InfoSection(title: "Возможности") {
                    FeatureRow(
                        icon: "lock.fill",
                        title: "Авторизация",
                        isEnabled: endpoint.auth != nil,
                        color: .orange
                    )
                    FeatureRow(
                        icon: "speedometer",
                        title: "Ограничение скорости",
                        isEnabled: endpoint.rateLimit != nil,
                        color: .red
                    )
                    FeatureRow(
                        icon: "arrow.triangle.branch",
                        title: "Зависимости",
                        isEnabled: !(endpoint.calls?.isEmpty ?? true),
                        color: .blue
                    )
                    FeatureRow(
                        icon: "cylinder.fill",
                        title: "Базы данных",
                        isEnabled: !(endpoint.databases?.isEmpty ?? true),
                        color: .green
                    )
                }
                
                // Metadata
                if let metadata = endpoint.metadata, !metadata.isEmpty {
                    InfoSection(title: "Метаданные") {
                        JSONDataView(data: metadata)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Schema Tab

struct EndpointSchemaTab: View {
    let endpoint: EndpointResponse
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Request Schema
                if let requestSchema = endpoint.requestSchema, !requestSchema.isEmpty {
                    InfoSection(title: "Схема запроса") {
                        JSONDataView(data: requestSchema)
                    }
                } else {
                    InfoSection(title: "Схема запроса") {
                        Text("Схема запроса не определена")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                
                // Response Schemas
                if let responseSchemas = endpoint.responseSchemas, !responseSchemas.isEmpty {
                    InfoSection(title: "Схемы ответов") {
                        JSONDataView(data: responseSchemas)
                    }
                } else {
                    InfoSection(title: "Схемы ответов") {
                        Text("Схемы ответов не определены")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Dependencies Tab

struct EndpointDependenciesTab: View {
    let endpoint: EndpointResponse
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Service Dependencies
                if let calls = endpoint.calls, !calls.isEmpty {
                    InfoSection(title: "Зависимости сервисов") {
                        ForEach(calls) { call in
                            DependencyCallView(call: call)
                        }
                    }
                }
                
                // Database Dependencies
                if let databases = endpoint.databases, !databases.isEmpty {
                    InfoSection(title: "Зависимости баз данных") {
                        ForEach(databases) { database in
                            DatabaseDependencyView(database: database)
                        }
                    }
                }
                
                // Empty state
                if (endpoint.calls?.isEmpty ?? true) && (endpoint.databases?.isEmpty ?? true) {
                    VStack(spacing: 16) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("Нет зависимостей")
                            .font(.headline)
                        
                        Text("Этот endpoint не имеет зависимостей от других сервисов или баз данных")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
            .padding()
        }
    }
}

// MARK: - Security Tab

struct EndpointSecurityTab: View {
    let endpoint: EndpointResponse
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Authentication
                InfoSection(title: "Аутентификация") {
                    if let auth = endpoint.auth, !auth.isEmpty {
                        JSONDataView(data: auth)
                    } else {
                        Text("Аутентификация не требуется")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                
                // Rate Limiting
                InfoSection(title: "Ограничение скорости") {
                    if let rateLimit = endpoint.rateLimit, !rateLimit.isEmpty {
                        JSONDataView(data: rateLimit)
                    } else {
                        Text("Ограничения скорости не установлены")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Helper Views

struct InfoSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .textSelection(.enabled)
            
            Spacer()
        }
        .font(.subheadline)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let isEnabled: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(isEnabled ? color : .gray)
                .frame(width: 20)
            
            Text(title)
                .foregroundColor(isEnabled ? .primary : .secondary)
            
            Spacer()
            
            Text(isEnabled ? "Включено" : "Отключено")
                .font(.caption)
                .foregroundColor(isEnabled ? color : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isEnabled ? color.opacity(0.2) : Color.gray.opacity(0.2))
                )
        }
    }
}

struct DependencyCallView: View {
    let call: EndpointCallResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: call.dependency.dependencyType.icon)
                    .foregroundColor(.blue)
                
                Text(call.dependency.name)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(call.callType.displayName)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.opacity(0.2))
                    )
            }
            
            if let description = call.dependency.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let config = call.config, !config.isEmpty {
                DisclosureGroup("Конфигурация") {
                    JSONDataView(data: config)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

struct DatabaseDependencyView: View {
    let database: EndpointDatabaseResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cylinder.fill")
                    .foregroundColor(.green)
                
                Text(database.database.name)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(database.operationType.displayName)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green.opacity(0.2))
                    )
            }
            
            if let description = database.database.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let tableNames = database.tableNames, !tableNames.isEmpty {
                Text("Таблицы: \(tableNames.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let config = database.config, !config.isEmpty {
                DisclosureGroup("Конфигурация") {
                    JSONDataView(data: config)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.green.opacity(0.1))
        )
    }
}

#Preview {
    EndpointDetailView(
        endpoint: EndpointResponse(
            endpointId: UUID(),
            serviceId: UUID(),
            method: .GET,
            path: "/api/v1/users",
            summary: "Get all users",
            requestSchema: nil,
            responseSchemas: nil,
            auth: nil,
            rateLimit: nil,
            metadata: nil,
            calls: nil,
            databases: nil,
            createdAt: Date(),
            updatedAt: Date()
        ),
        service: ServiceResponse(
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
        )
    )
}
