//
//  Main Map.swift
//  File name: finalProject-meetMeInTheMiddle
//  CS329 Final Project
//  Created by jao3589 on 12/1/23.
//

//import so. many. things.
import UIKit
import MapboxMaps
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapboxSearch
import MapboxSearchUI
import FirebaseAuth
import FirebaseFirestore
import Foundation

//use global variables to allow settings screen access to the map!
var mapView: MapView!
var showWaitingScreen = true

//protocol for our waiting screen!
protocol WaitingScreenDelegate: AnyObject {
    func startNavScreen()
}

class Main_Map: UIViewController, WaitingScreenDelegate {
    //declare stuff!
    let searchController = MapboxSearchController()
    var panelController: MapboxPanelController?
    var locationManager = CLLocationManager()
    var navigationViewController: NavigationViewController? = nil
    
    //placeholders for future coordinates!
    var friendLocation: SearchResult?
    var destination: SearchResult?
    var friendOrigin: Waypoint?
    var myOrigin: Waypoint?
    var ourDestination: Waypoint?
    
    //variables for our meetup time!
    var friendETA: Int = -1
    var myETA: Int = -1
    var skipWaiting: Bool = false
    var timeToLeave: String = ""
    var timeDiff: Int = -1
    
    //calculates two ETAs when the app has the routes loaded!
    var presentNavigation: Bool = false {
        didSet {
            if presentNavigation == true {
                timeDifference(userTime: myETA,
                               friendTime: friendETA,
                               navigationScreen: navigationViewController!)

                
                presentNavigation = false
            }
        }
    }
    
    //outlets!
    @IBOutlet weak var startRoute: UIButton!
    @IBOutlet weak var stackView: UIStackView!
    
    override func viewDidLoad() {
        //load view!
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        //set up map!
        mapView = MapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapView)
        view.addSubview(startRoute)
        view.addSubview(stackView)
        
        //customize map and camera angle!
        mapView.location.options.puckType = .puck2D()
        let followPuckViewportState = mapView.viewport.makeFollowPuckViewportState(
            options: FollowPuckViewportStateOptions(
                padding: UIEdgeInsets(top: 200, left: 0, bottom: 0, right: 0),
                bearing: .constant(0)))
        mapView.viewport.transition(to: followPuckViewportState)
        
        //searchbar stuff!
        searchController.delegate = self
        searchController.searchBarPlaceholder = "Where's our friend?"
        
        //load user preferences!
        let userId = Auth.auth().currentUser?.uid
        let collection = firestore_storage.collection("users")
        let userCollection = collection.document(userId!)
        userCollection.getDocument { (document, error) in
            if let document = document, document.exists {
                //Change appearance of the app
                if (document["dark_Mode"] as! Bool) == true {
                    //enable dark mode!
                    UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .dark
                }
                
                if (document["compass_on"] as! Bool) == false {
                    //disable compass on map!
                    mapView.ornaments.compassView.isHidden = true
                }
                
                if (document["showScreen_on"] as! Bool) == false {
                    //disable waiting screen!
                    showWaitingScreen = false
                }
                
                if (document["scale_on"] as! Bool) == false {
                    //disable scale bar on map!
                    mapView.ornaments.options.scaleBar.visibility = .hidden
                }
                
                //locate correct map style!
                let mapStyle = document["map_Style"] as! String
                let darkMode = document["dark_Mode"] as! Bool
                
                switch mapStyle {
                    //load user's map!
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
            } else {
                // Document does not exist or there was an error
                print("Error: \(error?.localizedDescription ?? "error unknown")")
            }
        }
    }
    
    func clearSearchbar(placeholder: String) {
        //clears the Search bar and changes the placeholder!
        searchController.searchBarPlaceholder = placeholder
        
        if placeholder == "Where are we going?" {
            //send an alert to let the user know the search has changed!
            let controller = UIAlertController(title: "Where are we going?",
                                           message: "Please enter our destination.",
                                           preferredStyle: .alert)

            controller.addAction(UIAlertAction(title: "OK",
                                               style: .default))
            
            present(controller, animated: true)
        }
    }
    
    func initiateNavigation(myOrigin: Waypoint, friendOrigin: Waypoint, destination: Waypoint) {
        //Specify that the two routes are for cars avoiding traffic!
        let myRouteOptions = NavigationRouteOptions(waypoints: [myOrigin, destination],
                                                    profileIdentifier: .automobile)
        let friendRouteOptions = NavigationRouteOptions(waypoints: [friendOrigin, destination],
                                                        profileIdentifier: .automobile)
        
        //Find most efficient route for our friend, then get their ETA!
        Directions.shared.calculate(friendRouteOptions) { [weak self] (session, result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):
                guard let route = response.routes?.first, let strongSelf = self else {
                    return
                }
                //calculate their ETA!
                if let firstLeg = route.legs.first {
                    strongSelf.friendETA = Int(firstLeg.expectedTravelTime)
                    print("friend ETA: \(strongSelf.friendETA)")
                }
                
                if strongSelf.myETA > 0 && strongSelf.friendETA > 0 && self!.navigationViewController != nil {
                    strongSelf.presentNavigation = true
                }
            }
        }
        
        //Find most efficient route for user, then get their ETA!
        Directions.shared.calculate(myRouteOptions) { [weak self] (session, result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):
                guard let route = response.routes?.first, let strongSelf = self else {
                    return
                }
                
                //create the screen that contains user's navigation instructions!
                let myNavigationService = MapboxNavigationService(routeResponse: response, routeIndex: 0, routeOptions: myRouteOptions, simulating: .always)
                let myNavigationOptions = NavigationOptions(navigationService: myNavigationService)
                self!.navigationViewController = NavigationViewController(for: response, routeIndex: 0, routeOptions: myRouteOptions, navigationOptions: myNavigationOptions)
                
                //calculate user ETA!
                if let firstLeg = route.legs.first {
                    strongSelf.myETA = Int(firstLeg.expectedTravelTime)
                    print("my ETA: \(strongSelf.myETA)")
                }
                if strongSelf.myETA > 0 && strongSelf.friendETA > 0 && self!.navigationViewController != nil {
                    strongSelf.presentNavigation = true
                }
            }
        }
    }
    
    func timeDifference(userTime: Int, friendTime: Int, navigationScreen: NavigationViewController) {
        //find current time to find what time last person should leave!
        let currentDate = Date()
        timeDiff = userTime - friendTime
        
        //find the time of departure for closest person and format it!
        let latestTimeOfDepart = currentDate.addingTimeInterval(TimeInterval(abs(timeDiff)))
        let dateFormatter = DateFormatter(); dateFormatter.dateFormat = "h:mm a"
        
        //declare stuff for an alert!
        var controller = UIAlertController()
        var titleMessage = String()
        var message = String()
        
        //change main variables!
        timeToLeave = dateFormatter.string(from: latestTimeOfDepart)
        print("TIME MARK: \(currentDate), \(latestTimeOfDepart), \(timeToLeave)")
        
        if timeDiff < 0 {
            //User's ETA is less than friend's ETA, so user leaves 2nd!
            titleMessage = "Our friend should leave now"
            message = "You should leave at \(timeToLeave)."
        } else {
            //User's ETA is greater than friend's ETA, so friend leaves 2nd!
            titleMessage = "Your route will start now"
            message = "Our friend should leave at \(timeToLeave)."
        }
        
        //create an alert for the user!
        controller = UIAlertController(title: titleMessage,
                                       message: message,
                                       preferredStyle: .alert)

        controller.addAction(UIAlertAction(title: "OK",
                                           style: .default) { _ in
            if self.timeDiff < 0 && showWaitingScreen == true {
                //user needs to wait!
                self.performSegue(withIdentifier: "MainToWait", sender: nil)
            } else {
                //user needs to start route immediately!
                self.startNavScreen()
            }
        })
        
        controller.addAction(UIAlertAction(title: "Cancel",
                                           style: .cancel) { _ in
            //Cancel the route!
            self.resetNavigation()
        })
        
        present(controller, animated: true)
    }
    
    func startNavScreen() {
        //called when user starts route immediately or after waiting screen is dismissed
        present(navigationViewController!, animated: true)
        resetNavigation()
    }
    
    func resetNavigation() {
        //reset variables to prepare for a new route!
        myETA = -1
        friendETA = -1
        friendLocation = nil
        destination = nil
        navigationViewController = nil
        skipWaiting = false
        timeToLeave = ""
        timeDiff = -1
        panelController?.setState(.hidden)
    }
    
    @IBAction func recenterScreen(_ sender: Any) {
        //recenters the map camera!
        let followPuckViewportState = mapView.viewport.makeFollowPuckViewportState(
            options: FollowPuckViewportStateOptions(
                padding: UIEdgeInsets(top: 200, left: 0, bottom: 0, right: 0),
                bearing: .constant(0)))
        
        mapView.viewport.transition(to: followPuckViewportState)
    }

    @IBAction func startSearch(_ sender: Any) {
            //occurs when the user clicks on the big blue button!
            panelController = MapboxPanelController(rootViewController: searchController)
            addChild(panelController!)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //prepare to segue to our waiting screen!
        if segue.identifier == "MainToWait" {
            if let destinationVC = segue.destination as? Waiting_Screen {
                //change variables to wait time!
                destinationVC.delegate = self
                destinationVC.secondsToWait = -1 * timeDiff
                destinationVC.timeOfDeparture = timeToLeave
            }
        }
    }
}

extension Main_Map: SearchControllerDelegate {
    //runs the search box!
    func categorySearchResultsReceived(category: MapboxSearchUI.SearchCategory, results: [SearchResult]) { }
    
    func searchResultSelected(_ searchResult: SearchResult) {
        //is called when user selects a search result!
        if friendLocation == nil {
            //assign friend location first!
            friendLocation = searchResult
            clearSearchbar(placeholder: "Where are we going?")
        } else {
            //assign destination second!
            destination = searchResult
            clearSearchbar(placeholder: "Where's our friend?")
            
            // Define three waypoints to travel between!
            myOrigin = Waypoint(coordinate: locationManager.location!.coordinate,
                                coordinateAccuracy: -1,
                                name: "myStart")
            friendOrigin = Waypoint(coordinate: friendLocation!.coordinate,
                                    coordinateAccuracy: -1,
                                    name: "friendStart")
            ourDestination = Waypoint(coordinate: destination!.coordinate,
                                      coordinateAccuracy: -1,
                                      name: "End")
            
            //run navigation!
            initiateNavigation(myOrigin: myOrigin!, friendOrigin: friendOrigin!, destination: ourDestination!)
        }
    }

    func userFavoriteSelected(_ userFavorite: FavoriteRecord) { }
    }
