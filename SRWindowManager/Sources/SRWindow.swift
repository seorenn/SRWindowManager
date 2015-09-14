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

/* SRWindowSharingState Wraps belows:
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
    public let windowID: CGWindowID
    public let pid: pid_t
//    public let sharingState: SRWindowSharingState
    public var windowElement: AXUIElementRef?
    
    init(pid: pid_t, windowElement: AXUIElementRef) {
        self.pid = pid
        self.windowElement = windowElement
        self.windowID = SRWindowGetID(windowElement)
    }
    
    public var frame: NSRect {
        if let element = self.windowElement {
            return SRWindowGetFrameOfWindowElement(element)
        } else {
            return NSRect.null
        }
    }
    
    public var screenImage: NSImage? {
        return SRWindowCaptureScreen(self.windowID, self.frame)
    }
    
    public var name: String {
        return SRWindowGetWindowName(self.windowID)
    }
    
    public var ownerName: String {
        return SRWindowGetWindowOwnerName(self.windowID)
    }
    
    public var debugDescription: String {
        let frameString = "{ \(self.frame.origin.x), \(self.frame.origin.y) }, { \(self.frame.size.width), \(self.frame.size.height) }"
        return "<SRWindow \"\(self.name)\" ID[\(self.windowID)] PID[\(self.pid)] Frame[\(frameString)]>"
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
    
#endif  // os(OSX)
