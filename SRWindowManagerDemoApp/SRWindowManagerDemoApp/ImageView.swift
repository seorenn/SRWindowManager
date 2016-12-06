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
    case mouseEnter, mouseExit, mouseMoved
}

class ImageView: NSImageView {
    
    var clickHandler: ImageViewClickHandler?
    var eventHandler: ImageViewEventHandler?
    
    func makeTrackable() {
        let trackingArea = NSTrackingArea(rect: self.bounds, options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways], owner: self, userInfo: nil)
        self .addTrackingArea(trackingArea)
    }
    
    override func mouseDown(with theEvent: NSEvent) {
        super.mouseDown(with: theEvent)
        guard let handler = self.clickHandler else { return }
        
        if theEvent.clickCount == 1 && theEvent.type == .leftMouseDown {
            let point = self.convert(theEvent.locationInWindow, from: nil)
            handler(point)
        }
    }
    
    override func mouseEntered(with theEvent: NSEvent) {
        NSLog("Mouse Entered")
        guard let handler = self.eventHandler else { return }
        let point = self.convert(theEvent.locationInWindow, from: nil)
        handler(.mouseEnter, point)
    }
    
    override func mouseExited(with theEvent: NSEvent) {
        NSLog("Mouse Exited")
        guard let handler = self.eventHandler else { return }
        let point = self.convert(theEvent.locationInWindow, from: nil)
        handler(.mouseExit, point)
    }
    
    override func mouseMoved(with theEvent: NSEvent) {
        guard let handler = self.eventHandler else { return }
        let point = self.convert(theEvent.locationInWindow, from: nil)
        handler(.mouseMoved, point)
    }
    
}
