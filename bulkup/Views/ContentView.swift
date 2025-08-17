// MARK: - Vista de Contenido Principal
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authManager: AuthManager
    
    init() {
        // Necesitamos usar un patrón diferente ya que no podemos acceder al modelContext aquí
        let container = try! ModelContainer(for: User.self, DietDay.self, Meal.self, MealOption.self, MealConditions.self, ConditionalMeal.self, Supplement.self)
        self._authManager = StateObject(wrappedValue: AuthManager(modelContext: container.mainContext))
    }
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                DietView(modelContext: modelContext)
                    .environmentObject(authManager)
            } else {
                LoginView(modelContext: modelContext)
            }
        }
        .onAppear {
            // Configurar el authManager con el contexto actual si es necesario
        }
    }
}