//
//  DateFormatter+Extensions.swift
//  bulkup
//
//  Created by sebastianblancogonz on 18/8/25.
//
import Foundation

extension DateFormatter {
    func apply(_ closure: (DateFormatter) -> Void) -> DateFormatter {
        closure(self)
        return self
    }
}
