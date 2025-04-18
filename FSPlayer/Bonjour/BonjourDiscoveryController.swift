//
//  BonjourDiscoveryController.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 18.04.2025.
//

import SwiftUI
import Combine
import Network

@available(macOS 12.0, iOS 15.0, *)
class BonjourDiscoveryController: ObservableObject {
    // MARK: - Properties
    
    // Основной сервис для обнаружения Bonjour
    private let discoveryService: BonjourDiscoveryService
    
    // Публикуемые свойства для обновления UI
    @Published var discoveredServices: [BonjourDiscoveryService.DiscoveredService] = []
    @Published var isDiscovering: Bool = false
    @Published var resolvedServices: [UUID: (hostname: String, port: Int)] = [:]
    @Published var resolvingErrors: [UUID: String] = [:]
    @Published var selectedServer: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(discoveryService: BonjourDiscoveryService = BonjourDiscoveryService()) {
        self.discoveryService = discoveryService
        setupPublishers()
    }
    
    private func setupPublishers() {
        // Подписка на публикации сервисов
        discoveryService.servicesPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] services in
                self?.discoveredServices = services
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Запустить поиск Bonjour-сервисов определенного типа
    /// - Parameter type: Тип сервиса для поиска (например, "_http._tcp")
    func startDiscovery(for type: String = "_http._tcp") {
        isDiscovering = true
        // Очищаем предыдущие результаты
        resolvedServices.removeAll()
        resolvingErrors.removeAll()
        
        discoveryService.startDiscovery(for: type)
    }
    
    /// Остановить текущий поиск
    func stopDiscovery() {
        isDiscovering = false
        discoveryService.stopDiscovery()
    }
    
    /// Разрешить сервис для получения хоста и порта
    /// - Parameter service: Сервис для разрешения
    func resolveService(_ service: BonjourDiscoveryService.DiscoveredService) {
        // Очищаем предыдущие ошибки для этого сервиса
        resolvingErrors[service.id] = nil
        print("Попытка разрешения сервиса: \(service.name)")
        discoveryService.resolveService(service)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("Ошибка разрешения: \(error.localizedDescription)")
                        self?.resolvingErrors[service.id] = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] resolved in
                    print("Сервис разрешен: \(resolved.hostname):\(resolved.port)")
                    self?.resolvedServices[service.id] = resolved
                }
            )
            .store(in: &cancellables)
    }
    
    /// Выбрать сервер и вернуть его хост
    /// - Parameter serviceId: ID сервиса для выбора
    func selectServer(with serviceId: UUID) {
        if let resolved = resolvedServices[serviceId] {
            selectedServer = "\(resolved.hostname):\(resolved.port)"
        }
    }
    
    deinit {
        stopDiscovery()
        cancellables.removeAll()
    }
}
