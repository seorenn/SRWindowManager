//
//  SRApplicationInfo.swift
//  SRWindowManager
//
//  Created by Heeseung Seo on 2015. 9. 11..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Cocoa

public struct SRApplicationInfo: CustomDebugStringConvertible {
    
    public let runningApplication: NSRunningApplication
    private let appElement: AXUIElement
    
    public init(runningApplication: NSRunningApplication) {
        self.runningApplication = runningApplication
        self.appElement = AXUIElementCreateApplication(runningApplication.processIdentifier)
    }
    
    public init(pid: pid_t) {
        self.runningApplication = NSRunningApplication(processIdentifier: pid)!
        self.appElement = AXUIElementCreateApplication(pid)
    }
    
    public var pid: pid_t {
        return self.runningApplication.processIdentifier
    }
    
    public var localizedName: String {
        return self.runningApplication.localizedName!
    }
    
    public var bundleIdentifier: String {
        return self.runningApplication.bundleIdentifier!
    }
    
    public var icon: NSImage? {
        return self.runningApplication.icon
    }
    
    public var windowInfos: [SRWindowInfo] {
        var result = [SRWindowInfo]()

        var values: CFTypeRef?
        let res = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &values)
        guard res == .success, values != nil, let windowList = values as! CFArray? else { return [] }

        let count = CFArrayGetCount(windowList)
        for i in 0..<count {
            guard let windowElement = SRWindowCopyWindowElementFromArray(windowList, Int32(i))?.takeUnretainedValue() else { continue }
            
            let window = SRWindowInfo(pid: self.pid, windowElement: windowElement)
            if window.windowID != 0 {
                // 0 is always failed to get descriptions
                result.append(window)
            }
        }
        
        return result
    }
    
    public var debugDescription: String {
        return "<SRApplicationInfo: \(self.localizedName)(PID:\(self.pid))>"
    }
}
