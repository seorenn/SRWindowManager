//
//  OverlayWindow.swift
//  SRWindowManagerDemoApp
//
//  Created by Heeseung Seo on 2015. 11. 25..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Cocoa

class OverlayWindow: NSWindow {
    override init(contentRect: NSRect, styleMask aStyle: Int, backing bufferingType: NSBackingStoreType, `defer` flag: Bool) {
        super.init(contentRect: contentRect, styleMask: aStyle, backing: bufferingType, `defer`: flag)

        self.opaque = false
        self.hasShadow = false
        self.level = Int(CGWindowLevelForKey(.FloatingWindowLevelKey))
        self.alphaValue = 0.5
        
        self.backgroundColor = NSColor.blackColor()
        self.ignoresMouseEvents = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override var canBecomeKeyWindow: Bool { return true }
}
