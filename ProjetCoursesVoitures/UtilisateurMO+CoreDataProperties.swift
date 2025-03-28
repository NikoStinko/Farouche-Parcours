//
//  UtilisateurMO+CoreDataProperties.swift
//  ProjetCoursesVoitures
//
//  Created by Nodewiz on 11/12/2024.
//
//

import Foundation
import CoreData
import UIKit


extension UtilisateurMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UtilisateurMO> {
        return NSFetchRequest<UtilisateurMO>(entityName: "Utilisateur")
    }

    @NSManaged public var mdp: String?
    @NSManaged public var nom: String?
    @NSManaged public var prenom: String?
    @NSManaged public var pseudo: String?
    @NSManaged public var sa_voiture: VoitureMO?
    @NSManaged public var ses_trajets: NSSet?

}

// MARK: Generated accessors for ses_trajets
extension UtilisateurMO {

    @objc(addSes_trajets:)
    @NSManaged public func addToSes_trajets(_ values: NSSet)

    @objc(removeSes_trajets:)
    @NSManaged public func removeFromSes_trajets(_ values: NSSet)

}
