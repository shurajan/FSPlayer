//
//  SafeTask.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 28.04.2025.
//
import Foundation

final class SafeTask {
    private var task: Task<Void, Never>?

    deinit {
        cancel()
    }

    func start(operation: @Sendable @escaping () async -> Void) {
        cancel()
        task = Task(operation: operation)
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}
