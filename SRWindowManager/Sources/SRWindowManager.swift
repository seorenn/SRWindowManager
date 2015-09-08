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
    func windowManager(windowManager: SRWindowManager, detectWindowActivating: SRApplicationWindow)
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
    
    public var runningApplications: [NSRunningApplication]? {
        return NSWorkspace.sharedWorkspace().runningApplications
    }
    
//    public var windows: [SRWindow]? {
//        let list = self.impl.windows()
//        return list.map() { SRWindow(runningApplication: $0 as! NSRunningApplication) }
//    }
    public var windows: [SRWindow]? {
        let list = SRWindowGetInfoList() as! [[String: AnyObject]]
        return list.map {
            (windowInfo) in
            let windowID = (windowInfo["windowid"] as! NSNumber).intValue
            let frame = NSMakeRect(CGFloat((windowInfo["bounds.origin.x"] as! NSNumber).floatValue),
                CGFloat((windowInfo["bounds.origin.y"] as! NSNumber).floatValue),
                CGFloat((windowInfo["bounds.size.width"] as! NSNumber).floatValue),
                CGFloat((windowInfo["bounds.size.height"] as! NSNumber).floatValue))
            let pid = (windowInfo["pid"] as! NSNumber).intValue
            
            return SRWindow(windowID: windowID, frame: frame, pid: pid)
        }
    }
    
    public var applicationWindows: [SRApplicationWindow]? {
        var results = [SRApplicationWindow]()
        
        if let procs = self.runningApplications {
            for proc in procs {
                if proc.activationPolicy != NSApplicationActivationPolicy.Regular { continue }
            
                let window = SRApplicationWindow(runningApplication: proc)
                results.append(window)
            }
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
        let window = SRApplicationWindow(runningApplication: runningApplication)
        if let d = self.delegate {
            d.windowManager(self, detectWindowActivating: window)
        }
    }
}

#endif  // os(OSX)
