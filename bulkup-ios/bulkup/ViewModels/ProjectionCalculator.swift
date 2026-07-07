//
//  ProjectionCalculator.swift
//  bulkup
//

import Foundation

struct NutritionProjection {
    let projectedWeight: Double
    let projectedBodyFat: Double
    let projectedLeanMass: Double
    let weightChange: Double
    let leanMassChange: Double
    let bodyFatPercentageChange: Double
    let daysToReview: Int
    let complianceRate: Double
}

struct ProjectionCalculator {

    /// Calculate projections based on current body composition, compliance, and time to review
    /// - Parameters:
    ///   - currentWeight: Current weight in kg
    ///   - currentBodyFatPercentage: Current body fat %
    ///   - currentLeanMass: Current lean mass in kg
    ///   - complianceRate: Diet compliance rate (0.0 - 1.0)
    ///   - daysToReview: Days until next nutritional review
    ///   - sex: "H" for male, "M" for female
    static func calculate(
        currentWeight: Double,
        currentBodyFatPercentage: Double,
        currentLeanMass: Double,
        complianceRate: Double,
        daysToReview: Int,
        sex: String
    ) -> NutritionProjection {
        let weeksToReview = Double(daysToReview) / 7.0

        // Base rates per week at 100% compliance
        // Men: ~0.125 kg muscle/week (0.5 kg/month)
        // Women: ~0.0625 kg muscle/week (0.25 kg/month)
        let baseMuscleGainPerWeek = sex == "H" ? 0.125 : 0.0625

        // Scale by compliance
        let effectiveMuscleGainPerWeek = baseMuscleGainPerWeek * complianceRate

        // Fat change: assume moderate recomposition (~0.1 kg fat loss/week)
        let currentFatMass = currentWeight * (currentBodyFatPercentage / 100)
        let baseFatLossPerWeek = 0.1
        let effectiveFatLossPerWeek = baseFatLossPerWeek * complianceRate

        let projectedLeanMass = currentLeanMass + (effectiveMuscleGainPerWeek * weeksToReview)
        let projectedFatMass = max(currentFatMass - (effectiveFatLossPerWeek * weeksToReview), currentFatMass * 0.5)
        let projectedWeight = projectedLeanMass + projectedFatMass
        let projectedBodyFat = (projectedFatMass / projectedWeight) * 100

        return NutritionProjection(
            projectedWeight: projectedWeight,
            projectedBodyFat: projectedBodyFat,
            projectedLeanMass: projectedLeanMass,
            weightChange: projectedWeight - currentWeight,
            leanMassChange: projectedLeanMass - currentLeanMass,
            bodyFatPercentageChange: projectedBodyFat - currentBodyFatPercentage,
            daysToReview: daysToReview,
            complianceRate: complianceRate
        )
    }
}
