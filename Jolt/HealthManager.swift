//
//  HealthKitManager.swift
//  Jolt
//
//  Created by Sharon You on 4/2/16.
//  Copyright © 2016 JoltApp. All rights reserved.
//
import Foundation
import HealthKit
class HealthKitManager {
    
    let healthKitStore: HKHealthStore = HKHealthStore()
    
    func authorizeHealthKit(completion: ((success: Bool, error: NSError!) -> Void)!) {
        let healthDataToRead = Set([
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
            ])
        
        let healthDataToWrite = Set([HKObjectType.workoutType(),
            ])
        
        /*
         let healthDataToRead = Set(arrayLiteral: HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)!)
         
         let healthDataToWrite = Set(arrayLiteral: HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)!)
         */
        // Just in case OneHourWalker makes its way to an iPad...
        if !HKHealthStore.isHealthDataAvailable() {
            print("Can't access HealthKit.")
        }
        
        // Request authorization to read and/or write the specific data.
        healthKitStore.requestAuthorizationToShareTypes(healthDataToWrite, readTypes: healthDataToRead) { (success, error) -> Void in
            if( completion != nil ) {
                completion(success:success, error:error)
            }
        }
        
    }
}
