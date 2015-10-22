//
//  SRWindowManager.swift
//  SRWindowManager
//
//  Created by Heeseung Seo on 2015. 7. 30..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

#if os(OSX)
    
import Cocoa
import SRWindowManagerPrivates

public typealias SRWindowActivatingApplicationHandler = (SRApplication) -> ()
public typealias SRWindowActivatingWindowHandler = (SRWindow) -> ()

public class SRWindowManager: CustomDebugStringConvertible {
    public static let sharedInstance = SRWindowManager()
    
    public private(set) var detecting = false
    
    private let nc = NSWorkspace.sharedWorkspace().notificationCenter
    private var detectingWindowHandler: SRWindowActivatingWindowHandler?
    private var detectingApplicationHandler: SRWindowActivatingApplicationHandler?
    
    private lazy var pointer: UnsafeMutablePointer<Void> = {
        return UnsafeMutablePointer<Void>(Unmanaged.passUnretained(self).toOpaque())
        }()

    public class var available: Bool {
        return AXIsProcessTrustedWithOptions(nil)
    }
    
    public class func requestAccessibility() {
        SRWindowRequestAccessibility()
    }
    
    public class func openAccessibilityAccessDialogWindow() {
        let script = "tell application \"System Preferences\" \n reveal anchor \"Privacy_Accessibility\" of pane id \"com.apple.preference.security\" \n activate \n end tell"
        //let script_for_10_8_or_lower = "tell application \"System Preferences\" \n set the current pane to pane id \"com.apple.preference.universalaccess\" \n activate \n end tell"
        
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(nil)
        }
    }
    
    private let systemWideElement = AXUIElementCreateSystemWide().takeUnretainedValue();
    
    private var frontmostWindowElement: AXUIElementRef? {
        var app: CFTypeRef?
        let res = AXUIElementCopyAttributeValue(self.systemWideElement, kAXFocusedApplicationAttribute, &app)
        guard res == .Success else {
            print("Failed to get focused application attribute: \(res)")
            return nil
        }
        
        var window: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app! as! AXUIElementRef, NSAccessibilityFocusedWindowAttribute, &window) == .Success else {
            print("Failed to get accessibility focused window attribute")
            return nil
        }
        
        return window as! AXUIElementRef?
    }
    
    public init() { }
    
    deinit {
        self.stopAll()
    }
    
    public class var applications: [SRApplication] {
        return NSWorkspace.sharedWorkspace().runningApplications.map {
            SRApplication(runningApplication: $0)
        }
    }
    
    private func startDetector() {
        if self.detecting { return }
        
        self.nc.addObserverForName(NSWorkspaceDidActivateApplicationNotification, object: nil, queue: NSOperationQueue.mainQueue(), usingBlock: {
            (notification) -> Void in
            
            print("Workspace Did Activate Application Notification")
            
            guard let userInfo = notification.userInfo as? [String: AnyObject] else {
                print("There's no user informations.")
                return
            }
            guard let application = userInfo[NSWorkspaceApplicationKey] as? NSRunningApplication else {
                print("There's no application informations.")
                return
            }
            
            if let appHandler = self.detectingApplicationHandler {
                let app = SRApplication(runningApplication: application)
                appHandler(app)
            }
            
            if let windowHandler = self.detectingWindowHandler {
                //guard let element = SRWindowGetFrontmostWindowElement()?.takeUnretainedValue() else {
                guard let element = self.frontmostWindowElement else {
                    print("Failed to get frontmost window")
//                    
//                    if let _ = self.frontmostWindowElement {
//                        print("I've tried another way, and it succeeded")
//                    }
                    return
                }
                let window = SRWindow(pid: application.processIdentifier, windowElement: element)
                windowHandler(window)
            }
        })
            
        self.detecting = true
    }
    
    public func startDetectWindowActivating(handler: SRWindowActivatingWindowHandler) {
        self.detectingWindowHandler = handler
        self.startDetector()
    }
    
    public func startDetectApplicationActivating(handler: SRWindowActivatingApplicationHandler) {
        self.detectingApplicationHandler = handler
        self.startDetector()
    }
    
    public func stopAll() {
        if self.detecting == false { return }
        
        self.detectingWindowHandler = nil
        self.detectingApplicationHandler = nil
        
        self.nc.removeObserver(self)
        self.detecting = false
    }
    
    public var debugDescription: String {
        let info = self.detecting ? " [DETECTING WINDOW ACTIVATION]" : ""
        return "<SRWindowManager\(info)>"
    }
}

#endif  // os(OSX)
