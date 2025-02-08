//
//  NoteDetailViewController.swift
//  notepadApp
//
//  Created by TuanTa on 8/2/25.
//

import UIKit

class NoteDetailViewController: UIViewController {
    weak var delegate: NoteDetailViewControllerDelegate?
    let textView = UITextView()
    let viewModel = NotesViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveNote))
        
        textView.frame = view.bounds
        textView.font = UIFont.systemFont(ofSize: 18)
        view.addSubview(textView)
    }
    
    @objc func saveNote() {
        guard let content = textView.text, !content.isEmpty else { return }
        viewModel.addNote(content: content)
        delegate?.didSaveNote()
        navigationController?.popViewController(animated: true)
    }
}

extension NotesViewController: NoteDetailViewControllerDelegate {
    func didSaveNote() {
        notes = viewModel.fetchNotes()
        tableView.reloadData()
    }
}

protocol NoteDetailViewControllerDelegate: AnyObject {
    func didSaveNote()
}

