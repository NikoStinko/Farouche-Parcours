//
//  AppDelegate.swift
//  ProjetCoursesVoitures
//
//  Created by Nodewiz on 05/12/2024.
//

import UIKit
import CoreData
import CoreLocation
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {

	public static var currentUser: UtilisateurMO? = nil

	private var locationManager = CLLocationManager()
	private var userLocation: CLLocation? = nil

	public static var userListeTrajets : [TrajetMO] = []
	public static var allUsersTrajets : [[TrajetMO]] = []
	public static var currentTrajet: TrajetMO? = nil
	public static var allUsers : [UtilisateurMO] = []
	
	public static var nextCheckpoint: CheckPointMO? = nil
	
	public static var lesOptions: AppOptions? = nil
	
	public static var couleurVoiture: UIColor? = nil

	// MARK: début du programme
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		
		// charger les options système
		AppDelegate.lesOptions = OptionsManager.shared.lireLesOptions()
		if AppDelegate.lesOptions != nil {
			AppDelegate.loadAndApplyOptions(AppDelegate.lesOptions)
		} else {
			AppDelegate.lesOptions = AppOptions(theme: "light", notificationsEnabled: true, locationServicesEnabled: true, dataSavingModeEnabled: true, useWebService: true)
			AppDelegate.loadAndApplyOptions(AppDelegate.lesOptions)
			print("[AppDelegate]: !!! Paramètres par défaut choisis !!!")
		}
		
		
		// localisation de l'utilisateur
		if AppDelegate.lesOptions?.locationServicesEnabled == true {
			locationManager.delegate = self
			locationManager.requestWhenInUseAuthorization()
			locationManager.startUpdatingLocation()
		}
		print("[AppDelegate]: Status des services de localisation : \(CLLocationManager.locationServicesEnabled())")

		let objLocationManager = CLLocationManager()
		objLocationManager.delegate = self
		objLocationManager.startUpdatingLocation()

		// chargement des listes statiques
		AppDelegate.allUsers = Outils.donneTousLesUtilisateurs()
		print("[AppDelegate]: \(AppDelegate.allUsers.count) utilisateur(s) chargé(s) !")

		// définir un utilisateur par défaut
		if !AppDelegate.allUsers.isEmpty {
			AppDelegate.setCurrentUser(AppDelegate.allUsers.first!)
			
			// Couleur de la voiture
			AppDelegate.couleurVoiture = Outils.donneCouleurVoiture((AppDelegate.currentUser?.sa_voiture?.couleur)!)
			print("[AppDelegate]: Couleur de la voiture : \(String(describing: AppDelegate.couleurVoiture))")
		} else {
			print("[AppDelegate]: Aucun utilisateur trouvé !")
		}

		// Configurer les notifications
		if AppDelegate.lesOptions?.notificationsEnabled == true {
			UNUserNotificationCenter.current().delegate = self
		} else {
			print("[AppDelegate]: Notifications désactivées dans l'application.")
		}
		UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
			if granted {
				print("[AppDelegate]: Permission de notifications acceptée.")
			} else {
				print("[AppDelegate]: Permission de notifications refusée.")
			}
		}
		
		return true
	}

	public static func setCurrentUser(_ utilisateur: UtilisateurMO) {
		AppDelegate.currentUser = utilisateur
		AppDelegate.userListeTrajets = Outils.donneTousLesTrajetsDUnUtilisateur(utilisateur)
		print("[AppDelegate]: Utilisateur connecté: \(utilisateur.pseudo ?? "Inconnu")")
		print("[AppDelegate]: \(AppDelegate.userListeTrajets.count) trajet(s) chargé(s) pour cet utilisateur.")
	}

	public static func logoutCurrentUser() {
		AppDelegate.currentUser = nil
		AppDelegate.userListeTrajets = []
		print("[AppDelegate]: Utilisateur déconnecté.")
	}

	// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
		// Called when the user discards a scene session.
	}

	// MARK: - Core Data stack
	lazy var persistentContainer: NSPersistentContainer = {
		let container = NSPersistentContainer(name: "ProjetCoursesVoitures")
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error as NSError? {
				fatalError("[AppDelegate]: Erreur non-résolue \(error), \(error.userInfo)")
			}
		})
		return container
	}()

	// MARK: - Core Data Saving support

	func saveContext() {
		let context = persistentContainer.viewContext
		if context.hasChanges {
			// sauvegarder le contexte
			if ((AppDelegate.lesOptions?.dataSavingModeEnabled) != nil) {
				do {
					try context.save()
				} catch {
					let nserror = error as NSError
					fatalError("[AppDelegate]: Erreur \(nserror), \(nserror.userInfo)")
				}
			}
		}
	}
	
	// MARK: Changer le thème
	public static func changeTheme(to theme: String) {
		if theme == "dark" {
			for window in UIApplication.shared.windows {
				window.overrideUserInterfaceStyle = .dark
			}
		} else {
			for window in UIApplication.shared.windows {
				window.overrideUserInterfaceStyle = .light
			}
		}
	}
	
	// MARK: - Charger et appliquer les options
	public static func loadAndApplyOptions(_ lesOptions: AppOptions?) {
		AppDelegate.changeTheme(to: lesOptions!.theme)
	}
}
