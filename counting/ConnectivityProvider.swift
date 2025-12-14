//
//  ConnectivityProvider.swift
//  counting
//
//  Created by MARKLIM on 2025-12-07.
//
//  [Sync Disabled]
//

import Foundation
import Combine
import WatchConnectivity

class ConnectivityProvider: NSObject, ObservableObject {
    static let shared = ConnectivityProvider()
    
    // Sync Result Enum (Maintained for compatibility but unused)
    enum SyncResult {
        case success
        case failure(Error)
    }
    
    // Callbacks (Unused)
    var onReceiveCategories: (([TallyCategory]) -> Void)?
    var onReset: (() -> Void)?
    var dataSource: (() -> [TallyCategory])?
    
    private override init() {
        super.init()
        // WCSession disabled
    }
    
    func send(categories: [TallyCategory], completion: ((SyncResult) -> Void)? = nil) {
        // Disabled
    }
    
    func sendReset() {
        // Disabled
    }
    
    func sendLanguage(_ languageCode: String) {
        // Disabled
    }
}
