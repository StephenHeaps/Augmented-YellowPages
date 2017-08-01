//
//  ViewController.swift
//  AugmentedPhoneBook
//
//  Created by Stephen Heaps on 2017-07-30.
//  Copyright © 2017 Stephen Heaps. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import CoreLocation
import SafariServices
import ARCL

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    let apiKey = "YOUR-API-KEY-HERE"
    
    var sceneLocationView: SceneLocationView!
    
    var summary: Summary?
    var businesses: [Business] = []
    let locationManager = CLLocationManager()
    
    var topStackView: UIStackView!
    private var cameraLabel = UILabel()
    let distanceSlider = UISlider()
    let refreshLocationsButton = UIButton(type: .custom)
    
    private var urlButton = UIButton(type: .custom)
    
    override func loadView() {
        super.loadView()
        
        
        sceneLocationView = SceneLocationView()
        sceneLocationView.session.delegate = self
        self.view = sceneLocationView
        
        cameraLabel.frame = CGRect(x: 10, y: 25, width: UIScreen.main.bounds.width - 20, height: 25)
        cameraLabel.backgroundColor = .gray
        cameraLabel.layer.cornerRadius = 10
        cameraLabel.clipsToBounds = true
        cameraLabel.textAlignment = .center
        cameraLabel.text = "Loading..."
        
        distanceSlider.isHidden = true
        distanceSlider.value = 0.5
        distanceSlider.addTarget(self, action: #selector(handleSliderValueChanged(_:)), for: .valueChanged)
        
        refreshLocationsButton.setTitle("Search for Nearby Restaurants", for: .normal)
        refreshLocationsButton.setTitleColor(.blue, for: .normal)
        refreshLocationsButton.backgroundColor = cameraLabel.backgroundColor
        refreshLocationsButton.layer.cornerRadius = 10
        refreshLocationsButton.clipsToBounds = true
        refreshLocationsButton.isHidden = true
        refreshLocationsButton.bounds = cameraLabel.bounds
        refreshLocationsButton.addTarget(self, action: #selector(handleButtonPress(_:)), for: .touchUpInside)
        
        topStackView = UIStackView(arrangedSubviews: [cameraLabel, distanceSlider, refreshLocationsButton])
        topStackView.translatesAutoresizingMaskIntoConstraints = false
        topStackView.axis = .vertical
        topStackView.spacing = 10
        self.view.addSubview(topStackView)
        
        cameraLabel.heightAnchor.constraint(equalToConstant: cameraLabel.bounds.height).isActive = true
        distanceSlider.heightAnchor.constraint(equalToConstant: distanceSlider.bounds.height).isActive = true
        refreshLocationsButton.heightAnchor.constraint(equalToConstant: refreshLocationsButton.bounds.height).isActive = true
        
        topStackView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
        topStackView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 20 + 10).isActive = true // 20 for status bar
        topStackView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10).isActive = true
        
        urlButton.frame = CGRect(x: 10, y: UIScreen.main.bounds.height - 25 - 50, width: cameraLabel.bounds.width, height: 50)
        urlButton.backgroundColor = .white
        urlButton.layer.cornerRadius = 10
        urlButton.clipsToBounds = true
        urlButton.setTitleColor(.black, for: .normal)
        urlButton.isHidden = true
        urlButton.addTarget(self, action: #selector(handleButtonPress(_:)), for: .touchUpInside)
        self.view.addSubview(urlButton)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sceneLocationView.run()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
//        pausing then resuming currently displays all nodes 180 degrees in the opposite direction (stores in front of you will appear behind you)
//        sceneLocationView.pause()
    }
    
    var currentBusiness: Business?
    @objc func handleButtonPress(_ button: UIButton) {
        if button == urlButton {
            if let currentBusiness = currentBusiness {
                if let businessURL = currentBusiness.url {
                    let safariViewController = SFSafariViewController(url: businessURL)
                    self.present(safariViewController, animated: true, completion: {
                        
                    })
                }
            }
        } else if button == refreshLocationsButton {
            if self.distanceSlider.isHidden { // reset app
                reset()
            } else {
                self.refreshLocationsButton.setTitle("searching...", for: .normal)
                self.distanceSlider.isHidden = true
                self.cameraLabel.isHidden = true
                self.beginRequestingLocation()
            }
        }
    }
    
    var locationNodes: [LocationNode] = []
    private func reset() {
        self.currentBusiness = nil
        self.distanceSlider.isHidden = false
        self.cameraLabel.isHidden = false
        self.refreshLocationsButton.isHidden = false
        self.urlButton.isHidden = true
        savedLocation = false

        for node in locationNodes {
            node.removeFromParentNode()
        }
        self.businesses = []

        self.handleSliderValueChanged(self.distanceSlider) // update button text
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let sceneView = gesture.view as! ARSCNView
        let touchLocation = gesture.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(touchLocation, options: [:])
        
        if !hitTestResult.isEmpty {
            if let hit = hitTestResult.first {
                if let business = (hit.node as? BusinessSCNNode)?.business {
                    self.currentBusiness = business
                    self.urlButton.isHidden = false
                    self.urlButton.setTitle("View \(business.name)", for: .normal)
                }
            }
        }
    }
    
    @objc func handleSliderValueChanged(_ slider: UISlider) {
        if slider.value <= 0 {
            let value = String(format: "%.2f", 0.5)
            self.refreshLocationsButton.setTitle("Search for Food ≤\(value)km away", for: .normal)
            return
        }
        let step: Float = 0.25
        let temp = slider.value * 10
        let sliderValue = (temp * step) + 0.5
        let value = String(format: "%.2f", sliderValue)
        
        self.refreshLocationsButton.setTitle("Search for Food ≤\(value)km away", for: .normal)
    }
    
    func beginRequestingLocation() {
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    // MARK: - Location Manage Delegate
    var savedLocation = false
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        self.locationManager.stopUpdatingLocation()
        if !savedLocation {
            savedLocation = true
            
            let longitude = locValue.latitude
            let latitude = locValue.longitude
            let numberOfItems = 35
            
            let step: Float = 0.25
            let temp = self.distanceSlider.value * 10
            let sliderValue = (temp * step) + 0.5
            let maxDistance = sliderValue // in km
            let url = URL(string: "http://api.sandbox.yellowapi.com/FindBusiness/?what=Restaurants&where=cZ\(longitude),\(latitude)&fmt=JSON&pgLen=\(numberOfItems)&apikey=\(apiKey)&UID=127.0.0.1&dist=\(maxDistance)")
            if let yellowURL = url {
                performURLSessionCallWithURL(yellowURL)
            }
        }
    }
    
    // MARK: - YellowPages api
    func performURLSessionCallWithURL(_ url: URL) {
        let config = URLSessionConfiguration.default // Session Configuration
        let session = URLSession(configuration: config) // Load configuration into Session
        
        let task = session.dataTask(with: url, completionHandler: {
            (data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any] {
                        if let summary = json["summary"] as? [String:Any] {
                            if let structSummary = Summary(json: summary) {
                                self.summary = structSummary
                            } else {
                                print("error with summary")
                            }
                        }
                        
                        if let listings = json["listings"] as? [[String:Any]] {
                            for listing in listings {
                                if let business = Business(json: listing) {
                                    self.businesses.append(business)
                                } else {
                                    print("error with listing")
                                }
                            }
                        }
                    }
                    self.completedApiRequest(true)
                } catch {
                    self.completedApiRequest(false)
                    print("error in JSONSerialization")
                }
            }
        })
        task.resume()
    }
    
    func completedApiRequest(_ success: Bool) {
        if !success {
            print("Api request failed")
            return
        }
        DispatchQueue.main.async {
            self.refreshLocationsButton.setTitle("Found \(self.businesses.count) restaurants! (tap to reset)", for: .normal)
        }

        sceneLocationView.customNodeUpdateBlock = { (locationNode) in
            if let annotationNode = locationNode as? LocationTextBoxNode {
                //The scale of a node with a billboard constraint applied is ignored
                //The annotation subnode itself, as a subnode, has the scale applied to it
                let appliedScale = locationNode.scale
                locationNode.scale = SCNVector3(x: 1, y: 1, z: 1)
                
                var scale: Float = 1
                
                if annotationNode.scaleRelativeToDistance {
                    if appliedScale.y < 0.5 {
                        scale = 0.5
                    } else {
                        scale = appliedScale.y
                    }
                    annotationNode.annotationNode.scale = appliedScale
                }
                
                annotationNode.pivot = SCNMatrix4MakeTranslation(0, -1.1 * scale, 0)
            }
        }
        
        for index in 0...self.businesses.count-1 {
            let business = self.businesses[index]
            let coordinate = CLLocationCoordinate2D(latitude: business.location.latitude, longitude: business.location.longitude)
            let altitude = Double().randomInRange(start: 100, end: 400)
            let location = CLLocation(coordinate: coordinate, altitude: altitude)

            let annotationNode = LocationTextBoxNode(location: location, business: business)//LocationAnnotationNode(location: location, image: image)
            annotationNode.scaleRelativeToDistance = true
            self.locationNodes.append(annotationNode)
            sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
        }
    }
}

extension ViewController: ARSessionDelegate {
    public func sessionWasInterrupted(_ session: ARSession) {
        sceneLocationView.sessionWasInterrupted(session)
    }
    
    public func sessionInterruptionEnded(_ session: ARSession) {
        sceneLocationView.sessionInterruptionEnded(session)
    }
    
    public func session(_ session: ARSession, didFailWithError error: Error) {
        sceneLocationView.session(session, didFailWithError: error)
    }
    
    public func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .limited(.insufficientFeatures):
            cameraLabel.text = "camera: limited, insufficient features"
            cameraLabel.textColor = .yellow
        case .limited(.excessiveMotion):
            cameraLabel.text = "camera: limited, excessive motion"
            cameraLabel.textColor = .yellow
        case .limited(.none):
            cameraLabel.text = "camera: limited, no reason"
            cameraLabel.textColor = .yellow
        case .limited(.initializing):
            cameraLabel.text = "camera: limited, initializing"
            cameraLabel.textColor = .yellow
        case .normal:
            cameraLabel.text = "camera: Ready!"
            cameraLabel.textColor = .green

            self.handleSliderValueChanged(self.distanceSlider)
            if refreshLocationsButton.isHidden {
                UIView.animate(withDuration: 0.5, animations: {
                    self.refreshLocationsButton.isHidden = false
                    self.distanceSlider.isHidden = false
                })
            }
            return
        case .notAvailable:
            cameraLabel.text = "camera: not available"
            cameraLabel.textColor = .red
        }

        if refreshLocationsButton.isHidden {
            UIView.animate(withDuration: 0.5, animations: {
                self.distanceSlider.isHidden = true
            })
        }
        sceneLocationView.session(session, cameraDidChangeTrackingState: camera)
    }
}
