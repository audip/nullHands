//
//  ViewController.swift
//  nullHands
//
//  Created by Wilson Ding on 9/10/16.
//  Copyright © 2016 Wilson Ding. All rights reserved.
//

import UIKit
import Firebase
import CoreMotion

class ViewController: UIViewController {
    
    var ref: FIRDatabaseReference!
    
    var manager: CMMotionManager = CMMotionManager()
    var attitude: CMAttitude = CMAttitude()
    var motion: CMDeviceMotion = CMDeviceMotion()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.ref = FIRDatabase.database().reference()

        manager.deviceMotionUpdateInterval = 0.01
        manager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler:{
            deviceManager, error in
            self.motion = self.manager.deviceMotion!
            self.attitude = self.motion.attitude
            self.ref.child("gyro").setValue(["x": self.attitude.yaw,
                                             "y": self.attitude.pitch,
                                             "z": self.attitude.roll])
        })
        
        print(manager.isDeviceMotionActive)
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
