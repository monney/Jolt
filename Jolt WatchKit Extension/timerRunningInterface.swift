//
//  timerRunningInterface.swift
//  Jolt
//
//  Created by Neamah Hussein on 4/2/16.
//  Copyright © 2016 JoltApp. All rights reserved.
//

import WatchKit
import Foundation


class timerRunningInterface: WKInterfaceController {

    @IBOutlet var timeElapsedGroup: WKInterfaceGroup!
    @IBOutlet var timeElapsedImage: WKInterfaceImage!
    
    @IBAction func stopTimingButton() {
        popController()
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        // Configure interface objects here.
        let imageString = "first-\(context!).png"
        
        self.timeElapsedGroup.setBackgroundImageNamed(imageString)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
