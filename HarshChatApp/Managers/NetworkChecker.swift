//
//  NetworkChecker.swift
//  HarshChatApp
//
//  Created by Harsh on 20/03/26.
//  🌐 Portfolio → https://dev1008iharsh.github.io/
//

import Foundation
import Network

// MARK: - NetworkChecker

/// A modern, production-grade utility class to check network connectivity.
/// Uses Apple's modern `NWPathMonitor` framework as `SCNetworkReachability` is deprecated in iOS 17.4+.
final class NetworkChecker {
    // Shared instance that quietly tracks network changes in the background with zero impact on UI.
    static let shared = NetworkChecker()

    private let monitor = NWPathMonitor()
    // Using a low-priority background queue to save battery and performance.
    private let queue = DispatchQueue(label: "NetworkChecker_BackgroundQueue", qos: .background)

    // Holds the latest network state.
    private(set) var currentStatus: Bool = false

    private init() {
        // Start monitoring as soon as the singleton is created in memory.
        monitor.pathUpdateHandler = { [weak self] path in
            self?.currentStatus = (path.status == .satisfied)
        }
        monitor.start(queue: queue)
    }

    /// Instantly returns `true` if the internet is available, `false` otherwise.
    /// You can use this synchronously like: `if NetworkChecker.isConnected { ... }`
    static var isConnected: Bool {
        return shared.currentStatus
    }
}
