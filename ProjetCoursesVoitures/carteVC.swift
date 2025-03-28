//
//  carteVC.swift
//  ProjetCoursesVoitures
//
//  Created by Nodewiz on 05/12/2024.
//

import UIKit
import MapKit
import CoreLocation

class carteVC: UIViewController, CLLocationManagerDelegate {

    @IBOutlet var carte: MKMapView!

    var tabCheckpoints: [CheckPointMO] = []
	var userAnnotation: MKPointAnnotation? = nil
	var locationManager = CLLocationManager()
	
    override func viewDidLoad() {
        super.viewDidLoad()

        carte.mapType = .standard
		carte.delegate = self

        for checkpoint in tabCheckpoints {
            let annotation = MKPointAnnotation()
            annotation.title = checkpoint.label
            annotation.coordinate = CLLocationCoordinate2D(latitude: checkpoint.x, longitude: checkpoint.y)
            carte.addAnnotation(annotation)
        }
		
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		locationManager.requestWhenInUseAuthorization()

		// gestion d'activation de la localisation
		if CLLocationManager.locationServicesEnabled() {
			locationManager.startUpdatingLocation()
			locationManager.startUpdatingHeading()
		} else {
			let alert = UIAlertController(title: "Localisation désactivée", message: "L'accès à la localisation est nécessaire pour afficher votre position sur la carte.", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
			present(alert, animated: true, completion: nil)
		}
		
		// Ajouter un gestionnaire de gestes
		let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
		longPressGesture.minimumPressDuration = 0.2
		carte.addGestureRecognizer(longPressGesture)
    }
	
	@objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
		let location = gestureRecognizer.location(in: carte)
		let coordinate = carte.convert(location, toCoordinateFrom: carte)
		let annotation = MKPointAnnotation()
		
		let cooX = coordinate.latitude.description
		let cooY = coordinate.longitude.description
		
		
		annotation.title = String(format: "%@", cooX) + " / " + String(format: "%@", cooY)
		annotation.coordinate = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
		carte.addAnnotation(annotation)
	}
	
	// MARK: Calculer une route
	// à partir d'un point de départ et d'un point d'arrivée
	func calculerRoute(from start: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
		let request = MKDirections.Request()
		request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
		request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
		request.transportType = .automobile

		let directions = MKDirections(request: request)
		directions.calculate { [weak self] response, error in
			guard let self = self else { return }
			if let error = error {
				print("[principaleVC]: Erreur de calcul de direction: \(error.localizedDescription)")
				return
			}

			guard let response = response, let route = response.routes.first else {
				print("[principaleVC]: Pas de route trouvée !")
				return
			}

			self.carte.addOverlay(route.polyline)
			self.carte.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
			
			// Post notification to update the full-screen map
			NotificationCenter.default.post(name: NSNotification.Name("updateFullScreenMap"), object: nil)
		}
	}

	// MARK: Localisation en temps réel
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		carte.removeAnnotations(carte.annotations)
		guard let location = locations.last else { return }
		
		carte.removeOverlays(carte.overlays)
		userAnnotation = nil

		var region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 200, longitudinalMeters: 200)
		carte.setRegion(region, animated: true)
		
		if AppDelegate.currentTrajet != nil {
			let checkpoints = Outils.donneCheckpointsTriesParId(pourTrajet: AppDelegate.currentTrajet!)
			
			for checkpoint in checkpoints {
				let annotation = MKPointAnnotation()
				annotation.title = checkpoint.label
				annotation.coordinate = CLLocationCoordinate2D(latitude: checkpoint.x, longitude: checkpoint.y)
				carte.addAnnotation(annotation)
			}

			if checkpoints.count > 1 {
				for i in 0..<(checkpoints.count - 1) {
					let start = CLLocationCoordinate2D(latitude: checkpoints[i].x, longitude: checkpoints[i].y)
					let destination = CLLocationCoordinate2D(latitude: checkpoints[i + 1].x, longitude: checkpoints[i + 1].y)
					calculerRoute(from: start, to: destination)
				}
			}
		}
		
		userAnnotation = MKPointAnnotation()
		userAnnotation?.title = "Vous êtes ici"
		userAnnotation?.coordinate = location.coordinate

		
		region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 200, longitudinalMeters: 200)
		carte.addAnnotation(userAnnotation!)
		carte.setRegion(region, animated: true)
	}
}

// MARK: Dessiner les points et les routes sur la carte
extension carteVC: MKMapViewDelegate {
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		if let polyline = overlay as? MKPolyline {
			let renderer = MKPolylineRenderer(polyline: polyline)
			renderer.strokeColor = .systemPink
			renderer.lineWidth = 3.0
			return renderer
		}

		return MKOverlayRenderer(overlay: overlay)
	}

	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		if annotation.title == "Vous êtes ici" {
			let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "userLocation")
			annotationView.image = UIImage(systemName: "car")
			annotationView.backgroundColor = AppDelegate.couleurVoiture
			annotationView.canShowCallout = false
			return annotationView
		}

		let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "checkpoint")
		pinView.pinTintColor = .red
		pinView.canShowCallout = true
		return pinView
	}
}
