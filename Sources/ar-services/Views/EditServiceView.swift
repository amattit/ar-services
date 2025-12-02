//
//  EditServiceView.swift
//  api-registry-descktop
//
//  Created by OpenHands on 01.12.2025.
//

import SwiftUI

struct EditServiceView: View {
    let service: ServiceResponse
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var serviceViewModel: ServiceViewModel
    @StateObject private var formData = CreateServiceFormData()
    @State private var isUpdating = false
    @State private var showingDeleteConfirmation = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Service Info Header
                ServiceInfoCard(service: service)
                    .padding()
                
                Divider()
                
                // Tab View
                TabView(selection: $selectedTab) {
                    // Service Settings Tab
                    ServiceSettingsTab(
                        service: service,
                        formData: formData,
                        isUpdating: $isUpdating,
                        showingDeleteConfirmation: $showingDeleteConfirmation
                    )
                    .tabItem {
                        Label("Настройки", systemImage: "gear")
                    }
                    .tag(0)
                    
                    // Endpoints Tab
                    EndpointsView(service: service)
                        .tabItem {
                            Label("Endpoints", systemImage: "list.bullet.rectangle")
                        }
                        .tag(1)
                }
            }
            .navigationTitle("Редактирование сервиса")
//            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        updateService()
                    }
                    .disabled(!formData.isValid || isUpdating)
                    .buttonStyle(.borderedProminent)
                }
            }
            .disabled(isUpdating)
            .overlay {
                if isUpdating {
                    ProgressView("Обновление сервиса...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
            .onAppear {
                formData.populate(from: service)
            }
            .confirmationDialog(
                "Удалить сервис",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Удалить", role: .destructive) {
                    deleteService()
                }
                Button("Отмена", role: .cancel) { }
            } message: {
                Text("Вы уверены, что хотите удалить сервис \"\(service.name)\"? Это действие нельзя отменить.")
            }
        }
        .frame(minWidth: 600, minHeight: 700)
    }
    
    private func updateService() {
        isUpdating = true
        
        Task {
            let success = await serviceViewModel.updateService(
                id: service.serviceId,
                request: formData.toUpdateRequest()
            )
            
            await MainActor.run {
                isUpdating = false
                if success {
                    dismiss()
                }
            }
        }
    }
    
    private func deleteService() {
        isUpdating = true
        
        Task {
            let success = await serviceViewModel.deleteService(id: service.serviceId)
            
            await MainActor.run {
                isUpdating = false
                if success {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Service Info Card

struct ServiceInfoCard: View {
    let service: ServiceResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: serviceTypeIcon(service.serviceType))
                    .foregroundColor(serviceTypeColor(service.serviceType))
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("ID: \(service.serviceId.uuidString)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(service.serviceType.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(serviceTypeColor(service.serviceType).opacity(0.2))
                        )
                        .foregroundColor(serviceTypeColor(service.serviceType))
                    
                    if let createdAt = service.createdAt {
                        Text("Создан: \(createdAt, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let description = service.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label(service.owner, systemImage: "person")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 12) {
                    if service.supportsDatabase {
                        Label("База данных", systemImage: "cylinder.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    if service.proxy {
                        Label("Прокси", systemImage: "arrow.triangle.branch")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }
            }
            
            if !service.tags.isEmpty {
                TagsView(tags: service.tags)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func serviceTypeIcon(_ type: ServiceType) -> String {
        switch type {
        case .APPLICATION:
            return "app"
        case .LIBRARY:
            return "books.vertical"
        case .JOB:
            return "clock"
        case .PROXY:
            return "arrow.triangle.branch"
        }
    }
    
    private func serviceTypeColor(_ type: ServiceType) -> Color {
        switch type {
        case .APPLICATION:
            return .blue
        case .LIBRARY:
            return .green
        case .JOB:
            return .orange
        case .PROXY:
            return .purple
        }
    }
}

// MARK: - Danger Zone

struct DangerZoneView: View {
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Опасная зона")
                .font(.headline)
                .foregroundColor(.red)
            
            Text("Удаление сервиса необратимо. Все связанные данные будут потеряны.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Удалить сервис") {
                onDelete()
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Service Settings Tab

struct ServiceSettingsTab: View {
    let service: ServiceResponse
    @ObservedObject var formData: CreateServiceFormData
    @Binding var isUpdating: Bool
    @Binding var showingDeleteConfirmation: Bool
    @EnvironmentObject private var serviceViewModel: ServiceViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Настройки сервиса")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Обновите информацию о сервисе \(service.name)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Form
                VStack(alignment: .leading, spacing: 20) {
                    // Service Name
                    FormField(
                        title: "Название сервиса",
                        isRequired: true,
                        description: "Уникальное название для идентификации сервиса"
                    ) {
                        TextField("Например: user-service", text: $formData.name)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Description
                    FormField(
                        title: "Описание",
                        description: "Опишите основную функциональность и назначение сервиса"
                    ) {
                        TextEditor(text: $formData.description)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Owner
                    FormField(
                        title: "Владелец",
                        isRequired: true,
                        description: "Команда или разработчик, ответственный за сервис"
                    ) {
                        TextField("Например: backend-team", text: $formData.owner)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Tags
                    FormField(
                        title: "Теги",
                        description: "Добавьте теги для категоризации сервиса (например: users, authentication, api)"
                    ) {
                        TextField("Добавить тег...", text: $formData.tags)
                            .textFieldStyle(.roundedBorder)
                        
                        if !formData.tagsArray.isEmpty {
                            TagsView(tags: formData.tagsArray)
                        }
                    }
                    
                    // Service Type
                    FormField(
                        title: "Тип сервиса",
                        isRequired: true,
                        description: "Выберите тип сервиса для правильной категоризации"
                    ) {
                        Picker("Тип сервиса", selection: $formData.serviceType) {
                            ForEach(ServiceType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    // Options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Дополнительные опции")
                            .font(.headline)
                        
                        Toggle("Поддерживает базу данных", isOn: $formData.supportsDatabase)
                        Toggle("Использует прокси", isOn: $formData.proxy)
                    }
                }
                
                // Action Buttons
                HStack {
                    Button("Сохранить изменения") {
                        updateService()
                    }
                    .disabled(!formData.isValid || isUpdating)
                    .buttonStyle(.borderedProminent)
                    
                    if isUpdating {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                // Danger Zone
                DangerZoneView {
                    showingDeleteConfirmation = true
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            formData.populate(from: service)
        }
    }
    
    private func updateService() {
        isUpdating = true
        
        Task {
            let success = await serviceViewModel.updateService(
                id: service.serviceId,
                request: formData.toUpdateRequest()
            )
            
            await MainActor.run {
                isUpdating = false
                if success {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EditServiceView(
        service: ServiceResponse(
            serviceId: UUID(),
            name: "user-service",
            description: "Сервис управления пользователями",
            owner: "backend-team",
            tags: ["users", "authentication"],
            serviceType: .APPLICATION,
            supportsDatabase: true,
            proxy: false,
            createdAt: Date(),
            updatedAt: Date(),
            environments: nil
        )
    )
    .environmentObject(ServiceViewModel())
}
