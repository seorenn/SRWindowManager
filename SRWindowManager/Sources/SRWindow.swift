//
//  SRWindow.swift
//  SRWindowManager
//
//  Created by Seorenn on 2015. 7. 30..
//  Copyright © 2015 Seorenn. All rights reserved.
//

#if os(OSX)
    
import Cocoa

    /*
    NSDictionary *info = @{ @"name": name,
    @"bounds.origin.x": [NSNumber numberWithFloat:bounds.origin.x],
    @"bounds.origin.y": [NSNumber numberWithFloat:bounds.origin.y],
    @"bounds.size.width": [NSNumber numberWithFloat:bounds.size.width],
    @"bounds.size.height": [NSNumber numberWithFloat:bounds.size.height],
    @"pid": [NSNumber numberWithInt:pid],
    @"number": [NSNumber numberWithInt:number] };

*/
public class SRWindow {
    let windowID: Int32
    let frame: NSRect
    let pid: pid_t
    
    public init(windowID: Int32, frame: NSRect, pid: pid_t) {
        self.windowID = windowID
        self.frame = frame
        self.pid = pid
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
    
    public init(infoDictionary: [String:AnyObject]) {
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
        return "<SRWindow: \(self.localizedName)(\(self.pid))>"
    }
}
    
#endif  // os(OSX)
