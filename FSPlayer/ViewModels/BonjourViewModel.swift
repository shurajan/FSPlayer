//
//  BonjourViewModel.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 18.04.2025.
//
import Foundation
import Combine

final class BonjourViewModel: ObservableObject {
    @Published var discoveredServices: [BonjourDiscoveryService.DiscoveredService] = []
    @Published var isDiscovering: Bool = false
    @Published var resolvedServices: [UUID: (hostname: String, port: Int)] = [:]
    @Published var resolvingErrors: [UUID: String] = [:]
    
    private let discoveryService = BonjourDiscoveryService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        discoveryService.servicesPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] services in
                self?.discoveredServices = services
            }
            .store(in: &cancellables)
    }
    
    func startDiscovery(for type: String = "_http._tcp") {
        isDiscovering = true
        discoveryService.startDiscovery(for: type)
    }
    
    func stopDiscovery() {
        isDiscovering = false
        discoveryService.stopDiscovery()
    }
    
    func resolveService(_ service: BonjourDiscoveryService.DiscoveredService) {
        discoveryService.resolveService(service)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.resolvingErrors[service.id] = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] resolved in
                    self?.resolvedServices[service.id] = resolved
                }
            )
            .store(in: &cancellables)
    }
}
