import SwiftUI
import Combine
import Network

@available(macOS 12.0, iOS 15.0, *)
class BonjourDiscoveryController: ObservableObject {
    // MARK: - Properties
    
    // Основной сервис для обнаружения Bonjour
    private let browser: MediaFSBrowser
    
    // Публикуемые свойства для обновления UI
    @Published var discoveredServices: [MediaFSBrowser.DiscoveredService] = []
    @Published var isDiscovering: Bool = false
    @Published var selectedServer: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(browser: MediaFSBrowser = MediaFSBrowser()) {
        self.browser = browser
        setupPublishers()
    }
    
    private func setupPublishers() {
        // Подписка на публикации сервисов
        browser.servicesPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] services in
                self?.discoveredServices = services
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Запустить поиск Bonjour-сервисов MediaFS
    func startDiscovery() {
        isDiscovering = true
        // Очищаем предыдущие результаты
        selectedServer = nil
        browser.startDiscovery()
    }
    
    /// Остановить текущий поиск
    func stopDiscovery() {
        isDiscovering = false
        browser.stopDiscovery()
    }
    
    /// Выбрать сервер и вернуть его хост
    /// - Parameter service: Сервис для выбора
    func selectServer(_ service: MediaFSBrowser.DiscoveredService) {
        if service.isResolved, let hostname = service.hostname, let port = service.port {
            selectedServer = "\(hostname):\(port)"
            print("Выбран сервер: \(selectedServer!)")
        } else {
            print("Сервер не может быть выбран, так как не разрешен полностью")
        }
    }
    
    /// Получить базовый URL для выбранного сервера
    /// - Returns: URL-строка для API-запросов
    func getServerBaseURL() -> String? {
        return selectedServer.map { "http://\($0)" }
    }
    
    /// Проверить, разрешен ли сервис
    /// - Parameter id: ID сервиса
    /// - Returns: true если сервис разрешен и готов к использованию
    func isServiceResolved(_ id: UUID) -> Bool {
        return discoveredServices.first(where: { $0.id == id })?.isResolved ?? false
    }
    
    /// Получить информацию о разрешенном сервисе
    /// - Parameter id: ID сервиса
    /// - Returns: Кортеж с хостом и портом или nil
    func getResolvedServiceInfo(_ id: UUID) -> (hostname: String, port: Int)? {
        guard let service = discoveredServices.first(where: { $0.id == id }),
              service.isResolved,
              let hostname = service.hostname,
              let port = service.port else {
            return nil
        }
        
        return (hostname: hostname, port: port)
    }
    
    deinit {
        stopDiscovery()
        cancellables.removeAll()
    }
}
