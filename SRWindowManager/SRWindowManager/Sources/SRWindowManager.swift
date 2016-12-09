//
//  SRWindowManager.swift
//  SRWindowManager
//
//  Created by Heeseung Seo on 2015. 7. 30..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

#if os(OSX)
  
  import Cocoa
  
  public typealias SRWindowActivatingApplicationHandler = (SRApplicationInfo) -> ()
  
  open class SRWindowManager: CustomDebugStringConvertible {
    open static let shared = SRWindowManager()
    
    open fileprivate(set) var detecting = false
    
    fileprivate let nc = NSWorkspace.shared().notificationCenter
    fileprivate var detectingApplicationHandler: SRWindowActivatingApplicationHandler?
    
    fileprivate lazy var pointer: UnsafeMutableRawPointer = {
      return UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
    }()
    
    open class var available: Bool {
      return AXIsProcessTrustedWithOptions(nil)
    }
    
    open class func requestAccessibility() {
      SRWindowRequestAccessibility()
    }
    
    open class func openAccessibilityAccessDialogWindow() {
      let script = "tell application \"System Preferences\" \n reveal anchor \"Privacy_Accessibility\" of pane id \"com.apple.preference.security\" \n activate \n end tell"
      //let script_for_10_8_or_lower = "tell application \"System Preferences\" \n set the current pane to pane id \"com.apple.preference.universalaccess\" \n activate \n end tell"
      
      if let scriptObject = NSAppleScript(source: script) {
        scriptObject.executeAndReturnError(nil)
      }
    }
    
    // NOTE: Deprecated. Moved to SRWindowInfo
    //fileprivate let systemWideElement = AXUIElementCreateSystemWide().takeUnretainedValue();
    fileprivate let systemWideElement = AXUIElementCreateSystemWide()
    
    // NOTE: Deprecated. Moved to SRWindowInfo
    fileprivate var frontmostWindowElement: AXUIElement? {
      var app: CFTypeRef?
      let res = AXUIElementCopyAttributeValue(self.systemWideElement, kAXFocusedApplicationAttribute as CFString, &app)
      guard res == .success else {
        print("Failed to get focused application attribute: \(res)")
        return nil
      }
      
      var window: CFTypeRef?
      guard AXUIElementCopyAttributeValue(app! as! AXUIElement, NSAccessibilityFocusedWindowAttribute as CFString, &window) == .success else {
        print("Failed to get accessibility focused window attribute")
        return nil
      }
      
      return window as! AXUIElement?
    }
    
    private var activationDetector: SRWindowActivationDetector?
    
    // NOTE: Deprecated. Moved to SRWindowInfo
    open var frontmostWindowInfo: SRWindowInfo? {
      guard let element = self.frontmostWindowElement else { return nil }
      return SRWindowInfo(windowElement: element)
    }
    
    public init() { }
    
    deinit {
      self.stopAll()
    }
    
    open class var applicationInfos: [SRApplicationInfo] {
      return NSWorkspace.shared().runningApplications.map {
        SRApplicationInfo(runningApplication: $0)
      }
    }
    
    fileprivate func startDetector() {
      if self.detecting { return }
      
      self.nc.addObserver(forName: NSNotification.Name.NSWorkspaceDidActivateApplication, object: nil, queue: OperationQueue.main, using: {
        [unowned self] (notification) -> Void in
        
        //print("Workspace Did Activate Application Notification")
        
        guard let userInfo = notification.userInfo as? [String: AnyObject] else {
          print("WARN: There's no user informations.")
          return
        }
        guard let application = userInfo[NSWorkspaceApplicationKey] as? NSRunningApplication else {
          print("WARN: There's no application informations.")
          return
        }
        
        let interval = 0.5
        let t = DispatchTime.now() + .milliseconds(Int(interval * 1000))
        DispatchQueue.main.asyncAfter(deadline: t) {
          self.activationDetector = SRWindowActivationDetector()
          self.activationDetector?.handler = { [unowned self] (element, runningApplication) in
            if let appHandler = self.detectingApplicationHandler {
              appHandler(SRApplicationInfo(runningApplication: runningApplication))
            }
          }
          self.activationDetector?.start(with: application)
        }
        
        if let appHandler = self.detectingApplicationHandler {
          let app = SRApplicationInfo(runningApplication: application)
          appHandler(app)
        }
      })
      
      self.detecting = true
    }
    
    open func startDetectApplicationActivating(_ handler: @escaping SRWindowActivatingApplicationHandler) {
      self.detectingApplicationHandler = handler
      self.startDetector()
    }
    
    open func stopAll() {
      if self.detecting == false { return }
      
      self.detectingApplicationHandler = nil
      self.activationDetector?.stop()
      self.activationDetector = nil
      
      self.nc.removeObserver(self)
      self.detecting = false
    }
    
    open var debugDescription: String {
      let info = self.detecting ? " [DETECTING WINDOW ACTIVATION]" : ""
      return "<SRWindowManager\(info)>"
    }
  }
  
#endif  // os(OSX)
