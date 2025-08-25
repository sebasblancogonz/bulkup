//
//  CreateTrainingPlanView.swift
//  bulkup
//
//  Created by sebastian.blanco on 23/8/25.
//


import SwiftUI

struct CreateTrainingPlanView: View {
    @EnvironmentObject var trainingManager: TrainingManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    
    @State private var planName = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var useCustomDates = false
    @State private var creationMethod: CreationMethod = .manual
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var showingFilePicker = false
    
    enum CreationMethod: String, CaseIterable {
        case manual = "manual"
        case upload = "upload"
        case template = "template"
        
        var displayName: String {
            switch self {
            case .manual: return "Crear Manualmente"
            case .upload: return "Subir Archivo"
            case .template: return "Usar Plantilla"
            }
        }
        
        var icon: String {
            switch self {
            case .manual: return "pencil.and.outline"
            case .upload: return "doc.badge.plus"
            case .template: return "doc.on.doc"
            }
        }
        
        var description: String {
            switch self {
            case .manual: return "Construye tu plan paso a paso"
            case .upload: return "Sube un PDF con tu rutina"
            case .template: return "Comienza con una plantilla"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Plan Name Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nombre del Plan")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("Ej: Fuerza Primavera 2024", text: $planName)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.done)
                    }
                    
                    // Date Range Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Duración del Plan")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Toggle("Fechas específicas", isOn: $useCustomDates)
                                .toggleStyle(.switch)
                        }
                        
                        if useCustomDates {
                            VStack(spacing: 12) {
                                DatePicker("Fecha de inicio", selection: $startDate, displayedComponents: .date)
                                DatePicker("Fecha de fin", selection: $endDate, displayedComponents: .date)
                            }
                            .padding(.leading)
                        } else {
                            Text("Sin fechas específicas - plan indefinido")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.leading)
                        }
                    }
                    
                    // Creation Method Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Método de Creación")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            ForEach(CreationMethod.allCases, id: \.self) { method in
                                CreationMethodCard(
                                    method: method,
                                    isSelected: creationMethod == method
                                ) {
                                    creationMethod = method
                                }
                            }
                        }
                    }
                    
                    // Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
            }
            .navigationTitle("Nuevo Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Continuar") {
                        handleContinue()
                    }
                    .disabled(planName.isEmpty || isCreating)
                    .fontWeight(.semibold)
                }
            }
            .disabled(isCreating)
            .overlay {
                if isCreating {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .tint(.white)
                                
                                Text("Creando plan...")
                                    .foregroundColor(.white)
                                    .font(.headline)
                            }
                        }
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }
    
    private func handleContinue() {
        errorMessage = nil
        
        switch creationMethod {
        case .manual:
            // For now, create an empty plan - you'd implement a manual creation flow
            createEmptyPlan()
        case .upload:
            showingFilePicker = true
        case .template:
            // For now, just create an empty plan - you'd implement template selection
            createEmptyPlan()
        }
    }
    
    private func createEmptyPlan() {
        guard let userId = authManager.user?.id else { return }
        
        isCreating = true
        
        Task {
            do {
                let emptyTrainingData: [ServerTrainingDay] = [
                    ServerTrainingDay(day: "Lunes", workoutName: "Día 1", output: []),
                    ServerTrainingDay(day: "Miércoles", workoutName: "Día 2", output: []),
                    ServerTrainingDay(day: "Viernes", workoutName: "Día 3", output: [])
                ]
                
                let _ = try await APIService.shared.createTrainingPlan(
                    userId: userId,
                    filename: planName,
                    trainingData: emptyTrainingData,
                    planStartDate: useCustomDates ? startDate : nil,
                    planEndDate: useCustomDates ? endDate : nil
                )
                
                await MainActor.run {
                    isCreating = false
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            // Handle PDF processing - integrate with your existing file processing logic
            processTrainingPlanFile(url)
        case .failure(let error):
            errorMessage = "Error al seleccionar archivo: \(error.localizedDescription)"
        }
    }
    
    private func processTrainingPlanFile(_ url: URL) {
        // This would integrate with your existing file processing logic
        // For now, just create an empty plan
        createEmptyPlan()
    }
}

struct CreationMethodCard: View {
    let method: CreateTrainingPlanView.CreationMethod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: method.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isSelected ? .blue : .gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(method.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(method.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
