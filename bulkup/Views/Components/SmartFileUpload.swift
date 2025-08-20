//
//  SmartFileUpload.swift
//  bulkup
//
//  Created by sebastian.blanco on 20/8/25.
//

import SwiftUI
import UniformTypeIdentifiers
import Combine

// MARK: - Models
struct ProcessingStatus: Codable {
    let status: String
    let detectedType: String?
    let errorMessage: String?
    let dietData: [ServerDietDay]?
    let trainingData: [ServerTrainingDay]?
    let _id: String?
}

enum FileType {
    case diet
    case training
    case unknown
    
    var displayName: String {
        switch self {
        case .diet: return "Plan de Dieta"
        case .training: return "Plan de Entrenamiento"
        case .unknown: return "Desconocido"
        }
    }
    
    var icon: String {
        switch self {
        case .diet: return "🍎"
        case .training: return "💪"
        case .unknown: return "❓"
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .diet: return [.green, .green.opacity(0.8)]
        case .training: return [.blue, .blue.opacity(0.8)]
        case .unknown: return [.gray, .gray.opacity(0.8)]
        }
    }
}

// MARK: - SwiftData Model Extensions for Server Model Conversion
extension DietDay {
    convenience init(from serverDay: ServerDietDay) {
        self.init(day: serverDay.day)
        self.meals = serverDay.meals.map { Meal(from: $0) }
        self.supplements = serverDay.supplements?.map { Supplement(from: $0) } ?? []
    }
}

extension Meal {
    convenience init(from serverMeal: ServerMeal) {
        self.init(
            type: serverMeal.type,
            time: serverMeal.time,
            date: serverMeal.date,
            notes: serverMeal.notes
        )
        
        // Convert options
        if let serverOptions = serverMeal.options {
            self.options = serverOptions.map { MealOption(from: $0) }
        }
        
        // Convert conditions
        if let serverConditions = serverMeal.conditions {
            self.conditions = MealConditions(from: serverConditions)
        }
    }
}

extension MealOption {
    convenience init(from serverOption: ServerMeal.MealOptionData) {
        self.init(
            optionDescription: serverOption.description,
            ingredients: serverOption.ingredients,
            instructions: serverOption.instructions ?? []
        )
    }
}

extension MealConditions {
    convenience init(from serverConditions: ServerMealConditions) {
        self.init()
        
        if let trainingDays = serverConditions.trainingDays {
            self.trainingDays = ConditionalMeal(from: trainingDays)
        }
        
        if let nonTrainingDays = serverConditions.nonTrainingDays {
            self.nonTrainingDays = ConditionalMeal(from: nonTrainingDays)
        }
    }
}

extension ConditionalMeal {
    convenience init(from serverMeal: ServerConditionalMeal) {
        self.init(
            mealDescription: serverMeal.description,
            ingredients: serverMeal.ingredients
        )
    }
}

extension Supplement {
    convenience init(from serverSupplement: ServerSupplement) {
        self.init(
            name: serverSupplement.name,
            dosage: serverSupplement.dosage,
            timing: serverSupplement.timing,
            frequency: serverSupplement.frequency,
            notes: serverSupplement.notes
        )
    }
}

extension TrainingDay {
    convenience init(from serverDay: ServerTrainingDay) {
        self.init(
            day: serverDay.day,
            workoutName: serverDay.workoutName
        )
        self.exercises = serverDay.output.enumerated().map { index, exercise in
            Exercise(from: exercise, orderIndex: index)
        }
    }
}

extension Exercise {
    convenience init(from serverExercise: ServerExercise, orderIndex: Int = 0) {
        self.init(
            name: serverExercise.name,
            sets: serverExercise.sets,
            reps: serverExercise.reps,
            restSeconds: serverExercise.restSeconds,
            notes: serverExercise.notes,
            tempo: serverExercise.tempo,
            weightTracking: serverExercise.weightTracking,
            orderIndex: orderIndex
        )
    }
}

// MARK: - Main View
struct SmartFileUploadView: View {
    @EnvironmentObject var dietManager: DietManager
    @EnvironmentObject var trainingManager: TrainingManager
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = SmartFileUploadManager.shared
    @State private var showingFilePicker = false
    @State private var selectedFileURL: URL?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header card
                headerCard
                
                // Upload card
                uploadCard
                
                // Status card (if processing or detected)
                if viewModel.detectedType != .unknown && !viewModel.error.isNilOrEmpty {
                    statusCard
                }
                
                // Error card
                if let error = viewModel.error {
                    errorCard(error: error)
                }
                
                // Info cards
                infoCards
                
                // Usage limits (si tienes esta información disponible)
                // usageLimitsView
            }
            .padding()
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    selectedFileURL = url
                    Task {
                        await viewModel.uploadFile(
                            fileURL: url,
                            userId: authManager.user?.id ?? "guest",
                            dietManager: dietManager,
                            trainingManager: trainingManager
                        )
                    }
                }
            case .failure(let error):
                viewModel.error = error.localizedDescription
            }
        }
        .alert("Éxito", isPresented: $viewModel.showSuccessAlert) {
            Button("OK") {
                viewModel.reset()
            }
        } message: {
            Text(viewModel.successMessage)
        }
        .onAppear {
            if let userId = authManager.user?.id {
                GotifyWebSocketManager.shared.connect(userId: userId)
            }
        }
        .onDisappear {
            GotifyWebSocketManager.shared.disconnect()
        }
    }
    
    // MARK: - Components
    
    private var headerCard: some View {
        VStack(spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .purple.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "brain")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Subida Inteligente")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Powered by AI")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.purple)
            }
            
            Text("La IA estructurará tu plan de dieta o entrenamiento en un formato sencillo de entender en cuestión de minutos.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color(.systemBackground), Color.purple.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var uploadCard: some View {
        Button(action: {
            if !viewModel.isLoading {
                showingFilePicker = true
            }
        }) {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.purple)
                    
                    VStack(spacing: 8) {
                        Text("🧠 Analizando con IA...")
                            .font(.headline)
                        
                        Text(viewModel.processingProgress)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if !viewModel.fileName.isEmpty {
                            HStack {
                                Image(systemName: "doc.fill")
                                    .foregroundColor(.purple)
                                Text(viewModel.fileName)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(20)
                        }
                    }
                } else {
                    Image(systemName: "arrow.up.doc.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.purple.opacity(0.6))
                    
                    VStack(spacing: 8) {
                        Text("Pulsa para seleccionar")
                            .font(.headline)
                        
                        Text("Solo archivos PDF")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .cornerRadius(12)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 2, dash: [8])
                            )
                            .foregroundColor(
                                viewModel.isLoading ? Color.purple : Color(.systemGray3)
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(viewModel.isLoading)
    }
    
    private var statusCard: some View {
        HStack(spacing: 16) {
            Text(viewModel.detectedType.icon)
                .font(.system(size: 32))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Tipo Detectado")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(viewModel.detectedType.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: viewModel.detectedType.gradientColors.map { $0.opacity(0.1) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: viewModel.detectedType.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    private func errorCard(error: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Error de Procesamiento")
                    .font(.headline)
                    .foregroundColor(.red)
                
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var infoCards: some View {
        HStack(spacing: 16) {
            // Diet card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("🍎")
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Planes de Dieta")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("Menús y opciones")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 80) // Añadir frame fijo
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.1), Color.green.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
            
            // Training card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("💪")
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Entrenamientos")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("Ejercicios y rutinas")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 80) // Añadir frame fijo igual
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Helper Extensions
extension String? {
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }
}
