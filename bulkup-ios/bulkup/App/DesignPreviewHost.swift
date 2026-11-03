//
//  DesignPreviewHost.swift
//  bulkup
//
//  Debug-only design review harness. Launch the app with
//  `--design-preview <today|training|workout|rest|summary|paywall|gate|diet>` and
//  the screen renders with seeded local data: no account, no network, no
//  StoreKit. Used to screenshot the simulator in both appearances.
//

#if DEBUG
import SwiftData
import SwiftUI

enum DesignPreview {
    static var screen: String? {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--design-preview"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    static var isActive: Bool { screen != nil }

    /// Today's weekday in the plan's (Spanish) day naming, capitalised.
    static var todayName: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "EEEE"
        return f.string(from: Date()).capitalized
    }

    @MainActor
    static func seed() {
        let auth = AuthManager.shared
        auth.user = User(id: "design-preview", email: "preview@example.com", name: "Sebas Blanco")
        auth.isAuthenticated = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

        let tm = TrainingManager.shared
        tm.setTrainingData(makeDays(), planId: nil)
        tm.isLoading = false
        tm.isFullyLoaded = true

        let day = todayName.lowercased().folding(options: .diacriticInsensitive, locale: .current)
        let thisWeek = tm.weekString(for: Date())
        let lastWeek = tm.weekString(for: Calendar.current.date(byAdding: .day, value: -7, to: Date())!)
        // Two sets logged today on the first exercise, last week's numbers for the hints.
        tm.updateWeight(day: day, exerciseIndex: 0, exerciseName: "Press inclinado en multipower", setIndex: 0, weight: 60)
        tm.updateWeight(day: day, exerciseIndex: 0, exerciseName: "Press inclinado en multipower", setIndex: 1, weight: 62.5)
        tm.updateReps(day: day, exerciseIndex: 0, exerciseName: "Press inclinado en multipower", setIndex: 0, reps: 12)
        tm.updateReps(day: day, exerciseIndex: 0, exerciseName: "Press inclinado en multipower", setIndex: 1, reps: 10)
        for (i, w) in [57.5, 60, 60, 62.5].enumerated() {
            tm.weights[tm.generateWeightKey(day: day, exerciseIndex: 0, exerciseName: "Press inclinado en multipower",
                                            setIndex: i, weekStart: lastWeek)] = w
            tm.setReps[tm.generateWeightKey(day: day, exerciseIndex: 0, exerciseName: "Press inclinado en multipower",
                                            setIndex: i, weekStart: lastWeek)] = [12, 10, 8, 6][i]
        }
        for i in 0..<4 {
            tm.weights[tm.generateWeightKey(day: day, exerciseIndex: 1, exerciseName: "Cruces en polea",
                                            setIndex: i, weekStart: lastWeek)] = 15
        }
        _ = thisWeek

        let dm = DietManager.shared
        dm.setDietData(makeDiet(), planId: nil)
        dm.activePlanName = "Volumen 3.200 kcal"
        seedMealTracking()
    }

    /// Two meals ticked today so the diet screen shows every row state.
    @MainActor
    private static func seedMealTracking() {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let today = f.string(from: Date())
        let context = ModelContainer.bulkUpContainer.mainContext
        var records: [MealTrackingRecord] = []
        for (i, type) in ["desayuno", "media mañana", "comida", "merienda", "cena"].enumerated() {
            let r = MealTrackingRecord(date: today, dayName: todayName, planId: nil, mealType: type, mealOrder: i)
            r.completed = i < 2
            context.insert(r)
            records.append(r)
        }
        try? context.save()
        MealTrackingManager.shared.todayTracking = records
    }

    private static func makeDays() -> [TrainingDay] {
        let today = TrainingDay(day: todayName, workoutName: "Pecho y hombros", exercises: [
            Exercise(name: "Press inclinado en multipower", sets: 4, reps: "12, 10, 8, 6", restSeconds: 90, weightTracking: true, orderIndex: 0),
            Exercise(name: "Cruces en polea", sets: 4, reps: "12", restSeconds: 60, weightTracking: true, orderIndex: 1),
            Exercise(name: "Press militar con mancuernas", sets: 4, reps: "10, 8, 8, 6", restSeconds: 90, tempo: "3-1-1", weightTracking: true, orderIndex: 2),
            Exercise(name: "Elevaciones laterales", sets: 3, reps: "15", restSeconds: 45, weightTracking: true, orderIndex: 3),
            Exercise(name: "Fondos en paralelas", sets: 3, reps: "máx", restSeconds: 60, notes: "Al fallo, sin lastre.", weightTracking: false, orderIndex: 4),
            Exercise(name: "Face pull", sets: 3, reps: "15", restSeconds: 45, weightTracking: true, orderIndex: 5),
        ])
        let others: [(String, String)] = [
            ("Lunes", "Pierna"), ("Martes", "Espalda y bíceps"), ("Jueves", "Pierna"), ("Viernes", "Espalda y bíceps"),
        ].filter { $0.0 != todayName }
        let rest = others.prefix(3).map { name, title in
            TrainingDay(day: name, workoutName: title, exercises: [
                Exercise(name: "Sentadilla", sets: 4, reps: "8", restSeconds: 120, weightTracking: true, orderIndex: 0),
                Exercise(name: "Peso muerto rumano", sets: 3, reps: "10", restSeconds: 90, weightTracking: true, orderIndex: 1),
                Exercise(name: "Zancadas", sets: 3, reps: "12", restSeconds: 60, weightTracking: true, orderIndex: 2),
            ])
        }
        return [today] + rest
    }

    private static func makeDiet() -> [DietDay] {
        let breakfast = Meal(type: "desayuno", time: "08:00", order: 0)
        breakfast.options = [
            MealOption(optionDescription: "Avena con proteína y fruta",
                       ingredients: ["80 g de avena", "1 scoop de proteína", "1 plátano", "200 ml de leche"]),
            MealOption(optionDescription: "Tostadas con huevo y aguacate",
                       ingredients: ["2 rebanadas de pan integral", "3 huevos", "½ aguacate"]),
        ]
        let midMorning = Meal(type: "media mañana", time: "11:00", order: 1)
        midMorning.options = [MealOption(optionDescription: "Yogur griego con nueces", ingredients: ["200 g de yogur griego", "30 g de nueces"])]
        let lunch = Meal(type: "comida", time: "14:00", notes: "Pesar el arroz en crudo.", order: 2)
        lunch.options = [
            MealOption(optionDescription: "Pollo con arroz y verduras",
                       ingredients: ["200 g de pechuga de pollo", "120 g de arroz", "Verduras al gusto", "1 cda de aceite de oliva"],
                       instructions: ["Cocer el arroz.", "Pollo a la plancha con especias.", "Saltear las verduras."]),
        ]
        lunch.conditions = MealConditions(
            trainingDays: ConditionalMeal(mealDescription: "Añade 50 g más de arroz", ingredients: []),
            nonTrainingDays: ConditionalMeal(mealDescription: "Arroz a 80 g", ingredients: [])
        )
        let snack = Meal(type: "merienda", time: "17:30", order: 3)
        snack.options = [MealOption(optionDescription: "Batido de proteína y tortitas de arroz", ingredients: ["1 scoop", "3 tortitas de arroz"])]
        let dinner = Meal(type: "cena", time: "21:00", order: 4)
        dinner.options = [MealOption(optionDescription: "Salmón con patata y ensalada", ingredients: ["180 g de salmón", "250 g de patata", "Ensalada verde"])]

        let day = DietDay(day: todayName, meals: [breakfast, midMorning, lunch, snack, dinner], supplements: [
            Supplement(name: "Creatina monohidrato", dosage: "5 g", timing: "Con la comida", frequency: "Diario"),
            Supplement(name: "Omega 3", dosage: "2 cápsulas", timing: "Con la cena", frequency: "Diario"),
            Supplement(name: "Vitamina D3", dosage: "2.000 UI", timing: "Desayuno", frequency: "Diario"),
        ])
        day.hasMacros = true
        day.macroCalories = 3200
        day.macroProtein = 180
        day.macroCarbs = 400
        day.macroFat = 90
        day.allowsCheatMeal = true
        return [day]
    }

    static let paywallPlans: [PlanRowContent.Model] = [
        .init(title: "Anual", detail: "7 días gratis · Ahorra 44 %", price: "39,99 €", perMonth: "3,33 €/mes",
              highlightPerMonth: true, isBestValue: true, trial: "7 días gratis",
              renewalLine: "Después, 39,99 € al año. Se renueva automáticamente hasta que la canceles, al menos 24 h antes del fin del período, desde los ajustes de tu cuenta del App Store."),
        .init(title: "Mensual", detail: "Facturado cada mes", price: "5,99 €", perMonth: nil,
              highlightPerMonth: false, isBestValue: false, trial: nil,
              renewalLine: "5,99 € al mes. Se renueva automáticamente hasta que la canceles, al menos 24 h antes del fin del período, desde los ajustes de tu cuenta del App Store."),
    ]
}

struct DesignPreviewHost: View {
    let screen: String
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var languageManager = LanguageManager.shared
    @State private var ready = false

    var body: some View {
        Group {
            if !ready {
                BulkUpGround()
            } else {
                switch screen {
                case "paywall":
                    SubscriptionView(previewPlans: DesignPreview.paywallPlans)
                        .environmentObject(authManager)
                case "paywall-footer":
                    SubscriptionView(previewPlans: DesignPreview.paywallPlans, previewScrollToFooter: true)
                        .environmentObject(authManager)
                case "gate":
                    ZStack {
                        BulkUpGround()
                        SubscriptionRequiredView(onSubscribe: {})
                    }
                case "summary":
                    WorkoutSummaryView(
                        summary: WorkoutSummary(duration: 3140, totalVolume: 6240, totalSets: 18,
                                                exercisesCompleted: 6, exercisesTotal: 6, prs: [], date: Date()),
                        saveState: .saved, onRetry: {}, onReview: {}, onSave: {},
                        previousSession: WorkoutSessionRecord(
                            _id: "prev", userId: "design-preview", planId: nil, dayName: DesignPreview.todayName,
                            workoutName: "Pecho y hombros", durationSeconds: 3390, totalVolume: 5920, totalSets: 17,
                            exercisesCompleted: 6, exercisesTotal: 6, exercisesSkipped: 0, exercises: nil,
                            date: "2026-10-26", completedAt: nil
                        )
                    )
                default:
                    MainAppView(modelContext: modelContext)
                        .environmentObject(authManager)
                }
            }
        }
        .environment(\.locale, languageManager.locale)
        .environmentObject(languageManager)
        .task {
            guard !ready else { return }
            DesignPreview.seed()
            let tm = TrainingManager.shared
            if screen == "workout" || screen == "rest" {
                WorkoutSessionManager.shared.startWorkout(
                    dayName: DesignPreview.todayName, workoutName: "Pecho y hombros", trainingManager: tm
                )
                WorkoutSessionManager.shared.elapsedSeconds = 1265
                if screen == "rest" {
                    WorkoutSessionManager.shared.startRestTimer(seconds: 90, nextSetInfo: "Serie 3 · 62,5kg × 8")
                }
            }
            ready = true
            if screen == "training" || screen == "workout" || screen == "rest" {
                try? await Task.sleep(nanoseconds: 600_000_000)
                NotificationCenter.default.post(name: .navigateToTraining, object: nil)
            }
            if screen == "diet" || screen == "diet-detail" {
                try? await Task.sleep(nanoseconds: 600_000_000)
                NotificationCenter.default.post(name: .navigateToDiet, object: nil)
            }
        }
    }
}
#endif
