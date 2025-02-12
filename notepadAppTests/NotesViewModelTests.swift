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
    
    func testFetchNotesSorting() {
        // Create test notes
        let note1 = NoteModel(context: testCoreDataStack.context)
//        note1.uuid = UUID()
        note1.title = "Note 1"
        note1.content = "Content 1"
        note1.createdTime = Date(timeIntervalSinceNow: -3600) // 1 hour ago
        
        let note2 = NoteModel(context: testCoreDataStack.context)
//        note2.uuid = UUID()
        note2.title = "Note 2"
        note2.content = "Content 2"
        note2.createdTime = Date() // Now
        
        // Save the context
        do {
            try testCoreDataStack.context.save()
        } catch {
            XCTFail("Failed to save test context: \(error)")
        }
        
        // Test sorting
        let ascendingNotes = viewModel.fetchNotes(sortAscending: true)
        XCTAssertEqual(ascendingNotes.count, 2)
        XCTAssertEqual(ascendingNotes.first?.title, "Note 1")
        XCTAssertEqual(ascendingNotes.last?.title, "Note 2")
        
        let descendingNotes = viewModel.fetchNotes(sortAscending: false)
        XCTAssertEqual(descendingNotes.count, 2)
        XCTAssertEqual(descendingNotes.first?.title, "Note 2")
        XCTAssertEqual(descendingNotes.last?.title, "Note 1")
    }
}

// TestCoreDataStack.swift
class TestCoreDataStack: CoreDataManagerProtocol {
    static let shared = TestCoreDataStack()
    let persistentContainer: NSPersistentContainer
    
    init() {
        persistentContainer = NSPersistentContainer(name: "NoteList")
        let description = persistentContainer.persistentStoreDescriptions.first
        description?.type = NSInMemoryStoreType // Use in-memory store
        
        // Load the persistent stores
        persistentContainer.loadPersistentStores { _, error in
            if let error = error { fatalError("Test Core Data setup failed: \(error)") }
        }
        
        // Ensure the NoteModel entity is registered
        let entityDescription = NSEntityDescription.entity(forEntityName: "NoteModel", in: persistentContainer.viewContext)
        if entityDescription == nil {
            fatalError("Failed to register NoteModel entity in test Core Data stack.")
        }
    }
    
    var context: NSManagedObjectContext { persistentContainer.viewContext }
    
    func saveContext() { /* Optional for testing */ }
}
