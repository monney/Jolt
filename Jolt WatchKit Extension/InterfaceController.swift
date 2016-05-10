//
//  InterfaceController.swift
//  Jolt WatchKit Extension
//  Copyright © 2016 JoltApp. All rights reserved.

import WatchKit
import Foundation
import HealthKit
import CoreMotion


class InterfaceController: WKInterfaceController {
    
    @IBOutlet var timeDialPicker: WKInterfacePicker!
    @IBOutlet var timeSelectButton: WKInterfaceButton!
    
    var selectedTime: Int!
    
    @IBAction func timeSelectAction() {
        NSLog("Sequence Picker: \(selectedTime) selected.")
        contextForSegueWithIdentifier("modalPush")
    }
    
    override func contextForSegueWithIdentifier(segueIdentifier: String) -> AnyObject? {
        return selectedTime
    }
    
    
    @IBAction func pickerSelectTimeAction(value: Int) {
        selectedTime = value
        if (selectedTime != nil) {
            if (selectedTime != 0) {
                timeSelectButton.setEnabled(true)
            }
        }
        if (selectedTime == 0) {
            timeSelectButton.setEnabled(false)
        }
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        let pickerItems: [WKPickerItem] = (0...120).map {
            let pickerItem = WKPickerItem()
            pickerItem.contentImage = WKImage(imageName: "single\($0).png")
            return pickerItem
        }
        timeDialPicker.setItems(pickerItems)
        timeSelectButton.setEnabled(false)
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
