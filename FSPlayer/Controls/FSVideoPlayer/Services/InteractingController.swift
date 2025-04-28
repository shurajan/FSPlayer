//
//  InteractingController.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 28.04.2025.
//

import Foundation

actor InteractingController {
    private let subject = AsyncStream.makeStream(of: Bool.self)

    var interactingChanges: AsyncStream<Bool> { subject.stream }

    func startInteraction() {
        subject.continuation.yield(true)
    }

    func endInteraction() {
        subject.continuation.yield(false)
    }
}
