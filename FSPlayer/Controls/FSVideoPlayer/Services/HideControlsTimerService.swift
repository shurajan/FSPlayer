//
//  HideControlsTimerService.swift
//  FSVideoPlayer
//

import SwiftUI

@MainActor
final class HideControlsTimerService {
    private var timerTask: Task<Void, Never>?
    private var onTimeout: (() -> Void)?

    func configure(onTimeout: @escaping () -> Void) {
        self.onTimeout = onTimeout
    }

    func start(timeout: TimeInterval) {
        stop()
        timerTask = Task { [weak self, onTimeout] in
            do {
                try await Task.sleep(for: .seconds(timeout))
                guard let self, !Task.isCancelled else { return }
                onTimeout?()
            } catch {
                // Task was cancelled
            }
        }
    }

    func stop() {
        timerTask?.cancel()
        timerTask = nil
    }
}
