//
//  AppItem.swift
//  SRWindowManagerDemoApp
//
//  Created by Heeseung Seo on 2015. 9. 14..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Cocoa
import SRWindowManager

class AppItem: NSObject {
    let name: String
    let windows: [SRWindow]
    
    init(application: SRApplication) {
        self.name = application.localizedName
        self.windows = application.windows
        super.init()
        
        print("Application: \(self.name) Windows: \(self.windows)")
    }
}
