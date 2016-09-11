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
import Speech
import AFNetworking
import CoreLocation

class ViewController: UIViewController, SFSpeechRecognizerDelegate, StreamDelegate, CLLocationManagerDelegate {
    
    var ref: FIRDatabaseReference!
    
    @IBOutlet weak var xValue: UILabel!
    @IBOutlet weak var yValue: UILabel!
    
    @IBOutlet weak var microphoneButton: UIButton!
    
    var xCalib : Double!
    var yCalib : Double!
    
    var manager: CMMotionManager = CMMotionManager()
    var attitude: CMAttitude = CMAttitude()
    var motion: CMDeviceMotion = CMDeviceMotion()
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    
    fileprivate var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    fileprivate var recognitionTask: SFSpeechRecognitionTask?
    fileprivate let audioEngine = AVAudioEngine()
    
    let locationManager = CLLocationManager()
    
    //Socket server
    let addr = "10.103.224.161"
    let port = 25000
    
    //Network variables
    var inStream : InputStream?
    var outStream: OutputStream?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        inStream?.delegate = self
        outStream?.delegate = self
        
        NetworkEnable()
        
        let locManager = CLLocationManager()
        locManager.requestWhenInUseAuthorization()
        
        var currentLocation = CLLocation()
        
        if( CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorized){
            let lat = locManager.location?.coordinate.latitude
            let long = locManager.location?.coordinate.longitude
            
            let s = "loc:lat=\(lat),long=\(long)"
            let encodedDataArray = [UInt8](s.utf8)
            self.outStream?.write(encodedDataArray, maxLength: encodedDataArray.count)
        }
        
        microphoneButton.isEnabled = false
        
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnabled = false
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.microphoneButton.isEnabled = isButtonEnabled
            }
        }
        
        self.xCalib = 0.0
        self.yCalib = 0.0
        
        self.ref = FIRDatabase.database().reference()

        manager.deviceMotionUpdateInterval = 0.10
        manager.startDeviceMotionUpdates(to: OperationQueue.main, withHandler:{
            deviceManager, error in
            self.motion = self.manager.deviceMotion!
            self.attitude = self.motion.attitude
            
            let s = "gyro:x=\(String(format: "%.6f", self.attitude.yaw - self.xCalib)),y=\(String(format: "%.6f", self.attitude.roll - self.yCalib))"
            let encodedDataArray = [UInt8](s.utf8)
            self.outStream?.write(encodedDataArray, maxLength: encodedDataArray.count)
            
            self.xValue.text = "x: " + String(format: "%.3f", self.attitude.yaw - self.xCalib)
            self.yValue.text = "y: " + String(format: "%.3f", self.attitude.roll - self.yCalib)
        })
    }
    
    @IBAction func gyroCalibration(_ sender: AnyObject) {
        self.xCalib = self.attitude.yaw
        self.yCalib = self.attitude.roll
    }
    
    @IBAction func microphoneTapped(_ sender: AnyObject) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            microphoneButton.setImage(UIImage(named: "Record.png"), for: .normal)
        } else {
            startRecording()
            microphoneButton.setImage(UIImage(named: "Stop.png"), for: .normal)
        }
    }
    
    func startRecording() {
        
        if recognitionTask != nil {  //1
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()  //2
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()  //3
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }  //4
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        } //5
        
        recognitionRequest.shouldReportPartialResults = true  //6
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in  //7
            
            var isFinal = false  //8
            
            if result != nil {
                let text = result?.bestTranscription.formattedString
                
                let s = "speech:\(text!)"
                let encodedDataArray = [UInt8](s.utf8)
                self.outStream?.write(encodedDataArray, maxLength: encodedDataArray.count)
                
//                self.ref.child("values").child("speech").setValue(["value": text!])
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {  //10
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.microphoneButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)  //11
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()  //12
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
        }
    }
    
    func NetworkEnable() {
        
        print("NetworkEnable")
        Stream.getStreamsToHost(withName: addr, port: port, inputStream: &inStream, outputStream: &outStream)
        
        inStream?.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        outStream?.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        
        inStream?.open()
        outStream?.open()
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.endEncountered:
            print("EndEncountered")
            inStream?.close()
            inStream?.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
            outStream?.close()
            print("Stop outStream currentRunLoop")
            outStream?.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        case Stream.Event.errorOccurred:
            print("ErrorOccurred")
            
            inStream?.close()
            inStream?.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
            outStream?.close()
            outStream?.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
//        case Stream.Event.hasBytesAvailable:
//            print("HasBytesAvailable")
//            
//            if aStream == inStream {
//                inStream!.read(&buffer, maxLength: buffer.count)
//                let bufferStr = NSString(bytes: &buffer, length: buffer.count, encoding: String.Encoding.utf8.rawValue)
//                label.text = bufferStr! as String
//                print(bufferStr!)
//            }
//            
        case Stream.Event.hasSpaceAvailable:
            print("HasSpaceAvailable")
        case Stream.Event.openCompleted:
            print("OpenCompleted")
        default:
            print("Unknown")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
