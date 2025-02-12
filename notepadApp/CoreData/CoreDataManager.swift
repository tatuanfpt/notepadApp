//
//  CoreDataManager.swift
//  notepadApp
//
//  Created by TuanTa on 8/2/25.
//


import UIKit
import CoreData

protocol CoreDataManagerProtocol {
    func saveContext()
    var context: NSManagedObjectContext { get }
}

class CoreDataManager: CoreDataManagerProtocol {
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

// Logger.swift
protocol LoggerProtocol {
    func logError(_ message: String)
}

struct ConsoleLogger: LoggerProtocol {
    func logError(_ message: String) {
        print("ERROR: \(message)")
    }
}

import CoreData
// NotesViewModelProtocol.swift
protocol NotesViewModelProtocol {
    func fetchNotes(sortAscending: Bool) -> [NoteModel]
    func addNote(content: String)
    func updateNote(_ note: NoteModel, newContent: String)
    func deleteNote(_ note: NoteModel)
    func fetchNotes(with predicate: NSPredicate?) -> [NoteModel]
    var onError: ((String) -> Void)? { get set }
}
// NotesViewModel.swift
final class NotesViewModel: NotesViewModelProtocol {
    private let coreDataManager: CoreDataManagerProtocol
    private let logger: LoggerProtocol
    var onError: ((String) -> Void)?
    
    // Dependency Injection
    
    init(coreDataManager: CoreDataManagerProtocol = CoreDataManager.shared,
         logger: LoggerProtocol = ConsoleLogger()) {
        self.coreDataManager = coreDataManager
        self.logger = logger
    }
    
    private func saveContext() {
        do {
            try coreDataManager.context.save()
        } catch {
            let errorMessage = "Save failed: \(error.localizedDescription)"
            logger.logError(errorMessage)
            onError?(errorMessage)
        }
    }
    
    // Update an existing note
    func updateNote(_ note: NoteModel, newContent: String) {
        note.content = newContent
        note.lastEditTime = Date()
        note.title = newContent.components(separatedBy: ".").first ?? "Untitled"
        saveContext()
    }
    
    func fetchNotes(sortAscending: Bool) -> [NoteModel] {
        let request = NoteModel.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdTime", ascending: sortAscending)]
        return executeFetch(request: request)
    }
    
    func fetchNotes(with predicate: NSPredicate?) -> [NoteModel] {
        let request = NoteModel.fetchRequest()
        request.predicate = predicate
        return executeFetch(request: request)
    }
    
    private func executeFetch(request: NSFetchRequest<NoteModel>) -> [NoteModel] {
        do {
            return try coreDataManager.context.fetch(request)
        } catch {
            onError?("Failed to fetch notes: \(error.localizedDescription)")
            return []
        }
    }
    
    func addNote(content: String) {
        coreDataManager.context.perform { [weak self] in
            let newNote = NoteModel(context: self?.coreDataManager.context ?? NSManagedObjectContext())
            newNote.content = content
            newNote.createdTime = Date()
            newNote.lastEditTime = Date()
            self?.saveContext()
        }
    }
    
    func deleteNote(_ note: NoteModel) {
        coreDataManager.context.delete(note)
        saveContext()
    }
}

class NotesViewController: UIViewController {
    var collectionView: UICollectionView!
    var notes: [NoteModel] = []
    var filteredNotes: [NoteModel] = []
    let searchController = UISearchController(searchResultsController: nil)
    var sortAscending: Bool = true // Default to ascending order
    private var viewModel: NotesViewModelProtocol = NotesViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.onError = { [weak self] message in
            self?.showErrorAlert(message: message)
        }
        notes = viewModel.fetchNotes(sortAscending: true)
        setupCollectionView()
        setupSearchController()
        setupSortToggle() // Add sort toggle
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewNote))
        ]
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
        viewModel.deleteNote(note)
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

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
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
