//
//  Notification+Extensions.swift
//  bulkup
//
//  Created by sebastianblancogonz on 18/8/25.
//
import Foundation

extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
    static let userDidLogout = Notification.Name("userDidLogout")
    static let navigateToTrainingLibrary = Notification.Name("navigateToTrainingLibrary")
    static let navigateToDietLibrary = Notification.Name("navigateToDietLibrary")
    static let onboardingOpenTrainingUpload = Notification.Name("onboardingOpenTrainingUpload")
    static let onboardingOpenDietUpload = Notification.Name("onboardingOpenDietUpload")
    static let navigateToTraining = Notification.Name("navigateToTraining")
    static let navigateToDiet = Notification.Name("navigateToDiet")
    static let finishWorkoutSession = Notification.Name("finishWorkoutSession")
}
