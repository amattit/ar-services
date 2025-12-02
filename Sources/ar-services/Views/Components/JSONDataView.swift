//
//  JSONDataView.swift
//  ar-services
//
//  Created by OpenHands on 02.12.2025.
//

import SwiftUI

struct JSONDataView: View {
    let data: [String: AnyCodable]
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if data.isEmpty {
                Text("Нет данных")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                DisclosureGroup(isExpanded: $isExpanded) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(data.keys.sorted()), id: \.self) { key in
                            JSONKeyValueView(key: key, value: data[key]!)
                        }
                    }
                    .padding(.top, 8)
                } label: {
                    HStack {
                        Text("JSON данные")
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(data.count) \(pluralForm(data.count))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(NSColor.textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
    }
    
    private func pluralForm(_ count: Int) -> String {
        let remainder10 = count % 10
        let remainder100 = count % 100
        
        if remainder100 >= 11 && remainder100 <= 14 {
            return "полей"
        }
        
        switch remainder10 {
        case 1:
            return "поле"
        case 2, 3, 4:
            return "поля"
        default:
            return "полей"
        }
    }
}

struct JSONKeyValueView: View {
    let key: String
    let value: AnyCodable
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(key)
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                Text(":")
                    .foregroundColor(.secondary)
                
                if isSimpleValue {
                    Text(formattedValue)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                } else {
                    Button(action: {
                        isExpanded.toggle()
                    }) {
                        HStack(spacing: 4) {
                            Text(valueTypeDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
            
            if !isSimpleValue && isExpanded {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedComplexValue)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                        .padding(.leading, 16)
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    private var isSimpleValue: Bool {
        switch value.value {
        case is String, is Int, is Double, is Bool:
            return true
        case is NSNull:
            return true
        default:
            return false
        }
    }
    
    private var formattedValue: String {
        switch value.value {
        case let string as String:
            return "\"\(string)\""
        case let int as Int:
            return "\(int)"
        case let double as Double:
            return "\(double)"
        case let bool as Bool:
            return bool ? "true" : "false"
        case is NSNull:
            return "null"
        default:
            return "\(value.value)"
        }
    }
    
    private var valueTypeDescription: String {
        switch value.value {
        case is [Any]:
            let array = value.value as! [Any]
            return "массив (\(array.count) элементов)"
        case is [String: Any]:
            let dict = value.value as! [String: Any]
            return "объект (\(dict.count) полей)"
        default:
            return "сложное значение"
        }
    }
    
    private var formattedComplexValue: String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: value.value, options: [.prettyPrinted, .sortedKeys])
            return String(data: jsonData, encoding: .utf8) ?? "Ошибка форматирования"
        } catch {
            return "Ошибка: \(error.localizedDescription)"
        }
    }
}

// MARK: - Compact JSON View

struct CompactJSONView: View {
    let data: [String: AnyCodable]
    let maxLines: Int = 3
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            let keys = Array(data.keys.sorted().prefix(maxLines))
            
            ForEach(keys, id: \.self) { key in
                HStack {
                    Text(key)
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    Text(":")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    Text(compactValue(data[key]!))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Spacer()
                }
            }
            
            if data.count > maxLines {
                Text("... и еще \(data.count - maxLines)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
    
    private func compactValue(_ value: AnyCodable) -> String {
        switch value.value {
        case let string as String:
            return "\"\(string)\""
        case let int as Int:
            return "\(int)"
        case let double as Double:
            return "\(double)"
        case let bool as Bool:
            return bool ? "true" : "false"
        case is NSNull:
            return "null"
        case is [Any]:
            let array = value.value as! [Any]
            return "[массив из \(array.count)]"
        case is [String: Any]:
            let dict = value.value as! [String: Any]
            return "{объект из \(dict.count)}"
        default:
            return "сложное значение"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        JSONDataView(data: [
            "name": AnyCodable("John Doe"),
            "age": AnyCodable(30),
            "active": AnyCodable(true),
            "metadata": AnyCodable([
                "role": "admin",
                "permissions": ["read", "write"]
            ])
        ])
        
        CompactJSONView(data: [
            "timeout": AnyCodable(5000),
            "retries": AnyCodable(3),
            "enabled": AnyCodable(true)
        ])
    }
    .padding()
}