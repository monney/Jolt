//
//  InterfaceController.swift
//  Jolt WatchKit Extension
//
//  Created by Manbir Gulati on 3/21/16.
//  Copyright © 2016 JoltApp. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {
    
    @IBOutlet var timeDialPicker: WKInterfacePicker!
    @IBOutlet var timeSelectButton: WKInterfaceButton!
    @IBOutlet var timeLabel: WKInterfaceLabel!
    
    var selectedTime: Int!
    
    @IBAction func timeSelectAction() {
        NSLog("Sequence Picker: \(selectedTime) selected.")
        if (selectedTime != nil) {
            pushControllerWithName("timerRunningInterface", context: selectedTime)
        }
    }
    
    @IBAction func pickerSelectTimeAction(value: Int) {
        selectedTime = value
        timeLabel.setText("\(value) min")
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        let pickerItems: [WKPickerItem] = (0...10).map {
            let pickerItem = WKPickerItem()
            pickerItem.contentImage = WKImage(imageName: "first-\($0).png")
            return pickerItem
        }
        timeDialPicker.setItems(pickerItems)
        
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
