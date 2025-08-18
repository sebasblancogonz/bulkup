//
//  FileUploadView.swift
//  bulkup
//
//  Created by sebastian.blanco on 18/8/25.
//
import SwiftData
import SwiftUI

struct FileUploadView: View {
    @EnvironmentObject var dietManager: DietManager
    @EnvironmentObject var trainingManager: TrainingManager
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.2), .purple.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .purple.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: .purple.opacity(0.2), radius: 20, x: 0, y: 10)
            }
            
            VStack(spacing: 16) {
                Text("Subir Archivos")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Sube tus planes de dieta y entrenamiento para comenzar tu transformación")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            // Botones de prueba para simular carga de datos
            VStack(spacing: 16) {
                Button(action: {
                    // Simular carga de dieta con datos más realistas
                    let mockMeal = Meal(type: "desayuno", time: "08:00", order: 0)
                    let mockOption = MealOption(optionDescription: "Avena con frutas", ingredients: ["50g avena", "1 plátano", "200ml leche"], instructions: ["Mezclar ingredientes", "Calentar si deseas"])
                    mockMeal.options = [mockOption]
                    
                    let mockDietDay = DietDay(day: "Dieta Semanal")
                    mockDietDay.meals = [mockMeal]
                    
                    dietManager.setDietData([mockDietDay], planId: "mock-diet-plan")
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "leaf.fill")
                            .font(.title3)
                        
                        Text("Simular Plan de Dieta")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                
                Button(action: {
                    // Simular carga de entrenamiento con datos más realistas
                    let mockExercise = Exercise(
                        name: "Press Banca",
                        sets: 4,
                        reps: "8-12",
                        restSeconds: 90,
                        notes: "Controla la bajada",
                        weightTracking: true,
                        orderIndex: 0
                    )
                    
                    let mockTrainingDay = TrainingDay(day: "Lunes", workoutName: "Push Day")
                    mockTrainingDay.exercises = [mockExercise]
                    
                    trainingManager.setTrainingData([mockTrainingDay], planId: "mock-training-plan")
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "dumbbell.fill")
                            .font(.title3)
                        
                        Text("Simular Plan de Entrenamiento")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
