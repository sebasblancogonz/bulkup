//
//  DesignPreviewHost.swift
//  bulkup
//
//  Debug-only design review harness. Launch the app with
//  `--design-preview <today|training|workout|rest|summary|paywall|gate|diet|health>` and
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
        BrandFonts.register()   // before any `Font.brandMono` resolves in the harness
        let auth = AuthManager.shared
        auth.user = User(id: "design-preview", email: "preview@example.com", name: "Sebas Blanco")
        auth.user?.createdAt = Calendar.current.date(byAdding: .day, value: -86, to: Date())!
        auth.isAuthenticated = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

        let tm = TrainingManager.shared
        tm.setTrainingData(screen == "training-empty" ? [] : makeDays(), planId: nil)
        tm.isLoading = false
        tm.isFullyLoaded = true

        let explorer = ExerciseExplorerManager.shared
        explorer.exercises = sampleExercises
        explorer.loading = false

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
        dm.setDietData(screen == "diet-empty" ? [] : (screen == "diet-week" ? makeWeekDiet() : makeDiet()), planId: nil)
        dm.activePlanName = "Volumen 3.200 kcal"
        dm.isLoading = false
        seedMealTracking()
        seedProgress(subscribed: screen != "progress-free" && screen != "profile-free")
    }

    /// Progress: a lifter with ten weeks of measurements, three PRs, two
    /// friends and a 12-day streak. `subscribed: false` shows the PRO teaser.
    @MainActor
    private static func seedProgress(subscribed: Bool) {
        StoreKitManager.shared.hasActiveSubscription = subscribed

        let bm = BodyMeasurementsManager.shared
        let cal = Calendar.current
        let samples: [(weeks: Int, peso: Double, cintura: Double)] = [
            (0, 82.4, 86), (1, 82.9, 86), (2, 83.3, 87), (4, 83.1, 87), (6, 84.0, 88), (8, 84.6, 88), (10, 85.2, 89),
        ]
        let history: [BodyMeasurements] = samples.map { s in
            let date = cal.date(byAdding: .day, value: -7 * (10 - s.weeks), to: Date())!
            return BodyMeasurements(id: "m\(s.weeks)", userId: "design-preview", peso: s.peso, altura: 181, edad: 29, sexo: "male",
                                    cintura: s.cintura, cuello: 40, cadera: 98, brazo: 37.5, muslo: 60, pantorrilla: 39,
                                    fecha: date, createdAt: date, updatedAt: date)
        }
        bm.measurementsHistory = history.reversed()   // newest first, like the API
        bm.currentMeasurements = history.last
        bm.bodyComposition = BodyComposition(bodyFatPercentage: 14.8, fatMass: 12.6, leanMass: 72.6, bodyWater: 52.0, skeletalMuscle: 40.1)
        bm.isLoading = false

        let rm = RMManager.shared
        rm.exercises = [
            RMExercise(id: "e1", name: "Bench Press", nameEs: "Press de banca", category: "powerlifting", categoryEs: "Powerlifting"),
            RMExercise(id: "e2", name: "Squat", nameEs: "Sentadilla", category: "powerlifting", categoryEs: "Powerlifting"),
            RMExercise(id: "e3", name: "Deadlift", nameEs: "Peso muerto", category: "powerlifting", categoryEs: "Powerlifting"),
            RMExercise(id: "e4", name: "Overhead Press", nameEs: "Press militar", category: "strength", categoryEs: "Fuerza"),
            RMExercise(id: "e5", name: "Barbell Row", nameEs: "Remo con barra", category: "strength", categoryEs: "Fuerza"),
        ]
        let iso = ISO8601DateFormatter()
        func day(_ ago: Int) -> String { iso.string(from: cal.date(byAdding: .day, value: -ago, to: Date())!) }
        rm.records = [
            PersonalRecord(id: "r1", exerciseId: "e1", weight: 100, reps: 3, date: day(2), notes: nil),
            PersonalRecord(id: "r2", exerciseId: "e2", weight: 140, reps: 2, date: day(9), notes: nil),
            PersonalRecord(id: "r3", exerciseId: "e3", weight: 170, reps: 1, date: day(16), notes: nil),
            PersonalRecord(id: "r4", exerciseId: "e1", weight: 95, reps: 5, date: day(30), notes: nil),
        ]
        rm.bestRecords = Array(rm.records.prefix(3))
        rm.stats = RecordStats(totalRecords: 14, exercisesWithRM: 3, recordsThisMonth: 2)
        rm.isLoading = false

        let fm = FriendsManager.shared
        fm.myStreak = TrainingStreakResponse(userId: "design-preview", currentStreak: 12, longestStreak: 21, totalDays: 86)
        fm.friends = [
            FriendProfile(userId: "f1", name: "Marta", profileImageURL: nil, currentStreak: 18, longestStreak: 30, totalDays: 140),
            FriendProfile(userId: "f2", name: "Dani", profileImageURL: nil, currentStreak: 7, longestStreak: 12, totalDays: 54),
        ]
        fm.todayCompleted = true
        fm.isLoading = false

        let mm = MealTrackingManager.shared
        mm.weeklyCompletedMeals = 27
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

    /// A dozen library exercises (no images: the harness has no network).
    static let sampleExercises: [RMExerciseFull] = {
        func ex(_ id: String, _ en: String, _ es: String, force: String, level: String, mechanic: String,
                equipment: String, primary: [String], primaryEs: [String], secondary: [String] = [], secondaryEs: [String] = [],
                category: String = "strength", categoryEs: String = "Fuerza") -> RMExerciseFull {
            let forceEs = ["push": "Empuje", "pull": "Jalón", "static": "Estático"][force] ?? force
            let levelEs = ["beginner": "Principiante", "intermediate": "Intermedio", "expert": "Experto"][level] ?? level
            let mechanicEs = ["compound": "Compuesto", "isolation": "Aislamiento"][mechanic] ?? mechanic
            let equipmentEs = ["barbell": "Barra", "dumbbell": "Mancuerna", "body only": "Peso corporal", "machine": "Máquina",
                               "cable": "Cable", "kettlebells": "Pesas rusas", "bands": "Bandas"][equipment] ?? equipment
            return RMExerciseFull(
                id: id, name: en, nameEs: es, force: force, forceEs: forceEs, level: level, levelEs: levelEs,
                mechanic: mechanic, mechanicEs: mechanicEs, equipment: equipment, equipmentEs: equipmentEs,
                primaryMuscles: primary, primaryMusclesEs: primaryEs, secondaryMuscles: secondary, secondaryMusclesEs: secondaryEs,
                instructions: [
                    "Set the bench to 30 degrees and lie back with the bar over your upper chest.",
                    "Lower the bar under control until it touches your chest.",
                    "Press back up and lock out without bouncing.",
                ],
                instructionsEs: [
                    "Pon el banco a 30 grados y túmbate con la barra sobre la parte alta del pecho.",
                    "Baja la barra controlada hasta tocar el pecho.",
                    "Empuja hasta bloquear los codos sin rebotar.",
                ],
                category: category, categoryEs: categoryEs, images: nil
            )
        }
        return [
            ex("1", "Incline Barbell Bench Press", "Press inclinado con barra", force: "push", level: "intermediate", mechanic: "compound",
               equipment: "barbell", primary: ["chest"], primaryEs: ["Pecho"], secondary: ["shoulders", "triceps"], secondaryEs: ["Hombros", "Tríceps"]),
            ex("2", "Dumbbell Shoulder Press", "Press de hombro con mancuernas", force: "push", level: "beginner", mechanic: "compound",
               equipment: "dumbbell", primary: ["shoulders"], primaryEs: ["Hombros"], secondary: ["triceps"], secondaryEs: ["Tríceps"]),
            ex("3", "Pull-Up", "Dominadas", force: "pull", level: "intermediate", mechanic: "compound",
               equipment: "body only", primary: ["lats"], primaryEs: ["Dorsales"], secondary: ["biceps"], secondaryEs: ["Bíceps"]),
            ex("4", "Romanian Deadlift", "Peso muerto rumano", force: "pull", level: "intermediate", mechanic: "compound",
               equipment: "barbell", primary: ["hamstrings"], primaryEs: ["Isquiotibiales"], secondary: ["glutes", "lower back"], secondaryEs: ["Glúteos", "Espalda baja"]),
            ex("5", "Cable Crossover", "Cruces en polea", force: "push", level: "beginner", mechanic: "isolation",
               equipment: "cable", primary: ["chest"], primaryEs: ["Pecho"]),
            ex("6", "Bulgarian Split Squat", "Sentadilla búlgara", force: "push", level: "expert", mechanic: "compound",
               equipment: "dumbbell", primary: ["quadriceps"], primaryEs: ["Cuádriceps"], secondary: ["glutes"], secondaryEs: ["Glúteos"]),
            ex("7", "Seated Cable Row", "Remo sentado en polea", force: "pull", level: "beginner", mechanic: "compound",
               equipment: "cable", primary: ["middle back"], primaryEs: ["Espalda media"], secondary: ["biceps"], secondaryEs: ["Bíceps"]),
            ex("8", "Kettlebell Swing", "Swing con pesa rusa", force: "pull", level: "intermediate", mechanic: "compound",
               equipment: "kettlebells", primary: ["hamstrings"], primaryEs: ["Isquiotibiales"], secondary: ["glutes"], secondaryEs: ["Glúteos"]),
            ex("9", "Lateral Raise", "Elevaciones laterales", force: "push", level: "beginner", mechanic: "isolation",
               equipment: "dumbbell", primary: ["shoulders"], primaryEs: ["Hombros"]),
            ex("10", "Barbell Hip Thrust", "Hip thrust con barra", force: "push", level: "intermediate", mechanic: "compound",
               equipment: "barbell", primary: ["glutes"], primaryEs: ["Glúteos"], secondary: ["hamstrings"], secondaryEs: ["Isquiotibiales"]),
            ex("11", "Hanging Leg Raise", "Elevaciones de piernas colgado", force: "pull", level: "intermediate", mechanic: "isolation",
               equipment: "body only", primary: ["abdominals"], primaryEs: ["Abdominales"]),
            ex("12", "Hamstring Stretch", "Estiramiento de isquios", force: "static", level: "beginner", mechanic: "isolation",
               equipment: "body only", primary: ["hamstrings"], primaryEs: ["Isquiotibiales"], category: "stretching", categoryEs: "Estiramiento"),
            ex("13", "Box Jump", "Salto al cajón", force: "push", level: "intermediate", mechanic: "compound",
               equipment: "body only", primary: ["quadriceps"], primaryEs: ["Cuádriceps"], category: "plyometrics", categoryEs: "Pliometría"),
            ex("14", "Front Squat", "Sentadilla frontal", force: "push", level: "expert", mechanic: "compound",
               equipment: "barbell", primary: ["quadriceps"], primaryEs: ["Cuádriceps"], secondary: ["glutes", "abdominals"], secondaryEs: ["Glúteos", "Abdominales"]),
            ex("15", "Face Pull", "Face pull", force: "pull", level: "beginner", mechanic: "isolation",
               equipment: "cable", primary: ["shoulders"], primaryEs: ["Hombros"], secondary: ["traps"], secondaryEs: ["Trapecios"]),
            ex("16", "Leg Press", "Prensa de piernas", force: "push", level: "beginner", mechanic: "compound",
               equipment: "machine", primary: ["quadriceps"], primaryEs: ["Cuádriceps"], secondary: ["glutes"], secondaryEs: ["Glúteos"]),
            ex("17", "Chest-Supported Row", "Remo con apoyo en banco", force: "pull", level: "intermediate", mechanic: "compound",
               equipment: "dumbbell", primary: ["middle back"], primaryEs: ["Espalda media"], secondary: ["lats"], secondaryEs: ["Dorsales"]),
            ex("18", "Plank", "Plancha", force: "static", level: "beginner", mechanic: "isolation",
               equipment: "body only", primary: ["abdominals"], primaryEs: ["Abdominales"]),
            ex("19", "Walking Lunge", "Zancadas caminando", force: "push", level: "intermediate", mechanic: "compound",
               equipment: "dumbbell", primary: ["quadriceps"], primaryEs: ["Cuádriceps"], secondary: ["glutes"], secondaryEs: ["Glúteos"]),
            ex("20", "Barbell Curl", "Curl con barra", force: "pull", level: "beginner", mechanic: "isolation",
               equipment: "barbell", primary: ["biceps"], primaryEs: ["Bíceps"]),
        ]
    }()

    /// Marta's card as a friend sees it.
    static var sampleFriendProfile: FriendPublicProfile {
        let cal = Calendar.current
        func day(_ ago: Int) -> String {
            let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"
            return f.string(from: cal.date(byAdding: .day, value: -ago, to: Date())!)
        }
        return FriendPublicProfile(
            userId: "f1", name: "Marta", profileImageURL: nil,
            memberSince: cal.date(byAdding: .month, value: -9, to: Date())!,
            streak: TrainingStreakResponse(userId: "f1", currentStreak: 18, longestStreak: 30, totalDays: 140),
            workoutsLast7Days: 4, workoutsLast30Days: 17,
            recentSessions: [
                FriendSessionSummary(date: day(0), dayName: "Lunes", workoutName: "Pierna", durationSeconds: 3600, totalSets: 20, totalVolume: 8420),
                FriendSessionSummary(date: day(1), dayName: "Domingo", workoutName: "Espalda y bíceps", durationSeconds: 3100, totalSets: 18, totalVolume: 5960),
                FriendSessionSummary(date: day(3), dayName: "Viernes", workoutName: "Pecho y hombros", durationSeconds: 3300, totalSets: 21, totalVolume: 6240),
                FriendSessionSummary(date: day(5), dayName: "Miércoles", workoutName: "Pierna", durationSeconds: 3540, totalSets: 20, totalVolume: 8100),
            ],
            bestRecords: [
                FriendRecordSummary(exerciseName: "Sentadilla", weight: 120, reps: 3, date: cal.date(byAdding: .day, value: -4, to: Date())!),
                FriendRecordSummary(exerciseName: "Peso muerto", weight: 140, reps: 1, date: cal.date(byAdding: .day, value: -12, to: Date())!),
                FriendRecordSummary(exerciseName: "Press de banca", weight: 65, reps: 5, date: cal.date(byAdding: .day, value: -20, to: Date())!),
            ]
        )
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

    /// Monday to Sunday, each day a copy of the sample, so the day strip shows.
    private static func makeWeekDiet() -> [DietDay] {
        ["lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo"].map { name in
            let template = makeDiet()[0]
            let day = DietDay(day: name, meals: template.meals, supplements: template.supplements)
            day.hasMacros = template.hasMacros
            day.macroCalories = template.macroCalories
            day.macroProtein = template.macroProtein
            day.macroCarbs = template.macroCarbs
            day.macroFat = template.macroFat
            day.allowsCheatMeal = template.allowsCheatMeal
            return day
        }
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
                case "body":
                    NavigationStack {
                        BodyMeasurementsView().environmentObject(authManager)
                    }
                case "records":
                    NavigationStack {
                        RMTrackerView().environmentObject(authManager)
                    }
                case "live", "live-rest", "live-done":
                    LiveActivityPreview(state: DesignPreview.activityState(for: screen))
                case "explorer":
                    BulkUpGround().sheet(isPresented: .constant(true)) { ExerciseExplorerView() }
                case "explorer-filtered":
                    BulkUpGround().sheet(isPresented: .constant(true)) { ExerciseExplorerView() }
                        .onAppear {
                            ExerciseExplorerManager.shared.equipmentFilter = ["dumbbell"]
                            ExerciseExplorerManager.shared.levelFilter = ["beginner", "intermediate"]
                        }
                case "exercise":
                    BulkUpGround().sheet(isPresented: .constant(true)) {
                        RMExerciseDetailSheet(exercise: DesignPreview.sampleExercises[0])
                    }
                case "new-plan":
                    BulkUpGround().sheet(isPresented: .constant(true)) {
                        PlanActionsSheet(kind: .training, isSubscribed: false, canCreateAnother: false,
                                         hasActivePlan: true, viewMode: .constant(.day), onAction: { _ in })
                    }
                case "new-diet-plan":
                    BulkUpGround().sheet(isPresented: .constant(true)) {
                        PlanActionsSheet(kind: .diet, isSubscribed: true, canCreateAnother: true,
                                         hasActivePlan: true, onAction: { _ in })
                    }
                case "import", "import-busy", "import-failed":
                    BulkUpGround().sheet(isPresented: .constant(true)) {
                        ImportPlanView(
                            previewPhase: screen == "import-busy" ? .reading
                                : screen == "import-failed" ? .failed("El archivo no tiene texto legible. Prueba con una foto más nítida.")
                                : .idle,
                            previewName: screen == "import" ? "Volumen otoño" : ""
                        )
                        .environmentObject(authManager)
                    }
                case "code":
                    BulkUpGround().sheet(isPresented: .constant(true)) {
                        ImportPlanByCodeView()
                            .environmentObject(authManager)
                            .environmentObject(TrainingManager.shared)
                    }
                case "friend":
                    BulkUpGround().sheet(isPresented: .constant(true)) {
                        FriendProfileView(friend: FriendsManager.shared.friends[0], previewProfile: DesignPreview.sampleFriendProfile)
                    }
                case "edit-profile":
                    BulkUpGround().sheet(isPresented: .constant(true)) {
                        EditProfileView().environmentObject(authManager)
                    }
                case "add-friend":
                    BulkUpGround().sheet(isPresented: .constant(true)) {
                        AddFriendView().environmentObject(authManager)
                    }
                case "my-code":
                    BulkUpGround().sheet(isPresented: .constant(true)) {
                        MyFriendCodeView().onAppear { FriendsManager.shared.myFriendCode = "K7PM4W2X" }
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
            if screen == "training" || screen == "workout" || screen == "rest" || screen == "training-empty" || screen == "health" {
                try? await Task.sleep(nanoseconds: 600_000_000)
                NotificationCenter.default.post(name: .navigateToTraining, object: nil)
            }
            if screen == "health" {
                // Exercises the HealthKit wiring: the permission sheet proves the
                // entitlement and usage strings are in place for the iOS target.
                try? await Task.sleep(nanoseconds: 800_000_000)
                await HealthStore.shared.requestAuthorizationIfNeeded()
            }
            if screen == "progress" || screen == "progress-free" {
                try? await Task.sleep(nanoseconds: 600_000_000)
                NotificationCenter.default.post(name: .navigateToProgress, object: nil)
            }
            if screen == "profile" || screen == "profile-free" {
                try? await Task.sleep(nanoseconds: 600_000_000)
                NotificationCenter.default.post(name: .navigateToProfile, object: nil)
            }
            if screen == "diet" || screen == "diet-detail" || screen == "diet-empty" || screen == "diet-week" {
                try? await Task.sleep(nanoseconds: 600_000_000)
                NotificationCenter.default.post(name: .navigateToDiet, object: nil)
            }
        }
    }
}

// MARK: - Live Activity stand-in
/// The lock-screen card at the system's size (full width minus 14pt margins,
/// 160pt max height, 24pt radius) on a neutral wallpaper. The widget process
/// itself cannot be screenshotted from a script.
struct LiveActivityPreview: View {
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#3A4256"), Color(hex: "#151822")],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 24) {
                Text("9:41")
                    .font(.system(size: 84, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.top, 60)
                // Clip the card at its own height (the system rounds the real card
                // itself); the 160pt cap is the lock screen's, checked by eye.
                WorkoutActivityCard(state: state)
                    .fixedSize(horizontal: false, vertical: true)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .frame(maxHeight: 160, alignment: .top)
                    .padding(.horizontal, 14)
                Spacer()
            }
        }
    }
}

extension DesignPreview {
    static func activityState(for screen: String) -> WorkoutActivityAttributes.ContentState {
        var s = WorkoutActivityAttributes.ContentState(
            workoutName: "Pecho y hombros", startDate: Date().addingTimeInterval(-1265), isPaused: false,
            exerciseName: "Press inclinado en multipower", setIndex: 2, setsTotal: 4,
            weight: 62.5, reps: 8, weightUnit: "kg", needsWeight: false,
            completedSets: 4, totalSets: 18, isResting: false, restEndDate: nil, restStartDate: nil, isFinished: false
        )
        switch screen {
        case "live-rest":
            s.isResting = true
            s.restEndDate = Date().addingTimeInterval(67)
            s.restStartDate = Date().addingTimeInterval(-23)
        case "live-done":
            s.isFinished = true
            s.completedSets = 18
        default: break
        }
        return s
    }
}
#endif
