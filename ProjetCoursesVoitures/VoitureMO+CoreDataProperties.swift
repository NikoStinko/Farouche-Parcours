//
//  VoitureMO+CoreDataProperties.swift
//  ProjetCoursesVoitures
//
//  Created by Nodewiz on 11/12/2024.
//
//

import Foundation
import CoreData
import UIKit


extension VoitureMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<VoitureMO> {
        return NSFetchRequest<VoitureMO>(entityName: "Voiture")
    }

    @NSManaged public var couleur: String?
    @NSManaged public var idVoiture: Int64
    @NSManaged public var marque: String?
    @NSManaged public var nom: String?
    @NSManaged public var son_utilisateur: UtilisateurMO?

}

