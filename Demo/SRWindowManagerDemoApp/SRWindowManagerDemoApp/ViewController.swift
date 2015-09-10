//
//  ViewController.swift
//  SRWindowManagerDemoApp
//
//  Created by Heeseung Seo on 2015. 7. 30..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Cocoa
import SRWindowManager

class ViewController: NSViewController {
    @IBOutlet weak var textView: NSTextField!
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var accessibilityStatusLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let trigger = SRWindowManager.available ? "Trused" : "None"
        self.accessibilityStatusLabel.stringValue = "Accessibility Access: \(trigger)"

        // Do any additional setup after loading the view.
        SRWindowManager.sharedInstance.startDetectWindowActivating {
            (app) in
            let text = "Current Application Window: \(app)\n"
            
            self.textView.stringValue = text
            
            if let windows = SRWindowManager.sharedInstance.windows(app.pid) {
                for window in windows where window.frame.size.width > 0 && window.frame.size.height > 0 {
                    self.imageView.image = window.screenImage
                    break   // shows first image only
                }
            } else {
                self.imageView.image = nil
            }
        }
    }
    
    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func pressedOpenAccessibility(sender: AnyObject) {
        SRWindowManager.openAccessibilityAccessDialogWindow()
    }
    
}

