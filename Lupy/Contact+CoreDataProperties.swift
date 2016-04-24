//
//  Contact+CoreDataProperties.swift
//  
//
//  Created by Agree Ahmed on 4/10/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Contact {

    @NSManaged var name: String?
    @NSManaged var phone: String?
    @NSManaged var username: String?

}
