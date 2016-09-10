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
    
    @IBOutlet weak var xValue: UILabel!
    @IBOutlet weak var yValue: UILabel!
    
    var xCalib : Double!
    var yCalib : Double!
    
    var manager: CMMotionManager = CMMotionManager()
    var attitude: CMAttitude = CMAttitude()
    var motion: CMDeviceMotion = CMDeviceMotion()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.xCalib = 0.0
        self.yCalib = 0.0
        
        self.ref = FIRDatabase.database().reference()

        manager.deviceMotionUpdateInterval = 0.01
        manager.startDeviceMotionUpdates(to: OperationQueue.main, withHandler:{
            deviceManager, error in
            self.motion = self.manager.deviceMotion!
            self.attitude = self.motion.attitude
            
            //self.attitude.multiply(byInverseOf: self.referenceAttitude!)
            
            self.ref.child("gyro").setValue(["x": String(format: "%.10f", self.attitude.pitch - self.xCalib),
                                             "y": String(format: "%.10f", self.attitude.roll - self.yCalib)])
            self.xValue.text = "x: " + String(format: "%.10f", self.attitude.pitch - self.xCalib)
            self.yValue.text = "y: " + String(format: "%.10f", self.attitude.roll - self.yCalib)
        })

    }
    
    @IBAction func gyroCalibration(_ sender: AnyObject) {
        self.xCalib = self.attitude.pitch
        self.yCalib = self.attitude.roll
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
