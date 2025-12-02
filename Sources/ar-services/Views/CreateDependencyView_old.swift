//
//  CreateDependencyView.swift
//  ar-services
//
//  Created by OpenHands on 01.12.2025.
//

import SwiftUI

struct CreateDependencyView: View {
    @EnvironmentObject private var dependencyViewModel: DependencyViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedServiceId: UUID?
    @State private var selectedDependsOnServiceId: UUID?
    @State private var selectedDependencyType: DependencyType = .SYNCHRONOUS
    @State private var description: String = ""
    @State private var isCreating = false
    
    private var isFormValid: Bool {
        selectedServiceId != nil &&
        selectedDependsOnServiceId != nil &&
        selectedServiceId != selectedDependsOnServiceId
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Form
                ScrollView {
                    VStack(spacing: 20) {
                        serviceSelectionSection
                        dependsOnServiceSelectionSection
                        dependencyTypeSection
                        descriptionSection
                    }
                    .padding()
                }
                
                // Buttons
                buttonsView
            }
            .frame(width: 500, height: 600)
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Text("Добавить зависимость")
                .font(.headline)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Service Selection Section
    
    private var serviceSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Сервис")
                .font(.headline)
            
            Menu {
                ForEach(dependencyViewModel.services) { service in
                    Button(service.name) {
                        selectedServiceId = service.serviceId
                    }
                }
            } label: {
                HStack {
                    Text(selectedServiceName)
                        .foregroundColor(selectedServiceId == nil ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
            }
            .menuStyle(.borderlessButton)
        }
    }
    
    // MARK: - Depends On Service Selection Section
    
    private var dependsOnServiceSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Зависит от сервиса")
                .font(.headline)
            
            Menu {
                ForEach(availableDependsOnServices) { service in
                    Button(service.name) {
                        selectedDependsOnServiceId = service.serviceId
                    }
                }
            } label: {
                HStack {
                    Text(selectedDependsOnServiceName)
                        .foregroundColor(selectedDependsOnServiceId == nil ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
            }
            .menuStyle(.borderlessButton)
            .disabled(selectedServiceId == nil)
        }
    }
    
    // MARK: - Dependency Type Section
    
    private var dependencyTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Тип зависимости")
                .font(.headline)
            
            Menu {
                ForEach(DependencyType.allCases, id: \.self) { type in
                    Button(type.displayName) {
                        selectedDependencyType = type
                    }
                }
            } label: {
                HStack {
                    Text(selectedDependencyType.displayName)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
            }
            .menuStyle(.borderlessButton)
        }
    }
    
    // MARK: - Description Section
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Описание")
                .font(.headline)
            
            TextEditor(text: $description)
                .frame(height: 100)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
                .font(.body)
        }
    }
    
    // MARK: - Buttons View
    
    private var buttonsView: some View {
        HStack {
            Button("Отмена") {
                dismiss()
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button("Добавить") {
                Task {
                    await createDependency()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isFormValid || isCreating)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Computed Properties
    
    private var selectedServiceName: String {
        guard let selectedServiceId = selectedServiceId else {
            return "Выберите сервис"
        }
        return dependencyViewModel.services.first { $0.serviceId == selectedServiceId }?.name ?? "Выберите сервис"
    }
    
    private var selectedDependsOnServiceName: String {
        guard let selectedDependsOnServiceId = selectedDependsOnServiceId else {
            return "Выберите зависимый сервис"
        }
        return dependencyViewModel.services.first { $0.serviceId == selectedDependsOnServiceId }?.name ?? "Выберите зависимый сервис"
    }
    
    private var availableDependsOnServices: [ServiceResponse] {
        dependencyViewModel.services.filter { service in
            service.serviceId != selectedServiceId
        }
    }
    
    // MARK: - Actions
    
    private func createDependency() async {
        guard let serviceId = selectedServiceId,
              let dependsOnServiceId = selectedDependsOnServiceId else {
            return
        }
        
        isCreating = true
        
        let request = CreateDependencyRequest(
            serviceId: serviceId,
            dependsOnServiceId: dependsOnServiceId,
            dependencyType: selectedDependencyType,
            description: description.isEmpty ? nil : description
        )
        
        let success = await dependencyViewModel.createDependency(request)
        
        isCreating = false
        
        if success {
            dismiss()
        }
    }
}

#Preview {
    CreateDependencyView()
        .environmentObject(DependencyViewModel())
}