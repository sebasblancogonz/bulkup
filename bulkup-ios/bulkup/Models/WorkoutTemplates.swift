//
//  WorkoutTemplates.swift
//  bulkup
//

import SwiftUI

struct WorkoutTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let daysPerWeek: Int
    let icon: String
    let color: Color
    let trainingDays: [ServerTrainingDay]
}

// MARK: - Helper

private func exercise(_ name: String, sets: Int, reps: String) -> ServerExercise {
    ServerExercise(
        name: name,
        sets: sets,
        reps: reps,
        restSeconds: 90,
        notes: nil,
        tempo: nil,
        weightTracking: true
    )
}

// MARK: - Predefined Templates

enum WorkoutTemplates {
    static let all: [WorkoutTemplate] = [ppl, upperLower, fullBody, broSplit, torsoPierna]

    // MARK: PPL Completo — 6 días

    static let ppl = WorkoutTemplate(
        name: "PPL Completo",
        description: "Push/Pull/Legs con variantes A y B. Ideal para intermedios-avanzados que pueden entrenar 6 días.",
        daysPerWeek: 6,
        icon: "flame.fill",
        color: .blue,
        trainingDays: [
            ServerTrainingDay(day: "Lunes", workoutName: "Push A", output: [
                exercise("Press banca", sets: 4, reps: "5-8"),
                exercise("Press inclinado mancuernas", sets: 3, reps: "8-10"),
                exercise("Press militar", sets: 3, reps: "6-8"),
                exercise("Elevaciones laterales", sets: 4, reps: "12-15"),
                exercise("Extensión tríceps polea", sets: 3, reps: "10-12"),
            ]),
            ServerTrainingDay(day: "Martes", workoutName: "Pull A", output: [
                exercise("Dominadas lastradas", sets: 4, reps: "6-8"),
                exercise("Remo barra", sets: 4, reps: "6-8"),
                exercise("Remo mancuerna", sets: 3, reps: "8-10"),
                exercise("Face pull", sets: 3, reps: "12-15"),
                exercise("Curl barra", sets: 3, reps: "8-10"),
            ]),
            ServerTrainingDay(day: "Miércoles", workoutName: "Legs A", output: [
                exercise("Sentadilla", sets: 4, reps: "5-8"),
                exercise("Prensa", sets: 3, reps: "10-12"),
                exercise("Extensión cuádriceps", sets: 3, reps: "12-15"),
                exercise("Curl femoral", sets: 3, reps: "10-12"),
                exercise("Gemelos", sets: 4, reps: "15-20"),
            ]),
            ServerTrainingDay(day: "Jueves", workoutName: "Push B", output: [
                exercise("Press militar", sets: 4, reps: "5-8"),
                exercise("Press banca agarre cerrado", sets: 3, reps: "6-8"),
                exercise("Press inclinado", sets: 3, reps: "8-10"),
                exercise("Elevaciones laterales", sets: 4, reps: "15"),
                exercise("Fondos", sets: 3, reps: "AMRAP"),
            ]),
            ServerTrainingDay(day: "Viernes", workoutName: "Pull B", output: [
                exercise("Jalón agarre ancho", sets: 4, reps: "8-10"),
                exercise("Remo polea baja", sets: 3, reps: "10-12"),
                exercise("Pullover polea", sets: 3, reps: "12"),
                exercise("Pájaros", sets: 3, reps: "15"),
                exercise("Curl inclinado", sets: 3, reps: "10-12"),
            ]),
            ServerTrainingDay(day: "Sábado", workoutName: "Legs B", output: [
                exercise("Peso muerto rumano", sets: 4, reps: "6-8"),
                exercise("Zancadas", sets: 3, reps: "10"),
                exercise("Hip thrust", sets: 3, reps: "8-10"),
                exercise("Curl femoral", sets: 3, reps: "12"),
                exercise("Gemelos", sets: 4, reps: "15-20"),
            ]),
        ]
    )

    // MARK: Upper / Lower — 4 días

    static let upperLower = WorkoutTemplate(
        name: "Upper / Lower",
        description: "Combinación de fuerza e hipertrofia. 4 días por semana, ideal para nivel intermedio.",
        daysPerWeek: 4,
        icon: "arrow.up.arrow.down",
        color: .green,
        trainingDays: [
            ServerTrainingDay(day: "Lunes", workoutName: "Upper A (Fuerza)", output: [
                exercise("Press banca", sets: 5, reps: "5"),
                exercise("Dominadas", sets: 4, reps: "6"),
                exercise("Press militar", sets: 4, reps: "6"),
                exercise("Remo barra", sets: 4, reps: "6"),
                exercise("Curl + tríceps", sets: 3, reps: "8-10"),
            ]),
            ServerTrainingDay(day: "Martes", workoutName: "Lower A (Fuerza)", output: [
                exercise("Sentadilla", sets: 5, reps: "5"),
                exercise("Peso muerto rumano", sets: 4, reps: "6"),
                exercise("Prensa", sets: 3, reps: "10"),
                exercise("Gemelos", sets: 4, reps: "15"),
            ]),
            ServerTrainingDay(day: "Jueves", workoutName: "Upper B (Hipertrofia)", output: [
                exercise("Press inclinado", sets: 4, reps: "8-10"),
                exercise("Jalón", sets: 4, reps: "10-12"),
                exercise("Elevaciones laterales", sets: 4, reps: "15"),
                exercise("Remo polea", sets: 3, reps: "12"),
                exercise("Brazos", sets: 3, reps: "12-15"),
            ]),
            ServerTrainingDay(day: "Viernes", workoutName: "Lower B (Hipertrofia)", output: [
                exercise("Hack / zancadas", sets: 4, reps: "10"),
                exercise("Curl femoral", sets: 4, reps: "10-12"),
                exercise("Hip thrust", sets: 3, reps: "8-10"),
                exercise("Gemelos", sets: 4, reps: "20"),
            ]),
        ]
    )

    // MARK: Full Body — 3 días

    static let fullBody = WorkoutTemplate(
        name: "Full Body",
        description: "3 días por semana. Ideal para principiantes, mantenimiento o fuerza general.",
        daysPerWeek: 3,
        icon: "figure.strengthtraining.traditional",
        color: .orange,
        trainingDays: [
            ServerTrainingDay(day: "Lunes", workoutName: "Día A", output: [
                exercise("Sentadilla", sets: 4, reps: "5"),
                exercise("Press banca", sets: 4, reps: "6"),
                exercise("Remo barra", sets: 4, reps: "6"),
            ]),
            ServerTrainingDay(day: "Miércoles", workoutName: "Día B", output: [
                exercise("Peso muerto", sets: 3, reps: "5"),
                exercise("Press militar", sets: 4, reps: "6"),
                exercise("Dominadas", sets: 4, reps: "AMRAP"),
            ]),
            ServerTrainingDay(day: "Viernes", workoutName: "Día C", output: [
                exercise("Prensa", sets: 3, reps: "10"),
                exercise("Press inclinado", sets: 3, reps: "8"),
                exercise("Jalón", sets: 3, reps: "10"),
                exercise("Core", sets: 3, reps: "15-20"),
            ]),
        ]
    )

    // MARK: Bro Split — 5 días

    static let broSplit = WorkoutTemplate(
        name: "Bro Split Clásico",
        description: "Un grupo muscular por día. 5 días, alto volumen por músculo. Clásico del culturismo.",
        daysPerWeek: 5,
        icon: "dumbbell.fill",
        color: .red,
        trainingDays: [
            ServerTrainingDay(day: "Lunes", workoutName: "Pecho", output: [
                exercise("Press banca", sets: 4, reps: "5-8"),
                exercise("Press inclinado mancuernas", sets: 4, reps: "8-10"),
                exercise("Press plano mancuernas", sets: 3, reps: "10-12"),
                exercise("Aperturas", sets: 3, reps: "12-15"),
                exercise("Fondos", sets: 3, reps: "AMRAP"),
            ]),
            ServerTrainingDay(day: "Martes", workoutName: "Espalda", output: [
                exercise("Dominadas / jalón", sets: 4, reps: "6-10"),
                exercise("Remo barra", sets: 4, reps: "6-8"),
                exercise("Remo polea", sets: 3, reps: "10-12"),
                exercise("Pullover", sets: 3, reps: "12-15"),
                exercise("Face pull", sets: 3, reps: "15"),
            ]),
            ServerTrainingDay(day: "Miércoles", workoutName: "Pierna", output: [
                exercise("Sentadilla", sets: 4, reps: "5-8"),
                exercise("Prensa", sets: 4, reps: "10-12"),
                exercise("Peso muerto rumano", sets: 3, reps: "8-10"),
                exercise("Curl femoral", sets: 3, reps: "10-12"),
                exercise("Gemelos", sets: 5, reps: "15-20"),
            ]),
            ServerTrainingDay(day: "Jueves", workoutName: "Hombro", output: [
                exercise("Press militar", sets: 4, reps: "5-8"),
                exercise("Elevaciones laterales", sets: 5, reps: "12-15"),
                exercise("Pájaros", sets: 4, reps: "15"),
                exercise("Upright row / polea", sets: 3, reps: "10-12"),
            ]),
            ServerTrainingDay(day: "Viernes", workoutName: "Brazos", output: [
                exercise("Curl barra", sets: 4, reps: "6-8"),
                exercise("Curl inclinado", sets: 3, reps: "10-12"),
                exercise("Curl polea", sets: 3, reps: "12-15"),
                exercise("Press cerrado", sets: 4, reps: "6-8"),
                exercise("Extensión polea", sets: 3, reps: "10-12"),
                exercise("Extensión overhead", sets: 3, reps: "12-15"),
            ]),
        ]
    )

    // MARK: Torso / Pierna — 4 días

    static let torsoPierna = WorkoutTemplate(
        name: "Torso / Pierna",
        description: "Variante avanzada con sesiones de fuerza e hipertrofia. 4 días por semana.",
        daysPerWeek: 4,
        icon: "figure.walk",
        color: .purple,
        trainingDays: [
            ServerTrainingDay(day: "Lunes", workoutName: "Torso Fuerza", output: [
                exercise("Press banca", sets: 5, reps: "5"),
                exercise("Remo barra", sets: 5, reps: "5"),
                exercise("Press militar", sets: 3, reps: "5"),
            ]),
            ServerTrainingDay(day: "Martes", workoutName: "Pierna Fuerza", output: [
                exercise("Sentadilla", sets: 5, reps: "5"),
                exercise("Peso muerto rumano", sets: 4, reps: "6"),
            ]),
            ServerTrainingDay(day: "Jueves", workoutName: "Torso Hipertrofia", output: [
                exercise("Press inclinado", sets: 4, reps: "8"),
                exercise("Jalón", sets: 4, reps: "10"),
                exercise("Laterales + brazos", sets: 3, reps: "12"),
            ]),
            ServerTrainingDay(day: "Viernes", workoutName: "Pierna Hipertrofia", output: [
                exercise("Prensa", sets: 4, reps: "10"),
                exercise("Curl femoral", sets: 4, reps: "10"),
                exercise("Gemelos", sets: 5, reps: "15"),
            ]),
        ]
    )
}
