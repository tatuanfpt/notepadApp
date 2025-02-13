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
    var onNotesUpdated: (() -> Void)? { get set }
    func loadMoreNotes()
    func numberOfNotes() -> Int
    func note(at index: Int) -> NoteModel?
    var totalNotesCount: Int { get set }
    var sortAscending: Bool { get set }
}

final class NotesViewModel: NSObject, NotesViewModelProtocol, NSFetchedResultsControllerDelegate {
    private let coreDataManager: CoreDataManagerProtocol
    private let logger: LoggerProtocol
    var onError: ((String) -> Void)?
    private var fetchedResultsController: NSFetchedResultsController<NoteModel>!
    var onNotesUpdated: (() -> Void)?
    private var currentBatchSize = 20 // Number of notes to fetch per batch
    internal var totalNotesCount = 0 // Track total notes
    var sortAscending: Bool = false { // Default to newest first
        didSet {
            updateSortDescriptors()
        }
    }
    // Dependency Injection
    
    init(coreDataManager: CoreDataManagerProtocol = CoreDataManager.shared,
         logger: LoggerProtocol = ConsoleLogger()) {
        self.coreDataManager = coreDataManager
        self.logger = logger
        super.init()
        calculateTotalNotesCount()
        setupFetchedResultsController()
    }
    
    private func setupFetchedResultsController() {
        let request = NoteModel.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdTime", ascending: sortAscending)]
        request.fetchBatchSize = currentBatchSize
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: coreDataManager.context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Failed to initialize FRC: \(error)")
        }
    }
    
    private func updateSortDescriptors() {
        fetchedResultsController.fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "createdTime", ascending: sortAscending)
        ]
        reloadData()
    }
    
    private func reloadData() {
        do {
            try fetchedResultsController.performFetch()
            onNotesUpdated?()
        } catch {
            print("Failed to reload data: \(error)")
        }
    }
    
    // Calculate total notes for infinite scroll logic
    private func calculateTotalNotesCount() {
        let request = NSFetchRequest<NSNumber>(entityName: "NoteModel")
        request.resultType = .countResultType
        do {
            totalNotesCount = try coreDataManager.context.count(for: request)
        } catch {
            totalNotesCount = 0
        }
    }
    
    func loadMoreNotes() {
        guard numberOfNotes() < totalNotesCount else { return } // Fix: Don't load if all notes are fetched
        
        currentBatchSize += 20
        fetchedResultsController.fetchRequest.fetchLimit = currentBatchSize
        reloadData()
        calculateTotalNotesCount() // Recalculate after loading
    }
    
    func numberOfNotes() -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func note(at index: Int) -> NoteModel? {
        return fetchedResultsController.fetchedObjects?[index]
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        onNotesUpdated?()
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
        coreDataManager.context.performAndWait { // Use performAndWait
            let newNote = NoteModel(context: coreDataManager.context)
            newNote.content = content
            newNote.createdTime = Date()
            newNote.lastEditTime = Date()
            saveContext() // Save immediately
        }
    }
    
    func deleteNote(_ note: NoteModel) {
        coreDataManager.context.delete(note)
        saveContext()
    }
}




