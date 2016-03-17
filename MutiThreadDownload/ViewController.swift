//
//  ViewController.swift
//  MutiThreadDownload
//
//  Created by XWJACK on 3/13/16.
//  Copyright © 2016 XWJACK. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, downloadDelegate {
    
    @IBOutlet weak var Thread1: NSLevelIndicator!
    @IBOutlet weak var Thread2: NSLevelIndicator!
    @IBOutlet weak var Thread3: NSLevelIndicator!
    @IBOutlet weak var Thread4: NSLevelIndicator!
    
    @IBOutlet weak var url: NSTextField!
    @IBOutlet weak var progress: NSProgressIndicator!
    @IBOutlet weak var filePath: NSTextField!
    
    @IBOutlet weak var Status: NSButton!
    @IBOutlet weak var Stop: NSButton!
    
    var progressLength:Double = 50.0/* 50 Level */
    var mutidownload:MutiDownload?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        filePath.stringValue = ""
        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    @IBAction func download(sender: NSButton) {
        switch Status.title {
        case "Download":
            let downloadURL = url.stringValue
            guard !downloadURL.isEmpty else { filePath.stringValue = "Please input URL"; return }
            
            mutidownload = MutiDownload(url: downloadURL, delegate: self)
            
            /// Get file name to display at UI
            if let filename = mutidownload!.name {
                filePath.stringValue = filename
            }else { filePath.stringValue = "Unknow" }
            
            mutidownload!.xMutiDownload()
            
            Status.title = "Suspend"
            Stop.enabled = true
        case "Suspend":
            Status.title = "Resume"
            
            mutidownload!.xSuspend()
        case "Resume":
            Status.title = "Suspend"
            
            mutidownload!.xResume()
        default:
            assert(false)
        }
    }
    @IBAction func stop(sender: NSButton) {
        Status.title = "Download"
        Stop.enabled = false
        mutidownload = nil
        
        Thread1.doubleValue = 0
        Thread2.doubleValue = 0
        Thread3.doubleValue = 0
        Thread4.doubleValue = 0
        progress.doubleValue = 0
    }
    
    /**
    refresh UI
    
    - parameter thread:         current thread
    - parameter threadprogress: percent of threadprogress
    */
    func refresh(thread:Int, threadprogress:Double) {
        let progress = threadprogress * self.progressLength
        //print("\(thread):\(progress)")
        switch thread {
        case 1:
            self.Thread1.doubleValue = progress
        case 2:
            self.Thread2.doubleValue = progress
        case 3:
            self.Thread3.doubleValue = progress
        case 4:
            self.Thread4.doubleValue = progress
        default:
            assert(false)
        }
        self.progress.doubleValue = self.Thread1.doubleValue + self.Thread2.doubleValue + self.Thread3.doubleValue + self.Thread4.doubleValue
        /**
        *  Download Complete
        */
        if self.progress.doubleValue >= 200 {
            filePath.stringValue = "File Download Success"
            stop(Stop)
        }
    }
}

