//
//  debugVC.swift
//  ProjetCoursesVoitures
//
//  Created by Nodewiz on 05/12/2024.
//

import UIKit
import MapKit
import CoreLocation

class debugVC: UIViewController, CLLocationManagerDelegate {
	
	@IBOutlet weak var carte: MKMapView!
	
	var locationManager = CLLocationManager()
	var userLocation: CLLocationCoordinate2D?
	var userAnnotation: MKPointAnnotation?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		carte.delegate = self
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		locationManager.requestWhenInUseAuthorization()
		
		// Ajouter un point représentant l'utilisateur
		if CLLocationManager.locationServicesEnabled() {
			locationManager.startUpdatingLocation()
		}
		
		// Ajouter un gestionnaire de gestes
		let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
		longPressGesture.minimumPressDuration = 0.4
		carte.addGestureRecognizer(longPressGesture)
	}
	
	// Ajouter l'annotation de l'utilisateur sur la carte
	func addUserAnnotation() {
		if let userAnnotation = userAnnotation {
			carte.removeAnnotation(userAnnotation)
		}
		
		userAnnotation = MKPointAnnotation()
		userAnnotation?.title = "Vous êtes ici"
		userAnnotation?.coordinate = userLocation!
		carte.addAnnotation(userAnnotation!)
	}
	
	// Déplacer la position de l'utilisateur
	func moveUserLocation(latitudeDelta: Double, longitudeDelta: Double) {
		guard let currentLocation = userLocation else { return }
		
		let newLatitude = currentLocation.latitude + latitudeDelta
		let newLongitude = currentLocation.longitude + longitudeDelta
		
		userLocation = CLLocationCoordinate2D(latitude: newLatitude, longitude: newLongitude)
		addUserAnnotation()
		
		let region = MKCoordinateRegion(center: userLocation!, latitudinalMeters: 500, longitudinalMeters: 500)
		carte.setRegion(region, animated: true)
	}
	
	@IBAction func deplacerLocalisationHaut(_ sender: Any) {
		moveUserLocation(latitudeDelta: 0.001, longitudeDelta: 0)
	}
	
	@IBAction func deplacerLocalisationBas(_ sender: Any) {
		moveUserLocation(latitudeDelta: -0.001, longitudeDelta: 0)
	}
	
	@IBAction func deplacerLocalisationGauche(_ sender: Any) {
		moveUserLocation(latitudeDelta: 0, longitudeDelta: -0.001)
	}
	
	@IBAction func deplacerLocalisationDroite(_ sender: Any) {
		moveUserLocation(latitudeDelta: 0, longitudeDelta: 0.001)
	}
	
	// MARK: Gérer un appui long pour ajouter une annotation
	@objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
		let location = gestureRecognizer.location(in: carte)
		let coordinate = carte.convert(location, toCoordinateFrom: carte)
		
		let annotation = MKPointAnnotation()
		annotation.coordinate = coordinate
		annotation.title = "Checkpoint \(Int.random(in: 1...100))"
		carte.addAnnotation(annotation)
	}
	
	// MARK: Calculer une route entre l'utilisateur et un checkpoint
	func calculerRoute(from start: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
		let request = MKDirections.Request()
		request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
		request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
		request.transportType = .automobile
		
		let directions = MKDirections(request: request)
		directions.calculate { [weak self] response, error in
			guard let self = self else { return }
			if let error = error {
				print("[debugVC]: Erreur de calcul de direction: \(error.localizedDescription)")
				return
			}
			
			guard let response = response, let route = response.routes.first else {
				print("[debugVC]: Pas de route trouvée !")
				return
			}
			
			self.carte.addOverlay(route.polyline)
			self.carte.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
		}
	}
	
	// MARK: Localisation mise à jour
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let location = locations.last else { return }
		
		userLocation = location.coordinate
		addUserAnnotation()
		
		let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
		carte.setRegion(region, animated: true)
	}
}

// MARK: Dessiner les routes sur la carte
extension debugVC: MKMapViewDelegate {
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		if let polyline = overlay as? MKPolyline {
			let renderer = MKPolylineRenderer(polyline: polyline)
			renderer.strokeColor = .systemBlue
			renderer.lineWidth = 3.0
			return renderer
		}
		
		return MKOverlayRenderer(overlay: overlay)
	}
	
	func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
		guard let destinationAnnotation = view.annotation else { return }
		guard let userLocation = userLocation else { return }
		
		// Calculer une route entre "Vous êtes ici" et l'annotation sélectionnée
		calculerRoute(from: userLocation, to: destinationAnnotation.coordinate)
	}
}
