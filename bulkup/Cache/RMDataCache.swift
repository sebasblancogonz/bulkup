//
//  RMCacheManager.swift
//  bulkup
//
//  Sistema de caché para datos de RM
//

import Foundation

// MARK: - Cache Models
struct RMDataCache: Codable {
    let records: [PersonalRecord]
    let bestRecords: [PersonalRecord]
    let stats: RecordStats
    let timestamp: Date
    
    var isExpired: Bool {
        // El caché nunca expira automáticamente, solo se invalida con pull-to-refresh
        return false
    }
}

// MARK: - Enhanced Cache Manager
@MainActor
class RMCacheManager: ObservableObject {
    static let shared = RMCacheManager()
    
    private let cacheKey = "rm_data_cache"
    private let exercisesCacheKey = "rm_exercises_cache"
    
    // In-memory cache
    private var memoryCache: RMDataCache?
    private var exercisesMemoryCache: [RMExercise]?
    
    private init() {
        loadFromDisk()
    }
    
    // MARK: - Cache Management
    
    func getCachedData() -> RMDataCache? {
        // Primero intentar memoria
        if let memoryCache = memoryCache {
            return memoryCache
        }
        
        // Si no está en memoria, cargar de disco
        loadFromDisk()
        return memoryCache
    }
    
    func setCachedData(records: [PersonalRecord], bestRecords: [PersonalRecord], stats: RecordStats) {
        let cache = RMDataCache(
            records: records,
            bestRecords: bestRecords,
            stats: stats,
            timestamp: Date()
        )
        
        // Guardar en memoria
        memoryCache = cache
        
        // Guardar en disco de forma asíncrona
        Task {
            saveToDisk(cache)
        }
    }
    
    func getCachedExercises() -> [RMExercise]? {
        // Primero intentar memoria
        if let exercisesMemoryCache = exercisesMemoryCache {
            return exercisesMemoryCache
        }
        
        // Si no está en memoria, cargar de disco
        if let data = UserDefaults.standard.data(forKey: exercisesCacheKey),
           let exercises = try? JSONDecoder().decode([RMExercise].self, from: data) {
            exercisesMemoryCache = exercises
            return exercises
        }
        
        return nil
    }
    
    func setCachedExercises(_ exercises: [RMExercise]) {
        // Guardar en memoria
        exercisesMemoryCache = exercises
        
        // Guardar en disco
        if let data = try? JSONEncoder().encode(exercises) {
            UserDefaults.standard.set(data, forKey: exercisesCacheKey)
        }
    }
    
    func invalidateCache() {
        memoryCache = nil
        exercisesMemoryCache = nil
        UserDefaults.standard.removeObject(forKey: cacheKey)
        // No eliminar ejercicios del caché ya que raramente cambian
    }
    
    // MARK: - Private Methods
    
    private func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cache = try? JSONDecoder().decode(RMDataCache.self, from: data) {
            memoryCache = cache
        }
    }
    
    private func saveToDisk(_ cache: RMDataCache) {
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }
}

// MARK: - Updated RM Manager with Caching
extension RMManager {
    
    func loadInitialDataWithCache(token: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        let cacheManager = RMCacheManager.shared
        
        // Cargar ejercicios desde caché o API
        if let cachedExercises = cacheManager.getCachedExercises() {
            exercises = cachedExercises
        } else {
            await fetchExercises()
        }
        
        // Cargar datos de records desde caché
        if let cachedData = cacheManager.getCachedData() {
            await MainActor.run {
                self.records = cachedData.records
                self.bestRecords = cachedData.bestRecords
                self.stats = cachedData.stats
                self.isLoading = false
            }
            return
        }
        
        // Si no hay caché, cargar desde API
        await loadFromAPI(token: token)
    }
    
    func refreshData(token: String, forceRefresh: Bool = false) async {
        if !forceRefresh {
            // Si no es forzado, intentar usar caché
            await loadInitialDataWithCache(token: token)
            return
        }
        
        // Si es forzado (pull-to-refresh), invalidar caché y recargar
        RMCacheManager.shared.invalidateCache()
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        await loadFromAPI(token: token)
    }
    
    private func loadFromAPI(token: String) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchExercises() }
            group.addTask { await self.fetchRecordsAndCache() }
            group.addTask { await self.fetchBestRecordsAndCache() }
            group.addTask { await self.fetchStatsAndCache() }
        }
        
        // Guardar en caché después de cargar
        await MainActor.run {
            RMCacheManager.shared.setCachedData(
                records: self.records,
                bestRecords: self.bestRecords,
                stats: self.stats
            )
            self.isLoading = false
        }
    }
    
    private func fetchRecordsAndCache() async {
        guard let userId = authManager.user?.id else { return }
        
        do {
            let records = try await apiService.fetchRecords(userId: userId)
            await MainActor.run {
                self.records = records
            }
        } catch {
            print("Error fetching records: \(error)")
            await MainActor.run {
                self.errorMessage = "Error loading records"
            }
        }
    }
    
    private func fetchBestRecordsAndCache() async {
        guard let userId = authManager.user?.id else { return }
        
        do {
            let bestRecords = try await apiService.fetchBestRecords(userId: userId)
            await MainActor.run {
                self.bestRecords = bestRecords
            }
        } catch {
            print("Error fetching best records: \(error)")
            await MainActor.run {
                self.errorMessage = "Error loading best records"
            }
        }
    }
    
    private func fetchStatsAndCache() async {
        guard let userId = authManager.user?.id else { return }
        
        do {
            let stats = try await apiService.fetchRecordStats(userId: userId)
            await MainActor.run {
                self.stats = stats
            }
        } catch {
            print("Error fetching stats: \(error)")
            await MainActor.run {
                self.stats = RecordStats.empty
            }
        }
    }
    
    // Actualizar métodos CRUD para invalidar caché
    
    func createRecordWithCache(_ recordData: [String: Any], token: String) async -> Bool {
        let result = await createRecord(recordData, token: token)
        if result {
            // Invalidar caché y recargar
            RMCacheManager.shared.invalidateCache()
            await loadFromAPI(token: token)
        }
        return result
    }
    
    func updateRecordWithCache(recordId: String, recordData: [String: Any], token: String) async -> Bool {
        let result = await updateRecord(recordId: recordId, recordData: recordData, token: token)
        if result {
            // Invalidar caché y recargar
            RMCacheManager.shared.invalidateCache()
            await loadFromAPI(token: token)
        }
        return result
    }
    
    func deleteRecordWithCache(recordId: String, token: String) async -> Bool {
        let result = await deleteRecord(recordId: recordId, token: token)
        if result {
            // Invalidar caché y recargar
            RMCacheManager.shared.invalidateCache()
            await loadFromAPI(token: token)
        }
        return result
    }
}

// MARK: - Updated RMTrackerView
extension RMTrackerView {
    var updatedBody: some View {
        NavigationView {
            ZStack {
                if rmManager.isLoading && rmManager.records.isEmpty {
                    // Solo mostrar loading si no hay datos en caché
                    loadingView
                } else {
                    mainContentWithRefresh
                }

                VStack {
                    if let notification = notificationManager.currentNotification {
                        RMNotificationView(notification: notification)
                            .padding(.horizontal)
                    }
                    Spacer()
                }
                .zIndex(1)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddRecord() }) {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                }
            }
            .navigationTitle("Tus PR")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddForm) {
                AddRecordFormView(
                    formData: $formData,
                    exercises: rmManager.exercises,
                    isEditing: editingRecordId != nil,
                    isSubmitting: rmManager.isSubmitting,
                    onSubmit: handleSubmitWithCache,
                    onCancel: resetForm
                )
            }
        }
        .task {
            if let token = authManager.user?.token {
                // Cargar con caché al inicio
                await rmManager.loadInitialDataWithCache(token: token)
            }
        }
        .environmentObject(notificationManager)
    }
    
    private var mainContentWithRefresh: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Stats Cards
                StatsCardsView(stats: rmManager.stats)
                    .padding(.horizontal)

                // Search Bar
                SearchBar(text: $searchTerm)
                    .padding(.horizontal)

                // Exercise Cards
                exerciseCardsGrid

                // Espacio extra para el tab bar
                Color.clear
                    .frame(height: 90)
            }
        }
        .refreshable {
            // Pull-to-refresh fuerza recarga desde API
            if let token = authManager.user?.token {
                await rmManager.refreshData(token: token, forceRefresh: true)
            }
        }
        .overlay(
            Group {
                if rmManager.isLoading && !rmManager.records.isEmpty {
                    // Mostrar indicador sutil cuando se está refrescando con datos en caché
                    VStack {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Actualizando...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .shadow(radius: 2)
                        
                        Spacer()
                    }
                    .padding(.top, 8)
                }
            }
        )
    }
    
    private func handleSubmitWithCache() {
        guard let token = authManager.user?.token else { return }

        Task {
            let success: Bool

            if let recordId = editingRecordId {
                success = await rmManager.updateRecordWithCache(
                    recordId: recordId,
                    recordData: formData.asDictionary,
                    token: token
                )
            } else {
                success = await rmManager.createRecordWithCache(
                    formData.asDictionary,
                    token: token
                )
            }

            await MainActor.run {
                if success {
                    resetForm()
                    let message = editingRecordId != nil ? "Récord actualizado" : "Récord creado"
                    notificationManager.showNotification(.success, message: message)
                } else {
                    notificationManager.showNotification(.error, message: "Error al guardar el récord")
                }
            }
        }
    }
    
    private func deleteRecordWithCache(_ record: PersonalRecord) {
        guard let token = authManager.user?.token else { return }

        Task {
            let success = await rmManager.deleteRecordWithCache(
                recordId: record.id,
                token: token
            )

            await MainActor.run {
                if success {
                    notificationManager.showNotification(.success, message: "Récord eliminado")
                } else {
                    notificationManager.showNotification(.error, message: "Error al eliminar el récord")
                }
            }
        }
    }
}