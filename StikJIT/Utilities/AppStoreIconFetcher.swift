//
//  AppStoreIconFetcher.swift
//  StikJIT
//
//  Created by neoarz on 3/28/25.
//

import UIKit

// Not AppStore
class AppStoreIconFetcher {
    static private var iconCache: [String: UIImage] = [:]
    
    static func getIcon(for bundleID: String, completion: @escaping (UIImage?) -> Void) {
        // Check cache first
        if let cachedIcon = iconCache[bundleID] {
            completion(cachedIcon)
            return
        }
        
        Task {
            do {
                let ans = try JITEnableContext.shared.getAppIcon(withBundleId: bundleID)
                iconCache[bundleID] = ans
                completion(ans)
            } catch {
                print("Failed to get icon: \(error)")
                completion(nil)
            }
        }
    }
} 
