//
//  BodyMeasurementsView.swift
//  bulkup
//
//  Created by sebastian.blanco on 25/8/25.
//

import SwiftUI

struct BodyMeasurementsView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var measurementsManager = BodyMeasurementsManager.shared
    @State private var selectedTab = 0
    @State private var showingAddMeasurements = false
    @State private var hasAppeared = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Medidas Actuales y Composición
            currentMeasurementsTab
                .tabItem {
                    Label("Actual", systemImage: "person.crop.rectangle")
                }
                .tag(0)
            
            // Tab 2: Historial
            historyTab
                .tabItem {
                    Label("Historial", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)
        }
        .navigationTitle("Medidas Corporales")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddMeasurements = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                }
            }
        }
        .sheet(isPresented: $showingAddMeasurements) {
            AddMeasurementsView()
                .environmentObject(measurementsManager)
                .environmentObject(authManager)
        }
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                loadInitialData()
            }
        }
        .alert("Error", isPresented: .constant(measurementsManager.errorMessage != nil && !measurementsManager.errorMessage!.contains("no encontrado"))) {
            Button("OK") {
                measurementsManager.errorMessage = nil
            }
        } message: {
            Text(measurementsManager.errorMessage ?? "")
        }
    }
    
    private func loadInitialData() {
        guard let userId = authManager.user?.id else { return }
        
        Task {
            // Load measurements first
            await measurementsManager.loadLatestMeasurements(userId: userId)
            
            // Only calculate composition if we have measurements and no error occurred
            if measurementsManager.currentMeasurements != nil && measurementsManager.errorMessage == nil {
                await measurementsManager.calculateBodyComposition(userId: userId)
            }
        }
    }
    
    // MARK: - Current Measurements Tab
    private var currentMeasurementsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                if measurementsManager.isLoading {
                    ProgressView("Cargando medidas...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let measurements = measurementsManager.currentMeasurements {
                    // Medidas básicas
                    MeasurementsCardView(measurements: measurements)
                        .environmentObject(authManager)
                        .environmentObject(measurementsManager)
                    
                    // Composición corporal
                    if let composition = measurementsManager.bodyComposition {
                        BodyCompositionCardView(composition: composition)
                    } else {
                        Button("Calcular Composición Corporal") {
                            Task {
                                if let userId = authManager.user?.id {
                                    measurementsManager.errorMessage = nil
                                    await measurementsManager.calculateBodyComposition(userId: userId)
                                }
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(measurementsManager.isLoading)
                    }
                } else {
                    // Estado vacío
                    VStack(spacing: 20) {
                        Image(systemName: "figure.arms.open")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No hay medidas registradas")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Agrega tus primeras medidas para comenzar a hacer seguimiento de tu progreso")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Agregar Medidas") {
                            showingAddMeasurements = true
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding()
        }
        .refreshable {
            guard let userId = authManager.user?.id else { return }
            
            // Reset error state
            measurementsManager.errorMessage = nil
            
            // Load measurements first
            await measurementsManager.loadLatestMeasurements(userId: userId)
            
            // Only calculate composition if we have measurements and no error occurred
            if measurementsManager.currentMeasurements != nil && measurementsManager.errorMessage == nil {
                await measurementsManager.calculateBodyComposition(userId: userId)
            }
        }
    }
    
    // MARK: - History Tab
    private var historyTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                if measurementsManager.measurementsHistory.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("Sin historial")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Agrega más medidas para ver tu progreso a lo largo del tiempo")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ForEach(measurementsManager.measurementsHistory, id: \.id) { measurement in
                        HistoryMeasurementCardView(measurements: measurement)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            Task {
                if let userId = authManager.user?.id, measurementsManager.measurementsHistory.isEmpty {
                    await measurementsManager.loadMeasurementsHistory(userId: userId)
                }
            }
        }
        .refreshable {
            guard let userId = authManager.user?.id else { return }
            await measurementsManager.loadMeasurementsHistory(userId: userId)
        }
    }
}

// MARK: - Supporting Views
struct MeasurementsCardView: View {
    let measurements: BodyMeasurements
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var measurementsManager: BodyMeasurementsManager
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Medidas Actuales")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text(measurements.fecha.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button {
                        showingDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MeasurementItemView(title: "Peso", value: String(format: "%.1f kg", measurements.peso), icon: "scalemass")
                MeasurementItemView(title: "Altura", value: String(format: "%.0f cm", measurements.altura), icon: "ruler")
                MeasurementItemView(title: "Cintura", value: String(format: "%.1f cm", measurements.cintura), icon: "circle.dashed")
                MeasurementItemView(title: "Cuello", value: String(format: "%.1f cm", measurements.cuello), icon: "circle")
                
                if let cadera = measurements.cadera {
                    MeasurementItemView(title: "Cadera", value: String(format: "%.1f cm", cadera), icon: "circle.dotted")
                }
                
                if let brazo = measurements.brazo {
                    MeasurementItemView(title: "Brazo", value: String(format: "%.1f cm", brazo), icon: "arm.wave")
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .alert("Eliminar Medida Actual", isPresented: $showingDeleteConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                deleteMeasurement()
            }
        } message: {
            Text("Esta acción no se puede deshacer. Se eliminará esta medida y se mostrará la siguiente más reciente.")
        }
    }
    
    private func deleteMeasurement() {
        guard let measurementId = measurements.id,
              let userId = authManager.user?.id else { return }
        
        Task {
            await measurementsManager.deleteMeasurement(measurementId: measurementId, userId: userId)
        }
    }
}

struct BodyCompositionCardView: View {
    let composition: BodyComposition
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Composición Corporal")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                CompositionItemView(
                    title: "% Grasa",
                    value: String(format: "%.1f%%", composition.porcentajeGrasa),
                    color: .orange
                )
                CompositionItemView(
                    title: "Masa Muscular",
                    value: String(format: "%.1f kg", composition.masaMuscular),
                    color: .green
                )
                CompositionItemView(
                    title: "Masa Magra",
                    value: String(format: "%.1f kg", composition.masaMagra),
                    color: .blue
                )
                CompositionItemView(
                    title: "Agua Corporal",
                    value: String(format: "%.1f kg", composition.aguaCorporal),
                    color: .cyan
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MeasurementItemView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
    }
}

struct CompositionItemView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct HistoryMeasurementCardView: View {
    let measurements: BodyMeasurements
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var measurementsManager: BodyMeasurementsManager
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(measurements.fecha.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 16) {
                    Text(String(format: "%.1f kg", measurements.peso))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("C: \(String(format: "%.1f", measurements.cintura))cm")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Botón de eliminar
            Button {
                showingDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .alert("Eliminar Medida", isPresented: $showingDeleteConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                deleteMeasurement()
            }
        } message: {
            Text("Esta acción no se puede deshacer. ¿Estás seguro de que quieres eliminar esta medida?")
        }
    }
    
    private func deleteMeasurement() {
        guard let measurementId = measurements.id,
              let userId = authManager.user?.id else { return }
        
        Task {
            await measurementsManager.deleteMeasurement(measurementId: measurementId, userId: userId)
        }
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
            .fontWeight(.semibold)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.green.opacity(0.1))
            .foregroundColor(.green)
            .cornerRadius(12)
            .fontWeight(.medium)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
