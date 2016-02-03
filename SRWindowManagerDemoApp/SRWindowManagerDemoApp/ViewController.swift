//
//  ViewController.swift
//  SRWindowManagerDemoApp
//
//  Created by Heeseung Seo on 2015. 7. 30..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Cocoa
import SRWindowManager

extension NSPoint {
    var verticalReversedPoint: NSPoint {
        guard let screen = NSScreen.mainScreen() else { return self }
        
        return NSMakePoint(self.x, screen.frame.size.height - self.y)
    }
}

class ViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate, NSTableViewDelegate {
    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var openAccessbilityButton: NSButton!
    @IBOutlet weak var contentScrollView: NSScrollView!
    
    var imageView: ImageView!
    var currentWindow: SRWindow?
    
    var items = [AppItem]()
    var fakeCursor: FakeCursorWindowController!
    
    func refresh(reloadData: Bool = false) {
        self.items = SRWindowManager.applications.map {
            return AppItem(application: $0)
        }
        
        if reloadData {
            self.outlineView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if SRWindowManager.available {
            self.statusLabel.stringValue = "Accessibility Trusted :-)"
            self.openAccessbilityButton.hidden = true
        } else {
            self.statusLabel.stringValue = "This app restricting by accessibility :-("
        }
        
        // Do any additional setup after loading the view.
        
        SRWindowManager.sharedInstance.startDetectApplicationActivating { (app) -> () in
            print("App Activation: \(app)")
            print("App Windows: \(app.windows)")
            guard let window = SRWindowManager.sharedInstance.frontmostWindow else { return }
            print("Frontmost Window: \(window)")
        }
        
        self.refresh()
        
        // -----
        
        self.fakeCursor = FakeCursorWindowController(windowNibName: "FakeCursorWindowController")
        self.fakeCursor.showWindow(nil)
        self.fakeCursor.window!.alphaValue = 0
    }
    
    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func pressedOpenAccessibility(sender: AnyObject) {
        if SRWindowManager.available {
            SRWindowManager.openAccessibilityAccessDialogWindow()
        } else {
            SRWindowManager.requestAccessibility()
        }
    }
    
    func convertPoint(point: NSPoint) -> NSPoint {
        guard let window = self.currentWindow else { return point }
        
        let frame = window.frame
        
        return NSMakePoint(frame.origin.x + point.x, frame.origin.y + point.y)
    }
    
    func setImage(image: NSImage?) {
        guard let image = image else {
            self.contentScrollView.documentView = nil
            return
        }
        
        let rect = CGRectMake(0, 0, image.size.width, image.size.height)
        self.imageView = ImageView(frame: rect)
        self.imageView.makeTrackable()
        self.imageView.image = image
        self.imageView.clickHandler = {
            point in
            self.detectClick(point)
        }
        self.imageView.eventHandler = {
            (event, point) in
            switch (event) {
            case .MouseEnter:
                self.fakeCursor.window!.alphaValue = 0.5
            case .MouseExit:
                self.fakeCursor.window!.alphaValue = 0.0
            case .MouseMoved:
                self.moveFakeCursor(point!)
            }
        }
        
        self.contentScrollView.documentView = imageView
    }
    
    // Convert currentWindow.frame to Cocoa Coordinate System
    var currentWindowCocoaFrame: CGRect {
        var frame = self.currentWindow!.frame
        let point = frame.origin.verticalReversedPoint
        
        frame.origin.y = point.y - frame.size.height
        return frame
    }
    
    func moveFakeCursor(mousePoint: NSPoint) {
        let windowFrame = self.currentWindowCocoaFrame
        let frame = CGRectMake(
            windowFrame.origin.x + mousePoint.x,
            windowFrame.origin.y + mousePoint.y,
            self.fakeCursor.window!.frame.size.width,
            self.fakeCursor.window!.frame.size.height)
        self.fakeCursor.window!.setFrame(frame, display: true)
    }
    
    func detectClick(point: NSPoint) {
        print("Detect Click: \(point)")
        guard let window = self.currentWindow else {
            print("No Window Information. Skip")
            return
        }
        let windowFrame = self.currentWindow!.frame
        let location = NSMakePoint(point.x, windowFrame.size.height - point.y)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            window.activate()
            NSThread.sleepForTimeInterval(0.3)
            window.click(location, button: .Left)
        }
    }
    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        if item is AppItem {
            let app = item as! AppItem
            return app.windows.count > 0
        }
        
        return false
    }
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        if let item = item {
            let app = item as! AppItem
            return app.windows.count
        } else {
            return self.items.count
        }
    }
    
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if let item = item {
            let app = item as! AppItem
            return app.windows[index]
        } else {
            return self.items[index]
        }
    }

    func outlineView(outlineView: NSOutlineView, objectValueForTableColumn tableColumn: NSTableColumn?, byItem item: AnyObject?) -> AnyObject? {
        guard item != nil else { return nil }
        
        if tableColumn?.identifier == "Application" {
            let app = item as? AppItem
            return app?.name
        } else if tableColumn?.identifier == "Window" {
            let window = item as? SRWindow
            return window?.name
        } else {
            return nil
        }
    }
    
    @IBAction func outlineCellSelected(sender: AnyObject) {
        self.currentWindow = nil

        guard let item = self.outlineView.itemAtRow(self.outlineView.selectedRow) else {
            print("No Item Found")
            return
        }
        
        print("Selecting Item = \(item)")
        
        if item is AppItem {
            print("This is AppItem instance. Skip.")
        }
        else if item is SRWindow {
            print("This is SRWindow. Start process...")
            let window = item as! SRWindow
            self.currentWindow = window
            
            self.setImage(window.screenImage)
        }
    }
}

