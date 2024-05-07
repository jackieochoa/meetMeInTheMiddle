# meetMeInTheMiddle
An iOS application coded in Swift that enables users to input multiple locations and calculate optimal departure times for synchronized arrivals.

Project name: Meet Me in the Middle
Project Description: “Meet Me in the Middle” is an app for coordinating meetups! The user can
input their friend’s location, their destination, and the app will calculate what time each person
needs to leave so each person can arrive at their destination at the same time. The interface will
let the user know who needs to leave first and each person’s time of departure, followed by
turn-by-turn navigation instructions.


How to use this app:
  ● You can log in or create your own account on the first VC
  ● The main screen will immediately load a map centered on the user location.
  ● To start a search, click on “start your engine!”. This will launch a search bar where you can input your friend’s location. After selecting their location, you can search for your destination.
  ● The app will send an alert to tell the user if they should wait or leave immediately
  ● If the user should wait, they will be sent to a waiting screen with a countdown timer.
  ● Once the user needs to leave, the navigation instructions will show :-)


Packages imported:
  ● Mapbox Search: https://github.com/mapbox/search-ios.git
    ○ Used to display a search panel, auto-fill an address search, and find coordinates of the user’s inputs
  ● Mapbox navigation: https://github.com/mapbox/mapbox-navigation-ios.git
    ○ Used to calculate ETAs, draw routes, and show navigation instructions
  ● Firebase: https://github.com/firebase/firebase-ios-sdk
    ○ Used to manage user logins through firebase and user preferences through firestore


Special instructions:
  ● This app is meant to be used in portrait mode only.
  ● Mapbox requires a special access key to be able to run their project.
  ● Mapbox includes a way to simulate a route being followed, so you can fully run the app on the simulator - no need to download on phone :-)
  ● Sometimes the mapbox packages will not let the app run without a secret token access key, so you will need to create a .netrc file. This is how i did it on my laptop-
    ○ Fire up Terminal
    ○ cd ~ (go to the home directory)
    ○ touch .netrc (create file)
    ○ open .netrc (open .netrc)
    ○ Set required data.
      ■ Type this into the .netrc file:
        machine api.mapbox.com
        login mapbox
        password **YOUR MAPBOX PASSWORD**
○ Save
