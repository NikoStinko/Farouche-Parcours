//
//  choixTrajet.swift
//  ProjetCoursesVoitures
//
//  Created by Nodewiz on 14/12/2024.
//

import UIKit

class choixTrajet: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var maTable: UITableView!
    weak var delegate: SelectionTrajet?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        maTable.dataSource = self
        maTable.delegate = self
    }
    
    // MARK: Config de la Table View
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        AppDelegate.userListeTrajets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "pickerCell", for: indexPath)
        cell.textLabel?.text = AppDelegate.userListeTrajets[indexPath.row].label
        cell.detailTextLabel?.text = AppDelegate.userListeTrajets[indexPath.row].nom
        
        return cell
    }
    
    // MARK: Sélectionner un trajet
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // mettre à jour le trajet en cours
        AppDelegate.currentTrajet = AppDelegate.userListeTrajets[indexPath.row]
        
        // notifier delegate
        delegate?.pickTrajet()
        
        // fermer la vue
        self.dismiss(animated: true, completion: nil)
    }

}
