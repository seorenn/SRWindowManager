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
  
  public class SRWindowManager: CustomDebugStringConvertible {
    public static let shared = SRWindowManager()
    
    open private(set) var detecting = false
    
    private var nc: NotificationCenter {
      return NSWorkspace.shared().notificationCenter
    }

    private var detectingApplicationHandler: SRWindowActivatingApplicationHandler?
    
    private lazy var pointer: UnsafeMutableRawPointer = {
      return UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
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
    
    private var activationDetector: SRWindowActivationDetector?
    
    public init() { }
    
    deinit {
      self.stopDetectApplicationActivating()
    }
    
    public class var applicationInfos: [SRApplicationInfo] {
      return NSWorkspace.shared().runningApplications.map {
        SRApplicationInfo(runningApplication: $0)
      }
    }
    
    private func startDetector() {
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
    
    public func startDetectApplicationActivating(_ handler: @escaping SRWindowActivatingApplicationHandler) {
      self.detectingApplicationHandler = handler
      self.startDetector()
    }
    
    public func stopDetectApplicationActivating() {
      if self.detecting == false { return }
      
      self.detectingApplicationHandler = nil
      self.activationDetector?.stop()
      self.activationDetector = nil
      
      self.nc.removeObserver(self)
      self.detecting = false
    }
    
    public var debugDescription: String {
      let info = self.detecting ? " [DETECTING WINDOW ACTIVATION]" : ""
      return "<SRWindowManager\(info)>"
    }
  }
  
#endif  // os(OSX)
