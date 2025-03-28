//
//  ModifTrajet.swift
//  ProjetCoursesVoitures
//
//  Created by Nodewiz on 12/12/2024.
//

import UIKit

class ModifTrajet: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var delegate: TrajetModificationDelegate?
    var trajet: TrajetMO?
    var checkpoints: [[Any]] = []
    
    @IBOutlet weak var maTable: UITableView!
    @IBOutlet weak var nomTF: UITextField!
    @IBOutlet weak var labelTF: UITextField!
    @IBOutlet weak var currentCPLab: UITextField!
    @IBOutlet weak var currentCPX: UITextField!
    @IBOutlet weak var currentCPY: UITextField!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        maTable.dataSource = self
        maTable.delegate = self
        
		// Charger le trajet importé par la segue
		if let trajet = trajet {
			nomTF.text = trajet.nom
			labelTF.text = trajet.label

			// Utiliser la méthode pour trier les checkpoints
			let sortedCheckpoints = Outils.donneCheckpointsTriesParId(pourTrajet: trajet)

			checkpoints = sortedCheckpoints.compactMap { checkpoint in
				return [checkpoint.label ?? "", checkpoint.x, checkpoint.y, checkpoint.id]
			}

			print("[ModifTrajet]: Trajet à modifier : \(checkpoints)")
		}
    }
    
    // MARK: Config de la table
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return checkpoints.count
    }
    
    // MARK: Config de chaque cellule
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "modifCheckpointCell", for: indexPath)
        let checkpoint = checkpoints[indexPath.row]
        
        cell.textLabel?.text = "\(checkpoint[3]). \(checkpoint[0])"
        cell.detailTextLabel?.text = "[\(checkpoint[1]), \(checkpoint[2])]"
        
        return cell
    }
    
    // MARK: Afficher les infos du trajet à modifier lors d'une sélection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCheckpoint = checkpoints[indexPath.row]
        currentCPLab.text = selectedCheckpoint[0] as? String
        currentCPX.text = "\(selectedCheckpoint[1])"
        currentCPY.text = "\(selectedCheckpoint[2])"
    }
    
    // MARK: Supprimer une ligne en swipant vers la gauche
    // fonctionne sur 1 ligne à la fois
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            checkpoints.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    // MARK: Ajouter un checkpoint
    @IBAction func addRow(_ sender: Any) {
        guard let label = currentCPLab.text, !label.isEmpty,
              let x = Double(currentCPX.text ?? ""),
        let y = Double(currentCPY.text ?? "") else {
            print("[ModifTrajet]: Erreur: Veuillez remplir tous les champs pour ajouter un checkpoint.")
            return
        }
        
        let unCheckpoint: [Any] = [label, x, y]
        checkpoints.append(unCheckpoint)
        
        let newIndexPath = IndexPath(row: checkpoints.count - 1, section: 0)
        maTable.insertRows(at: [newIndexPath], with: UITableView.RowAnimation.automatic)
    }
    
    // MARK: Mettre à jour une ligne
    @IBAction func modifierUnLigne(_ sender: Any) {
        guard let selectedIndex = maTable.indexPathForSelectedRow?.row else {
            print("[ModifTrajet]: Erreur: Aucun checkpoint sélectionné pour modif.")
            return
        }
        
        guard let label = currentCPLab.text, !label.isEmpty,
              let x = Double(currentCPX.text ?? ""),
              let y = Double(currentCPY.text ?? "") else {
                  print("[ModifTrajet]: Erreur: Veuillez remplir tous les champs pour modifier le checkpoint.")
                  return
              }
        
		checkpoints[selectedIndex] = [label, x, y, selectedIndex + 1]
        maTable.reloadRows(at: [IndexPath(row: selectedIndex, section: 0)], with: .automatic)
    }
    
    // MARK: Sauvegarder le trajet
    @IBAction func tapSurSauver(_ sender: Any) {
        guard let trajet = trajet else { return }
        
        trajet.nom = nomTF.text
        trajet.label = labelTF.text
        
        let leContext = Outils.donneContexte()
        
        var nouveauxCheckpoints = Set<CheckPointMO>()
        
        for checkpoint in checkpoints {
            let unCheckpoint = CheckPointMO(context: leContext)
            unCheckpoint.label = checkpoint[0] as? String
            unCheckpoint.x = checkpoint[1] as! Double
            unCheckpoint.y = checkpoint[2] as! Double
            unCheckpoint.son_trajet = trajet
            unCheckpoint.id = Int64(nouveauxCheckpoints.count + 1)
            nouveauxCheckpoints.insert(unCheckpoint)
        }
        
        trajet.ses_checkpoints = NSSet(set: nouveauxCheckpoints)
        
		// sauvegarder le contexte
		if ((AppDelegate.lesOptions?.dataSavingModeEnabled) != nil) {
			do {
				try leContext.save()
				delegate?.modifTrajet()
				print("[ModifTrajet]: Trajet modifié avec succès")
			} catch let error as NSError {
				print("[ModifTrajet]: Erreur lors de la sauvegarde du trajet : \(error.localizedDescription)")
			}
		}
        
        
        // fermer la vue
        self.dismiss(animated: true, completion: nil)
    }
}
