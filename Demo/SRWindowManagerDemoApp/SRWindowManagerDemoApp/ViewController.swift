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
            (window) in
            let text = "Current Application Window: \(window)\n"
            
            self.textView.stringValue = text

            let rect = window.frame
            if rect.size.width > 0 && rect.size.height > 0 {
                self.imageView.image = window.screenImage
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

