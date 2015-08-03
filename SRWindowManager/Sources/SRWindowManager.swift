//
//  SRWindowManager.swift
//  SRWindowManager
//
//  Created by Heeseung Seo on 2015. 7. 30..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

#if os(OSX)
    
import Cocoa

public protocol SRWindowManagerDelegate {
    func windowManager(windowManager: SRWindowManager, detectWindowActivating: SRWindow)
}
    
public class SRWindowManager: CustomDebugStringConvertible, SRWindowManagerImplDelegate {
    public static let sharedInstance = SRWindowManager()
    public var delegate: SRWindowManagerDelegate?
    
    private let impl: SRWindowManagerImpl
    
    public init() {
        self.impl = SRWindowManagerImpl()
        self.impl.delegate = self
    }
    
    public var detecting: Bool {
        return self.impl.detecting
    }
    
    public var processes: [NSRunningApplication]? {
        return NSWorkspace.sharedWorkspace().runningApplications
    }
    
    public var windows: [SRWindow]? {
        let list = self.impl.windows()
        return list.map() { SRWindow(runningApplication: $0 as! NSRunningApplication) }
    }
    
    public var applicationWindows: [SRWindow]? {
        var results = [SRWindow]()
        
        let procs = self.processes!
        for proc in procs {
            if proc.activationPolicy != NSApplicationActivationPolicy.Regular { continue }
            
            let window = SRWindow(runningApplication: proc)
            results.append(window)
        }

        return results
    }
    
    public func startDetectWindowActivating() {
        self.impl.startDetect()
    }
    
    public func stopDetectWindowActivating() {
        self.impl.stopDetect()
    }
    
    public var debugDescription: String {
        return "<SRWindowManager>"
    }
    
    // MARK: - Delegation of Objective-C Implementations
    
    @objc public func windowManagerImpl(windowManagerImpl: SRWindowManagerImpl!, detectWindowActivating runningApplication: NSRunningApplication!) {
        let window = SRWindow(runningApplication: runningApplication)
        if let d = self.delegate {
            d.windowManager(self, detectWindowActivating: window)
        }
    }
}

#endif  // os(OSX)
