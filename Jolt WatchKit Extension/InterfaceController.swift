////
////  InterfaceController.swift
////  Jolt WatchKit Extension
////
////  Created by Manbir Gulati on 3/21/16.
////  Copyright © 2016 JoltApp. All rights reserved.
////
//
//import WatchKit
//import HealthKit
//import Foundation
//
//
//class InterfaceController: WKInterfaceController {
//    
//    let healthKitStore: HKHealthStore = HKHealthStore()
//    //let workoutSession: HKWorkoutSession = HKWorkoutSession(activityType: .Other, locationType: .Indoor)
//    
//
//    override func awakeWithContext(context: AnyObject?) {
//        super.awakeWithContext(context)
//        
//        // Configure interface objects here.
//    }
//
//    override func willActivate() {
//        // This method is called when watch view controller is about to be visible to user
//        super.willActivate()
//        
//        let typesToShare = Set([
//            HKObjectType.workoutType(),
//        ])
//        
//        let typesToRead = Set([
//            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
//        ])
//    
//        self.healthKitStore.requestAuthorizationToShareTypes(typesToShare, readTypes: typesToRead) {(success, error) -> Void in
//        
//        // let session = HKWorkoutSession(activityType: .Running, locationType: .Indoor)
//        // session.delegate = self
//        // self.healthKitStore.startWorkoutSession(self.workoutSession)
//        
//        }
//    }
//    
//    
//    override func contextForSegueWithIdentifier(segueIdentifier: String) -> AnyObject? {
//        let activityType: HKWorkoutActivityType
//        
//        activityType = .Other
//        /*
//        switch segueIdentifier {
//        default:
//            activityType = .Other
//        }
//        */
//        
//        return WorkoutSessionContext(healthKitStore: self.healthKitStore, activityType: activityType)
//        //self.workoutSession = HKWorkoutSession(activityType: .Other)
//        //self.workoutSession!.delegate = self;
//    }
//
//    override func didDeactivate() {
//        // This method is called when watch view controller is no longer visible
//        super.didDeactivate()
//    }
//    
//
//}

//
//  InterfaceController.swift
//  VimoHeartRate WatchKit App Extension
//
//  Created by Ethan Fan on 6/25/15.
//  Copyright © 2015 Vimo Lab. All rights reserved.
//

import Foundation
import HealthKit
import WatchKit
import CoreMotion


class InterfaceController: WKInterfaceController, HKWorkoutSessionDelegate {
    
    @IBOutlet private weak var label: WKInterfaceLabel!
    @IBOutlet private weak var deviceLabel : WKInterfaceLabel!
    @IBOutlet private weak var heart: WKInterfaceImage!
    @IBOutlet private weak var startStopButton : WKInterfaceButton!
    
    let healthStore = HKHealthStore()
    var heartRateArray: [UInt16] = []
    var heartCounter = 0
    let heartBufferSize = 180
    
    // variables for accelerometer
    @IBOutlet weak var labelX: WKInterfaceLabel!
    @IBOutlet weak var labelY: WKInterfaceLabel!
    @IBOutlet weak var labelZ: WKInterfaceLabel!
    var motionArray: [UInt16] = []
    var motionCounter = 0
    let motionBufferSize = 45000
    let motionManager = CMMotionManager()
    let pi = M_PI
    
    
    //State of the app - is the workout activated
    var workoutActive = false
    
    // define the activity type and location
    var workoutSession : HKWorkoutSession?
    let heartRateUnit = HKUnit(fromString: "count/min")
    var anchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
    
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        motionManager.accelerometerUpdateInterval = 0.1
    }
    
    override func willActivate() {
        super.willActivate()
        
        // ACCELEROMETER CODE
        if motionManager.accelerometerAvailable {
            var x = 0.0
            var y = 0.0
            var z = 0.0
            let handler:CMAccelerometerHandler = {(data: CMAccelerometerData?, error: NSError?) -> Void in
                x = data!.acceleration.x
                y = data!.acceleration.y
                z = data!.acceleration.z
                
                self.labelX.setText(String(format: "%.2f", data!.acceleration.x))
                self.labelY.setText(String(format: "%.2f", data!.acceleration.y))
                self.labelZ.setText(String(format: "%.2f", data!.acceleration.z))
            }
            
            // calculate angle
            let angle = atan((z)/sqrt((x*x) + (y*y))) * 180/pi
            
            // circular buffer of motion data
            self.motionArray[self.motionCounter % self.motionBufferSize] = UInt16(angle)
            self.motionCounter = self.motionCounter + 1
            
            motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler: handler)
        }
        else {
            labelX.setText("not available")
            labelY.setText("not available")
            labelZ.setText("not available")
        }
        /*************************************/
        
        guard HKHealthStore.isHealthDataAvailable() == true else {
            label.setText("not available")
            return
        }
        
        guard let quantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate) else {
            displayNotAllowed()
            return
        }
        
        let dataTypes = Set(arrayLiteral: quantityType)
        healthStore.requestAuthorizationToShareTypes(nil, readTypes: dataTypes) { (success, error) -> Void in
            if success == false {
                self.displayNotAllowed()
            }
        }
    }
    
    // NEW FUNCTION
    override func didDeactivate() {
        super.didDeactivate()
        motionManager.stopAccelerometerUpdates()
    }
    /*************************************/
    
    func displayNotAllowed() {
        label.setText("not allowed")
    }
    
    func workoutSession(workoutSession: HKWorkoutSession, didChangeToState toState: HKWorkoutSessionState, fromState: HKWorkoutSessionState, date: NSDate) {
        switch toState {
        case .Running:
            workoutDidStart(date)
        case .Ended:
            workoutDidEnd(date)
        default:
            print("Unexpected state \(toState)")
        }
    }
    
    func workoutSession(workoutSession: HKWorkoutSession, didFailWithError error: NSError) {
        // Do nothing for now
        NSLog("Workout error: \(error.userInfo)")
    }
    
    func workoutDidStart(date : NSDate) {
        if let query = createHeartRateStreamingQuery(date) {
            healthStore.executeQuery(query)
        } else {
            label.setText("cannot start")
        }
    }
    
    func workoutDidEnd(date : NSDate) {
        if let query = createHeartRateStreamingQuery(date) {
            healthStore.stopQuery(query)
            label.setText("---")
        } else {
            label.setText("cannot stop")
        }
    }
    
    // MARK: - Actions
    @IBAction func startBtnTapped() {
        if (self.workoutActive) {
            //finish the current workout
            self.workoutActive = false
            self.startStopButton.setTitle("Start")
            if let workout = self.workoutSession {
                healthStore.endWorkoutSession(workout)
            }
        } else {
            //start a new workout
            self.workoutActive = true
            self.startStopButton.setTitle("Stop")
            startWorkout()
        }
        
    }
    
    func startWorkout() {
        self.workoutSession = HKWorkoutSession(activityType: HKWorkoutActivityType.CrossTraining, locationType: HKWorkoutSessionLocationType.Indoor)
        self.workoutSession?.delegate = self
        healthStore.startWorkoutSession(self.workoutSession!)
    }
    
    func createHeartRateStreamingQuery(workoutStartDate: NSDate) -> HKQuery? {
        // adding predicate will not work
        // let predicate = HKQuery.predicateForSamplesWithStartDate(workoutStartDate, endDate: nil, options: HKQueryOptions.None)
        
        guard let quantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate) else { return nil }
        
        let heartRateQuery = HKAnchoredObjectQuery(type: quantityType, predicate: nil, anchor: anchor, limit: Int(HKObjectQueryNoLimit)) { (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
            guard let newAnchor = newAnchor else {return}
            self.anchor = newAnchor
            self.updateHeartRate(sampleObjects)
        }
        
        heartRateQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            self.anchor = newAnchor!
            self.updateHeartRate(samples)
        }
        return heartRateQuery
    }
    
    func updateHeartRate(samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else {return}
        
        
        
        dispatch_async(dispatch_get_main_queue()) {
            guard let sample = heartRateSamples.first else{return}
            let value = sample.quantity.doubleValueForUnit(self.heartRateUnit)
            self.label.setText(String(UInt16(value)))
            
            // retrieve source from sample
            let name = sample.sourceRevision.source.name
            self.updateDeviceName(name)
            self.animateHeart()
            
            // circular buffer of heartrate data
            self.heartRateArray[self.heartCounter % self.heartBufferSize] = UInt16(value)
            self.heartCounter = self.heartCounter + 1
            
            
        }
    }
    
    func updateDeviceName(deviceName: String) {
        deviceLabel.setText(deviceName)
    }
    
    func animateHeart() {
        self.animateWithDuration(0.5) {
            self.heart.setWidth(60)
            self.heart.setHeight(90)
        }
        
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * double_t(NSEC_PER_SEC)))
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        dispatch_after(when, queue) {
            dispatch_async(dispatch_get_main_queue(), {
                self.animateWithDuration(0.5, animations: {
                    self.heart.setWidth(50)
                    self.heart.setHeight(80)
                })
            })
        }
    }
}
