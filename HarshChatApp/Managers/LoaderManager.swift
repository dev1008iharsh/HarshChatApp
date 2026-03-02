//
//  LoaderManager.swift
//  HarshChatApp
//
//  Created by Harsh on 02/03/26.
//  🌐 Portfolio → https://dev1008iharsh.github.io/
//

import UIKit

// MARK: - LoaderService Protocol

/// Protocol to define loader behavior, making it easy to mock for testing.
protocol LoaderService {
    func startLoading()
    func stopLoading()
}

// MARK: - LoaderManager

/// A thread-safe singleton to manage global loading overlay.
final class LoaderManager: @preconcurrency LoaderService {
    static let shared = LoaderManager()

    private var backgroundView: UIView?
    private var spinner: UIActivityIndicatorView?

    private init() {}

    // MARK: - Public Methods

    /// Displays a full-screen loading spinner on the Key Window.
    @MainActor
    func startLoading() {
        // Prevent duplicate loaders
        guard backgroundView == nil else { return }

        guard let window = getActiveWindow() else { return }

        print("🔄 [Debug] UI: Starting Loader...")

        let containerView = UIView(frame: window.bounds)
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        containerView.alpha = 0

        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white
        activityIndicator.center = containerView.center
        activityIndicator.hidesWhenStopped = true

        containerView.addSubview(activityIndicator)
        window.addSubview(containerView)

        activityIndicator.startAnimating()

        backgroundView = containerView
        spinner = activityIndicator

        UIView.animate(withDuration: 0.25) {
            containerView.alpha = 1.0
        }
    }

    /// Hides and removes the loading spinner from the view hierarchy.
    @MainActor
    func stopLoading() {
        guard let view = backgroundView else { return }

        print("✅ [Debug] UI: Stopping Loader.")

        UIView.animate(withDuration: 0.2) {
            view.alpha = 0
        } completion: { _ in
            self.spinner?.stopAnimating()
            view.removeFromSuperview()
            self.backgroundView = nil
            self.spinner = nil
        }
    }

    // MARK: - Private Helpers

    /// Safely fetches the current active key window.
    private func getActiveWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first { $0.isKeyWindow }
    }
}
