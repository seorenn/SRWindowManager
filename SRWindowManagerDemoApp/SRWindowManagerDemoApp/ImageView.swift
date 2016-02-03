//
//  ImageView.swift
//  SRWindowManagerDemoApp
//
//  Created by Heeseung Seo on 2015. 11. 23..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Cocoa

typealias ImageViewClickHandler = (NSPoint) -> ()
typealias ImageViewEventHandler = (ImageViewEvent, NSPoint?) -> ()

enum ImageViewEvent {
    case MouseEnter, MouseExit, MouseMoved
}

class ImageView: NSImageView {
    
    var clickHandler: ImageViewClickHandler?
    var eventHandler: ImageViewEventHandler?
    
    func makeTrackable() {
        let trackingArea = NSTrackingArea(rect: self.bounds, options: [.MouseEnteredAndExited, .MouseMoved, .ActiveAlways], owner: self, userInfo: nil)
        self .addTrackingArea(trackingArea)
    }
    
    override func mouseDown(theEvent: NSEvent) {
        super.mouseDown(theEvent)
        guard let handler = self.clickHandler else { return }
        
        if theEvent.clickCount == 1 && theEvent.type == .LeftMouseDown {
            let point = self.convertPoint(theEvent.locationInWindow, fromView: nil)
            handler(point)
        }
    }
    
    override func mouseEntered(theEvent: NSEvent) {
        NSLog("Mouse Entered")
        guard let handler = self.eventHandler else { return }
        let point = self.convertPoint(theEvent.locationInWindow, fromView: nil)
        handler(.MouseEnter, point)
    }
    
    override func mouseExited(theEvent: NSEvent) {
        NSLog("Mouse Exited")
        guard let handler = self.eventHandler else { return }
        let point = self.convertPoint(theEvent.locationInWindow, fromView: nil)
        handler(.MouseExit, point)
    }
    
    override func mouseMoved(theEvent: NSEvent) {
        guard let handler = self.eventHandler else { return }
        let point = self.convertPoint(theEvent.locationInWindow, fromView: nil)
        handler(.MouseMoved, point)
    }
    
}
