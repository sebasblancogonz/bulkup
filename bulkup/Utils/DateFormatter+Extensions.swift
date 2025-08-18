//
//  DateFormatter+Extensions.swift
//  bulkup
//
//  Created by sebastian.blanco on 18/8/25.
//
import Foundation

extension DateFormatter {
    func apply(_ closure: (DateFormatter) -> Void) -> DateFormatter {
        closure(self)
        return self
    }
}
