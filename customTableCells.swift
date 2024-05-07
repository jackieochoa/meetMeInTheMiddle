//
//  customTableCells.swift
//  File name: finalProject-meetMeInTheMiddle
//  CS329 Final Project
//  Created by jao3589 on 12/1/23.
//

import Foundation
import UIKit

class profileCell: UITableViewCell {
    //variables and outlets for the profile cell!
    var delegate: tableCellDelegate?
    @IBOutlet weak var profileLabel: UILabel!
    
    @IBAction func editName(_ sender: Any) {
        delegate?.editNameTapped()
    }
}

class mapSettingsCell: UITableViewCell {
    //outlets for the map settings cell!
    @IBOutlet weak var mapSettingsIcon: UIImageView!
    @IBOutlet weak var mapSettingsLabel: UILabel!
    @IBOutlet weak var mapSettingsSwitch: UISwitch!
    
    var switchValueChangedHandler: ((Bool) -> Void)?

    @IBAction func switchToggled(_ sender: UISwitch) {
        //allows user to use the switches!
        switchValueChangedHandler?(sender.isOn)
    }
    
}

class advancedSettingsCell: UITableViewCell {
    //outlets for the advanced settings cell!
    @IBOutlet weak var advancedSettingsIcon: UIImageView!
    @IBOutlet weak var advancedSettingsLabel: UILabel!
}
