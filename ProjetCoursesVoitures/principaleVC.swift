//
//  principaleVC.swift
//  ProjetCoursesVoitures
//
//  Created by Nodewiz on 05/12/2024.
//

import UIKit
import CoreLocation
import MapKit

// MARK: protocole de sélection d'un trajet
protocol SelectionTrajet: AnyObject {
    func pickTrajet()
}

class principaleVC: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var carte: MKMapView!
    @IBOutlet weak var nbCheckpointsLab: UILabel!
    @IBOutlet weak var nbTotalCheckpoints: UILabel!
    @IBOutlet weak var distanceProchainCheckpointLab: UILabel!
    @IBOutlet weak var vitesseUtilisateurLab: UILabel!

    var locationManager = CLLocationManager()
    var checkpoints: [CheckPointMO] = []
    var currentCheckpointIndex: Int = 0
    var userAnnotation: MKPointAnnotation? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
		
        if AppDelegate.currentTrajet == nil {
            message.text = "Aucun parcours sélectionné !"
        } else {
            message.text = "Trajet \(AppDelegate.currentTrajet?.label ?? "Inconnu") sélectionné !"
        }

        carte.mapType = .hybrid
        carte.delegate = self

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
        longPressGesture.minimumPressDuration = 0.1
        carte.addGestureRecognizer(longPressGesture)
		
		// gestion du thème au démarrage
		AppDelegate.changeTheme(to: AppDelegate.lesOptions!.theme)
    }
    
    // MARK: Afficher les coordonnées de l'endroit sur la carte
    // où l'utilisateur appuie longtemps sur l'écran
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        let location = gestureRecognizer.location(in: carte)
        let coordinate = carte.convert(location, toCoordinateFrom: carte)
        print("[principaleVC]: Coordinates: \(coordinate.latitude), \(coordinate.longitude)")
    }

    // MARK: Lancer la simulation
    @IBAction func lancerSimulation(_ sender: Any) {
        guard let trajet = AppDelegate.currentTrajet else {
            let alert = UIAlertController(title: "Erreur", message: "Aucun trajet sélectionné ! Veuillez sélectionner un trajet avant de lancer la simulation.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
		
		// Utiliser la méthode pour trier les checkpoints
        checkpoints = Outils.donneCheckpointsTriesParId(pourTrajet: trajet)
		
        carte.removeAnnotations(carte.annotations)
        carte.removeOverlays(carte.overlays)
		
        currentCheckpointIndex = 0

        var coordinates: [CLLocationCoordinate2D] = []
        
		for checkpoint in checkpoints {
            let annotation = MKPointAnnotation()
            annotation.title = checkpoint.label
            annotation.coordinate = CLLocationCoordinate2D(latitude: checkpoint.x, longitude: checkpoint.y)
            carte.addAnnotation(annotation)
            coordinates.append(annotation.coordinate)
        }
		
		if let userLocation = locationManager.location {
			let userCoordinate = userLocation.coordinate
			coordinates.insert(userCoordinate, at: 0)
			let userAnnotation = MKPointAnnotation()
			userAnnotation.title = "Vous êtes ici"
			userAnnotation.coordinate = userCoordinate
			carte.addAnnotation(userAnnotation)

			if let firstCheckpoint = checkpoints.first {
				calculerRoute(from: userCoordinate, to: CLLocationCoordinate2D(latitude: firstCheckpoint.x, longitude: firstCheckpoint.y))
			}
		}

        if checkpoints.count > 1 {
			
			// "checkpoints.count - 1" si c'est l'iPhone 13
			// "checkpoints.count" si c'est l'iPhone 12
            for i in 0..<(checkpoints.count) { // testé sur l'iPhone 12
                calculerRoute(from: coordinates[i], to: coordinates[i + 1])
				print("[principaleVC]: \(i)/\(checkpoints.count)")
            }
        }

        nbTotalCheckpoints.text = "\(checkpoints.count)"
        distanceProchainCheckpointLab.text = ""

        print("[principaleVC]: Simulation lancée avec \(checkpoints.count) checkpoints affichés.")
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
        }
    }

    // MARK: Localisation en temps réel
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		carte.removeAnnotations(carte.annotations)
		nbCheckpointsLab.text = "0"
		guard let location = locations.last else { return }

        let vitesse = location.speed
        let vitesseKmH = max(vitesse * 3.6, 0)
        vitesseUtilisateurLab.text = String(format: "%.1f km/h", vitesseKmH)

        
		userAnnotation = MKPointAnnotation()
		userAnnotation?.title = "Vous êtes ici"
		userAnnotation?.coordinate = location.coordinate
		
		

        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 200, longitudinalMeters: 200)
        

        if currentCheckpointIndex < checkpoints.count {
            let nextCheckpoint = checkpoints[currentCheckpointIndex]
			AppDelegate.nextCheckpoint = nextCheckpoint
            let checkpointLocation = CLLocation(latitude: nextCheckpoint.x, longitude: nextCheckpoint.y)
            let distance = location.distance(from: checkpointLocation)

            distanceProchainCheckpointLab.text = String(format: "%.2f m", distance)

            if distance < 10.0 {
                currentCheckpointIndex += 1
                nbCheckpointsLab.text = "\(currentCheckpointIndex)"
                if currentCheckpointIndex >= checkpoints.count {
                    distanceProchainCheckpointLab.text = "Trajet terminé ! 🎉"
                } else if currentCheckpointIndex < checkpoints.count {
					calculerRoute(from: location.coordinate, to: CLLocationCoordinate2D(latitude: checkpoints[currentCheckpointIndex].x, longitude: checkpoints[currentCheckpointIndex].y))
				}
            }
        }
		
		if AppDelegate.nextCheckpoint != nil {
			updateDistanceNotification()
		}
		
		carte.addAnnotation(userAnnotation!)
		carte.setRegion(region, animated: true)
    }

    // MARK: Gestion des segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pickTrajet" {
            let secondControleur = segue.destination as! choixTrajet
            secondControleur.delegate = self
        }
    }
	
	// MARK: procédure principale de notification
	func updateDistanceNotification() {
		let checkpointLocation = CLLocation(latitude: AppDelegate.nextCheckpoint!.x, longitude: AppDelegate.nextCheckpoint!.y)
		
		let userLocation = locationManager.location
		
		let distance = calculateDistance(from: userLocation!, to: checkpointLocation)
		notifieUtilisateur(distance: distance)
		
	}

	// MARK: Distance utilisateur-checkpoint
	func calculateDistance(from userLocation: CLLocation, to checkpoint: CLLocation) -> CLLocationDistance {
		return userLocation.distance(from: checkpoint)
	}

	// MARK: Crée une notification
	func notifieUtilisateur(distance: CLLocationDistance) {
		let content = UNMutableNotificationContent()
		content.title = "Distance jusqu'au prochain checkpoint"
		content.body = "Vous êtes à \(Int(distance)) mètres du prochain checkpoint."
		content.sound = .default

		// Définir le déclencheur
		let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

		// Créer la requête de notification
		let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

		// Ajouter la requête au centre de notifications
		let center = UNUserNotificationCenter.current()
		center.add(request) { error in
			if let error = error {
				print("[AppDelegate]: Erreur lors de l'ajout de la requête de notification: \(error)")
			}
		}
		
		print("[principaleVC]: Ajout de la notification")
	}

	// MARK: Méthode appelée lorsque l'utilisateur appuie sur la notification
	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		let userInfo = response.notification.request.content.userInfo

		if let customData = userInfo["customData"] as? String {
			print("Custom data received: \(customData)")
		}

		// Gérer l'action de la notification
		switch response.actionIdentifier {
		case UNNotificationDefaultActionIdentifier:
			// Action par défaut
			print("Default identifier")
		case UNNotificationDismissActionIdentifier:
			// Action de rejet
			print("Dismiss identifier")
		default:
			break
		}

		completionHandler()
	}
}

// MARK: Mettre à jour textes
extension principaleVC: SelectionTrajet {
    func pickTrajet() {
        message.text = "Trajet \(AppDelegate.currentTrajet?.label ?? "Inconnu") sélectionné !"
        nbTotalCheckpoints.text = "\(AppDelegate.currentTrajet?.ses_checkpoints?.count ?? 0)"
        print("[principaleVC]: Trajet Sélectionné !")
    }
}

// MARK: Dessiner les points et les routes sur la carte
extension principaleVC: MKMapViewDelegate {
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

