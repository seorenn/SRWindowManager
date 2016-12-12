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
    guard let screen = NSScreen.main() else { return self }
    
    return NSMakePoint(self.x, screen.frame.size.height - self.y)
  }
}

class ViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate, NSTableViewDelegate {
  @IBOutlet weak var outlineView: NSOutlineView!
  @IBOutlet weak var statusLabel: NSTextField!
  @IBOutlet weak var openAccessbilityButton: NSButton!
  @IBOutlet weak var contentScrollView: NSScrollView!
  
  var imageView: ImageView!
  var currentWindow: SRWindowInfo?
  
  var items = [AppItem]()
  var fakeCursor: FakeCursorWindowController!
  
  func refresh(_ reloadData: Bool = false) {
    self.items = SRWindowManager.applicationInfos.map {
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
      self.openAccessbilityButton.isHidden = true
    } else {
      self.statusLabel.stringValue = "This app restricting by accessibility :-("
    }
    
    // Do any additional setup after loading the view.
    
    SRWindowManager.shared.startDetectApplicationActivating { (app) -> () in
      print("App Activation: \(app)")
      print("App Windows: \(app.windowInfos)")
      guard let window = SRWindowInfo.frontmost else { return }
      print("Frontmost Window: \(window)")
    }
    
    self.refresh()
    
    // -----
    
    self.fakeCursor = FakeCursorWindowController(windowNibName: "FakeCursorWindowController")
    self.fakeCursor.showWindow(nil)
    self.fakeCursor.window!.alphaValue = 0
  }
  
  @IBAction func pressedOpenAccessibility(_ sender: AnyObject) {
    if SRWindowManager.available {
      SRWindowManager.openAccessibilityAccessDialogWindow()
    } else {
      SRWindowManager.requestAccessibility()
    }
  }
  
  func convertPoint(_ point: NSPoint) -> NSPoint {
    guard let window = self.currentWindow else { return point }
    
    let frame = window.frame
    
    return NSMakePoint(frame.origin.x + point.x, frame.origin.y + point.y)
  }
  
  func setImage(_ image: NSImage?) {
    guard let image = image else {
      self.contentScrollView.documentView = nil
      return
    }
    
    let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
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
      case .mouseEnter:
        self.fakeCursor.window!.alphaValue = 0.5
      case .mouseExit:
        self.fakeCursor.window!.alphaValue = 0.0
      case .mouseMoved:
        self.moveFakeCursor(point!)
      }
    }
    
    self.contentScrollView.documentView = imageView
  }
  
  // Convert currentWindow.frame to Cocoa Coordinate System
  var currentWindowCocoaFrame: CGRect {
    guard let currentWindow = self.currentWindow else { return CGRect.null }
    
    var frame = currentWindow.frame
    let point = frame.origin.verticalReversedPoint
    
    frame.origin.y = point.y - frame.size.height
    return frame
  }
  
  func moveFakeCursor(_ mousePoint: NSPoint) {
    let windowFrame = self.currentWindowCocoaFrame
    
    guard windowFrame.isNull == false else { return }
    
    let frame = CGRect(
      x: windowFrame.origin.x + mousePoint.x,
      y: windowFrame.origin.y + mousePoint.y,
      width: self.fakeCursor.window!.frame.size.width,
      height: self.fakeCursor.window!.frame.size.height)
    self.fakeCursor.window!.setFrame(frame, display: true)
  }
  
  func detectClick(_ point: NSPoint) {
    print("Detect Click: \(point)")
    guard let window = self.currentWindow else {
      print("No Window Information. Skip")
      return
    }
    let windowFrame = self.currentWindow!.frame
    let location = NSMakePoint(point.x, windowFrame.size.height - point.y)
    
    DispatchQueue.global().async {
      window.activate()
      Thread.sleep(forTimeInterval: 0.3)
      window.click(location, button: .left)
    }
  }
  
  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
    if item is AppItem {
      let app = item as! AppItem
      return app.windows.count > 0
    }
    
    return false
  }
  
  func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
    if let app = item as? AppItem {
      return app.windows.count
    } else {
      return items.count
    }
  }
  
  func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
    if let app = item as? AppItem {
      return app.windows[index]
    } else {
      return items[index]
    }
  }
  
  func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
    guard item != nil else { return nil }
    
    if tableColumn?.identifier == "Application", let app = item as? AppItem {
      return app.name
    } else if tableColumn?.identifier == "Window", let window = item as? SRWindowInfo {
      return window.name
    } else {
      return nil
    }
  }
  
  @IBAction func outlineCellSelected(_ sender: AnyObject) {
    self.currentWindow = nil
    
    guard let item = self.outlineView.item(atRow: self.outlineView.selectedRow) else {
      print("No Item Found")
      return
    }
    
    print("Selecting Item = \(item)")
    
    if item is AppItem {
      print("This is AppItem instance. Skip.")
    }
    else if item is SRWindowInfo {
      print("This is SRWindow. Start process...")
      let window = item as! SRWindowInfo
      self.currentWindow = window
      
      self.setImage(window.screenImage)
    }
  }
}

