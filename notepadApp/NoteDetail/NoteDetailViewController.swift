//
//  NoteDetailViewController.swift
//  notepadApp
//
//  Created by TuanTa on 8/2/25.
//

import UIKit

protocol NoteDetailViewControllerDelegate: AnyObject {
    func didSaveNote()
}

class NoteDetailViewController: UIViewController {
    weak var delegate: NoteDetailViewControllerDelegate?
    let textView = UITextView()
    let viewModel = NotesViewModel()
    var note: NoteModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveNote)),
            UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editNote)),
            UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(deleteNote)), // Add delete button
        ]
        setupTextView()
    }
    
    fileprivate func setupTextView() {
        view.addSubview(textView)
        textView.frame = view.bounds
        textView.font = UIFont.systemFont(ofSize: 18)
        if let note = note {
            textView.text = note.content
        }
        textView.becomeFirstResponder()
    }
    
    @objc func deleteNote() {
        guard let note = note else { return }
        
        // Show confirmation alert
        let alert = UIAlertController(title: "Delete Note", message: "Are you sure you want to delete this note?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.viewModel.deleteNote(note)
            self.delegate?.didSaveNote() // Notify delegate to refresh the list
            self.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
    
    @objc func saveNote() {
        guard let content = textView.text, !content.isEmpty else { return }
        if let note = note {
            viewModel.updateNote(note, newContent: content)
        } else {
            viewModel.addNote(content: content)
        }
        delegate?.didSaveNote()
        navigationController?.popViewController(animated: true)
    }
    
    @objc func editNote() {
        textView.isEditable = true
        textView.becomeFirstResponder()
    }
}


