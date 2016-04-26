//
//  ViewController.swift
//  Jolt
//
//  Created by Manbir Gulati on 3/21/16.
//  Copyright © 2016 JoltApp. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    
    let healthManager: HealthKitManager = HealthKitManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        getHealthKitPermission()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func getHealthKitPermission() {
        
        // Seek authorization in HealthKitManager.swift.
        healthManager.authorizeHealthKit { (authorized,  error) -> Void in
            
        }
    }
    
}

