////
////  WorkoutManager.swift
////  Jolt
////
////  Created by Aneesh Rai and Sharon You on 4/2/16.
////  Copyright © 2016 JoltApp. All rights reserved.
////
//
//import Foundation
//import HealthKit
//
//class WorkoutSessionContext {
//    
//    
//    let healthKitStore: HKHealthStore
//    var activityType: HKWorkoutActivityType
//    var locationType: HKWorkoutSessionLocationType
//    
//    
//    init(healthKitStore: HKHealthStore, activityType: HKWorkoutActivityType = .Other, locationType: HKWorkoutSessionLocationType = .Unknown) {
//        self.healthKitStore = healthKitStore
//        self.activityType = activityType
//        self.locationType = locationType
//    }
//}
//
//protocol WorkoutSessionManagerDelegate: class {
//    
//    func workoutSessionManager(workoutSessionManager: WorkoutSessionManager, didStartWorkoutWithDate startDate: NSDate)
//    
//    func workoutSessionManager(workoutSessionManager: WorkoutSessionManager, didStopWorkoutWithDate startDate: NSDate)
//    
//    func workoutSessionManager(workoutSessionManager: WorkoutSessionManager, didUpdateHeartRateSample: HKQuantitySample)
//}
//
//class WorkoutSessionManager: NSObject, HKWorkoutSessionDelegate {
//    
//    let healthKitStore: HKHealthStore
//    let workoutSession: HKWorkoutSession
//    
//    var workoutStartDate: NSDate?
//    var workoutEndDate: NSDate?
//    
//    let distanceUnit = HKUnit.meterUnit()
//    
//    var currentActiveEnergyQuantity: HKQuantity
//    var currentHeartRateSample: HKQuantitySample?
//    
//    var queries: [HKQuery] = []
//    
//    weak var delegate: WorkoutSessionManagerDelegate?
//    
//    init(context: WorkoutSessionContext){
//        self.healthKitStore = context.healthKitStore
//        self.workoutSession = HKWorkoutSession(activityType: context.activityType, locationType: context.locationType);
//        self.currentActiveEnergyQuantity = HKQuantity(unit: self.distanceUnit, doubleValue: 0.0)
//    
//        super.init()
//        
//        self.workoutSession.delegate = self
//    }
//    
//    func startWorkout() {
//        self.healthKitStore.startWorkoutSession(self.workoutSession)
//    }
//    
//    func stopWorkoutAndSave() {
//        self.healthKitStore.endWorkoutSession(self.workoutSession)
//        
//    }
//    
//    func workoutSession(workoutSession: HKWorkoutSession, didChangeToState toState: HKWorkoutSessionState, date: NSDate) {
//        dispatch_async(dispatch_get_main_queue()) {
//            switch toState {
//            case .Running:
//                self.workoutDidStart(date)
//            case .Ended:
//                self.workoutDidEnd(date)
//            default:
//                print("Unexpected workout session state \(toState)")
//            }
//        }
//    }
//    
//    func workoutSession(workoutSession: HKWorkoutSession, didFailWithError error: NSError) {
//        // Do nothing for now
//        NSLog("Workout error: \(error.userInfo)")
//    }
//    
//    func workoutDidStart(date: NSDate) {
//        
//        self.workoutStartDate = date
//        
//        queries.append(self.createStreamingHeartRateQuery(date))
//        
//        for query in queries {
//            self.healthKitStore.executeQuery(query)
//        }
//        
//        self.delegate?.workoutSessionManager(self, didStartWorkoutWithDate: date)
//        
//
//    }
//    
//    func workoutDidEnd(date : NSDate) {
//        self.workoutEndDate = date
//        for query in queries {
//            self.healthKitStore.stopQuery(query)
//        }
//        
//        self.queries.removeAll()
//        self.delegate?.workoutSessionManager(self, didStopWorkoutWithDate: date)
//        
//        self.saveWorkout()
//    }
//    
//    func saveWorkout() {
//        
//        guard let startDate = self.workoutStartDate, endDate = self.workoutEndDate else {return}
//        
//        let workout = HKWorkout(activityType: self.workoutSession.activityType,
//                                startDate: startDate,
//                                endDate: endDate,
//                                duration: endDate.timeIntervalSinceDate(startDate),
//                                metaData: nil)
//        var allSamples: [HKQuantitySample] = []
//        allSamples += self.heartRateSamples
//        
//        self.healthKitStore.saveObject(workout) {success, error in
//            
//            if success && allSamples.count > 0 {
//                self.healthKitStore.addSamples(allSamples, toWorkout: workout, completion: {success, error in})
//            }
//        }
//        
//        
//        
//                                
//        
//        
//    }
//    
//    func createStreamingHeartRateQuery(workoutStartDate: NSDate) -> HKQuery {
//        //let predicate = self.predicateForWorkoutSamples(workoutStartDate)
//        
//        let sampleHandler { (samples: [HKQuantitySample]) -> Void in
//            var mostRecentSample = self.currentHeartRateSample
//            var mostRecentStartDate = mostRecentSample?.startDate ?? NSDate.distantPast()
//            
//            for sample in samples {
//                if mostReceptStartDate.compare(sample.startDate) == .OrderedAscending {
//                    mostRecentSample = sample
//                    mostRecentStartDate = sample.startDate
//                }
//            }
//            
//            self.currentHeartRateSample = mostRecentSample
//            
//            if let sample = mostRecentSample {
//                self.delegate?.workoutSessionManager(self, didUpdateHeartRateSample: sample)
//            }
//        }
//        
//        let heartRateQuery = HKAnchoredObjectQuery(type: self.heartRateType, predicate: predicate, anchor: 0, limit: 0) {query, samples, deletedObjects, anchor, error in
//            if let quantitySamples = samples as? [HKQuantitySample] {
//                sampleHandler(quantitySamples)
//            }
//        }
//        
//        heartRateQuery.updateHandler = {query, samples, deletedObjects, anchor, error in
//            if let quantitySamples = samples as? [HKQuantitySample] {
//                sampleHandler(quantitySamples)
//            }
//        }
//        
//        return heartRateQuery
//    }
//}
//
//
