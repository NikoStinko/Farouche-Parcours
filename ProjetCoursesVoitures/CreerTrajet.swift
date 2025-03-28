//
//  CreerTrajet.swift
//  ProjetCoursesVoitures
//
//  Created by Nodewiz on 12/12/2024.
//

import UIKit

// structures outils pour charger des trajets
struct Trajet: Codable {
	let nom: String
	let label: String
	let checkpoints: [Checkpoint]
}

struct Checkpoint: Codable {
	let id: Int64
	let label: String
	let x: Double
	let y: Double
}

class CreerTrajet: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
	@IBOutlet weak var urlTextField: UITextField!
	var checkpoints : [[Any]] = []
    weak var delegate: TrajetCreationDelegate?
    
    @IBOutlet weak var nomTF: UITextField!
    @IBOutlet weak var labelTF: UITextField!
    @IBOutlet weak var maTable: UITableView!
    @IBOutlet weak var currentCPLab: UITextField!
    @IBOutlet weak var currentCPX: UITextField!
    @IBOutlet weak var currentCPY: UITextField!
    
    override func viewDidLoad() {
        maTable.dataSource = self
        maTable.delegate = self
    }
    
    // MARK: Gestion de la table
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return checkpoints.count
    }
    
    // MARK: Gestion de la vue
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "createCheckpointCell", for: indexPath)
        cell.textLabel?.text = (checkpoints[indexPath.row][0] as! String)
        cell.detailTextLabel?.text = "[\(checkpoints[indexPath.row][1]) , \(checkpoints[indexPath.row][2])]"
        
        return cell
    }
    
    // MARK: Supprimer une ligne en swipant vers la gauche
    // fonctionne sur 1 ligne à la fois
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            checkpoints.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    // MARK: Boutons +
    @IBAction func addRow(_ sender: UIButton) {
        
        guard let label = currentCPLab.text, !label.isEmpty,
              let x = Double(currentCPX.text ?? ""),
        let y = Double(currentCPY.text ?? "") else {
            print("[CreerTrajet]: Erreur: Veuillez remplir tous les champs pour ajouter un checkpoint.")
            return
        }
        
        let unCheckPoint: [Any] = [label, x, y]
        
        
        checkpoints.append(unCheckPoint)
        let newIndexPath = IndexPath(row: checkpoints.count - 1, section: 0)
        maTable.insertRows(at: [newIndexPath], with: .automatic)
    }
    
    // MARK: Bouton Sauvegarder
    @IBAction func tapSurSauver(_ sender: Any) {
        guard let nom = nomTF.text, !nom.isEmpty,
              let label = labelTF.text, !label.isEmpty else {
            print("[CreerTrajet]: Erreur : Le nom ou le label est vide.")
            return
        }

        let leContext = Outils.donneContexte()
        
        let unTrajet = TrajetMO(context: leContext)
        
        unTrajet.nom = nomTF.text
        unTrajet.label = labelTF.text
        unTrajet.son_utilisateur = AppDelegate.currentUser
        
        // caster le tableau de checkpoints en Set pour stocker correctement
        // les checkpoints dans CoreData
        var checkPointsExistants = unTrajet.ses_checkpoints as? Set<CheckPointMO>
        
        for checkpoint in checkpoints {
            let unCheckpoint = CheckPointMO(context: leContext)
            
            unCheckpoint.id = Int64(checkPointsExistants!.count + 1)
            unCheckpoint.label = (checkpoint[0] as! String)
            unCheckpoint.x = checkpoint[1] as! Double
            unCheckpoint.y = checkpoint[2] as! Double
            unCheckpoint.son_trajet = unTrajet
            
            checkPointsExistants!.insert(unCheckpoint)
            print("[CreerTrajet]: \(unCheckpoint.label ?? "Inconnu") : \(unCheckpoint.x) / \(unCheckpoint.y)")
        }
        
        // caster le tableau de checkpoints en NSSet pour les utiliser
        // dans AppDelegate
        unTrajet.ses_checkpoints = NSSet(set: checkPointsExistants!)
        
        AppDelegate.userListeTrajets.append(unTrajet)
        
		// sauvegarder le contexte
		if ((AppDelegate.lesOptions?.dataSavingModeEnabled) != nil) {
        	do {
            	try leContext.save()
            	print("[CreerTrajet]: Trajet ajouté !")
        	} catch let error as NSError {
            	print("[CreerTrajet]: Erreur dans la création d'un trajet : \(error)")
       		}
		}
		
        // notifier delegate
        delegate?.ajouteTrajet()
        
        // fermer cette vue
        self.dismiss(animated: true, completion: nil)
    }
	
	
	// MARK: Charger depuis le web service
	@IBAction func chargerTrajetDepuisWebService(_ sender: Any) {
		guard let url = URL(string: urlTextField.text!) else {
			print("[CreerTrajet]: URL invalide.")
			return
		}
		
		let leContext = Outils.donneContexte()
		
		// Effectuer la requête réseau
		let session = URLSession.shared
		session.dataTask(with: url) { [self] data, response, error in
			if let error = error {
				print("[CreerTrajet]: Erreur lors de la requête - \(error.localizedDescription)")
				return
			}
			
			guard let data = data else {
				print("[CreerTrajet]: Pas de données reçues.")
				return
			}
			
			do {
				let decoder = JSONDecoder()
				print("[CreerTrajet]: Contenu récupéré : \(data)")
				let trajetData = try decoder.decode(Trajet.self, from: data)
				
				
				let unTrajet = TrajetMO(context: leContext)
				unTrajet.nom = trajetData.nom
				unTrajet.label = trajetData.label
				unTrajet.son_utilisateur = AppDelegate.currentUser
				
				
				var checkPointsExistants = unTrajet.ses_checkpoints as? Set<CheckPointMO> ?? []
				for checkpoint in trajetData.checkpoints {
					let unCheckpoint = CheckPointMO(context: leContext)
					unCheckpoint.id = Int64(checkPointsExistants.count + 1)
					unCheckpoint.label = checkpoint.label
					unCheckpoint.x = checkpoint.x
					unCheckpoint.y = checkpoint.y
					unCheckpoint.son_trajet = unTrajet
					
					checkPointsExistants.insert(unCheckpoint)
					print("[CreerTrajet]: Checkpoint ajouté - \(unCheckpoint.label ?? "Inconnu") : \(unCheckpoint.x), \(unCheckpoint.y)")
				}
				
				
				unTrajet.ses_checkpoints = NSSet(set: checkPointsExistants)
				
				AppDelegate.userListeTrajets.append(unTrajet)
				
				// Sauvegarder le contexte
				if AppDelegate.lesOptions?.dataSavingModeEnabled == true {
					do {
						try leContext.save()
						print("[CreerTrajet]: Trajet chargé et sauvegardé avec succès.")
					} catch let error as NSError {
						print("[CreerTrajet]: Erreur lors de la sauvegarde - \(error.localizedDescription)")
					}
				}
				
				// notifier delegate
				delegate?.ajouteTrajet()
				
				// fermer cette vue
				self.dismiss(animated: true, completion: nil)
			} catch {
				print("[CreerTrajet]: Erreur lors du décodage JSON - \(error.localizedDescription)")
			}
		}.resume()
	}
}
