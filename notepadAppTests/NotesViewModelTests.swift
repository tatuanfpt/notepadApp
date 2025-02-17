//
//  CoreDataStackTest.swift
//  notepadAppTests
//
//  Created by TuanTa on 12/2/25.
//

// NotesViewModelTests.swift
import XCTest
import CoreData
@testable import notepadApp

// NotesViewModelTests.swift
import XCTest
import CoreData
@testable import notepadApp

class NotesViewModelTests: XCTestCase {
    var viewModel: NotesViewModel!
    var testCoreDataStack: TestCoreDataStack!
    
    override func setUp() {
        super.setUp()
        testCoreDataStack = TestCoreDataStack() // New instance for each test
        viewModel = NotesViewModel(coreDataManager: testCoreDataStack)
    }
    
    override func tearDown() {
        testCoreDataStack.reset() // Delete all data
        viewModel = nil
        testCoreDataStack = nil
        super.tearDown()
    }
    
    // MARK: - Fetch Notes Tests
    func testFetchNotes() {
        // Create test notes using NSEntityDescription
        guard let entity = NSEntityDescription.entity(forEntityName: "NoteModel", in: testCoreDataStack.context) else {
            XCTFail("Failed to create NoteModel entity")
            return
        }
        
        let note1 = NoteModel(entity: entity, insertInto: testCoreDataStack.context)
        note1.content = "Test Note 1"
        note1.createdTime = Date()
        
        let note2 = NoteModel(entity: entity, insertInto: testCoreDataStack.context)
        note2.content = "Test Note 2"
        note2.createdTime = Date().addingTimeInterval(-3600) // 1 hour ago
        
        testCoreDataStack.saveContext()
        
        // Fetch notes
        let notes = viewModel.fetchNotes(sortAscending: true)
        XCTAssertEqual(notes.count, 2)
        XCTAssertEqual(notes.first?.content, "Test Note 2") // Oldest first
    }
    
    // MARK: - Add Note Tests
    func testAddNote() {
        viewModel.addNote(content: "New Note")
        
        let notes = viewModel.fetchNotes(sortAscending: true)
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.content, "New Note")
    }
    
    // MARK: - Update Note Tests
    func testUpdateNote() {
        guard let entity = NSEntityDescription.entity(forEntityName: "NoteModel", in: testCoreDataStack.context) else {
            XCTFail("Failed to create NoteModel entity")
            return
        }
        
        let note = NoteModel(entity: entity, insertInto: testCoreDataStack.context)
        note.content = "Old Content"
        note.createdTime = Date()
        testCoreDataStack.saveContext()
        
        viewModel.updateNote(note, newContent: "Updated Content")
        
        let updatedNote = viewModel.fetchNotes(sortAscending: true).first
        XCTAssertEqual(updatedNote?.content, "Updated Content")
    }
    
    // MARK: - Delete Note Tests
    func testDeleteNote() {
        guard let entity = NSEntityDescription.entity(forEntityName: "NoteModel", in: testCoreDataStack.context) else {
            XCTFail("Failed to create NoteModel entity")
            return
        }
        
        let note = NoteModel(entity: entity, insertInto: testCoreDataStack.context)
        note.content = "Note to Delete"
        note.createdTime = Date()
        testCoreDataStack.saveContext()
        
        viewModel.deleteNote(note)
        
        let notes = viewModel.fetchNotes(sortAscending: true)
        XCTAssertEqual(notes.count, 0)
    }
    
    // MARK: - Load More Notes Tests
    func testLoadMoreNotes() {
        guard let entity = NSEntityDescription.entity(forEntityName: "NoteModel", in: testCoreDataStack.context) else {
            XCTFail("Failed to create NoteModel entity")
            return
        }
        // Add 25 notes
        for i in 1...25 {
            let note = NoteModel(entity: entity, insertInto: testCoreDataStack.context)
            note.content = "Note \(i)"
            note.createdTime = Date().addingTimeInterval(TimeInterval(i))
        }
        testCoreDataStack.saveContext()
        viewModel = NotesViewModel(coreDataManager: testCoreDataStack)
        // Initial fetch (20 notes)
        viewModel.loadMoreNotes()
        XCTAssertEqual(viewModel.numberOfNotes(), 20)
        
        // Load more (total = 25, not 40)
        viewModel.loadMoreNotes()
        XCTAssertEqual(viewModel.numberOfNotes(), 25) // Not 40!
    }
    
    // MARK: - Search Notes Tests
    func testSearchNotes() {
        guard let entity = NSEntityDescription.entity(forEntityName: "NoteModel", in: testCoreDataStack.context) else {
            XCTFail("Failed to create NoteModel entity")
            return
        }
        
        let note1 = NoteModel(entity: entity, insertInto: testCoreDataStack.context)
        note1.content = "Searchable Note 1"
        note1.createdTime = Date()
        
        let note2 = NoteModel(entity: entity, insertInto: testCoreDataStack.context)
        note2.content = "Another Note"
        note2.createdTime = Date()
        
        testCoreDataStack.saveContext()
        
        // Search for "Searchable"
        let predicate = NSPredicate(format: "content CONTAINS[cd] %@", "Searchable")
        let results = viewModel.fetchNotes(with: predicate)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.content, "Searchable Note 1")
    }
    
    // MARK: - Error Handling Tests
    func testErrorHandling() {
        // Simulate a fetch error
        let invalidRequest = NSFetchRequest<NoteModel>(entityName: "InvalidEntity")
        let notes = viewModel.executeFetch(request: invalidRequest)
        XCTAssertTrue(notes.isEmpty)
    }
}

// TestCoreDataStack.swift
class TestCoreDataStack: CoreDataManagerProtocol {
    // Remove singleton pattern
    let persistentContainer: NSPersistentContainer
    
    init() {
        guard let modelURL = Bundle.main.url(forResource: "NoteList", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to load Core Data model")
        }
        
        persistentContainer = NSPersistentContainer(name: "NoteList", managedObjectModel: model)
        let description = persistentContainer.persistentStoreDescriptions.first
        description?.type = NSInMemoryStoreType
        
        persistentContainer.loadPersistentStores { _, error in
            if let error = error { fatalError("Test Core Data setup failed: \(error)") }
        }
    }
    
    var context: NSManagedObjectContext { persistentContainer.viewContext }
    
    func saveContext() {
        do {
            try context.save()
        } catch {
            fatalError("Failed to save test context: \(error)")
        }
    }

    // Reset the context by deleting all existing data
    func reset() {
        let allNotes = try! context.fetch(NoteModel.fetchRequest())
        allNotes.map { context.delete($0) }
        
        do {
            try context.save()
        } catch {
            fatalError("Failed to reset test context: \(error)")
        }
    }
}


