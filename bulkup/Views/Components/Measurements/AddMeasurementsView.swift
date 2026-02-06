//
//  AddMeasurementsView.swift
//  bulkup
//
//  Created by sebastian.blanco on 25/8/25.
//

import SwiftUI

struct AddMeasurementsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var measurementsManager: BodyMeasurementsManager
    @ObservedObject private var profileManager = ProfileManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // Campos requeridos
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var age: String = ""
    @State private var sex: String = "H" // H = Hombre, M = Mujer
    @State private var waist: String = ""
    @State private var neck: String = ""
    
    // Campos opcionales
    @State private var hip: String = ""
    @State private var arm: String = ""
    @State private var thigh: String = ""
    @State private var calf: String = ""
    
    @State private var showingOptionalFields = false
    @State private var isLoading = false
    @State private var hasCalculatedAge = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "figure.arms.open")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        
                        Text("Nuevas Medidas")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Registra tus medidas para calcular tu composición corporal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Campos requeridos
                    VStack(spacing: 20) {
                        Text("Información Básica")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                MeasurementField(
                                    title: "Peso",
                                    value: $weight,
                                    unit: "kg",
                                    icon: "scalemass"
                                )
                                
                                MeasurementField(
                                    title: "Altura",
                                    value: $height,
                                    unit: "cm",
                                    icon: "ruler"
                                )
                            }
                            
                            HStack(spacing: 12) {
                                MeasurementField(
                                    title: "Edad",
                                    value: $age,
                                    unit: "años",
                                    icon: "calendar"
                                )
                                
                                // Selector de sexo
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Sexo", systemImage: "person.2")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Picker("Sexo", selection: $sex) {
                                        Text("Hombre").tag("H")
                                        Text("Mujer").tag("M")
                                    }
                                    .pickerStyle(.segmented)
                                }
                            }
                            
                            // Nota sobre edad calculada automáticamente
                            if hasCalculatedAge {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    
                                    Text("Edad calculada desde tu fecha de nacimiento. Puedes modificarla si es necesario.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                            }
                            
                            HStack(spacing: 12) {
                                MeasurementField(
                                    title: "Cintura",
                                    value: $waist,
                                    unit: "cm",
                                    icon: "circle.dashed"
                                )
                                
                                MeasurementField(
                                    title: "Cuello",
                                    value: $neck,
                                    unit: "cm",
                                    icon: "circle"
                                )
                            }
                        }
                    }
                    
                    // Toggle para campos opcionales
                    Button {
                        withAnimation(.spring()) {
                            showingOptionalFields.toggle()
                        }
                    } label: {
                        HStack {
                            Text("Medidas Adicionales")
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Image(systemName: showingOptionalFields ? "chevron.up" : "chevron.down")
                                .font(.caption)
                        }
                        .foregroundColor(.green)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Campos opcionales
                    if showingOptionalFields {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                MeasurementField(
                                    title: "Cadera",
                                    value: $hip,
                                    unit: "cm",
                                    icon: "circle.dotted",
                                    isOptional: true
                                )
                                
                                MeasurementField(
                                    title: "Brazo",
                                    value: $arm,
                                    unit: "cm",
                                    icon: "arm.wave",
                                    isOptional: true
                                )
                            }
                            
                            HStack(spacing: 12) {
                                MeasurementField(
                                    title: "Muslo",
                                    value: $thigh,
                                    unit: "cm",
                                    icon: "figure.walk",
                                    isOptional: true
                                )
                                
                                MeasurementField(
                                    title: "Pantorrilla",
                                    value: $calf,
                                    unit: "cm",
                                    icon: "figure.run",
                                    isOptional: true
                                )
                            }
                        }
                        .transition(.opacity.combined(with: .slide))
                    }
                    
                    // Botón de guardar
                    Button {
                        saveMeasurements()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            
                            Text(isLoading ? "Guardando..." : "Guardar Medidas")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isLoading || !isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)
                    
                    Color.clear
                        .frame(height: 20)
                }
                .padding()
            }
            .navigationTitle("Agregar Medidas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }.onAppear {
            calculateAgeFromProfile()
        }
    }
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        !weight.isEmpty &&
        !height.isEmpty &&
        !age.isEmpty &&
        !waist.isEmpty &&
        !neck.isEmpty &&
        Double(weight) != nil &&
        Double(height) != nil &&
        Int(age) != nil &&
        Double(waist) != nil &&
        Double(neck) != nil
    }
    
    // MARK: - Functions
    private func saveMeasurements() {
        guard let userId = authManager.user?.id,
              let weightValue = Double(weight),
              let heightValue = Double(height),
              let ageValue = Int(age),
              let waistValue = Double(waist),
              let neckValue = Double(neck) else {
            return
        }
        
        isLoading = true
        
        Task {
            await measurementsManager.saveMeasurements(
                userId: userId,
                weight: weightValue,
                height: heightValue,
                age: ageValue,
                sex: sex,
                waist: waistValue,
                neck: neckValue,
                hip: hip.isEmpty ? nil : Double(hip),
                arm: arm.isEmpty ? nil : Double(arm),
                thigh: thigh.isEmpty ? nil : Double(thigh),
                calf: calf.isEmpty ? nil : Double(calf)
            )
            
            isLoading = false
            
            if measurementsManager.errorMessage == nil {
                dismiss()
            }
        }
    }
    
    // MARK: - Calculate age from profile
    private func calculateAgeFromProfile() {
        // Solo calcular si el usuario tiene fecha de nacimiento
        if let dateOfBirth = authManager.user?.dateOfBirth {
            let calendar = Calendar.current
            let now = Date()
            let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: now)
            
            if let calculatedAge = ageComponents.year {
                age = String(calculatedAge)
                hasCalculatedAge = true
            }
        }
        // Si no tiene fecha de nacimiento, el campo de edad quedará vacío para input manual
    }
}


// MARK: - Measurement Field Component
struct MeasurementField: View {
    let title: String
    @Binding var value: String
    let unit: String
    let icon: String
    var isOptional: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Label(title, systemImage: icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if isOptional {
                    Text("(opcional)")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
            
            HStack {
                TextField("0", text: $value)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 30, alignment: .leading)
            }
        }
    }
}
