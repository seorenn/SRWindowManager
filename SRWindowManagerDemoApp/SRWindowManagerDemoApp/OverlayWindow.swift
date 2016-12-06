//
//  OverlayWindow.swift
//  SRWindowManagerDemoApp
//
//  Created by Heeseung Seo on 2015. 11. 25..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Cocoa

class OverlayWindow: NSWindow {
    override init(contentRect: NSRect, styleMask aStyle: NSWindowStyleMask, backing bufferingType: NSBackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: aStyle, backing: bufferingType, defer: flag)

        self.isOpaque = false
        self.hasShadow = false
        self.level = Int(CGWindowLevelForKey(.floatingWindow))
        self.alphaValue = 0.5
        
        self.backgroundColor = NSColor.black
        self.ignoresMouseEvents = true
    }
    
    override var canBecomeKey: Bool { return true }
}
