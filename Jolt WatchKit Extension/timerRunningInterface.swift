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
    
    var timeLimit = 0
    
    @IBAction func stopTimingButton() {
        popController()
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        // Configure interface objects here.
        let imageString = "first-\(context!).png"
        
        self.timeElapsedGroup.setBackgroundImageNamed(imageString)
        timeLimit = Int(context! as! NSNumber)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        // Animate the blue bar as time elapses.
        timeElapsedImage.setImageNamed("second-")
        timeElapsedImage.startAnimatingWithImagesInRange(NSMakeRange(0, timeLimit + 1), duration: 5 * Double(timeLimit), repeatCount: 1)
        
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
