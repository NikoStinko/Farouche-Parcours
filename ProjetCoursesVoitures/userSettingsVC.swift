//
//  userSettingsVC.swift
//  ProjetCoursesVoitures
//
//  Created by Nodewiz on 12/12/2024.
//

import UIKit

class userSettingsVC: UIViewController {
    
	@IBOutlet weak var UNomTF: UITextField!
    @IBOutlet weak var UPrenomTF: UITextField!
    @IBOutlet weak var UPseudoTF: UITextField!
    @IBOutlet weak var UMdpTF: UITextField!
    @IBOutlet weak var VNomTF: UITextField!
    @IBOutlet weak var VMarqueTF: UITextField!
    @IBOutlet weak var VCouleurTF: UITextField!
    @IBOutlet weak var chargerUser: UITextField!
    @IBOutlet weak var chargerMDP: UITextField!
    @IBOutlet weak var labelInfo: UILabel!
	@IBOutlet weak var deconnexionBouton: UIButton!
	
	override func viewDidLoad() {
        super.viewDidLoad()
        UMdpTF.isSecureTextEntry = true
        chargerMDP.isSecureTextEntry = true
		VCouleurTF.placeholder = "blanc, bleu, ..."
		VMarqueTF.placeholder = "Audi, BMW, ..."
    }
    
    // MARK: Bouton pour cacher le mot de passe
    @IBAction func tapSurVoirOuCacher(_ sender: Any) {
        if UMdpTF.isSecureTextEntry == true {
            UMdpTF.isSecureTextEntry = false
        } else {
            UMdpTF.isSecureTextEntry = true
        }
    }
    
    // MARK: Charge un utilisateur selon le Pseudo et le MDP
    @IBAction func tapSurCharger(_ sender: Any) {
        let lePseudo : String = chargerUser.text!
        let leMDP : String = chargerMDP.text!
        let lUtilisateur: [UtilisateurMO] = Outils.donneLUtilisateur(lePseudo)
        if lUtilisateur[0].mdp == leMDP {
            AppDelegate.userListeTrajets = Outils.donneTousLesTrajetsDUnUtilisateur(lUtilisateur [0])
            labelInfo.text = "Utilisateur \(lePseudo) chargé avec succès !"
        } else {
            labelInfo.text = "Les champs entrés sont incorrects !"
        }
		
		deconnexionBouton.configuration?.title = "Se Déconnecter"
		deconnexionBouton.configuration?.image = UIImage(systemName: "")
    }
    
    // MARK: Ajoute un utilisateur
    @IBAction func tapSurAjouterUser(_ sender: Any) {
        let leContexte = Outils.donneContexte()
        
        // création des objets voiture et utilisateurs
        let objVoiture = VoitureMO(context: leContexte)
        objVoiture.nom = VNomTF.text
        objVoiture.marque = VMarqueTF.text
        objVoiture.couleur = VCouleurTF.text
        
        let objUtilisateur = UtilisateurMO(context: leContexte)
        objUtilisateur.nom = UNomTF.text
        objUtilisateur.prenom = UPrenomTF.text
        objUtilisateur.pseudo = UPseudoTF.text
        objUtilisateur.mdp = UMdpTF.text
        objUtilisateur.sa_voiture = objVoiture
        
        // sauvegarde du contexte
		if ((AppDelegate.lesOptions?.dataSavingModeEnabled) != nil) {
			do {
				try leContexte.save()
				print("Utilisateur sauvegardé avec succès !")
			} catch let error as NSError {
				print("Impossible de sauver le contexte pour ajouter un utilisateur : \(error)")
			}
		}
        
    }
	@IBAction func deconnecterUtilisateur(_ sender: Any) {
		AppDelegate.logoutCurrentUser()
		deconnexionBouton.configuration?.title = "Déconnecté"
		deconnexionBouton.configuration?.image = UIImage(systemName: "checkmark.seal")
	}
}
