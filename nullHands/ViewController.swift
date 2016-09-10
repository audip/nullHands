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
    
    var manager: CMMotionManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.ref = FIRDatabase.database().reference()
            
        self.ref.child("gyro").setValue(["x": 0,
                                         "y": 0])
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
