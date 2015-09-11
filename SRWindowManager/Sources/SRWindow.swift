//
//  SRWindow.swift
//  SRWindowManager
//
//  Created by Seorenn on 2015. 7. 30..
//  Copyright © 2015 Seorenn. All rights reserved.
//

#if os(OSX)
    
import Cocoa
import SRWindowManagerPrivates

/* Wraps belows:
    enum {
        kCGWindowSharingNone      = 0,
        kCGWindowSharingReadOnly  = 1,
        kCGWindowSharingReadWrite = 2
    };
 */
public enum SRWindowSharingState: Int {
    case None = 0
    case ReadOnly = 1
    case ReadWrite = 2
}

public enum SRMouseButtonType {
    case Left, Right, Center
}
    
public class SRWindow: CustomDebugStringConvertible {
    public let windowID: Int32
    public let frame: NSRect
    public let pid: pid_t
    public let sharingState: SRWindowSharingState
    
    public var applicationWindow: SRApplicationWindow {
        return SRApplicationWindow(pid: self.pid)
    }
    
    public init(infoDictionary: [String: AnyObject]) {
        self.windowID = (infoDictionary["windowid"] as! NSNumber).intValue
        self.frame = NSMakeRect(CGFloat((infoDictionary["bounds.origin.x"] as! NSNumber).floatValue),
                                CGFloat((infoDictionary["bounds.origin.y"] as! NSNumber).floatValue),
                                CGFloat((infoDictionary["bounds.size.width"] as! NSNumber).floatValue),
                                CGFloat((infoDictionary["bounds.size.height"] as! NSNumber).floatValue))
        self.pid = (infoDictionary["pid"] as! NSNumber).intValue
        
        let sharingRawValue = Int((infoDictionary["sharingstate"] as! NSNumber).intValue)
        if let ss = SRWindowSharingState(rawValue: sharingRawValue) {
            self.sharingState = ss
        } else {
            self.sharingState = .None
        }
    }
    
    public var screenImage: NSImage? {
        return SRWindowCaptureScreen(self.windowID, self.frame)
    }
    
    public var debugDescription: String {
        let frameString = "{ \(self.frame.origin.x), \(self.frame.origin.y) }, { \(self.frame.size.width), \(self.frame.size.height) }"
        return "<SRWindow ID[\(self.windowID)] PID[\(self.pid)] Frame[\(frameString)]>"
    }
    
    private func convertButtonType(button: SRMouseButtonType) -> CGMouseButton {
        switch (button) {
        case SRMouseButtonType.Left:
            return CGMouseButton.Left
        case SRMouseButtonType.Right:
            return CGMouseButton.Right
        case SRMouseButtonType.Center:
            return CGMouseButton.Center
        }
    }
    
    private func convertMousePoint(position: CGPoint) -> CGPoint? {
        let point = CGPointMake(self.frame.origin.x + position.x, self.frame.origin.y + position.y)
        if CGRectContainsPoint(self.frame, point) == false { return nil }
        
        return point
    }
    
    public func click(position: CGPoint, button: SRMouseButtonType) {
        let btn = self.convertButtonType(button)
        if let point = self.convertMousePoint(position) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                SRMousePostEvent(btn, .LeftMouseDown, point)
                SRMousePostEvent(btn, .LeftMouseUp, point)
            }
        }
    }

    public func doubleClick(position: CGPoint, button: SRMouseButtonType) {
        let btn = self.convertButtonType(button)
        let point = CGPointMake(self.frame.origin.x + position.x, self.frame.origin.y + position.y)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            SRMousePostEvent(btn, .LeftMouseDown, point)
            SRMousePostEvent(btn, .LeftMouseUp, point)
            SRMousePostEvent(btn, .LeftMouseDown, point)
            SRMousePostEvent(btn, .LeftMouseUp, point)
        }
    }
}
    
public class SRApplicationWindow: CustomDebugStringConvertible {
    public let runningApplication: NSRunningApplication?

    public init(runningApplication: NSRunningApplication) {
        self.runningApplication = runningApplication
    }
    
    public init(pid: pid_t) {
        self.runningApplication = NSRunningApplication(processIdentifier: pid)!
    }
    
    private var numberValue: Int?
    private var pidValue: Int?
    private var boundsValue: NSRect?
    private var nameValue: String?
    
    init(infoDictionary: [String:AnyObject]) {
        self.runningApplication = nil
        
        self.numberValue = infoDictionary["number"] as? Int
        self.pidValue = infoDictionary["pid"] as? Int
        self.boundsValue = NSMakeRect(
            (infoDictionary["bounds.origin.x"] as! CGFloat),
            (infoDictionary["bounds.origin.y"] as! CGFloat),
            (infoDictionary["bounds.size.width"] as! CGFloat),
            (infoDictionary["bounds.size.height"] as! CGFloat))
        self.nameValue = infoDictionary["name"] as? String
    }
    
    public var pid: pid_t {
        if self.pidValue != nil { return pid_t(self.pidValue!) }
        return self.runningApplication!.processIdentifier
    }
    
    public var localizedName: String {
        if self.nameValue != nil { return self.nameValue! }
        return self.runningApplication!.localizedName!
    }
    
    public var bundleIdentifier: String {
        return self.runningApplication!.bundleIdentifier!
    }
    
    public var icon: NSImage? {
        return self.runningApplication?.icon
    }
    
    public var debugDescription: String {
        return "<SRApplicationWindow: \(self.localizedName)(PID:\(self.pid))>"
    }
}
    
#endif  // os(OSX)
