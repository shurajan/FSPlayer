import Foundation
import Network
import Combine

class MediaFSBrowser {
    // MARK: - Types
    
    struct DiscoveredService: Identifiable, Hashable {
        let id: UUID = UUID()
        let name: String
        let type: String
        let domain: String
        let endpoint: NWEndpoint?
        var hostname: String?
        var port: Int?
        var isResolved: Bool = false
        
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
    private var resolvers: [UUID: NetService] = [:]
    
    // Publisher для найденных сервисов
    var servicesPublisher: AnyPublisher<[DiscoveredService], Never> {
        servicesSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Public Methods
    
    func startDiscovery() {
        stopDiscovery()
        servicesSubject.send([])
        
        // Создаем параметры для поиска, включая peer-to-peer
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        
        // Ищем сервис с типом "_http._tcp" в локальной сети
        let browser = NWBrowser(for: .bonjour(type: "_http._tcp", domain: nil), using: parameters)
        self.browser = browser
        
        browser.stateUpdateHandler = { [weak self] newState in
            switch newState {
            case .ready:
                print("🔍 Browser is ready")
                // Публикуем начальные результаты
                if let results = self?.browser?.browseResults {
                    self?.handleBrowseResults(results)
                }
            case .failed(let error):
                if error == NWError.dns(DNSServiceErrorType(kDNSServiceErr_DefunctConnection)) {
                    print("🔄 Browser failed with \(error), restarting")
                    browser.cancel()
                    self?.startDiscovery()
                } else {
                    print("❌ Browser failed with \(error), stopping")
                    browser.cancel()
                }
            case .cancelled:
                print("🛑 Browser was cancelled")
            default:
                break
            }
        }
        
        browser.browseResultsChangedHandler = { [weak self] results, changes in
            self?.handleBrowseResults(results)
        }
        
        // Запускаем поиск на главной очереди
        browser.start(queue: .main)
    }
    
    func stopDiscovery() {
        browser?.cancel()
        browser = nil
        
        // Останавливаем все активные резолверы
        for (_, resolver) in resolvers {
            resolver.stop()
        }
        resolvers.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func handleBrowseResults(_ results: Set<NWBrowser.Result>) {
        var updatedServices: [DiscoveredService] = []
        
        for result in results {
            if case .service(let name, let type, let domain, _) = result.endpoint {
                // Фильтруем только MediaFS сервисы
                if name == "MediaFS" {
                    print("📡 Found MediaFS service: \(name)")
                    let service = DiscoveredService(
                        name: name,
                        type: type,
                        domain: domain,
                        endpoint: result.endpoint
                    )
                    updatedServices.append(service)
                    
                    // Автоматически запускаем разрешение для найденного сервиса
                    resolveService(service) { hostname, port in
                        print("✅ Resolved MediaFS at \(hostname):\(port)")
                        
                        // Обновляем информацию в сервисе
                        DispatchQueue.main.async {
                            var services = self.servicesSubject.value
                            if let index = services.firstIndex(where: { $0.id == service.id }) {
                                var updatedService = services[index]
                                updatedService.hostname = hostname
                                updatedService.port = port
                                updatedService.isResolved = true
                                services[index] = updatedService
                                self.servicesSubject.send(services)
                            }
                        }
                    }
                }
            }
        }
        
        servicesSubject.send(updatedServices)
    }
    
    func resolveService(_ service: DiscoveredService, completion: @escaping (String, Int) -> Void) {
        guard let endpoint = service.endpoint,
              case .service(let name, let type, let domain, _) = endpoint else {
            print("❌ Invalid endpoint for resolution")
            return
        }
        
        print("🔄 Resolving service: \(name)")
        
        // Создаем соединение для получения хоста и порта
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        
        // Решение 1: используем NWConnection для прямого подключения и получения информации
        let connection = NWConnection(to: endpoint, using: parameters)
        
        connection.stateUpdateHandler = { state in
            switch state {
            case .preparing:
                print("🔄 Connection is preparing...")
            case .ready:
                if let endpoint = connection.currentPath?.remoteEndpoint,
                   case .hostPort(let host, let port) = endpoint {
                    // Извлекаем имя хоста из различных типов
                    var hostname: String
                    
                    switch host {
                    case .name(let name, _):
                        hostname = name
                    case .ipv4(let address):
                        hostname = address.debugDescription
                    case .ipv6(let address):
                        hostname = address.debugDescription
                    @unknown default:
                        hostname = "unknown"
                    }
                    
                    // Удаляем zone index, если есть
                    if let percentIndex = hostname.firstIndex(of: "%") {
                        hostname = String(hostname[..<percentIndex])
                    }
                    
                    print("✅ Connection success: \(hostname):\(Int(port.rawValue))")
                    completion(hostname, Int(port.rawValue))
                }
                connection.cancel()
            case .failed(let error):
                print("⚠️ Connection failed: \(error)")
                connection.cancel()
                
                // Если не удалось подключиться, используем NetService в качестве запасного варианта
                self.resolveWithNetService(service, completion: completion)
            case .cancelled:
                print("🛑 Connection cancelled")
            default:
                break
            }
        }
        
        connection.start(queue: .main)
        
        // Устанавливаем таймаут для соединения
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak connection] in
            guard let connection = connection else { return }
            if connection.state != .ready && connection.state != .cancelled {
                print("⏱️ Connection timeout, falling back to NetService")
                connection.cancel()
                self.resolveWithNetService(service, completion: completion)
            }
        }
    }
    
    private func resolveWithNetService(_ service: DiscoveredService, completion: @escaping (String, Int) -> Void) {
        guard case .service(let name, let type, let domain, _) = service.endpoint else {
            return
        }
        
        print("🔄 Resolving with NetService: \(name)")
        
        let netService = NetService(domain: domain, type: type, name: name)
        resolvers[service.id] = netService
        
        class Resolver: NSObject, NetServiceDelegate {
            let completion: (String, Int) -> Void
            var timer: Timer?
            
            init(completion: @escaping (String, Int) -> Void) {
                self.completion = completion
                super.init()
            }
            
            func netServiceDidResolveAddress(_ sender: NetService) {
                timer?.invalidate()
                
                if let hostname = sender.hostName, sender.port > 0 {
                    print("✅ NetService resolved: \(hostname):\(sender.port)")
                    completion(hostname, sender.port)
                } else if let addresses = sender.addresses, !addresses.isEmpty {
                    // Пробуем извлечь IP напрямую из адресов
                    if let ipPort = self.extractIPAndPort(from: addresses) {
                        print("✅ Extracted IP and port: \(ipPort.ip):\(ipPort.port)")
                        completion(ipPort.ip, ipPort.port)
                    }
                }
            }
            
            func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
                timer?.invalidate()
                print("❌ NetService failed to resolve: \(errorDict)")
            }
            
            func startTimer() {
                timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
                    print("⏱️ NetService resolution timeout")
                }
            }
            
            private func extractIPAndPort(from addresses: [Data]) -> (ip: String, port: Int)? {
                for address in addresses {
                    var hostname: String?
                    var port: Int = 0
                    
                    address.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
                        if buffer.count >= MemoryLayout<sockaddr>.size {
                            let sockAddr = buffer.baseAddress!.assumingMemoryBound(to: sockaddr.self)
                            if sockAddr.pointee.sa_family == UInt8(AF_INET) {
                                // IPv4
                                let sockAddrIn = buffer.bindMemory(to: sockaddr_in.self)
                                var addr = sockAddrIn[0].sin_addr
                                var hostBuffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                                inet_ntop(AF_INET, &addr, &hostBuffer, socklen_t(INET_ADDRSTRLEN))
                                hostname = String(cString: hostBuffer)
                                port = Int(UInt16(bigEndian: sockAddrIn[0].sin_port))
                            } else if sockAddr.pointee.sa_family == UInt8(AF_INET6) {
                                // IPv6
                                let sockAddrIn6 = buffer.bindMemory(to: sockaddr_in6.self)
                                var addr = sockAddrIn6[0].sin6_addr
                                var hostBuffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
                                inet_ntop(AF_INET6, &addr, &hostBuffer, socklen_t(INET6_ADDRSTRLEN))
                                hostname = String(cString: hostBuffer)
                                port = Int(UInt16(bigEndian: sockAddrIn6[0].sin6_port))
                            }
                        }
                    }
                    
                    if let hostname = hostname, port > 0 {
                        return (hostname, port)
                    }
                }
                
                return nil
            }
        }
        
        let resolver = Resolver(completion: completion)
        netService.delegate = resolver
        resolver.startTimer()
        
        print("🔄 Starting NetService resolution for \(name)")
        netService.resolve(withTimeout: 10.0)
    }
    
    deinit {
        stopDiscovery()
        cancellables.removeAll()
    }
}
