//
//  CoreDataStack.swift
//  notesapp
//
//  Created by Vladyslav Kolomiets on 5/24/19.
//  Copyright © 2019 Vladyslav Kolomiets. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
  // MARK: - Core Data stack
  
  lazy var persistentContainer: NSPersistentContainer = {
    
    let container = NSPersistentContainer(name: "Notes")
    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
      if let error = error as NSError? {
        
        fatalError("Unreseolved error \(error), \(error.userInfo)")
      }
    })
    return container
  }()
  
  // MARK: - Core Data Saving Support
  func saveContext() {
    let context = persistentContainer.viewContext
    if context.hasChanges {
      do {
        try context.save()
      } catch {
        let nserror = error as NSError
        fatalError("Unreseolved error \(nserror), \(nserror.userInfo)")
      }
    }
  }
}
