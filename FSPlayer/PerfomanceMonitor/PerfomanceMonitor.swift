//
//  PerfomanceMonitor.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 26.04.2025.
//

import Foundation
import UIKit

@MainActor
final class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()

    @Published var fps: Int = 0
    @Published var memory: Double = 0 // MB
    @Published var cpu: Double = 0     // %

    private var displayLink: CADisplayLink?
    private var lastTimestamp: TimeInterval = 0
    private var frameCount: Int = 0

    private init() {}

    func start() {
        displayLink?.invalidate()

        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func update(link: CADisplayLink) {
        guard lastTimestamp > 0 else {
            lastTimestamp = link.timestamp
            return
        }

        frameCount += 1
        let delta = link.timestamp - lastTimestamp
        if delta >= 1 {
            fps = frameCount
            frameCount = 0
            lastTimestamp = link.timestamp

            memory = currentMemoryUsage()
            cpu = currentCPUUsage()
        }
    }

    private func currentMemoryUsage() -> Double {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let usedBytes = info.phys_footprint
            return Double(usedBytes) / 1024.0 / 1024.0
        } else {
            return 0
        }
    }

    private func currentCPUUsage() -> Double {
        var kr: kern_return_t
        var taskInfoCount = mach_msg_type_number_t(TASK_INFO_MAX)
        var tinfo = [integer_t](repeating: 0, count: Int(taskInfoCount))

        kr = task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), &tinfo, &taskInfoCount)
        if kr != KERN_SUCCESS {
            return 0
        }

        var threadList: thread_act_array_t?
        var threadCount = mach_msg_type_number_t(0)

        defer {
            if let threadList = threadList {
                vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threadList), vm_size_t(threadCount) * vm_size_t(MemoryLayout<thread_t>.size))
            }
        }

        kr = task_threads(mach_task_self_, &threadList, &threadCount)
        if kr != KERN_SUCCESS {
            return 0
        }

        guard let threadList else { return 0 }

        var totalUsageOfCPU = 0.0

        for i in 0..<Int(threadCount) {
            var threadInfo = thread_basic_info()
            var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
            kr = withUnsafeMutablePointer(to: &threadInfo) {
                $0.withMemoryRebound(to: integer_t.self, capacity: Int(threadInfoCount)) {
                    thread_info(threadList[i], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                }
            }

            if kr != KERN_SUCCESS {
                continue
            }

            if threadInfo.flags & TH_FLAGS_IDLE == 0 {
                totalUsageOfCPU += Double(threadInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
            }
        }

        return totalUsageOfCPU
    }
}
