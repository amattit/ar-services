//
//  CreateDependencyView.swift
//  ar-services
//
//  Created by OpenHands on 01.12.2025.
//

import SwiftUI

struct CreateDependencyView: View {
    let dependencyViewModel: DependencyViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var createMode: CreateMode = .dependency
    
    // For creating new dependency
    @State private var dependencyName: String = ""
    @State private var dependencyDescription: String = ""
    @State private var dependencyVersion: String = ""
    @State private var dependencyType: DependencyType = .LIBRARY
    @State private var dependencyConfig: [String: String] = [:]
    
    // For adding service dependency
    @State private var selectedServiceId: UUID?
    @State private var selectedDependencyId: UUID?
    @State private var environmentCode: String = "prod"
    
    // For service-to-service dependency
    @State private var consumerServiceId: UUID?
    @State private var providerServiceId: UUID?
    @State private var serviceToServiceDescription: String = ""
    @State private var serviceDependencyType: ServiceDependencyType = .API_CALL
    @State private var serviceToServiceConfig: [String: String] = [:]
    @State private var serviceEnvironmentCode: String = "prod"
    
    @State private var isCreating = false
    
    enum CreateMode: String, CaseIterable {
        case dependency = "Новая зависимость"
        case serviceDependency = "Добавить к сервису"
        case serviceToService = "Связь между сервисами"
    }
    
    private var isFormValid: Bool {
        switch createMode {
        case .dependency:
            return !dependencyName.isEmpty && !dependencyVersion.isEmpty
        case .serviceDependency:
            return selectedServiceId != nil && selectedDependencyId != nil
        case .serviceToService:
            return consumerServiceId != nil && providerServiceId != nil && consumerServiceId != providerServiceId
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Mode Selection
                modeSelectionView
                
                // Form
                ScrollView {
                    VStack(spacing: 20) {
                        switch createMode {
                        case .dependency:
                            dependencyFormSection
                        case .serviceDependency:
                            serviceDependencyFormSection
                        case .serviceToService:
                            serviceToServiceFormSection
                        }
                    }
                    .padding()
                }
                
                // Buttons
                buttonsView
            }
            .frame(width: 500, height: 700)
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Добавить зависимость")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color(.systemGray))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .background(Color(.systemGray))
    }
    
    // MARK: - Mode Selection
    
    private var modeSelectionView: some View {
        Picker("Режим", selection: $createMode) {
            ForEach(CreateMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .background(Color(.controlBackgroundColor))
    }
    
    // MARK: - Dependency Form
    
    private var dependencyFormSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Создать новую зависимость")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Название")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Например: postgresql, jwt-library", text: $dependencyName)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Версия")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Например: 14.5, 3.2.1", text: $dependencyVersion)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Тип зависимости")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Тип", selection: $dependencyType) {
                    ForEach(DependencyType.allCases, id: \.self) { type in
                        HStack {
                            Image(systemName: type.icon)
                            Text(type.displayName)
                        }.tag(type)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Описание")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Описание зависимости...", text: $dependencyDescription, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Конфигурация")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                VStack(spacing: 8) {
                    ForEach(Array(dependencyConfig.keys.sorted()), id: \.self) { key in
                        HStack {
                            TextField("Ключ", text: .constant(key))
                                .textFieldStyle(.roundedBorder)
                                .disabled(true)
                            
                            TextField("Значение", text: Binding(
                                get: { dependencyConfig[key] ?? "" },
                                set: { dependencyConfig[key] = $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                            
                            Button(action: {
                                dependencyConfig.removeValue(forKey: key)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    Button("Добавить параметр") {
                        dependencyConfig["new_key"] = ""
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    // MARK: - Service Dependency Form
    @MainActor
    private var serviceDependencyFormSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Добавить зависимость к сервису")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Сервис")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Выберите сервис", selection: $selectedServiceId) {
                    Text("Выберите сервис").tag(nil as UUID?)
                    ForEach(dependencyViewModel.services, id: \.serviceId) { service in
                        Text(service.name).tag(service.serviceId as UUID?)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Зависимость")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Выберите зависимость", selection: $selectedDependencyId) {
                    Text("Выберите зависимость").tag(nil as UUID?)
                    ForEach(dependencyViewModel.dependencies, id: \.dependencyId) { dependency in
                        HStack {
                            Image(systemName: dependency.dependencyType.icon)
                            Text("\(dependency.name) v\(dependency.version)")
                        }.tag(dependency.dependencyId as UUID?)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Окружение")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("prod, dev, staging", text: $environmentCode)
                    .textFieldStyle(.roundedBorder)
            }
            
            if let selectedDependencyId = selectedDependencyId,
               let dependency = dependencyViewModel.dependencies.first(where: { $0.dependencyId == selectedDependencyId }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Информация о зависимости")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: dependency.dependencyType.icon)
                                .foregroundColor(.blue)
                            Text(dependency.dependencyType.displayName)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        if let description = dependency.description {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if !dependency.config.isEmpty {
                            Text("Конфигурация: \(dependency.config.keys.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Service-to-Service Form
    
    private var serviceToServiceFormSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Создать связь между сервисами")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Сервис-потребитель")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Выберите сервис-потребитель", selection: $consumerServiceId) {
                    Text("Выберите сервис").tag(nil as UUID?)
                    ForEach(dependencyViewModel.services, id: \.serviceId) { service in
                        Text(service.name).tag(service.serviceId as UUID?)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Сервис-провайдер")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Выберите сервис-провайдер", selection: $providerServiceId) {
                    Text("Выберите сервис").tag(nil as UUID?)
                    ForEach(dependencyViewModel.services.filter { $0.serviceId != consumerServiceId }, id: \.serviceId) { service in
                        Text(service.name).tag(service.serviceId as UUID?)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Тип зависимости")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Тип зависимости", selection: $serviceDependencyType) {
                    ForEach(ServiceDependencyType.allCases, id: \.self) { type in
                        HStack {
                            Image(systemName: type.icon)
                            Text(type.displayName)
                        }
                        .tag(type)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Описание")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Описание зависимости...", text: $serviceToServiceDescription, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Окружение")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("prod, dev, staging", text: $serviceEnvironmentCode)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Configuration section
            VStack(alignment: .leading, spacing: 8) {
                Text("Конфигурация")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                VStack(spacing: 8) {
                    switch serviceDependencyType {
                    case .API_CALL:
                        configField(key: "endpoint", placeholder: "/api/v1/endpoint")
                        configField(key: "timeout", placeholder: "5s")
                        configField(key: "retries", placeholder: "3")
                    case .EVENT_SUBSCRIPTION:
                        configField(key: "topic", placeholder: "events.topic")
                        configField(key: "consumer_group", placeholder: "service-name")
                        configField(key: "auto_offset_reset", placeholder: "earliest")
                    case .DATA_SHARING:
                        configField(key: "database", placeholder: "shared_db")
                        configField(key: "table", placeholder: "shared_table")
                    case .AUTHENTICATION:
                        configField(key: "endpoint", placeholder: "/api/v1/auth")
                        configField(key: "timeout", placeholder: "3s")
                    case .PROXY:
                        configField(key: "upstream", placeholder: "http://service:8080")
                        configField(key: "path", placeholder: "/api/*")
                    case .LIBRARY_USAGE:
                        configField(key: "library", placeholder: "shared-lib")
                        configField(key: "version", placeholder: "1.0.0")
                    }
                }
            }
            
            // Type description
            VStack(alignment: .leading, spacing: 4) {
                Text("О типе зависимости")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(serviceDependencyType.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.systemGray))
            .cornerRadius(8)
        }
    }
    
    private func configField(key: String, placeholder: String) -> some View {
        HStack {
            Text("\(key):")
                .font(.caption)
                .frame(width: 80, alignment: .leading)
            
            TextField(placeholder, text: Binding(
                get: { serviceToServiceConfig[key] ?? "" },
                set: { serviceToServiceConfig[key] = $0.isEmpty ? nil : $0 }
            ))
            .textFieldStyle(.roundedBorder)
        }
    }
    
    // MARK: - Buttons View
    
    private var buttonsView: some View {
        HStack(spacing: 12) {
            Button("Отмена") {
                dismiss()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            
            Button(createMode == .dependency ? "Создать" : "Добавить") {
                Task {
                    await createDependency()
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .disabled(!isFormValid || isCreating)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemGray))
    }
    
    // MARK: - Actions
    
    private func createDependency() async {
        isCreating = true
        
        let success: Bool
        
        switch createMode {
        case .dependency:
            let request = CreateDependencyRequest(
                name: dependencyName,
                description: dependencyDescription.isEmpty ? nil : dependencyDescription,
                version: dependencyVersion,
                dependencyType: dependencyType,
                config: dependencyConfig
            )
            success = await dependencyViewModel.createDependency(request)
            
        case .serviceDependency:
            guard let serviceId = selectedServiceId,
                  let dependencyId = selectedDependencyId else {
                isCreating = false
                return
            }
            
            success = await dependencyViewModel.createServiceDependency(
                serviceId: serviceId,
                dependencyId: dependencyId,
                environmentCode: environmentCode.isEmpty ? nil : environmentCode
            )
            
        case .serviceToService:
            guard let consumerServiceId = consumerServiceId,
                  let providerServiceId = providerServiceId else {
                isCreating = false
                return
            }
            
            let request = CreateServiceToServiceDependencyRequest(
                providerServiceId: providerServiceId,
                environmentCode: serviceEnvironmentCode.isEmpty ? nil : serviceEnvironmentCode,
                description: serviceToServiceDescription.isEmpty ? nil : serviceToServiceDescription,
                dependencyType: serviceDependencyType,
                config: serviceToServiceConfig
            )
            
            success = await dependencyViewModel.createServiceToServiceDependency(
                consumerServiceId: consumerServiceId,
                request: request
            )
        }
        
        isCreating = false
        
        if success {
            dismiss()
        }
    }
}

#Preview {
    CreateDependencyView(dependencyViewModel: DependencyViewModel())
}
