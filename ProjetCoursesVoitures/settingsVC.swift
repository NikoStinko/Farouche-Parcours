//
//  settingsVC.swift
//  ProjetCoursesVoitures
//
//  Created by Nodewiz on 05/12/2024.
//

import UIKit
import Foundation

// MARK: Structure d'options
struct AppOptions: Codable {
	var theme: String
	var notificationsEnabled: Bool
	var locationServicesEnabled: Bool
	var dataSavingModeEnabled: Bool
	var useWebService: Bool
}

// MARK: Option Manager
class OptionsManager {
	static let shared = OptionsManager()

	private let fileName = "options.json"

	func lireLesOptions() -> AppOptions? {
		let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
		do {
			let data = try Data(contentsOf: fileURL)
			let decoder = JSONDecoder()
			let options = try decoder.decode(AppOptions.self, from: data)
			print("[settingsVC]: Fichier d'options lu !")
			return options
		} catch {
			print("[settingsVC]: Erreur de lecture du fichier : \(error)")
			
			return nil
		}
	}

	func ecrireLesOptions(_ options: AppOptions) {
		let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
		do {
			let encoder = JSONEncoder()
			let data = try encoder.encode(options)
			try data.write(to: fileURL)
			print("[settingsVC]: Fichier d'options écrit !")
		} catch {
			print("[settingsVC]: Erreur d'écriture du fichier: \(error)")
		}
	}

	private func getDocumentsDirectory() -> URL {
		let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		return paths.first!
	}
}

// MARK: Contrôleur SettingsView
class settingsVC: UIViewController {
	@IBOutlet weak var themeSwitch: UISwitch!
	@IBOutlet weak var notificationsSwitch: UISwitch!
	@IBOutlet weak var soundEffectsSwitch: UISwitch!
	@IBOutlet weak var locationServicesSwitch: UISwitch!
	@IBOutlet weak var dataSavingModeSwitch: UISwitch!
	@IBOutlet weak var useWebServiceSwitch: UISwitch!
	@IBOutlet weak var boutonAppliquer: UIButton!
	@IBOutlet weak var boutonReinitialiser: UIButton!
	
	private var options = OptionsManager.shared.lireLesOptions() ?? AppOptions(theme: "light", notificationsEnabled: true, locationServicesEnabled: true, dataSavingModeEnabled: true, useWebService: true)

	override func viewDidLoad() {
		super.viewDidLoad()

		// Charger les options sauvegardées
		chargerLesOptions()
		appliquerLesOptions()
	}

	// MARK: Action des switch
	@IBAction func themeSwitchChanged(_ sender: UISwitch) {
		self.options.theme = sender.isOn ? "dark" : "light"
		
		// Appeler la méthode de changement de thème dans AppDelegate
		AppDelegate.changeTheme(to: self.options.theme)
	}

	@IBAction func notificationsSwitchChanged(_ sender: UISwitch) {
		self.options.notificationsEnabled = sender.isOn
	}

	@IBAction func locationServicesSwitchChanged(_ sender: UISwitch) {
		self.options.locationServicesEnabled = sender.isOn
	}

	@IBAction func dataSavingModeSwitchChanged(_ sender: UISwitch) {
		self.options.dataSavingModeEnabled = sender.isOn
	}

	@IBAction func useWebServiceSwitchChanged(_ sender: UISwitch) {
		self.options.useWebService = sender.isOn
	}

	@IBAction func boutonAppliquerPressed(_ sender: UIButton) {
		// Appliquer les options sauvegardées
		OptionsManager.shared.ecrireLesOptions(self.options)
		appliquerLesOptions()
		print("[settingsVC]: Options appliquées avec succès !")
	}

	@IBAction func boutonReinitialiserPressed(_ sender: UIButton) {
		// Réinitialiser les options
		reinitialiserLesOptions()
	}

	func chargerLesOptions() {
		themeSwitch.isOn = (self.options.theme == "dark")
		notificationsSwitch.isOn = self.options.notificationsEnabled
		locationServicesSwitch.isOn = self.options.locationServicesEnabled
		dataSavingModeSwitch.isOn = self.options.dataSavingModeEnabled
		useWebServiceSwitch.isOn = self.options.useWebService
	}

	// MARK: Appliquer les options sauvegardées
	func appliquerLesOptions() {
		if self.options.theme == "dark" {
			overrideUserInterfaceStyle = .dark
		} else {
			overrideUserInterfaceStyle = .light
		}
	}

	// MARK: Réinitialiser les options
	func reinitialiserLesOptions() {
		let defaultOptions = AppOptions(theme: "light", notificationsEnabled: true, locationServicesEnabled: true, dataSavingModeEnabled: true, useWebService: false)
		OptionsManager.shared.ecrireLesOptions(defaultOptions)
		chargerLesOptions()
	}
}
