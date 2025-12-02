//
//  DependencyGraphView.swift
//  ar-services
//
//  Created by OpenHands on 01.12.2025.
//

import SwiftUI

struct DependencyGraphView: View {
    let dependencyViewModel: DependencyViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedNode: DependencyNode?
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Graph Content
                if let graph = dependencyViewModel.dependencyGraph {
                    graphView(graph: graph)
                } else {
                    loadingOrEmptyView
                }
            }
            .frame(minWidth: 800, minHeight: 600)
            .task {
                await dependencyViewModel.loadDependencyGraph()
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Text("Граф зависимостей")
                .font(.headline)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button("Сбросить масштаб") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        scale = 1.0
                        offset = .zero
                    }
                }
                .buttonStyle(.bordered)
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Graph View
    
    private func graphView(graph: DependencyGraph) -> some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(NSColor.controlBackgroundColor)
                    .opacity(0.3)
                
                // Graph Content
                ZStack {
                    // Edges (connections)
                    ForEach(graph.edges) { edge in
                        if let fromNode = graph.nodes.first(where: { $0.id == edge.fromNodeId }),
                           let toNode = graph.nodes.first(where: { $0.id == edge.toNodeId }) {
                            EdgeView(
                                from: nodePosition(for: fromNode, in: geometry.size),
                                to: nodePosition(for: toNode, in: geometry.size),
                                edge: edge
                            )
                        }
                    }
                    
                    // Nodes (services)
                    ForEach(graph.nodes) { node in
                        NodeView(
                            node: node,
                            isSelected: selectedNode?.id == node.id
                        )
                        .position(nodePosition(for: node, in: geometry.size))
                        .onTapGesture {
                            selectedNode = selectedNode?.id == node.id ? nil : node
                        }
                    }
                }
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    SimultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = max(0.5, min(3.0, value))
                            },
                        DragGesture()
                            .onChanged { value in
                                offset = value.translation
                            }
                    )
                )
                
                // Legend
                legendView
                    .position(x: geometry.size.width - 120, y: 80)
                
                // Selected Node Info
                if let selectedNode = selectedNode {
                    selectedNodeInfoView(node: selectedNode)
                        .position(x: 150, y: geometry.size.height - 100)
                }
            }
        }
    }
    
    // MARK: - Loading or Empty View
    
    private var loadingOrEmptyView: some View {
        VStack(spacing: 16) {
            if dependencyViewModel.isLoading {
                ProgressView("Загрузка графа зависимостей...")
            } else {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 48))
                    .foregroundColor(.gray)
                
                Text("Граф зависимостей недоступен")
                    .font(.headline)
                
                Text("Добавьте зависимости между сервисами")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Legend View
    
    private var legendView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Легенда")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(DependencyType.allCases, id: \.self) { type in
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(colorForDependencyType(type))
                        .frame(width: 16, height: 3)
                    
                    Text(type.displayName)
                        .font(.caption)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(radius: 2)
        )
    }
    
    // MARK: - Selected Node Info View
    
    private func selectedNodeInfoView(node: DependencyNode) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(node.name)
                .font(.headline)
            
            Text("Тип: \(node.type)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let serviceType = node.serviceType {
                Text("Сервис: \(serviceType)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let description = node.metadata["description"]?.value as? String, !description.isEmpty {
                Text("Описание: \(description)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(radius: 2)
        )
    }
    
    // MARK: - Helper Methods
    
    private func nodePosition(for node: DependencyNode, in size: CGSize) -> CGPoint {
        // Простое размещение узлов по кругу
        let nodes = dependencyViewModel.dependencyGraph?.nodes ?? []
        guard let index = nodes.firstIndex(where: { $0.id == node.id }) else {
            return CGPoint(x: size.width / 2, y: size.height / 2)
        }
        
        let angle = Double(index) * 2.0 * Double.pi / Double(nodes.count)
        let radius = min(size.width, size.height) * 0.3
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        return CGPoint(
            x: centerX + cos(angle) * radius,
            y: centerY + sin(angle) * radius
        )
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

// MARK: - Node View

struct NodeView: View {
    let node: DependencyNode
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(serviceTypeColor)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )
                .overlay(
                    Text(String(node.name.prefix(2).uppercased()))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            Text(node.name)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
    }
    
    private var serviceTypeColor: Color {
        if node.type == "service" {
            // Color based on service type from metadata
            if let serviceType = node.serviceType {
                switch serviceType.uppercased() {
                case "APPLICATION":
                    return .blue
                case "LIBRARY":
                    return .green
                case "JOB":
                    return .orange
                case "PROXY":
                    return .purple
                default:
                    return .gray
                }
            }
            return .blue
        } else {
            // Color for dependencies
            return .gray
        }
    }
}

// MARK: - Edge View

struct EdgeView: View {
    let from: CGPoint
    let to: CGPoint
    let edge: DependencyEdge
    
    var body: some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(edgeColor, lineWidth: 2)
        .overlay(
            // Arrow head
            Path { path in
                let angle = atan2(to.y - from.y, to.x - from.x)
                let arrowLength: CGFloat = 10
                let arrowAngle: CGFloat = 0.5
                
                let arrowPoint1 = CGPoint(
                    x: to.x - arrowLength * cos(angle - arrowAngle),
                    y: to.y - arrowLength * sin(angle - arrowAngle)
                )
                let arrowPoint2 = CGPoint(
                    x: to.x - arrowLength * cos(angle + arrowAngle),
                    y: to.y - arrowLength * sin(angle + arrowAngle)
                )
                
                path.move(to: to)
                path.addLine(to: arrowPoint1)
                path.move(to: to)
                path.addLine(to: arrowPoint2)
            }
            .stroke(edgeColor, lineWidth: 2)
        )
    }
    
    private var edgeColor: Color {
        switch edge.dependencyType {
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
    DependencyGraphView()
        .environmentObject(DependencyViewModel())
}