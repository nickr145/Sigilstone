//
//  AnalyticsService.swift
//  Sigilstone
//

import Foundation

// If a real analytics SDK is ever added, update PrivacyInfo.xcprivacy and the App Store privacy answers.
protocol AnalyticsService {
    func track(event: String, properties: [String: Any])
}

extension AnalyticsService {
    func track(event: String) {
        track(event: event, properties: [:])
    }
}

final class ConsoleAnalyticsService: AnalyticsService {
    func track(event: String, properties: [String: Any]) {
        #if DEBUG
        print("[Analytics] \(event) \(properties)")
        #endif
    }
}
