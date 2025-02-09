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
    
    func fetchNotes(with predicate: NSPredicate) -> [NoteModel] {
      let request = NoteModel.fetchRequest()
        request.predicate = predicate
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }
    
    // In NotesViewModel:
    lazy var fetchedResultsController: NSFetchedResultsController<NoteModel> = {
        let request = NoteModel.fetchRequest()
        request.fetchBatchSize = 20 // Load 20 notes at a time
        let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil , cacheName: nil)
        return controller
    }()
}

class NotesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var viewModel = NotesViewModel()
    var notes: [NoteModel] = []
    let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        notes = viewModel.fetchNotes()
    }
    
    func setupUI() {
        view.backgroundColor = .white
        navigationItem.title = "Notepad"
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewNote)),
            UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editNotes))
        ]
        
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.delegate = self
        tableView.dataSource = self
        
    }
    
    @objc func addNewNote() {
        let detailVC = NoteDetailViewController()
        detailVC.delegate = self
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    @objc func editNotes() {
        tableView.setEditing(!tableView.isEditing, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let note = notes[indexPath.row]
        cell.textLabel?.text = note.title
        cell.detailTextLabel?.text = note.content
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let note = notes[indexPath.row]
        let detailVC = NoteDetailViewController()
        detailVC.note = note
        detailVC.delegate = self
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let note = notes[indexPath.row]
            viewModel.deleteNote(note: note)
            notes.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    // In NotesViewController:
//    private func createLayout() -> UICollectionViewLayout {
//      UICollectionViewCompositionalLayout { [weak self] (sectionIndex, layoutEnv) -> NSCollectionLayoutSection? in
//        let device = layoutEnv.traitCollection
//        let columnCount = (device.horizontalSizeClass == .compact) ? 1 : 2 // 1 column for iPhone, 2 for iPad
//        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(100))
//        let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitem: item, count: columnCount)
//        return NSCollectionLayoutSection(group: group)
//      }
//    }

    // Update setupUI() to use UICollectionView instead of UITableView.
    
    // In NotesViewController:
    let searchController = UISearchController()

    func updateSearchResults(for searchController: UISearchController) {
      guard let query = searchController.searchBar.text else { return }
      let predicate = NSPredicate(format: "content CONTAINS[cd] %@", query)
      notes = viewModel.fetchNotes(with: predicate) // Extend ViewModel to accept predicates.
    }
    
    // In NotesViewController: Implement UIScrollViewDelegate to detect scroll position.
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
      let offsetY = scrollView.contentOffset.y
      if offsetY > scrollView.contentSize.height - scrollView.frame.height {
        loadMoreNotes() // Fetch next batch
      }
    }
    
    func loadMoreNotes() {
        viewModel.fetchNotes()
    }
    
    // In NotesViewController:
    private func generateRandomGradient() {
      let gradient = CAGradientLayer()
      gradient.colors =  [UIColor.red.cgColor, UIColor.green.cgColor] //[UIColor.random().cgColor, UIColor.random().cgColor]
      gradient.frame = view.bounds
      view.layer.insertSublayer(gradient, at: 0)
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
            UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editNote))
        ]
        
        textView.frame = view.bounds
        textView.font = UIFont.systemFont(ofSize: 18)
        view.addSubview(textView)
        
        if let note = note {
            textView.text = note.content
        }
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

extension NotesViewController: NoteDetailViewControllerDelegate {
    func didSaveNote() {
        notes = viewModel.fetchNotes()
        tableView.reloadData()
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
