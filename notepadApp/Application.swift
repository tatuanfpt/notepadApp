//
//  Application.swift
//  notepadApp
//
//  Created by TuanTa on 8/2/25.
//


import UIKit

final class Application {
    
    static let shared = Application()
    private init() {
        
    }
    
    func configureMainInterface(_ window: UIWindow = UIWindow()) {
        var expectViewController: UIViewController!
        expectViewController = NotesViewController()
        expectViewController.title = "Notepad"
        expectViewController.view.backgroundColor = .green
        if let window = UIApplication.shared.windows.first {
            let navigationController = UINavigationController(rootViewController: expectViewController)
            window.rootViewController = navigationController
        }
        
    }
}

// FirestoreManager.swift
import FirebaseFirestore

class FirestoreManager {
    static let shared = FirestoreManager()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func syncNote(_ note: NoteModel) {
        let noteID = note.objectID.uriRepresentation().absoluteString
        let noteData: [String: Any] = [
            "title": note.title,
            "content": note.content,
            "createdTime": Timestamp(date: note.createdTime),
            "lastEditTime": Timestamp(date: note.lastEditTime),
            "backgroundTheme": note.backgroundTheme
        ]
        
        db.collection("notes").document(noteID).setData(noteData) { error in
            if let error = error {
                print("Failed to sync note: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchNotes(completion: @escaping ([NoteModel]) -> Void) {
        db.collection("notes").getDocuments { snapshot, error in
            if let error = error {
                print("Failed to fetch notes: \(error.localizedDescription)")
                completion([])
                return
            }
            
            let notes = snapshot?.documents.compactMap { document -> NoteModel? in
                let data = document.data()
                let note = NoteModel(context: CoreDataManager.shared.context)
                note.title = data["title"] as? String ?? ""
                note.content = data["content"] as? String ?? ""
                note.createdTime = (data["createdTime"] as? Timestamp)?.dateValue() ?? Date()
                note.lastEditTime = (data["lastEditTime"] as? Timestamp)?.dateValue() ?? Date()
                note.backgroundTheme = data["backgroundTheme"] as? String ?? "Default"
                return note
            }
            completion(notes ?? [])
        }
    }
}
