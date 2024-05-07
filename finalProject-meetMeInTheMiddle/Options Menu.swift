//
//  Options Menu.swift
//  File name: finalProject-meetMeInTheMiddle
//  CS329 Final Project
//  Created by jao3589 on 12/1/23.
//

import UIKit
import FirebaseAuth
import AVFoundation

protocol tableCellDelegate: AnyObject {
    func editNameTapped()
}

class Options_Menu: UIViewController, UITableViewDelegate, UITableViewDataSource, tableCellDelegate {
    //outlets and variables!
    @IBOutlet weak var optionsTable: UITableView!

    //arrays for our table!
    var mapSettingsToggles: [Bool] = [true, true, false, true]
    let mapSettingsIcons = [UIImage(systemName: "safari.fill"),
                            UIImage(systemName: "exclamationmark.bubble.circle.fill"),
                            UIImage(systemName: "moon.circle.fill"),
                            UIImage(systemName: "line.horizontal.2.decrease.circle.fill")]
    let mapSettingsLabels = ["Toggle Compass",
                             "Show Waiting Screen",
                             "Dark Mode", 
                             "Show scale bar"]
    let mapSettingsColors = [UIColor(named: "icon_green"),
                             UIColor(named: "icon_pink"),
                             UIColor(named: "icon_orange"),
                             UIColor(named: "icon_purple")]
    let advancedSettingsIcons = [UIImage(systemName: "map.circle.fill"),
                                 UIImage(systemName: "lock.circle.fill"),
                                 UIImage(systemName: "arrow.right.circle.fill"),
                                 UIImage(systemName: "minus.circle.fill") ]
    let advancedSettingsLabels = ["Change Map Appearance",
                                  "Change password",
                                  "Log out",
                                  "Delete Account"]
    let advancedSettingsColors = [UIColor(named: "icon_green"),
                                  UIColor(named: "icon_pink"),
                                  UIColor(named: "icon_orange"),
                                  UIColor.red]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        optionsTable.dataSource = self
        optionsTable.delegate = self
        
        //change screen appearance
        navigationController?.navigationBar.tintColor = UIColor(named: "black_to_white")
        
        //register custom table cells!
        optionsTable.register(UINib(nibName: "ProfileSettingsCell", bundle: nil), forCellReuseIdentifier: "profileCell")
        optionsTable.register(UINib(nibName: "MapSettingsCell", bundle: nil), forCellReuseIdentifier: "mapSettingsCell")
        optionsTable.register(UINib(nibName: "AdvancedSettingsCell", bundle: nil), forCellReuseIdentifier: "advancedSettingsCell")
        
        //gather user preferences!
        let userId = Auth.auth().currentUser?.uid
        let collection = firestore_storage.collection("users")
        let userCollection = collection.document(userId!)
        userCollection.getDocument { (document, error) in
            if let document = document, document.exists {
                //Change our switches
                self.mapSettingsToggles = [(document["compass_on"] as! Bool),
                                           (document["showScreen_on"] as! Bool),
                                           (document["dark_Mode"] as! Bool),
                                           (document["scale_on"] as! Bool)]
                self.optionsTable.reloadData()
            } else {
                // Document does not exist or there was an error
                print("Error: \(error?.localizedDescription ?? "error unknown")")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //enable navigation bar!
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //disable navigation bar!
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // Return the number of sections!
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in each section!
        switch section{
        case 0:
            return 1
        case 1:
            return 4
        default:
            return 4
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Return the title for each section!
        switch section {
        case 0:
            return "Profile settings"
        case 1:
            return "Map Settings"
        case 2:
            return "Advanced Settings"
        default:
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        //Disable user interaction for 2nd section!
        return indexPath.section == 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //locate user preferences!
        let user = Auth.auth().currentUser
        let user_id = user!.uid
        let userReference = firestore_storage.collection("users").document(user_id)
        
        switch indexPath.section {
        case 0:
            //PROFILE SECTION!
            let cell = tableView.dequeueReusableCell(withIdentifier: "testCell", for: indexPath) as! profileCell
            cell.delegate = self
            
            userReference.getDocument { (document, error) in
                if let document = document, document.exists {
                    // Access the user data and update the label
                    let userData = document.data()
                    if let firstName = userData?["first_Name"] as? String,
                        let lastName = userData?["last_Name"] as? String {
                        // Update your label here
                        cell.profileLabel.text = "Hi \(firstName) \(lastName)!"
                        }
                } else {
                    print("Document does not exist")
                }
            }

            return cell
        case 1:
            //MAP SETTINGS SECTION!
            let cell = tableView.dequeueReusableCell(withIdentifier: "mapSettings", for: indexPath) as! mapSettingsCell
            
            //fill the cell with map settings labels & icons!
            cell.mapSettingsLabel.text = mapSettingsLabels[indexPath.row]
            cell.mapSettingsIcon.image = mapSettingsIcons[indexPath.row]
            cell.mapSettingsIcon.tintColor = mapSettingsColors[indexPath.row]
            cell.mapSettingsSwitch.setOn(mapSettingsToggles[indexPath.row], animated: false)
            
            //Add actions for switch!
            cell.switchValueChangedHandler = { isOn in
                switch indexPath.row{
                case 0:
                    //compass is toggled
                    if isOn == true{
                        //change compass on map!
                        mapView.ornaments.compassView.isHidden = false
                        //change user preference to true!
                        userReference.updateData(["compass_on": true]) { error in
                                if let error = error {
                                    print("Error updating compass to true: \(error.localizedDescription)")
                                }
                            }
                    } else {
                        //disable compass on map!
                        mapView.ornaments.compassView.isHidden = true
                        
                        //change user preference to false!
                        userReference.updateData(["compass_on": false]) { error in
                                if let error = error {
                                    print("Error updating compass to false: \(error.localizedDescription)")
                                }
                            }
                    }
                case 1:
                    //show waiting screen is toggled
                    if isOn == true{
                        //show waiting screen!
                        showWaitingScreen = true
                        
                        //change user preference to true!
                        userReference.updateData(["showScreen_on": true]) { error in
                                if let error = error {
                                    print("Error updating showScreen to true: \(error.localizedDescription)")
                                }
                            }
                    } else {
                        //hide waiting screen!
                        showWaitingScreen = false
                        
                        //change user preference to false!
                        userReference.updateData(["showScreen_on": false]) { error in
                                if let error = error {
                                    print("Error updating showScreen to false: \(error.localizedDescription)")
                                }
                            }
                    }
                case 2:
                    //dark mode is toggled
                    if isOn == true{
                        //enable dark mode
                        //MARK: enable on nav screen
                        //MARK: DO THIS ON MAIN MAP WHEN LOADING
                        UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .dark
                        self.changeMapStyle()
                                        
                        //change user preference to true!
                        userReference.updateData(["dark_Mode": true]) { error in
                                if let error = error {
                                    print("Error updating showScreen to false: \(error.localizedDescription)")
                                }
                            }
                    } else {
                        //disable dark mode
                        //MARK: disable on nav screen
                        UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .light
                        self.changeMapStyle()
                        
                        //change user preference to false!
                        userReference.updateData(["dark_Mode": false]) { error in
                                if let error = error {
                                    print("Error updating showScreen to false: \(error.localizedDescription)")
                                }
                            }
                    }
                case 3:
                    //scale bar is toggled!
                    if isOn == true{
                        //scale bar is on
                        mapView.ornaments.options.scaleBar.visibility = .visible
                        
                        //change user preference to true!
                        userReference.updateData(["scale_on": true]) { error in
                                if let error = error {
                                    print("Error updating scale bar to true: \(error.localizedDescription)")
                                }
                            }
                    } else {
                        //disable scale bar is off
                        mapView.ornaments.options.scaleBar.visibility = .hidden
                        
                        //change user preference to false!
                        userReference.updateData(["scale_on": false]) { error in
                                if let error = error {
                                    print("Error updating scale bar to false: \(error.localizedDescription)")
                                }
                            }
                    }
                default:
                    break
                }
            }
            
            return cell
        default:
            //ADVANCED SETTINGS SECTION!
            let cell = tableView.dequeueReusableCell(withIdentifier: "advancedSettings", for: indexPath) as! advancedSettingsCell
            
            //load in colors, texts, and icons!
            cell.advancedSettingsLabel.text = advancedSettingsLabels[indexPath.row]
            cell.advancedSettingsIcon.image = advancedSettingsIcons[indexPath.row]
            cell.advancedSettingsIcon.tintColor = advancedSettingsColors[indexPath.row]
            
            if indexPath.row == 3 {
                //special red text for our "delete account" button!
                cell.advancedSettingsLabel.textColor = UIColor.red
            } else {
                cell.advancedSettingsLabel.textColor = UIColor(named: "black_to_white")
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            //PROFILE SECTION - nothing to select!
            //MARK: change name here??
            break
        case 1:
            //MAP SETTINGS SECTION - nothing to select!
            break
        case 2:
            //ADVANCED SETTINGS SECTION!
            if let user = Auth.auth().currentUser {
                let user_id = user.uid
                let userReference = firestore_storage.collection("users").document(user_id)
                let collection = firestore_storage.collection("users")
                let userCollection = collection.document(user_id)
                
                switch indexPath.row {
                case 0:
                    //change map appearance via alert
                    let controller = UIAlertController(title: "Select Map Style", message: "Please select a map style", preferredStyle: .actionSheet)
                    
                    controller.addAction(UIAlertAction(title: "Cancel",
                                                       style: .cancel))
                    
                    controller.addAction(UIAlertAction(title: "Classic", style: .default) {_ in
                        //update to classic style
                        userReference.updateData(["map_Style": "classic"]) { error in
                            if let error = error {
                                print("Error updating scale bar to false: \(error.localizedDescription)")
                            }
                        }
                        self.changeMapStyle()
                    })
                    
                    controller.addAction(UIAlertAction(title: "Navigation", style: .default) {_ in
                        userReference.updateData(["map_Style": "navigation"]) { error in
                            if let error = error {
                                print("Error updating scale bar to false: \(error.localizedDescription)")
                            }
                        }
                        self.changeMapStyle()
                    })
                    
                    controller.addAction(UIAlertAction(title: "Streets (Dark Mode not supported)", style: .default) {_ in
                        userReference.updateData(["map_Style": "streets"]) { error in
                            if let error = error {
                                print("Error updating scale bar to false: \(error.localizedDescription)")
                            }
                        }
                        self.changeMapStyle()
                    })
                    
                    controller.addAction(UIAlertAction(title: "Satellite (Dark Mode not supported)", style: .default) {_ in
                        userReference.updateData(["map_Style": "satellite"]) { error in
                            if let error = error {
                                print("Error updating scale bar to false: \(error.localizedDescription)")
                            }
                        }
                        self.changeMapStyle()
                    })
                    
                    present(controller, animated: true)
                case 1:
                    sendAlert(user: user,
                              title: "Change password",
                              message: "Please enter a new 6 digit password.")
                case 2:
                    //Log out!
                    sendAlert(user: user,
                              title: "Sign out",
                              message: "Are you sure you want to sign out?")
                    
                case 3:
                    //Delete account!
                    sendAlert(user: user,
                              title: "Delete account",
                              message: "Are you sure you want to delete your account?")
                default:
                    break
                }
            } else {
                switch indexPath.row {
                case 1:
                    sendErrorAlert(title: "Change password ",
                                   message: "Error in changing password.")
                case 2:
                    sendErrorAlert(title: "Log out",
                                   message: "Error in logging out.")
                case 3:
                    sendErrorAlert(title: "Delete account",
                                   message: "Error in deleting account.")
                default:
                    break
                }
            }
        default:
            break
        }
    }
    
    func sendAlert(user: User, title: String, message: String){
        //used to send alert to the user!
        let controller = UIAlertController(title: title,
                                           message: message,
                                           preferredStyle: .alert)
        
        //all controllers will have a cancel button
        controller.addAction(UIAlertAction(title: "Cancel",
                                           style: .cancel))
        
        switch title {
        case "Change password":
            //add text fields and action to change password!
            controller.addTextField {textField in textField.placeholder = "Current password..."}
            controller.addTextField {textField in textField.placeholder = "New password..."}
            
            controller.addAction(UIAlertAction(title: "Confirm", style: .default) {_ in
                //update the password
                let currentPassword = controller.textFields?[0].text ?? ""
                let newPassword = controller.textFields?[1].text ?? ""
                let credential = EmailAuthProvider.credential(withEmail: user.email ?? "", password: currentPassword)
                
                user.reauthenticate(with: credential) {_, reauthError in
                    if reauthError != nil {
                        print("error authenticating user")
                        self.sendErrorAlert(title: "Change password",
                                       message: "Incorrect password.")
                    } else {
                        user.updatePassword(to: newPassword) { error in
                            if let error = error {
                                //handle password update error!
                                print("Error updating password: \(error.localizedDescription)")
                            } else {
                                //password updated successfully!
                                print("Password updated successfully!")
                                
                            }
                        }
                    }
                }
            })
            
            let confirmAction = controller.actions.last!
            confirmAction.isEnabled = false
            
            NotificationCenter.default.addObserver(
                //add an observer to enable the confirm button when there are 6 characters!
                forName: UITextField.textDidChangeNotification,
                object: controller.textFields?[1],
                queue: .main) {notification in
                    guard let textFieldText = controller.textFields?[1].text else { return }
                    confirmAction.isEnabled = textFieldText.count >= 6
                }
            
        case "Sign out":
            //add action to log out!
            controller.addAction(UIAlertAction(title: "Log out",
                                               style: .destructive) { _ in
                do {
                    try Auth.auth().signOut()
                    self.segueOut()
                } catch {
                    print("sign out error")
                }
            })
        case "Delete account":
            //add action to delete account!
            controller.addTextField {textField in textField.placeholder = "Enter current password..."}
            
            controller.addAction(UIAlertAction(title: "Confirm",
                                               style: .destructive) { _ in
                //locate user info to delete account
                let currentPassword = controller.textFields?[0].text ?? ""
                let credential = EmailAuthProvider.credential(withEmail: user.email ?? "", password: currentPassword)
                let userData = firestore_storage.collection("users").document(user.uid)
                
                user.reauthenticate(with: credential) {_, error in
                    if let error = error {
                        print("error signing out: \(error)")
                        self.sendErrorAlert(title: "Delete account",
                                       message: "Incorrect password.")
                    } else {
                        //delete here!
                        userData.delete()
                        user.delete()
                        self.segueOut()
                    }
                }
            })
        default:
            break
        }
        
        present(controller, animated: true)
    }
    
    func sendErrorAlert(title: String, message: String) {
        let controller = UIAlertController(title: title,
                                           message: message,
                                           preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(controller, animated: true)
    }
                        
                                         
    func changeMapStyle(){
        var mapStyle = String()
        var darkMode = Bool()
        let user = Auth.auth().currentUser
        let user_id = user!.uid
        let collection = firestore_storage.collection("users")
        let userCollection = collection.document(user_id)
        userCollection.getDocument { (document, error) in
            mapStyle = document!["map_Style"] as! String
            darkMode = document!["dark_Mode"] as! Bool
            
            switch mapStyle {
                //set map style!
            case "classic":
                if darkMode == true {
                    mapView.mapboxMap.loadStyleURI(.dark)
                } else {
                    mapView.mapboxMap.loadStyleURI(.light)
                }
            case "navigation":
                if darkMode == true {
                    mapView.mapboxMap.loadStyleURI(.navigationNight)
                } else {
                    mapView.mapboxMap.loadStyleURI(.navigationDay)
                }
            case "streets":
                mapView.mapboxMap.loadStyleURI(.streets)
            case "satellite":
                mapView.mapboxMap.loadStyleURI(.satellite)
            default:
                break
            }
        }
    }
    
    func editNameTapped(){
        //locate user info
        print("tapped")
        let user = Auth.auth().currentUser
        let user_id = user!.uid
        let userReference = firestore_storage.collection("users").document(user_id)
        userReference.getDocument { (document, error) in
            if let document = document, document.exists {
                //access the user data and update the label
                let userData = document.data()
                if let firstName = userData?["first_Name"] as? String,
                   let lastName = userData?["last_Name"] as? String {
                    //create an alert
                    let controller = UIAlertController(title: "Edit name",
                                                       message: "Please enter your first and last name",
                                                       preferredStyle: .alert)
    
                    //add cancel button
                    controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    
                    //add two text fields with the user's name
                    controller.addTextField { (textField) in
                        textField.text = firstName
                    }
                    controller.addTextField { (textField) in
                        textField.text = lastName
                    }
                    
                    //add confirm button
                    controller.addAction(UIAlertAction(title: "Confirm", style: .default) { (_) in
                        //access the text fields
                        guard let firstNameTextField = controller.textFields?[0],
                              firstNameTextField.text != "",
                              let lastNameTextField = controller.textFields?[1],
                              lastNameTextField.text != "" 
                        else {
                            self.sendErrorAlert(title: "Edit name", message: "Please enter a valid name.")
                            return
                        }
    
                        //save names in firebase
                        print("First Name: \(firstNameTextField.text!)")
                        print("Last Name: \(lastNameTextField.text!)")
                        
                        //save info in firebase
                        userReference.updateData(["first_Name": firstNameTextField.text!])
                        userReference.updateData(["last_Name": lastNameTextField.text!])
                        
                        //change username on screen (should just reload data)
                        self.optionsTable.reloadData()
                    })
                    //present controller
                    self.present(controller, animated: true)
                }
            } else {
                self.sendErrorAlert(title: "Edit name", message: "Unable to edit name.")
            }
        }
    }
    
    func segueOut(){
        //turn off dark mode when user logs out
        UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .light
        
        //Remove Main_Map from navigation stack!
        if let updatedStack = navigationController?.viewControllers.filter({ $0 !== Main_Map.self }) {
            navigationController?.setViewControllers(updatedStack, animated: true)
            
            //Now pop settings screen!
            self.dismiss(animated: true)
        }
    }
}
