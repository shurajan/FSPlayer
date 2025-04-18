import Foundation
import Network
import Combine

@available(macOS 12.0, iOS 15.0, *)
class BonjourDiscoveryService {
    // MARK: - Types
    
    struct DiscoveredService: Identifiable, Hashable {
        let id: UUID = UUID()
        let name: String
        let type: String
        let domain: String
        let endpoint: NWEndpoint?
        let txt: [String: String]
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: DiscoveredService, rhs: DiscoveredService) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    // MARK: - Properties
    
    private var browser: NWBrowser?
    private let servicesSubject = CurrentValueSubject<[DiscoveredService], Never>([])
    private var cancellables = Set<AnyCancellable>()
    
    // Publisher для найденных сервисов
    var servicesPublisher: AnyPublisher<[DiscoveredService], Never> {
        servicesSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Public Methods
    
    func startDiscovery(for type: String, in domain: String = "local") {
        stopDiscovery()
        servicesSubject.send([])
        
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        
        let browseDescriptor = NWBrowser.Descriptor.bonjour(type: type, domain: domain)
        browser = NWBrowser(for: browseDescriptor, using: parameters)
        
        browser?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("Browser is ready")
            case .failed(let error):
                print("Browser failed: \(error)")
                self?.stopDiscovery()
            case .cancelled:
                print("Browser was cancelled")
            default:
                break
            }
        }
        
        browser?.browseResultsChangedHandler = { [weak self] results, _ in
            self?.handleBrowseResults(results)
        }
        
        browser?.start(queue: .main)
    }
    
    func stopDiscovery() {
        browser?.cancel()
        browser = nil
    }
    
    // MARK: - Private Methods
    
    private func handleBrowseResults(_ results: Set<NWBrowser.Result>) {
        var updatedServices: [DiscoveredService] = []
        
        for result in results {
            switch result.endpoint {
            case .service(let name, let type, let domain, _):
                let service = DiscoveredService(
                    name: name,
                    type: type,
                    domain: domain,
                    endpoint: result.endpoint,
                    txt: [:]
                )
                updatedServices.append(service)
            default:
                break
            }
        }
        
        servicesSubject.send(updatedServices)
    }
    
    func resolveService(_ service: DiscoveredService) -> AnyPublisher<(hostname: String, port: Int), Error> {
        return Future<(hostname: String, port: Int), Error> { promise in
            guard let endpoint = service.endpoint,
                  case .service(let name, let type, let domain, _) = endpoint else {
                promise(.failure(NSError(domain: "BonjourService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid endpoint"])))
                return
            }
            
            print("Попытка разрешения сервиса: \(service.name)")
            
            // Используем NetService для разрешения вместо прямого подключения
            let netService = NetService(domain: domain, type: type, name: name)
            
            class Resolver: NSObject, NetServiceDelegate {
                let promise: (Result<(hostname: String, port: Int), Error>) -> Void
                var timer: Timer?
                
                init(promise: @escaping (Result<(hostname: String, port: Int), Error>) -> Void) {
                    self.promise = promise
                    super.init()
                }
                
                func netServiceDidResolveAddress(_ sender: NetService) {
                    timer?.invalidate()
                    
                    if let hostname = sender.hostName, sender.port > 0 {
                        print("✅ Успешно разрешено: \(hostname):\(sender.port)")
                        promise(.success((hostname: hostname, port: sender.port)))
                    } else {
                        let error = NSError(domain: "BonjourService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Сервис разрешен, но имя хоста или порт не получены"])
                        promise(.failure(error))
                    }
                }
                
                func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
                    timer?.invalidate()
                    let error = NSError(domain: "BonjourService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Не удалось разрешить сервис: \(errorDict)"])
                    promise(.failure(error))
                }
                
                func startTimer() {
                    timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
                        guard let self = self else { return }
                        let error = NSError(domain: "BonjourService", code: 6, userInfo: [NSLocalizedDescriptionKey: "Тайм-аут разрешения сервиса"])
                        self.promise(.failure(error))
                    }
                }
            }
            
            let resolver = Resolver(promise: promise)
            netService.delegate = resolver
            resolver.startTimer()
            
            // Запускаем разрешение с тайм-аутом
            print("Запуск разрешения для \(name)")
            netService.resolve(withTimeout: 5.0)
        }
        .eraseToAnyPublisher()
    }
    
    deinit {
        stopDiscovery()
        cancellables.removeAll()
    }
}
