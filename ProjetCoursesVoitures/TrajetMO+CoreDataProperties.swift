//
//  TrajetMO+CoreDataProperties.swift
//  ProjetCoursesVoitures
//
//  Created by Nodewiz on 11/12/2024.
//
//

import Foundation
import CoreData
import UIKit


extension TrajetMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TrajetMO> {
        return NSFetchRequest<TrajetMO>(entityName: "Trajet")
    }

    @NSManaged public var id: Int64
    @NSManaged public var label: String?
    @NSManaged public var nom: String?
    @NSManaged public var sesCheckPoints: Int64
    @NSManaged public var son_utilisateur: UtilisateurMO?
    @NSManaged public var ses_checkpoints: NSSet?

}

// MARK: Generated accessors for ses_checkpoints
extension TrajetMO {

    @objc(addSes_checkpoints:)
    @NSManaged public func addToSes_checkpoints(_ values: NSSet)

    @objc(removeSes_checkpoints:)
    @NSManaged public func removeFromSes_checkpoints(_ values: NSSet)

}
