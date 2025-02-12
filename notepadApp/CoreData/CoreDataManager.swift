//
//  CoreDataManager.swift
//  notepadApp
//
//  Created by TuanTa on 8/2/25.
//


import UIKit
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    let persistentContainer: NSPersistentContainer
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "NoteList")
        persistentContainer.loadPersistentStores { (_, error) in
            if let error = error {
                fatalError("Error loading persistent stores: \(error)")
            }
        }
    }
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        do {
            try context.save()
        } catch {
            print("Save error: \(error)")
        }
    }
}

@objc(NoteModel)
class NoteModel: NSManagedObject {
    @NSManaged var uuid: UUID
    @NSManaged var title: String
    @NSManaged var content: String
    @NSManaged var createdTime: Date
    @NSManaged var lastEditTime: Date
    @NSManaged var backgroundTheme: String
}

extension NoteModel {
    static func fetchRequest() -> NSFetchRequest<NoteModel> {
        return NSFetchRequest<NoteModel>(entityName: "NoteModel")
    }
}

import CoreData

class NotesViewModel {
    let context = CoreDataManager.shared.context
    
    func addNote(content: String) {
        let newNote = NoteModel(context: context)
        newNote.uuid = UUID() // Add this line
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
        context.delete(note) // Delete from Core Data
        saveContext() // Save changes
    }

    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Save error: \(error)")
        }
    }
    
    func fetchNotes(with predicate: NSPredicate? = nil) -> [NoteModel] {
        let request = NoteModel.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdTime", ascending: false)]
        request.predicate = predicate
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }
    
    func fetchNotes(sortAscending: Bool = true) -> [NoteModel] {
        let request = NoteModel.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdTime", ascending: sortAscending)]
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }
    
    func syncNotes() {
        FirestoreManager.shared.fetchNotes { [weak self] firestoreNotes in
            guard let self = self else { return }
            let localNotes = self.fetchNotes(sortAscending: true)
            
            // Merge local and remote notes
            let mergedNotes = self.mergeNotes(localNotes: localNotes, remoteNotes: firestoreNotes)
            
            // Save merged notes to Core Data
            self.saveNotes(mergedNotes)
            
            // Sync local notes to Firestore
            for note in localNotes {
                FirestoreManager.shared.syncNote(note)
            }
        }
    }
    
    private func mergeNotes(localNotes: [NoteModel], remoteNotes: [NoteModel]) -> [NoteModel] {
        // Implement conflict resolution logic here
        return localNotes + remoteNotes.filter { remoteNote in
            !localNotes.contains { $0.objectID == remoteNote.objectID }
        }
    }
    
    private func saveNotes(_ notes: [NoteModel]) {
        for note in notes {
            context.insert(note)
        }
        saveContext()
    }
}

import UIKit

class NotesViewController: UIViewController {
    var collectionView: UICollectionView!
    var notes: [NoteModel] = []
    var filteredNotes: [NoteModel] = []
    let viewModel = NotesViewModel()
    let searchController = UISearchController(searchResultsController: nil)
    var sortAscending: Bool = true // Default to ascending order
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupSearchController()
        setupSortToggle() // Add sort toggle
        notes = viewModel.fetchNotes(sortAscending: sortAscending)
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewNote))
        ]
        signInAnonymously()
        viewModel.syncNotes()
            // ... rest of the code
    }
    
    private func signInAnonymously() {
        AuthManager.shared.signInAnonymously { result in
            switch result {
            case .success(let user):
                print("Signed in anonymously with user ID: \(user.uid)")
            case .failure(let error):
                print("Failed to sign in anonymously: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func addNewNote() {
        let detailVC = NoteDetailViewController()
        detailVC.delegate = self
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewCompositionalLayout { [weak self] (sectionIndex, layoutEnv) -> NSCollectionLayoutSection? in
            return self?.createLayoutSection(for: layoutEnv)
        }
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(NoteCell.self, forCellWithReuseIdentifier: "NoteCell")
        view.addSubview(collectionView)
    }
    
    private func createLayoutSection(for layoutEnv: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let columnCount: Int
        switch layoutEnv.traitCollection.horizontalSizeClass {
        case .compact: columnCount = 1 // iPhone
        case .regular: columnCount = 2 // iPad
        default: columnCount = 1
        }

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / CGFloat(columnCount)),
            heightDimension: .estimated(100)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        
        return section
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search notes"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    private func setupSortToggle() {
        let sortControl = UISegmentedControl(items: ["Oldest First", "Newest First"])
        sortControl.selectedSegmentIndex = sortAscending ? 0 : 1
        sortControl.addTarget(self, action: #selector(sortOrderChanged(_:)), for: .valueChanged)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: sortControl)
    }
    
    @objc private func sortOrderChanged(_ sender: UISegmentedControl) {
        sortAscending = sender.selectedSegmentIndex == 0
        notes = viewModel.fetchNotes(sortAscending: sortAscending)
        collectionView.reloadData()
    }
    
    var isSearching: Bool {
        return searchController.isActive && !(searchController.searchBar.text?.isEmpty ?? true)
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension NotesViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isSearching ? filteredNotes.count : notes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NoteCell", for: indexPath) as! NoteCell
        let note = isSearching ? filteredNotes[indexPath.row] : notes[indexPath.row]
        cell.titleLabel.text = note.title
        cell.contentLabel.text = note.content
        cell.dateLabel.text = DateFormatter.localizedString(from: note.createdTime, dateStyle: .short, timeStyle: .short)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let note = isSearching ? filteredNotes[indexPath.row] : notes[indexPath.row]
        let detailVC = NoteDetailViewController()
        detailVC.note = note
        detailVC.delegate = self
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.deleteNote(at: indexPath)
            }
            return UIMenu(title: "", children: [deleteAction])
        }
    }
    
    private func deleteNote(at indexPath: IndexPath) {
        let note = isSearching ? filteredNotes[indexPath.row] : notes[indexPath.row]
        viewModel.deleteNote(note: note)
        if isSearching {
            filteredNotes.remove(at: indexPath.row)
        } else {
            notes.remove(at: indexPath.row)
        }
        collectionView.deleteItems(at: [indexPath])
    }
}

// MARK: - UISearchResultsUpdating
extension NotesViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text?.lowercased(), !query.isEmpty else {
            filteredNotes = notes
            collectionView.reloadData()
            return
        }
        
        let predicate = NSPredicate(format: "content CONTAINS[cd] %@ OR title CONTAINS[cd] %@", query, query)
        filteredNotes = viewModel.fetchNotes(with: predicate)
        collectionView.reloadData()
    }
}

// MARK: - NoteDetailViewControllerDelegate
extension NotesViewController: NoteDetailViewControllerDelegate {
    func didSaveNote() {
        notes = viewModel.fetchNotes(sortAscending: sortAscending)
        collectionView.reloadData()
    }
}

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
        view.backgroundColor = .white
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveNote)),
            UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editNote)),
            UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(deleteNote)) // Add delete button
        ]
        
        textView.frame = view.bounds
        textView.font = UIFont.systemFont(ofSize: 18)
        view.addSubview(textView)
        
        if let note = note {
            textView.text = note.content
        }
    }
    
    @objc func deleteNote() {
        guard let note = note else { return }
        
        // Show confirmation alert
        let alert = UIAlertController(title: "Delete Note", message: "Are you sure you want to delete this note?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.viewModel.deleteNote(note: note)
            self.delegate?.didSaveNote() // Notify delegate to refresh the list
            self.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
    
    @objc func saveNote() {
        guard let content = textView.text, !content.isEmpty else { return }
        if let note = note {
            viewModel.updateNote(note: note, newContent: content)
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

import FirebaseFirestore
import FirebaseCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        // Enable Firestore offline persistence
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        Firestore.firestore().settings = settings
        
        window = UIWindow(frame: UIScreen.main.bounds)
        let navController = UINavigationController(rootViewController: NotesViewController())
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
        return true
    }
}

import UIKit

class NoteCell: UICollectionViewCell {
    let titleLabel = UILabel()
    let contentLabel = UILabel()
    let dateLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 8
        layer.shadowOpacity = 0.1
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, contentLabel, dateLabel])
        stack.axis = .vertical
        stack.spacing = 4
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
        
        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.textColor = .secondaryLabel
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
