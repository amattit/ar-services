//
//  DashboardComponents.swift
//  api-registry-descktop
//
//  Created by OpenHands on 01.12.2025.
//

import SwiftUI

// MARK: - Action Button

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered in
            // Add hover effect if needed
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Service Row View

struct ServiceRowView: View {
    let service: ServiceResponse
    
    var body: some View {
        HStack(spacing: 12) {
            // Service Type Icon
            Image(systemName: serviceTypeIcon(service.serviceType))
                .foregroundColor(serviceTypeColor(service.serviceType))
                .font(.title3)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(service.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let description = service.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text(service.owner)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(service.serviceType.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(serviceTypeColor(service.serviceType).opacity(0.2))
                        )
                        .foregroundColor(serviceTypeColor(service.serviceType))
                }
            }
            
            Spacer()
            
            // Status indicators
            VStack(alignment: .trailing, spacing: 4) {
                if service.supportsDatabase {
                    Image(systemName: "cylinder.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                
                if service.proxy {
                    Image(systemName: "arrow.triangle.branch")
                        .foregroundColor(.purple)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
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

// MARK: - Empty State View

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cube")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("Нет сервисов")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Создайте первый сервис для начала работы")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Создать сервис") {
                // This will be handled by parent view
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Previews

#Preview("Action Button") {
    ActionButton(
        title: "Новый сервис",
        icon: "plus",
        color: .blue
    ) {
        print("Button tapped")
    }
    .frame(width: 120)
}

#Preview("Stat Card") {
    StatCard(
        title: "Всего сервисов",
        value: "12",
        icon: "cube",
        color: .blue
    )
    .frame(width: 150)
}

#Preview("Service Row") {
    ServiceRowView(
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
    .frame(width: 400)
}

#Preview("Empty State") {
    EmptyStateView()
        .frame(width: 400)
}