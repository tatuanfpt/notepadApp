//
//  NotesViewModel.swift
//  notepadApp
//
//  Created by TuanTa on 8/2/25.
//

import UIKit
import CoreData

protocol NotesViewModelProtocol {
    func fetchNotes(sortAscending: Bool) -> [NoteModel]
    func addNote(content: String)
    func updateNote(_ note: NoteModel, newContent: String)
    func deleteNote(_ note: NoteModel)
    func fetchNotes(with predicate: NSPredicate?) -> [NoteModel]
    var onError: ((String) -> Void)? { get set }
}

final class NotesViewModel: NotesViewModelProtocol {
    private let coreDataManager: CoreDataManagerProtocol
    private let logger: LoggerProtocol
    var onError: ((String) -> Void)?
    
    // Dependency Injection
    
    init(coreDataManager: CoreDataManagerProtocol = CoreDataManager.shared,
         logger: LoggerProtocol = ConsoleLogger()) {
        self.coreDataManager = coreDataManager
        self.logger = logger
    }
    
    private func saveContext() {
        do {
            try coreDataManager.context.save()
        } catch {
            let errorMessage = "Save failed: \(error.localizedDescription)"
            logger.logError(errorMessage)
            onError?(errorMessage)
        }
    }
    
    // Update an existing note
    func updateNote(_ note: NoteModel, newContent: String) {
        note.content = newContent
        note.lastEditTime = Date()
        note.title = newContent.components(separatedBy: ".").first ?? "Untitled"
        saveContext()
    }
    
    func fetchNotes(sortAscending: Bool) -> [NoteModel] {
        let request = NoteModel.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdTime", ascending: sortAscending)]
        return executeFetch(request: request)
    }
    
    func fetchNotes(with predicate: NSPredicate?) -> [NoteModel] {
        let request = NoteModel.fetchRequest()
        request.predicate = predicate
        return executeFetch(request: request)
    }
    
    private func executeFetch(request: NSFetchRequest<NoteModel>) -> [NoteModel] {
        do {
            return try coreDataManager.context.fetch(request)
        } catch {
            onError?("Failed to fetch notes: \(error.localizedDescription)")
            return []
        }
    }
    
    func addNote(content: String) {
        coreDataManager.context.perform { [weak self] in
            let newNote = NoteModel(context: self?.coreDataManager.context ?? NSManagedObjectContext())
            newNote.content = content
            newNote.createdTime = Date()
            newNote.lastEditTime = Date()
            self?.saveContext()
        }
    }
    
    func deleteNote(_ note: NoteModel) {
        coreDataManager.context.delete(note)
        saveContext()
    }
}




