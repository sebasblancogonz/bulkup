//
//  MealConditionsView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 17/8/25.
//

import SwiftUI
import SwiftData


struct MealConditionsView: View {
    let conditions: MealConditions
    let mealType: String
    
    var body: some View {
        VStack(spacing: 12) {
            if let trainingDays = conditions.trainingDays {
                ConditionCardView(
                    condition: trainingDays,
                    title: "Solo días de entrenamiento",
                    color: .blue,
                    icon: "dumbbell.fill"
                )
            }
            
            if let nonTrainingDays = conditions.nonTrainingDays {
                ConditionCardView(
                    condition: nonTrainingDays,
                    title: "Solo días sin entrenamiento",
                    color: .purple,
                    icon: "bed.double.fill"
                )
            }
        }
    }
}
