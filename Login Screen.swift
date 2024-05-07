//
//  Login Screen.swift
//  File name: finalProject-meetMeInTheMiddle
//  CS329 Final Project
//  Created by jao3589 on 12/1/23.
//

//import firebase!
import UIKit
import FirebaseAuth
import FirebaseFirestore

//set up our firestore!
let firestore_storage = Firestore.firestore()

class Login_Screen: UIViewController {
    //outlets!
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var transitionLabel: UILabel!
    @IBOutlet weak var emailAndFirst: UITextField!
    @IBOutlet weak var passwordAndSecond: UITextField!
    @IBOutlet weak var signupEmail: UITextField!
    @IBOutlet weak var signupPassword: UITextField!
    @IBOutlet weak var theButton: UIButton!
    @IBOutlet weak var transitionButton: UILabel!
    
    //default to login screen!
    var screenAppearance = "login"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //load login screen without animation!
        view.backgroundColor = UIColor(named: "light blue")
        errorLabel.text = ""
        theButton.titleLabel!.text = "Login"
        transitionLabel.text = "Don't have an account?"
        transitionLabel.textColor = UIColor.black
        transitionButton.textColor = UIColor.black
        emailAndFirst.placeholder = "Enter email..."
        passwordAndSecond.placeholder = "Enter password..."
        signupEmail.alpha = 0
        signupPassword.alpha = 0
        
        //watch for a login!
        Auth.auth().addStateDidChangeListener() {
            (auth,user) in
            if user != nil {
                self.performSegue(withIdentifier: "loginToMain", sender: nil)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        //reset appearance once view is out of sight!
        loginAppearance()
    }
    
    func loginAppearance(){
        screenAppearance = "login"
        
        //changes appearance to match login screen!
        resetFields()
        
        //hide extra text fields and change colora!
        UIView.animate(withDuration: 0.5){
            self.view.backgroundColor = UIColor(named: "light blue")
            self.theButton.titleLabel!.text = "Login"
            self.transitionLabel.text = "Don't have an account?"
            self.transitionLabel.textColor = UIColor.black
            self.transitionButton.textColor = UIColor.black
            self.emailAndFirst.placeholder = "Enter email..."
            self.passwordAndSecond.placeholder = "Enter password..."
            self.signupEmail.alpha = 0
            self.signupPassword.alpha = 0
            self.errorLabel.text = ""
        }
        
        //transition the image!
        UIView.transition(with: logoImage,
                          duration: 0.5,
                          options: .transitionCrossDissolve,
                          animations: { self.logoImage.image = UIImage(named: "logo_color")},
                          completion: nil)
    }
    
    func signupAppearance(){
        screenAppearance = "signup"
        
        //changes appearance to match sign up screen!
        resetFields()
        
        //show extra text fields and change colord!
        UIView.animate(withDuration: 0.5){
            self.view.backgroundColor = UIColor(named: "dark blue")
            self.theButton.titleLabel!.text = "Sign up"
            self.transitionLabel.text = "Already have an account?"
            self.transitionLabel.textColor = UIColor.white
            self.transitionButton.textColor = UIColor.white
            self.emailAndFirst.placeholder = "Enter first name..."
            self.passwordAndSecond.placeholder = "Enter last name..."
            self.signupEmail.alpha = 1.0
            self.signupPassword.alpha = 1.0
            self.errorLabel.text = ""
        }
        
        //change color of image!
        UIView.transition(with: logoImage,
                          duration: 0.5,
                          options: .transitionCrossDissolve,
                          animations: { self.logoImage.image = UIImage(named: "logo_dark")},
                          completion: nil)
    }
    
    func createUserData(firstName: String, lastName: String){
        //find user and store their data!
        let user = Auth.auth().currentUser
        
        if let user_id = user?.uid {
            //assign user's name and default settings!
            let userData = ["first_Name": firstName,
                            "last_Name": lastName,
                            "dark_Mode": false,
                            "showScreen_on": true,
                            "compass_on": true,
                            "scale_on": true,
                            "map_Style": "classic"] as [String : Any]
            
            firestore_storage.collection("users").document(user_id).setData(userData) {error in
                if let error = error {
                    print("Error writing document: \(error)")
                }
            }
        }
    }
    
    func resetFields(){
        //empty all fields!
        errorLabel.text = ""
        signupEmail.text = ""
        signupPassword.text = ""
        emailAndFirst.text = ""
        passwordAndSecond.text = ""
    }
    
    @IBAction func loginButton(_ sender: Any) {
        switch screenAppearance {
        case "login":
            //ensure text fields are filled!
            guard
                let emailText = emailAndFirst.text,
                let passwordText = passwordAndSecond.text,
                !emailText.isEmpty,
                !passwordText.isEmpty
                    else {errorLabel.text = "Error: Username or Password is empty."
                          return }
            
            //begin login!
            Auth.auth().signIn(withEmail: emailText, password: passwordText) {
                (authResult,error) in
                if (error as NSError?) != nil {
                    self.errorLabel.text = "Error: Username or Password is incorrect."
                }
                else {
                    self.errorLabel.text = ""
                }
            }
        case "signup":
            //ensure text fields are filled!
            guard
                let emailText = signupEmail.text,
                let passwordText = signupPassword.text,
                let firstNameText = emailAndFirst.text,
                let lastNameText = passwordAndSecond.text,
                !emailText.isEmpty,
                !passwordText.isEmpty,
                !firstNameText.isEmpty,
                !lastNameText.isEmpty
            else {errorLabel.text = "Error: Please fill empty fields"
                return }
            
            //create user!
            Auth.auth().createUser(withEmail: emailText, password: passwordText) {
                (authResult,error) in
                if (error as NSError?) != nil {
                    if passwordText.count < 6 {
                        self.errorLabel.text = "Password must include at least 6 characters."
                    }
                    else {
                        self.errorLabel.text = "Error creating account."
                    }
                } else {
                    //sign up was successful!
                    self.resetFields()
                    self.createUserData(firstName: firstNameText, lastName: lastNameText)
                }
            }
        default:
            break
        }
    }
    
    @IBAction func changeScreenAppearance(_ sender: Any) {
        //handles the transition between dark & light screens!
        if screenAppearance == "login" {
            //screen needs to change to sign up!
            signupAppearance()
        } else {
            //screen needs to change to login!
            loginAppearance()
        }
    }
}
