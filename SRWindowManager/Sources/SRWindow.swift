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
    public var windowElement: AXUIElementRef?
    
    init(pid: pid_t, windowElement: AXUIElementRef) {
        self.pid = pid
        self.windowElement = windowElement
        self.windowID = SRWindowGetID(windowElement)
    }
    
    init(windowElement: AXUIElementRef) {
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
            guard let element = self.windowElement else { return NSRect.null }
            
            var positionObject: CFTypeRef? = nil
            if AXUIElementCopyAttributeValue(element, kAXPositionAttribute, &positionObject) != .Success {
                return NSRect.null
            }
            
            var sizeObject: CFTypeRef? = nil
            if AXUIElementCopyAttributeValue(element, kAXSizeAttribute, &sizeObject) != .Success {
                return NSRect.null
            }
            
            guard let posPtr = positionObject, let sizePtr = sizeObject else {
                return NSRect.null
            }
            
            var size = CGSize()
            var position = CGPoint()
            AXValueGetValue(posPtr as! AXValue, AXValueType(rawValue: kAXValueCGPointType)!, &position)
            AXValueGetValue(sizePtr as! AXValue, AXValueType(rawValue: kAXValueCGSizeType)!, &size)
            
            return CGRectMake(position.x, position.y, size.width, size.height)
        }
        set {
            guard let element = self.windowElement else { return }
            
            var positionInput = newValue.origin
            var sizeInput = newValue.size
            guard let positionValue = AXValueCreate(AXValueType(rawValue: kAXValueCGPointType)!, &positionInput),
                let sizeValue = AXValueCreate(AXValueType(rawValue: kAXValueCGSizeType)!, &sizeInput)
                else { return }
            
            AXUIElementSetAttributeValue(element, kAXPositionAttribute, positionValue.takeUnretainedValue())
            AXUIElementSetAttributeValue(element, kAXSizeAttribute, sizeValue.takeUnretainedValue())
        }
    }
    
    private var descriptionDictionary: [String: AnyObject]? {
        let input = [self.windowID]
        let inputPtr = UnsafeMutablePointer<UnsafePointer<Void>>(input)
        let inputCFArray = CFArrayCreate(nil, inputPtr, input.count, nil)
        
        guard let cfarray = CGWindowListCreateDescriptionFromArray(inputCFArray)
            where CFArrayGetCount(cfarray) > 0
            else { return nil }
        
        let array = cfarray as NSArray
        guard let descriptionCFDict = array.firstObject else { return nil }
        let dict = descriptionCFDict as! NSDictionary
        return dict as? [String: AnyObject]
    }
    
    private func descriptionItem(key: CFString) -> AnyObject? {
        guard let dict = self.descriptionDictionary else { return nil }
        return dict[key as String]
    }
    
    public var screenImage: NSImage? {
        return SRWindowCaptureScreen(self.windowID, self.frame)
    }
    
    public var name: String {
        return self.descriptionItem(kCGWindowName) as? String ?? ""
    }
    
    public var ownerName: String {
        return self.descriptionItem(kCGWindowOwnerName) as? String ?? ""
    }
    
    public var sharingState: SRWindowSharingState {
        guard let state = self.descriptionItem(kCGWindowSharingState) as? Int else {
            return .None
        }
        
        return SRWindowSharingState(rawValue: state)!
    }
    
    public var debugDescription: String {
        return "<SRWindow \"\(self.name)\" ID[\(self.windowID)] PID[\(self.pid)] Frame[\(self.frame)]>"
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
