//
//  SRWindowInfo.swift
//  SRWindowManager
//
//  Created by Seorenn on 2015. 7. 30..
//  Copyright © 2015 Seorenn. All rights reserved.
//

#if os(OSX)
  
  import Cocoa
  
  /* SRWindowSharingState Wraps belows:
   enum {
   kCGWindowSharingNone      = 0,
   kCGWindowSharingReadOnly  = 1,
   kCGWindowSharingReadWrite = 2
   };
   */
  public enum SRWindowInfoSharingState: Int {
    case none = 0
    case readOnly = 1
    case readWrite = 2
  }
  
  public enum SRMouseButtonType {
    case left, right, center
  }
  
  public struct SRWindowInfo: CustomDebugStringConvertible {
    public let windowID: CGWindowID
    public let pid: pid_t
    public let windowElement: AXUIElement
    
    init(pid: pid_t, windowElement: AXUIElement) {
      self.pid = pid
      self.windowElement = windowElement
      self.windowID = SRWindowGetID(windowElement)
    }
    
    init(windowElement: AXUIElement) {
      // NOTE: This initializer not tested yet :-p
      self.windowElement = windowElement
      self.windowID = SRWindowGetID(windowElement)
      
      var pid: pid_t = 0
      
      // NOTE: You can use method 1
      AXUIElementGetPid(windowElement, &pid)
      self.pid = pid
      
      // NOTE: or method 2
      //self.pid = SRWindowGetWindowOwnerPID(self.windowID)
    }
    
    public var frame: NSRect {
      get {
        var positionObject: CFTypeRef? = nil
        if AXUIElementCopyAttributeValue(windowElement, kAXPositionAttribute as CFString, &positionObject) != .success {
          return NSRect.null
        }
        
        var sizeObject: CFTypeRef? = nil
        if AXUIElementCopyAttributeValue(windowElement, kAXSizeAttribute as CFString, &sizeObject) != .success {
          return NSRect.null
        }
        
        guard let posPtr = positionObject, let sizePtr = sizeObject else {
          return NSRect.null
        }
        
        var size = CGSize()
        var position = CGPoint()
        AXValueGetValue(posPtr as! AXValue, AXValueType(rawValue: kAXValueCGPointType)!, &position)
        AXValueGetValue(sizePtr as! AXValue, AXValueType(rawValue: kAXValueCGSizeType)!, &size)
        
        return CGRect(x: position.x, y: position.y, width: size.width, height: size.height)
      }
      set {
        //guard let element = self.windowElement else { return }
        
        var positionInput = newValue.origin
        var sizeInput = newValue.size
        guard let positionValue = AXValueCreate(AXValueType(rawValue: kAXValueCGPointType)!, &positionInput),
          let sizeValue = AXValueCreate(AXValueType(rawValue: kAXValueCGSizeType)!, &sizeInput)
          else { return }
        
        AXUIElementSetAttributeValue(windowElement, kAXPositionAttribute as CFString, positionValue)
        AXUIElementSetAttributeValue(windowElement, kAXSizeAttribute as CFString, sizeValue)
      }
    }
    
    fileprivate var descriptionDictionary: [String: Any]? {
      guard let descriptions = SRWindowGetDescriptions(windowID) else {
        print("ERROR: Failed to create window description for window ID \(windowID)")
        return nil
      }
      
      print("descriptions: \(descriptions)")
      return descriptions.first
    }
    
    fileprivate func descriptionItem(_ key: CFString) -> Any? {
      guard let dict = self.descriptionDictionary else { return nil }
      return dict[key as String]
    }
    
    public var screenImage: NSImage? {
      return SRWindowCaptureScreen(self.windowID, self.frame)
    }
    
    public var name: String {
      print("description dictionary: \(descriptionDictionary)")
      return self.descriptionItem(kCGWindowName) as? String ?? ""
    }
    
    public var ownerName: String {
      return self.descriptionItem(kCGWindowOwnerName) as? String ?? ""
    }
    
    public var sharingState: SRWindowInfoSharingState {
      guard let state = self.descriptionItem(kCGWindowSharingState) as? Int else {
        return .none
      }
      
      return SRWindowInfoSharingState(rawValue: state)!
    }
    
    public var applicationInfo: SRApplicationInfo {
      return SRApplicationInfo(pid: pid)
    }
    
    
    // MARK: - Another Informations
    
    private static var frontmostWindowElement: AXUIElement? {
      var app: CFTypeRef?
      let res = AXUIElementCopyAttributeValue(AXUIElementCreateSystemWide(), kAXFocusedApplicationAttribute as CFString, &app)
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
    
    public static var frontmost: SRWindowInfo? {
      guard let element = SRWindowInfo.frontmostWindowElement else { return nil }
      return SRWindowInfo(windowElement: element)
    }

    public var debugDescription: String {
      return "<SRWindowInfo \"\(self.name)\" ID[\(self.windowID)] PID[\(self.pid)] Frame[\(self.frame)]>"
    }
    
    // MARK: - Some Implementation of Actions for Window
    
    public func activate() {
      guard let app = NSRunningApplication(processIdentifier: self.pid) else {
        print("Cannot get instance for pid \(self.pid)")
        return
      }
      
      app.activate(options: .activateIgnoringOtherApps)
    }
    
    private func convertButtonType(_ button: SRMouseButtonType) -> CGMouseButton {
      switch (button) {
      case SRMouseButtonType.left:
        return CGMouseButton.left
      case SRMouseButtonType.right:
        return CGMouseButton.right
      case SRMouseButtonType.center:
        return CGMouseButton.center
      }
    }
    
    private func convertMousePoint(_ position: CGPoint) -> CGPoint? {
      let point = CGPoint(x: self.frame.origin.x + position.x, y: self.frame.origin.y + position.y)
      if self.frame.contains(point) == false { return nil }
      
      return point
    }
    
    public func click(_ position: CGPoint, button: SRMouseButtonType) {
      let btn = self.convertButtonType(button)
      if let point = self.convertMousePoint(position) {
        DispatchQueue.global().async {
          SRMousePostEvent(btn, .leftMouseDown, point)
          SRMousePostEvent(btn, .leftMouseUp, point)
        }
      }
    }
    
    public func doubleClick(_ position: CGPoint, button: SRMouseButtonType) {
      let btn = self.convertButtonType(button)
      let point = CGPoint(x: self.frame.origin.x + position.x, y: self.frame.origin.y + position.y)
      DispatchQueue.global().async {
        SRMousePostEvent(btn, .leftMouseDown, point)
        SRMousePostEvent(btn, .leftMouseUp, point)
        SRMousePostEvent(btn, .leftMouseDown, point)
        SRMousePostEvent(btn, .leftMouseUp, point)
      }
    }
    
  }
  
#endif  // os(OSX)
