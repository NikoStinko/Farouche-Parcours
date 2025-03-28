//
//  ajouterModifierSupprParcoursTVC.swift
//  ProjetCoursesVoitures
//
//  Created by Nodewiz on 05/12/2024.
//

import UIKit
import CoreLocation

// protocoles au bon fonctionnement du rechargement
protocol TrajetCreationDelegate: AnyObject {
    func ajouteTrajet()
}

protocol TrajetModificationDelegate: AnyObject {
    func modifTrajet()
}

// définition de la classe
class ajouterModifierSupprParcoursTVC: UITableViewController, CLLocationManagerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Config de la table
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AppDelegate.userListeTrajets.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "parcoursUtilisateurs", for: indexPath)
        
        cell.textLabel?.text = AppDelegate.userListeTrajets[indexPath.row].label
        cell.detailTextLabel?.text = AppDelegate.userListeTrajets[indexPath.row].nom

        return cell
        
    }
    
    // MARK: Supprimer une ligne en swipant vers la gauche
    // fonctionne sur 1 ligne à la fois
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let leContexte = Outils.donneContexte()
            leContexte.delete(AppDelegate.userListeTrajets[indexPath.row])
            
			// sauvegarder le contexte
			if ((AppDelegate.lesOptions?.dataSavingModeEnabled) != nil) {
            	do {
                	try leContexte.save()
                	AppDelegate.userListeTrajets.remove(at: indexPath.row)
                	tableView.deleteRows(at: [indexPath], with: .fade)
                	print("[AMSParcoursTVC]: Trajet supprimé !")
            	} catch let error as NSError {
                	print("[AMSParcoursTVC]: Erreur : \(error.localizedDescription)")
            	}
			}
        }
    }
    
    // MARK: - Pointage des segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "selectionTrajet"  {
            if let indexPath = tableView.indexPathForSelectedRow {
                let trajet = AppDelegate.userListeTrajets[indexPath.row]
                let secondControleur = segue.destination as! ModifTrajet
                secondControleur.trajet = trajet
                secondControleur.delegate = self
            }
        } else if segue.identifier == "creerTrajet" {
            let secondControleur = segue.destination as! CreerTrajet
            secondControleur.delegate = self
        }
    }
    
    // MARK: Afficher le menu pour ajouter un trajet
    @IBAction func tapSurAjouterTrajet(_ sender: Any) {
        performSegue(withIdentifier: "creerTrajet", sender: nil)
    }
}

// MARK: Recharger la vue de la table [AJOUTER]
extension ajouterModifierSupprParcoursTVC: TrajetCreationDelegate {
    func ajouteTrajet() {
        // appelée après l'ajout d'un trajet
        tableView.reloadData()
    }
}

// MARK: Recharger la vue de la table [MODIFIER]
extension ajouterModifierSupprParcoursTVC: TrajetModificationDelegate {
    func modifTrajet() {
        // appelé après modification d'un trajet, recharge uniquement la ligne modifiée
        let selectedIndex = tableView.indexPathForSelectedRow?.row
        tableView.reloadRows(at: [IndexPath(row: selectedIndex!, section: 0)], with: .automatic)
    }
}
