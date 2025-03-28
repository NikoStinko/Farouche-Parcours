//
//  CheckPointMO+CoreDataProperties.swift
//  ProjetCoursesVoitures
//
//  Created by Nodewiz on 11/12/2024.
//
//

import Foundation
import CoreData
import UIKit

extension CheckPointMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CheckPointMO> {
        return NSFetchRequest<CheckPointMO>(entityName: "CheckPoint")
    }

    @NSManaged public var label: String?
    @NSManaged public var x: Double
    @NSManaged public var y: Double
    @NSManaged public var id: Int64
    @NSManaged public var son_trajet: TrajetMO?

}
