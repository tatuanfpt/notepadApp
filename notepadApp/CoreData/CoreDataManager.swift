//
//  CoreDataManager.swift
//  notepadApp
//
//  Created by TuanTa on 8/2/25.
//

import UIKit
import CoreData

protocol CoreDataManagerProtocol {
    func saveContext()
    var context: NSManagedObjectContext { get }
}

class CoreDataManager: CoreDataManagerProtocol {
    static let shared = CoreDataManager()
    let persistentContainer: NSPersistentContainer
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "NoteList")
        persistentContainer.loadPersistentStores { (_, error) in
            if let error = error {
                fatalError("Error loading persistent stores: \(error)")
            }
        }
    }
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        do {
            try context.save()
        } catch {
            print("Save error: \(error)")
        }
    }
}

extension NoteModel {
    static func fetchRequest() -> NSFetchRequest<NoteModel> {
        return NSFetchRequest<NoteModel>(entityName: "NoteModel")
    }
}

// Logger.swift
protocol LoggerProtocol {
    func logError(_ message: String)
}

struct ConsoleLogger: LoggerProtocol {
    func logError(_ message: String) {
        print("ERROR: \(message)")
    }
}

