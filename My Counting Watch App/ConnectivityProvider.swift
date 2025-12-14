//
//  ConnectivityProvider.swift
//  My Counting Watch App
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
    
    // Callbacks (Unused)
    var onReceiveCategories: (([TallyCategory]) -> Void)?
    var onReset: (() -> Void)?
    var dataSource: (() -> [TallyCategory])?
    
    private override init() {
        super.init()
        // WCSession disabled
    }
    
    func requestData(onError: @escaping () -> Void, onSuccess: @escaping () -> Void) -> Bool {
        // Disabled
        return false
    }
    
    func send(categories: [TallyCategory]) {
        // Disabled
    }
}
