//
//  CoreDataStackTest.swift
//  notepadAppTests
//
//  Created by TuanTa on 12/2/25.
//

import XCTest
import CoreData

@testable import notepadApp

class NotesViewModelTests: XCTestCase {
    var testCoreDataStack: TestCoreDataStack!
    var viewModel: NotesViewModel!
    
    override func setUp() {
        super.setUp()
        testCoreDataStack = TestCoreDataStack.shared
        viewModel = NotesViewModel(coreDataManager: testCoreDataStack)
    }
    
    override func tearDown() {
        testCoreDataStack = nil
        viewModel = nil
        super.tearDown()
    }
    
    // NotesViewModelTests.swift
    func testFetchNotesSorting() {
        let context = testCoreDataStack.context
        
        // Create test notes with proper entity description
        guard let entity = NSEntityDescription.entity(forEntityName: "NoteModel", in: context) else {
            XCTFail("Failed to create NoteModel entity")
            return
        }
        
        let note1 = NoteModel(entity: entity, insertInto: context)
        note1.id = 1
        note1.title = "Note 1"
        note1.createdTime = Date(timeIntervalSinceNow: -3600)
        
        let note2 = NoteModel(entity: entity, insertInto: context)
        note2.id = 2
        note2.title = "Note 2"
        note2.createdTime = Date()
        
        do {
            try context.save()
        } catch {
            XCTFail("Failed to save context: \(error)")
        }
        
        // Test sorting logic
        let ascendingNotes = viewModel.fetchNotes(sortAscending: true)
        XCTAssertEqual(ascendingNotes.count, 2)
        XCTAssertEqual(ascendingNotes.first?.title, "Note 1")
    }
}
class TestCoreDataStack: CoreDataManagerProtocol {
    static let shared = TestCoreDataStack()
    let persistentContainer: NSPersistentContainer
    
    init() {
        // Load the managed object model
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
    
    func saveContext() { /* Optional for testing */ }
}
