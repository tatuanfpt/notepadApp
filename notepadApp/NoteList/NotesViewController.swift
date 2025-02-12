//
//  NotesViewController.swift
//  notepadApp
//
//  Created by TuanTa on 8/2/25.
//

import UIKit

class NotesViewController: UIViewController {
    var collectionView: UICollectionView!
    var notes: [NoteModel] = []
    var filteredNotes: [NoteModel] = []
    let searchController = UISearchController(searchResultsController: nil)
    var sortAscending: Bool = true // Default to ascending order
    var gradientLayer: CAGradientLayer!
    private let gradientKey = "savedGradientColors"
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
        setupGradientBackground()
        setupRefreshButton()
        loadSavedGradient()
    }
    private func setupGradientBackground() {
        gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        updateGradientColors()
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func updateGradientColors() {
        gradientLayer.colors = [UIColor.random().cgColor, UIColor.random().cgColor]
    }
    
    private func setupRefreshButton() {
        let refreshButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refreshBackground)
        )
        navigationItem.rightBarButtonItems?.append(refreshButton)
    }
    
    @objc private func refreshBackground() {
        updateGradientColors()
        saveGradientColors()
    }
    
    private func saveGradientColors() {
        let colors = gradientLayer.colors as! [CGColor]
        let colorStrings = colors.map { $0.toString() }
        UserDefaults.standard.set(colorStrings, forKey: gradientKey)
    }
    
    private func loadSavedGradient() {
        if let colorStrings = UserDefaults.standard.array(forKey: gradientKey) as? [String] {
            let colors = colorStrings.map { CGColor.fromString($0)}
            gradientLayer.colors = colors
        } else {
            updateGradientColors()
        }
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
        collectionView.backgroundColor = .clear
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

