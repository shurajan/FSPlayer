//
//  HideControlsTimerService.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 28.04.2025.
//

import SwiftUI

@MainActor
final class HideControlsTimerService: ObservableObject {
    private var timerTask: Task<Void, Never>?
    private var timeout: Duration = .seconds(3)
    private var onTimeout: (() -> Void)?

    func configure(timeout: TimeInterval, onTimeout: @escaping () -> Void) {
        self.timeout = .seconds(timeout)
        self.onTimeout = onTimeout
    }

    func start() {
        stop()
        timerTask = Task { [timeout, onTimeout] in
            do {
                try await Task.sleep(for: timeout)
                onTimeout?()
            } catch {
            }
        }
    }

    func stop() {
        timerTask?.cancel()
        timerTask = nil
    }

    deinit {
        Task { @MainActor [weak self] in
            self?.stop()
        }
    }
}
