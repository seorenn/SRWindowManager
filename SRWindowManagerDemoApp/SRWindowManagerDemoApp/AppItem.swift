//
//  AppItem.swift
//  SRWindowManagerDemoApp
//
//  Created by Heeseung Seo on 2015. 9. 14..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Cocoa
import SRWindowManager

struct AppItem {
    let name: String
    let windows: [SRWindowInfo]
    
    init(application: SRApplicationInfo) {
        self.name = application.localizedName ?? "(No Name)"
        self.windows = application.windowInfos
        
        print("Application: \(self.name) Windows: \(self.windows)")
    }
}
