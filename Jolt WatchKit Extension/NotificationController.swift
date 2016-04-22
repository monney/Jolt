//
//  NotificationController.swift
//  Jolt WatchKit Extension
//
//  Created by Manbir Gulati on 3/21/16.
//  Copyright © 2016 JoltApp. All rights reserved.
//

import WatchKit
import Foundation


class NotificationController: WKUserNotificationInterfaceController {

    @IBOutlet var wakeUpAnimation: WKInterfaceImage!
    var player: WKAudioFilePlayer!
    
    override init() {
        // Initialize variables here.
        super.init()
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        wakeUpAnimation.setImageNamed("second-")
        wakeUpAnimation.startAnimatingWithImagesInRange(NSMakeRange(0, 11), duration: 0.3, repeatCount: 10)
        if let filePath = NSBundle.mainBundle().pathForResource("alarm", ofType: "mp3") {
            let fileurl = NSURL.fileURLWithPath(filePath)
            let asset = WKAudioFileAsset(URL: fileurl)
            let playeritem = WKAudioFilePlayerItem(asset: asset)
            player = WKAudioFilePlayer(playerItem: playeritem)
            switch player.status {
            case .ReadyToPlay:
                player.play()
            case .Failed:
                NSLog("Alarm status: failed")
            case .Unknown:
                NSLog("Alarm status: unknown")
            }
            NSLog("Inside alarm code!")
            
            WKInterfaceDevice.currentDevice().playHaptic(.Notification)
        }
        
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    
    override func didReceiveLocalNotification(localNotification: UILocalNotification, withCompletion completionHandler: ((WKUserNotificationInterfaceType) -> Void)) {
        // This method is called when a local notification needs to be presented.
        // Implement it if you use a dynamic notification interface.
        // Populate your dynamic notification interface as quickly as possible.
        //
        // After populating your dynamic notification interface call the completion block.
        completionHandler(.Custom)
    }
    
    
    
    override func didReceiveRemoteNotification(remoteNotification: [NSObject : AnyObject], withCompletion completionHandler: ((WKUserNotificationInterfaceType) -> Void)) {
        // This method is called when a remote notification needs to be presented.
        // Implement it if you use a dynamic notification interface.
        // Populate your dynamic notification interface as quickly as possible.
        //
        // After populating your dynamic notification interface call the completion block.
        completionHandler(.Custom)
    }
    
}
