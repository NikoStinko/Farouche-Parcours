//
//  Outils.swift
//  ProjetCoursesVoitures
//
//  Created by Nodewiz on 29/12/2024.
//

import Foundation
import CoreData
import UIKit


class Outils {
    // MARK: Donne le contexte du magasin persistant dans l'objet AppDelegate
    public static func donneContexte() -> NSManagedObjectContext {
        let objAppDelegate = UIApplication.shared.delegate as! AppDelegate
        let magasinPersistent = objAppDelegate.persistentContainer
        let leContexte = magasinPersistent.viewContext
        print("[Outils]: Contexte appelé")
        return leContexte
    }
    
	
    // MARK: Trie des checkpoints avec un algo "Tri Rapide" récursif
    public static func quickSort(_ checkpoints: [CheckPointMO]) -> [CheckPointMO] {
        let nombreCheckpoints = checkpoints.count
        
        if nombreCheckpoints == 1 {
            return checkpoints
        } else {
            let pivot = checkpoints.last!
            
            var grand : [CheckPointMO] = []
            var petit : [CheckPointMO] = []
            
            for checkpoint in checkpoints {
                if checkpoint.id > pivot.id {
                    grand.append(checkpoint)
                } else {
                    petit.append(checkpoint)
                }
            }
            
            return Outils.quickSort(petit) + [pivot] + Outils.quickSort(grand)
        }
    }
	
	// MARK: Donne un objet couleur pour la voiture sur la carte
	public static func donneCouleurVoiture(_ couleur: String) -> UIColor {
		switch couleur.lowercased() {
		case "blanc":
			return UIColor(white: 1.0, alpha: 1.0) // Couleur blanche
		case "gris foncé":
			return UIColor(red: 0.33, green: 0.33, blue: 0.33, alpha: 1.0) // Gris foncé
		case "noir":
			return UIColor(white: 0.0, alpha: 0.7) // Noir
		case "gris clair":
			return UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 0.7) // Gris clair
		case "bleu":
			return UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.7) // Bleu
		case "rouge":
			return UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0) // Rouge
		case "beige":
			return UIColor(red: 0.59, green: 0.41, blue: 0.31, alpha: 1.0) // Bbeige
		case "marron":
			return UIColor(red: 0.59, green: 0.41, blue: 0.31, alpha: 1.0) // Marron
		case "vert":
			return UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0) // Vert
		case "jaune":
			return UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0) // Jaune
		default:
			return UIColor.gray // Couleur par défaut si non reconnue
		}
	}
	
	// MARK: Donne tous les utilisateurs
	public static func donneTousLesUtilisateurs() -> [UtilisateurMO] {
		let leContexte = Outils.donneContexte()
		
		let fetchRequest: NSFetchRequest<UtilisateurMO> = UtilisateurMO.fetchRequest()
		
		do {
			let results = try leContexte.fetch(fetchRequest)
			return results
		} catch {
			print("Erreur : \(error)")
			return []
		}
	}
	
	// MARK: Donne un utilisateur à partir d'un Pseudo
	public static func donneLUtilisateur(_ nom: String) -> [UtilisateurMO] {
		let leContexte = Outils.donneContexte()
		
		let fetchRequest: NSFetchRequest<UtilisateurMO> = UtilisateurMO.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "pseudo == %@", nom)
		
		
		do {
			let results = try leContexte.fetch(fetchRequest)
			return results
		} catch {
			print("Erreur : \(error)")
			return []
		}
	}
	
	// MARK: Donne les checkpoints triés d'un trajet par son identifiant
	public static func donneCheckpointsTriesParId(pourTrajet trajet: TrajetMO) -> [CheckPointMO] {
		if let checkpointsSet = trajet.ses_checkpoints as? Set<CheckPointMO> {
			let sortedCheckpoints = checkpointsSet.sorted(by: { $0.id < $1.id })
			return sortedCheckpoints
		}
		return []
	}
	
	// MARK: Donne tous les trajets d'un utilisateur donné
	public static func donneTousLesTrajetsDUnUtilisateur(_ user: UtilisateurMO) -> [TrajetMO] {
		let leContexte = Outils.donneContexte()
		let fetchRequest: NSFetchRequest<TrajetMO> = TrajetMO.fetchRequest()

		fetchRequest.predicate = NSPredicate(format: "son_utilisateur.pseudo == %@", user.pseudo!)

		do {
			let trajets = try leContexte.fetch(fetchRequest)

			// Trier les checkpoints de chaque trajet par leur attribut "id"
			for trajet in trajets {
				let sortedCheckpoints = donneCheckpointsTriesParId(pourTrajet: trajet)
				trajet.ses_checkpoints = Set(sortedCheckpoints) as NSSet
			}

			return trajets
		} catch {
			print("Erreur : (error)")
			return []
		}
	}
}
