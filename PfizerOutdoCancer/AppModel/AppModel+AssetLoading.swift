//
//  AppModel+AssetLoading.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 12/10/24.
//

import SwiftUI
import Darwin
import Foundation

extension Int64 {
    var bytesToMB: String {
        String(format: "%.1f", Double(self) / 1_048_576)
    }
}

private func getMemoryUsage() -> Int64? {
    var taskInfo = task_vm_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
    let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
        }
    }
    return result == KERN_SUCCESS ? Int64(taskInfo.phys_footprint) : nil
}

extension AppModel {
    // MARK: - Asset Loading
    
    var isLoadingAssets: Bool {
        if case .loading = assetLoadingManager.state {
            return true
        }
        return false
    }
    
    var assetsLoaded: Bool {
        if case .completed = assetLoadingManager.state {
            return true
        }
        return false
    }
    
    func startLoading(adcDataModel: ADCDataModel) async throws {
        Logger.debug("\n\n=== 🚀 STARTING ASSET LOAD ===")
        displayedProgress = 0.0
        
        do {
            // Load all assets using AssetLoadingManager
            let template = try await assetLoadingManager.loadAppAssets(adcDataModel: adcDataModel)
            
            // Handle app-specific setup with loaded assets
            gameState.setADCTemplate(template, dataModel: adcDataModel)
            
            // Continue with phase transition
            await transitionToPhase(.intro, adcDataModel: adcDataModel)
            Logger.debug("=== ✅ APP STATE AND GAME SETUP COMPLETE ===\n")
            
        } catch {
            Logger.error("""
            
            ❌ ASSET LOAD FAILED
            └─ Error: \(error.localizedDescription)
            """)
            throw error
        }
    }
}

struct AssetLoadLog {
    let assetName: String
    let category: AssetCategory
    private let loadStart = Date()
    private let initialMemory: Int64?
    
    init(assetName: String, category: AssetCategory) {
        self.assetName = assetName
        self.category = category
        self.initialMemory = getMemoryUsage()
    }
    
    func finalizeLog() -> String {
        let duration = -loadStart.timeIntervalSinceNow
        let memoryDelta = getMemoryUsage().map { $0 - (initialMemory ?? 0) }
        
        return """
        🧩 \(assetName)
        ├─ Category: \(category.rawValue)
        ├─ Duration: \(String(format: "%.2fs", duration))
        └─ Memory: \(memoryDelta?.bytesToMB ?? "N/A") MB
        """
    }
}
