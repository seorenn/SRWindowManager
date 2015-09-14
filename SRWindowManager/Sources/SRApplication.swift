//
//  SRApplication.swift
//  SRWindowManager
//
//  Created by Heeseung Seo on 2015. 9. 11..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Cocoa
import SRWindowManagerPrivates

public class SRApplication: CustomDebugStringConvertible {
    public let runningApplication: NSRunningApplication
    
    private let appElement: AXUIElementRef
    
    public init(runningApplication: NSRunningApplication) {
        self.runningApplication = runningApplication
        self.appElement = AXUIElementCreateApplication(runningApplication.processIdentifier).takeUnretainedValue()
    }
    
    public init(pid: pid_t) {
        self.runningApplication = NSRunningApplication(processIdentifier: pid)!
        self.appElement = AXUIElementCreateApplication(pid).takeUnretainedValue()
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
    
    public var windows: [SRWindow] {
        var result = [SRWindow]()

        guard let windowList = SRWindowCopyApplicationWindows(self.appElement)?.takeUnretainedValue() else { return result }
        
        let count = CFArrayGetCount(windowList)
        for i in 0..<count {
            guard let windowElement = SRWindowCopyWindowElementFromArray(windowList, Int32(i))?.takeUnretainedValue() else { continue }

            let window = SRWindow(pid: self.pid, windowElement: windowElement)
            result.append(window)
        }
        
        return result
    }
    
    public var debugDescription: String {
        return "<SRApplicationWindow: \(self.localizedName)(PID:\(self.pid))>"
    }
}
