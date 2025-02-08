//
//  NotesViewModel.swift
//  notepadApp
//
//  Created by TuanTa on 8/2/25.
//

import UIKit

class NotesViewModel {
    let context = CoreDataManager.shared.context
    
    func addNote(content: String) {
        let newNote = NoteModel(context: context)
        newNote.content = content
        newNote.createdTime = Date()
        newNote.lastEditTime = Date()
        newNote.title = content.components(separatedBy: ".").first ?? "Untitled"
        newNote.backgroundTheme = "Default"
        CoreDataManager.shared.saveContext()
    }
    
    func updateNote(note: NoteModel, newContent: String) {
        note.content = newContent
        note.lastEditTime = Date()
        note.title = newContent.components(separatedBy: ".").first ?? "Untitled"
        CoreDataManager.shared.saveContext()
    }
    
    func deleteNote(note: NoteModel) {
        context.delete(note)
        CoreDataManager.shared.saveContext()
    }
    
    func fetchNotes() -> [NoteModel] {
        let request = NoteModel.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }
}

