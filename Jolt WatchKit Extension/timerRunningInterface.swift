//
//  timerRunningInterface.swift
//  Jolt WatchKit Extension
//  Copyright © 2016 JoltApp. All rights reserved.

import WatchKit
import Foundation
import HealthKit
import CoreMotion


class timerRunningInterface: WKInterfaceController, HKWorkoutSessionDelegate {
    
    @IBOutlet var timeElapsedGroup: WKInterfaceGroup!
    @IBOutlet var displayElapsedTimer: WKInterfaceTimer!
    @IBOutlet var timePassedGroup: WKInterfaceGroup!
    
    var timeLimit = 0
    @IBOutlet var timerStopButton: WKInterfaceButton!
    let secInMin = 60.0
    weak var timer: NSTimer?
    var timerHasFired = false
    
    // HK
    let healthStore = HKHealthStore()
    let notificationCenter = NSNotificationCenter()
    var heartRateArray = [Double](count: 120, repeatedValue: 0.0)
    var heartRateSum = 0.0
    var heartRateSampleNo = 12
    var heartRateAvgNo = 10
    var heartRateAvgArray = [Double](count: 10, repeatedValue: 0.0)
    var heartRateDiffArray = [Double](count: 9, repeatedValue: 0.0)
    var heartCounter = 0
    var heartAvgCounter = 0
    let heartBufferSize = 120
    
    // variables for accelerometer
    var motionArray = [Double](count: 9000, repeatedValue: 0.0)
    var motionCounter = 0
    let motionBufferSize = 9000
    let motionManager = CMMotionManager()
    let pi = M_PI
    
    var motionDiffArray = [Double](count:8999, repeatedValue: 0.0)
    var aSum = 0.0
    var motionMean = 0.0
    var motionVar = 0.0
    var motiontval = 0.0
    var motionpval = 0.0
    var count = 0
    
    // conjunction variables
    var hrAnomaly = false
    var motionAnomaly = false
    var hrAnomalyCount = 0
    var motionAnomalyCount = 0
    var MOTIONANOMALYTHRESHOLD = 9000
    var HRANOMALYTHRESHOLD = 60
    
    var index10 = 0 // index into average array. Never exceeds 9
    var index12 = 0 // when this hits 12, compute average
    var tempSum = 0.0
    var hrMean = 0.0
    var hrVariance = 0.0
    var hrtval = 0.0
    var hrpval = 0.0
    var backuphrval = 0.0 // save this away before overwriting a val in circ buffer
    
    
    //State of the app - is the workout activated
    var workoutActive = false
    
    // define the activity type and location
    var workoutSession: HKWorkoutSession?
    let heartRateUnit = HKUnit(fromString: "count/min")
    var anchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
    
    
    @IBAction func stopTimingButton() {
        print("button pressed")
        if (self.workoutActive) {
            //finish the current workout
            self.workoutActive = false
            if let workout = self.workoutSession {
                healthStore.endWorkoutSession(workout)
                dismissController()
            }
        } else {
            //start a new workout
            self.workoutActive = true
            timerStopButton.setTitle("Stop Tracking")
            startWorkout()
            
            // Animate the blue bar as time elapses.
            timePassedGroup.setBackgroundImageNamed("progressnew")
            timePassedGroup.startAnimatingWithImagesInRange(NSMakeRange(0, timeLimit + 1), duration: secInMin * Double(timeLimit), repeatCount: 1)
            
            timer = NSTimer.scheduledTimerWithTimeInterval(Double(timeLimit) * secInMin, target: self, selector: #selector(timerRunningInterface.onTimerFire(_:)), userInfo: nil, repeats: false)
            let date: NSDate = NSDate(timeIntervalSinceNow: secInMin * Double(timeLimit))
            displayElapsedTimer.setDate(date)
            displayElapsedTimer.start()
            
            // ACCELEROMETER CODE
            if motionManager.accelerometerAvailable {
                var x = 0.0
                var y = 0.0
                var z = 0.0
                
                let handler: CMAccelerometerHandler = {
                    (data: CMAccelerometerData?, error: NSError?) -> Void in
                    x = data!.acceleration.x
                    y = data!.acceleration.y
                    z = data!.acceleration.z
                    
                    // calculate angle
                    let angle = atan((z) / sqrt((x * x) + (y * y))) * 180.0 / self.pi
                    
                    /****************** ACCEL ALGORITHM ******************/
                    
                    // first observation
                    if (self.motionCounter == 0) {
                        self.motionArray[self.motionCounter % self.motionBufferSize] = Double(angle)
                        self.motionCounter = self.motionCounter + 1
                    }
                        
                        // 2nd-9000th observations (3 minutes)
                    else {
                        // circular buffer of accel data
                        self.motionArray[self.motionCounter % self.motionBufferSize] = Double(angle)
                        self.motionCounter = self.motionCounter + 1
                        
                        // store the difference
                        self.motionDiffArray[(self.motionCounter - 2) % 8999] = self.motionArray[(self.motionCounter - 1) % self.motionBufferSize] - self.motionArray[(self.motionCounter - 2) % self.motionBufferSize]
                        
                        if (self.motionCounter >= 9000 && self.motionCounter % 250 == 0) {
                            
                            // calculate mean and variance
                            self.aSum = self.motionDiffArray.reduce(0, combine: +)
                            self.motionMean = self.aSum/9000.0
                            self.motionVar = 0.0
                            
                            for i in 0 ... 8998 {
                                self.motionVar = self.motionVar + (self.motionDiffArray[i] - self.motionMean) * (self.motionDiffArray[i] - self.motionMean)
                            }
                            self.motionVar = (self.motionVar / 9000.0)
                            //plug in the intercept and the coeffs to derive t
                            self.motiontval = 10.78 + (13.947 * self.motionMean) + (-48.131 * self.motionVar)
                            
                            // compute predicted probability
                            self.motionpval = (1.0 / (1.0 + exp(-1.0 * self.motiontval)))
                            
                            // uncomment this line to read sleep probabilities related to accelerometer data as they are computed
                            //print("Accelerometer Probability: " + String(self.motionpval))
                        }
                        
                    }
                    
                    if (self.motionCounter > 9000) {
                        
                        if (self.motionpval >= 0.50) {
                            self.motionAnomaly = true
                            self.motionAnomalyCount = 0
                        } else {
                            self.motionAnomaly = false
                        }
                        // check for conjunction of both anomalies
                        if (self.motionAnomalyCount > self.MOTIONANOMALYTHRESHOLD) {
                            self.motionAnomaly = false
                        }
                        
                        self.motionAnomalyCount += 1
                        
                        // trigger haptic if both anomalies are true
                        if (self.motionAnomaly == true && self.hrAnomaly == true && self.count < 10) {
                            WKInterfaceDevice.currentDevice().playHaptic(.Notification)
                            self.count+=1
                        }
                    }
                    
                }
                
                motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler: handler)
            } else {
                _ = 0
            }
            /*************************************/

        }
        
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        NSLog("awakeWithContext")
        // Configure interface objects here.
        self.setTitle("<")
        
        let imageString = "singlenotext\(context!).png"
        
        self.timeElapsedGroup.setBackgroundImageNamed(imageString)
        timeLimit = Int(context! as! NSNumber)
        
        motionManager.accelerometerUpdateInterval = 0.02
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        NSLog("willActivate")
        
        if (timerHasFired) {
            WKInterfaceDevice.currentDevice().playHaptic(.Notification)
            dismissController()
        }
        
        guard HKHealthStore.isHealthDataAvailable() == true else {
            NSLog("HK data not available")
            return
        }
    }
    
    func displayNotAllowed() {
        NSLog("not allowed")
    }
    
    func workoutSession(workoutSession: HKWorkoutSession, didChangeToState toState: HKWorkoutSessionState, fromState: HKWorkoutSessionState, date: NSDate) {
        NSLog("workoutSession1")
        switch toState {
        case .Running:
            workoutDidStart(date)
        case .Ended:
            workoutDidEnd(date)
        default:
            NSLog("Unexpected state \(toState)")
        }
    }
    
    func workoutSession(workoutSession: HKWorkoutSession, didFailWithError error: NSError) {
        NSLog("workoutSession2")
        // Do nothing for now
        NSLog("Workout error: \(error.userInfo)")
    }
    
    func workoutDidStart(date: NSDate) {
        NSLog("workoutDidStart")
        if let query = createHeartRateStreamingQuery(date) {
            healthStore.executeQuery(query)
        } else {
            NSLog("cannot start")
        }
    }
    
    func workoutDidEnd(date: NSDate) {
        NSLog("workoutDidEnd")
        if let query = createHeartRateStreamingQuery(date) {
            healthStore.stopQuery(query)
            NSLog("---")
        } else {
            NSLog("cannot stop")
        }
    }
    
    func startWorkout() {
        NSLog("startWorkout")
        self.workoutSession = HKWorkoutSession(activityType: HKWorkoutActivityType.CrossTraining, locationType: HKWorkoutSessionLocationType.Indoor)
        self.workoutSession?.delegate = self
        healthStore.startWorkoutSession(self.workoutSession!)
    }
    
    func createHeartRateStreamingQuery(workoutStartDate: NSDate) -> HKQuery? {
        NSLog("createHeartRateStreamingQuery")
        
        guard let sampleType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate) else {
            fatalError("Unable to create a heart rate sample type")
        }
        
        let query = HKAnchoredObjectQuery(type: sampleType,
                                          predicate: nil,
                                          anchor: self.anchor,
                                          limit: Int(HKObjectQueryNoLimit)) {
                                            [unowned self](query, newSamples, deletedSamples, newAnchor, error) -> Void in
                                            
                                            guard let samples = newSamples as? [HKQuantitySample] else {
                                                NSLog("*** Unable to query for heart rate: \(error?.localizedDescription) ***")
                                                abort()
                                            }
                                            
                                            self.anchor = newAnchor!
                                            
                                            self.updateHeartRate(samples)
                                            
                                            NSLog("Done!")
        }
        
        query.updateHandler = {
            (query, samples, deleteObjects, newAnchor, error) -> Void in
            self.anchor = newAnchor!
            self.updateHeartRate(samples)
        }
        return query
    }
    
    func updateHeartRate(samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else {
            return
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            
            
            guard let sample = heartRateSamples.first else{
                return
            }
            let value = sample.quantity.doubleValueForUnit(self.heartRateUnit)
            
            /****************** HEARTRATE ALGORITHM ******************/
                        if (self.heartCounter < 120) {
                            // circular buffer of heartrate data
                            self.heartRateArray[self.heartCounter % self.heartBufferSize] = Double(value)
            
                            if (self.index12 < 12) {
                                self.tempSum = self.tempSum + value
                                self.index12 = self.index12 + 1
                            } else {
                                self.heartRateAvgArray[self.index10] = self.tempSum / Double(self.heartRateSampleNo)
                                self.tempSum = 0.0
                                self.index10 = self.index10 + 1
                                self.index12 = 0
                            }
            
                            if (self.index10 == 10) {
                                // reset index10
                                self.index10 = 0
            
                                for i in 1 ... 9 {
                                    self.heartRateDiffArray[i - 1] = self.heartRateAvgArray[i] - self.heartRateAvgArray[i - 1]
                                }
                            }
            
                            // compute mean and variance of the 9 differences
                            self.tempSum = 0.0
                            self.tempSum = self.heartRateDiffArray.reduce(0, combine: +)
                            self.hrMean = (self.tempSum / 9.0)
            
                            for i in 0 ... 8 {
                                self.hrVariance = self.hrVariance + (self.heartRateDiffArray[i] - self.hrMean) * (self.heartRateDiffArray[i] - self.hrMean)
                            }
                            self.hrVariance = (self.hrVariance / 9.0)
            
                            // plug in the intercept and the coeffs to derive t
                            self.hrtval = -35.432 + (-186.129 * self.hrMean) + (-645.955 * self.hrVariance)
            
                            // compute predicted probability
                            self.hrpval = (1.0 / (1.0 + exp(-1.0 * self.hrtval)))
            
                            if (self.hrpval >= 0.50) {
                                self.hrAnomaly = true
                            } else {
                                self.hrAnomaly = false
                            }
                        }
                        else {
                            // update with each successive sample after 120
            
                            // store val before overwriting in circ buffer
                            self.backuphrval = self.heartRateArray[self.heartCounter % self.heartBufferSize]
            
                            // this overwrites one value in the circ buffer
                            self.heartRateArray[self.heartCounter % self.heartBufferSize] = Double(value)
            
                            // update the averages
                            for i in 0 ... 9 {
                                // this average uses the sentinel value
                                if (i == ((self.heartCounter % self.heartBufferSize) / self.heartRateSampleNo)) {
            
                                    
                                    self.heartRateAvgArray[i] = (((self.heartRateAvgArray[i] * 12)
                                        - self.backuphrval)
                                        + self.heartRateArray[((self.heartCounter % self.heartBufferSize) + 12 * (i + 1)) % self.heartBufferSize]) /
                                        Double(self.heartRateSampleNo)
                                }
                                else {
                                    // these averages do not use the sentinel value
                                    
                                    self.heartRateAvgArray[i] = (((self.heartRateAvgArray[i] * 12) -
                                        self.heartRateArray[((self.heartCounter % self.heartBufferSize) + 12 * i) % self.heartBufferSize])
                                        + self.heartRateArray[((self.heartCounter % self.heartBufferSize) + 12 * (i+1)) % self.heartBufferSize]) / Double(self.heartRateSampleNo)
                                }
                            }
            
                            for i in 1 ... 9 {
                                self.heartRateDiffArray[i - 1] = self.heartRateAvgArray[i] - self.heartRateAvgArray[i - 1]
                            }
            
            
           //  compute mean and variance of the 9 differences
            
                            self.tempSum = 0.0
                            self.tempSum = self.heartRateDiffArray.reduce(0, combine: +)
                            self.hrMean = (self.tempSum / 9.0)
            
                            for i in 0 ... 8 {
                                self.hrVariance = self.hrVariance + (self.heartRateDiffArray[i] - self.hrMean) * (self.heartRateDiffArray[i] - self.hrMean)
                            }
                            self.hrVariance = (self.hrVariance / 8.0)
            
                            // plug in the intercept and the coeffs to derive t
                            self.hrtval = -6.218 + (0.572 * self.hrMean) + (0.619 * self.hrVariance)
            
                            // compute predicted probability
                            self.hrpval = (1.0 / (1.0 + exp(-1.0 * self.hrtval)))
                            
                            if (self.hrAnomalyCount > self.HRANOMALYTHRESHOLD) {
                                self.hrAnomaly = false
                            }
                            self.hrAnomalyCount += 1
                            
                            // uncomment this line to read heartrate probabilities related to accelerometer data as they are computed
                            // print("Heartrate probability " + String(self.hrpval))
                            
                        }
            
            self.heartCounter += 1
            
            // trigger haptic if both anomalies are true
            if (self.motionAnomaly == true && self.hrAnomaly == true && self.count < 10) {
               WKInterfaceDevice.currentDevice().playHaptic(.Notification)
                self.count+=1
            }
            
        }
    }
    /*************************************/
    
    func onTimerFire(timer: NSTimer) {
        NSLog("onTimerFire")
        displayElapsedTimer.stop()
        timerStopButton.setTitle("Start Tracking")
        timerHasFired = true
        dismissController()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        NSLog("didDeactivate")
    }
    @IBAction func notificationTriggerButton() {
        contextForSegueWithIdentifier("dynNotificationSegue")
    }
    
    override func contextForSegueWithIdentifier(segueIdentifier: String) -> AnyObject? {
        return self
    }
    
}