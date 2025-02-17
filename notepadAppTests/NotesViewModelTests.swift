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

class NotesViewModelTests: XCTestCase {
    var viewModel: NotesViewModel!
    var testCoreDataStack: TestCoreDataStack!
    var entity: NSEntityDescription!
    
    override func setUp() {
        super.setUp()
        testCoreDataStack = TestCoreDataStack.shared
        viewModel = NotesViewModel(coreDataManager: testCoreDataStack)
    }
    
    override func tearDown() {
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
        note2.createdTime = Date().addingTimeInterval(-3600)
        
        testCoreDataStack.saveContext()
        
        // Fetch notes
        let notes = viewModel.fetchNotes(sortAscending: true)
        XCTAssertEqual(notes.count, 2)
    }
    
    // MARK: - Add Note Tests
    func testAddNote() {
        // Create test notes using NSEntityDescription
        guard let entity = NSEntityDescription.entity(forEntityName: "NoteModel", in: testCoreDataStack.context) else {
            XCTFail("Failed to create NoteModel entity")
            return
        }
        let note1 = NoteModel(entity: entity, insertInto: testCoreDataStack.context)
        
        testCoreDataStack.saveContext()
        viewModel.addNote(content: "New Note")
        
        let notes = viewModel.fetchNotes(sortAscending: true)
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.content, "New Note")
    }
    
    // MARK: - Update Note Tests
    func testUpdateNote() {
        // Create test notes using NSEntityDescription
        guard let entity = NSEntityDescription.entity(forEntityName: "NoteModel", in: testCoreDataStack.context) else {
            XCTFail("Failed to create NoteModel entity")
            return
        }
        
        let note = NoteModel(entity: entity, insertInto: testCoreDataStack.context)
        note.content = "Old Content"
        note.createdTime = Date()
        testCoreDataStack.saveContext()
        
        viewModel.updateNote(note, newContent: "Updated Content")
        let allNotes = viewModel.fetchNotes(sortAscending: true)
        if let updatedNote = allNotes.last {
            XCTAssertEqual(updatedNote.content, "Updated Content")
        }
    }
    
    // MARK: - Delete Note Tests
    func testDeleteNote() {
        let note = NoteModel(context: testCoreDataStack.context)
        note.content = "Note to Delete"
        note.createdTime = Date()
        testCoreDataStack.saveContext()
        
        viewModel.deleteNote(note)
        
        let notes = viewModel.fetchNotes(sortAscending: true)
        XCTAssertEqual(notes.count, 0)
    }
    
    // MARK: - Load More Notes Tests
    func testLoadMoreNotes() {
        // Add 25 notes
        for i in 1...25 {
            let note = NoteModel(context: testCoreDataStack.context)
            note.content = "Note \(i)"
            note.createdTime = Date().addingTimeInterval(TimeInterval(i))
        }
        testCoreDataStack.saveContext()
        
        // Initial fetch (20 notes)
        viewModel.loadMoreNotes()
        XCTAssertEqual(viewModel.numberOfNotes(), 20)
        
        // Load more (25 notes)
        viewModel.loadMoreNotes()
        XCTAssertEqual(viewModel.numberOfNotes(), 25)
    }
    
    // MARK: - Search Notes Tests
    func testSearchNotes() {
        let note1 = NoteModel(context: testCoreDataStack.context)
        note1.content = "Searchable Note 1"
        note1.createdTime = Date()
        
        let note2 = NoteModel(context: testCoreDataStack.context)
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
class TestCoreDataStack: CoreDataManagerProtocol {
    static let shared = TestCoreDataStack()
    let persistentContainer: NSPersistentContainer
    
    init() {
        // Load the Core Data model
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
}


