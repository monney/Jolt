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
    @IBOutlet var displayElapsedTimer: WKInterfaceTimer!
    @IBOutlet var timePassedGroup: WKInterfaceGroup!
    
    var timeLimit = 0
    
    let secInMin = 60.0
    
    weak var timer:NSTimer?
    
    @IBAction func stopTimingButton() {
        popController()
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        // Configure interface objects here.
        
        let imageString = "singlenotext\(context!).png"

        self.timeElapsedGroup.setBackgroundImageNamed(imageString)
        timeLimit = Int(context! as! NSNumber)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        // Animate the blue bar as time elapses.
        timePassedGroup.setBackgroundImageNamed("progressnew")
        timePassedGroup.startAnimatingWithImagesInRange(NSMakeRange(0, timeLimit + 1), duration: secInMin * Double(timeLimit), repeatCount: 1)
        
        timer = NSTimer.scheduledTimerWithTimeInterval(Double(timeLimit) * secInMin, target: self, selector: #selector(timerRunningInterface.onTimerFire(_:)), userInfo: nil, repeats: false)
        let date:NSDate = NSDate(timeIntervalSinceNow: secInMin * Double (timeLimit))
        displayElapsedTimer.setDate(date)
        displayElapsedTimer.start()
    }
    
    func onTimerFire(timer : NSTimer) {
        displayElapsedTimer.stop()
        popController()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        WKInterfaceDevice.currentDevice().playHaptic(.Stop)
        super.didDeactivate()
    }

}