//
//  ViewController.swift
//  SRWindowManagerDemoApp
//
//  Created by Heeseung Seo on 2015. 7. 30..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Cocoa
import SRWindowManager

class ViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate, NSTableViewDelegate {
    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var openAccessbilityButton: NSButton!
    
    var items = [AppItem]()
    
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
        }
    }
    
    /*
    // This may needed to call tableViewSelectionDidChange
    func tableView(tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return true
    }
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        print("Selection Did Change")
        let column = self.outlineView.selectedColumn
        let app = self.items[column]
        
        let index = self.outlineView.selectedRow
        if index < 0 || index >= app.windows.count { return }
        
        let window = app.windows[index]
        
        print("Selecting Window: \(window)")
    }
    */
}

