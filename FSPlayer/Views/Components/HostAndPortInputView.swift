//
//  HostAndPortInputView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 18.04.2025.
//

import SwiftUI

import SwiftUI

@available(macOS 12.0, iOS 15.0, *)
struct HostAndPortInputView: View {
    @Binding private var combinedHost: String

    @State private var host: String
    @State private var port: String

    init(host: Binding<String>) {
        self._combinedHost = host

        // Разбираем host:port при инициализации
        let components = host.wrappedValue.split(separator: ":", maxSplits: 1).map(String.init)
        if components.count == 2 {
            _host = State(initialValue: components[0])
            _port = State(initialValue: components[1])
        } else {
            _host = State(initialValue: host.wrappedValue)
            _port = State(initialValue: "8000")
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            TextField("Введите IP или имя хоста", text: $host)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.asciiCapable)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .onChange(of: host) {
                    let filtered = host.filter {
                        $0.isASCII && (
                            ("a"..."z" ~= $0 || "A"..."Z" ~= $0 || "0"..."9" ~= $0 || $0 == "." || $0 == "-")
                        )
                    }
                    if filtered != host {
                        host = filtered
                    }
                    updateCombined()
                }

            TextField("Введите порт", text: $port)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .onChange(of: port) {
                    let filtered = port.filter { $0.isNumber }
                    if filtered != port {
                        port = filtered
                    }
                    updateCombined()
                }
        }
    }

    private func updateCombined() {
        guard !host.isEmpty, !port.isEmpty else {
            combinedHost = host // или "", если нужно очищать
            return
        }
        combinedHost = "\(host):\(port)"
    }
}
