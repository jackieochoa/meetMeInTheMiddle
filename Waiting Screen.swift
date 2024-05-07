//
//  Waiting Screen.swift
//  File name: finalProject-meetMeInTheMiddle
//  CS329 Final Project
//  Created by jao3589 on 12/1/23.
//

import UIKit
import Foundation

class Waiting_Screen: UIViewController {
    //add a delegate!
    weak var delegate: WaitingScreenDelegate?
    
    //outlets!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var countdownLabel: UILabel!
    
    //variables for waiting screen!!
    let transparentScreen = UIView()
    var timeOfDeparture: String = ""
    var secondsToWait: Int = -1
    var stopWaiting = false
    var queue = DispatchQueue(label: "myQueue", qos: .utility)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Add a transparent blue background!
        transparentScreen.backgroundColor = UIColor(named: "blue_accent")
        transparentScreen.alpha = 0.8
        transparentScreen.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        
        view.addSubview(transparentScreen)
        view.sendSubviewToBack(transparentScreen)
        
        timeLabel.text = ""
        countdownLabel.text = ""
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //give user their time of departure and show timer!
        timeLabel.text = "Your route will start at \(timeOfDeparture)"
        countdownLabel.text = "(\(secondsToWait / 60) minutes and \(secondsToWait % 60) seconds remain)"
        
        //start our timer!
        queue.async {
            self.startTimer()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        //reset wait times!
        timeOfDeparture = ""
        secondsToWait = -1
        stopWaiting = false
    }
    
    func startTimer() {
        //function to handle timer!
        var timer = secondsToWait
        
        while timer > 0 && stopWaiting == false {
            //have a 1 second delay!
            usleep(1000000)
            
            DispatchQueue.main.sync {
                timer -= 1
                    
                //change label on screen!
                self.timeLabel.text = "Your route will start at \(timeOfDeparture)"
                self.countdownLabel.text = "(\(timer / 60) minutes and \(timer % 60) seconds remain)"
            }
        }
        
        DispatchQueue.main.sync{
            self.dismiss(animated: true)
            delegate?.startNavScreen()
        }
    }
    
    @IBAction func stopWaiting(_ sender: Any) {
        //cancel the timer!
        stopWaiting = true
    }
}

