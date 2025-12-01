//
//  CreateServiceView.swift
//  api-registry-descktop
//
//  Created by OpenHands on 01.12.2025.
//

import SwiftUI

struct CreateServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var serviceViewModel: ServiceViewModel
    @StateObject private var formData = CreateServiceFormData()
    @State private var isCreating = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Новый сервис")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Создайте новый микросервис в API Registry")
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
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Создание сервиса")
//            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать сервис") {
                        createService()
                    }
                    .disabled(!formData.isValid || isCreating)
                    .buttonStyle(.borderedProminent)
                }
            }
            .disabled(isCreating)
            .overlay {
                if isCreating {
                    ProgressView("Создание сервиса...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
        }
        .frame(minWidth: 600, minHeight: 700)
    }
    
    private func createService() {
        isCreating = true
        
        Task {
            let success = await serviceViewModel.createService(formData.toCreateRequest())
            
            await MainActor.run {
                isCreating = false
                if success {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Form Field Component

struct FormField<Content: View>: View {
    let title: String
    let isRequired: Bool
    let description: String?
    @ViewBuilder let content: Content
    
    init(
        title: String,
        isRequired: Bool = false,
        description: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.isRequired = isRequired
        self.description = description
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                
                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                }
            }
            
            if let description = description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            content
        }
    }
}

// MARK: - Tags View

struct TagsView: View {
    let tags: [String]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 80))
        ], alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.2))
                    )
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Recommendations View

struct RecommendationsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.blue)
                Text("Рекомендации по созданию сервиса")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                RecommendationItem(text: "Используйте понятные и описательные названия сервисов")
                RecommendationItem(text: "Укажите команду или разработчика, ответственного за сервис")
                RecommendationItem(text: "Добавьте релевантные теги для упрощения поиска и категоризации")
                RecommendationItem(text: "Выберите правильный тип сервиса для корректной классификации")
                RecommendationItem(text: "Отметьте, если сервис работает с базой данных или использует прокси")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct RecommendationItem: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.blue)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    CreateServiceView()
        .environmentObject(ServiceViewModel())
}
