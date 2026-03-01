//
//  LoaderManager.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//

import UIKit

protocol LoaderService {
    func startLoading()
    func stopLoading()
}

class LoaderManager: LoaderService {
    static let shared = LoaderManager()

    private var backgroundView: UIView?
    private var spinner: UIActivityIndicatorView?

    private init() {}

    func startLoading() {
        guard backgroundView == nil else { return }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return
        }

        let view = UIView(frame: window.bounds)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.alpha = 0

        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white
        activityIndicator.center = view.center

        view.addSubview(activityIndicator)
        window.addSubview(view)

        activityIndicator.startAnimating()

        backgroundView = view
        spinner = activityIndicator

        UIView.animate(withDuration: 0.25) {
            view.alpha = 1.0
        }
    }

    func stopLoading() {
        guard let view = backgroundView else { return }

        UIView.animate(withDuration: 0.25, animations: {
            view.alpha = 0
        }) { _ in
            self.spinner?.stopAnimating()
            view.removeFromSuperview()

            self.backgroundView = nil
            self.spinner = nil
        }
    }
}
