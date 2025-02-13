//
//  AuthManager.swift
//  notepadApp
//
//  Created by TuanTa on 11/2/25.
//

import Foundation
import FirebaseAuth

class AuthManager {
    static let shared = AuthManager()
    
    private init() {}
    
    func signInAnonymously(completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signInAnonymously { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = result?.user {
                completion(.success(user))
            }
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
        let noteID = note.uuid.uuidString // Use UUID
        let noteData: [String: Any] = [
            "uuid": noteID, // Include UUID in Firestore
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
                guard let uuidString = data["uuid"] as? String,
                      let uuid = UUID(uuidString: uuidString) else { return nil }
                
                // Check if note already exists in Core Data
                let request = NoteModel.fetchRequest()
                request.predicate = NSPredicate(format: "uuid == %@", uuid as CVarArg)
                
                if let existingNote = try? CoreDataManager.shared.context.fetch(request).first {
                    return existingNote
                } else {
                    let note = NoteModel(context: CoreDataManager.shared.context)
                    note.uuid = uuid
                    note.title = data["title"] as? String ?? ""
                    note.content = data["content"] as? String ?? ""
                    note.createdTime = (data["createdTime"] as? Timestamp)?.dateValue() ?? Date()
                    note.lastEditTime = (data["lastEditTime"] as? Timestamp)?.dateValue() ?? Date()
                    note.backgroundTheme = data["backgroundTheme"] as? String ?? "Default"
                    return note
                }
            
            }
            completion(notes ?? [])
        }
    }
}

