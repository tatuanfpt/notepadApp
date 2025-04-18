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
    var sortAscending: Bool = false // Default to ascending order
    var gradientLayer: CAGradientLayer!
    private var isLoadingMoreNotes = false
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let gradientKey = "savedGradientColors"
    private var viewModel: NotesViewModelProtocol = NotesViewModel()
    private var searchTimer: Timer?
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No results found."
        label.textColor = .secondaryLabel
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.onError = { [weak self] message in
            self?.showErrorAlert(message: message)
        }
        setupLoadingIndicator()
        viewModel.onNotesUpdated = { [weak self] in
            self?.collectionView.reloadData()
            self?.isLoadingMoreNotes = false
            self?.loadingIndicator.stopAnimating()
        }
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadNotes()
    }
    
    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    private func showEmptyStateIfNeeded() {
        let isEmpty = isSearching ? filteredNotes.isEmpty : notes.isEmpty
        emptyStateLabel.isHidden = !(isEmpty && isSearching)
    }
    
    private func reloadNotes() {
        viewModel.loadMoreNotes()
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
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(NoteCell.self, forCellWithReuseIdentifier: "NoteCell")
        view.addSubview(collectionView)
        collectionView.backgroundColor = .clear
        collectionView.backgroundView = emptyStateLabel
        // Pin to safe area
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
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
        viewModel.sortAscending = (sender.selectedSegmentIndex == 0) // 0 = Oldest First
    }
    
    var isSearching: Bool {
        return searchController.isActive && !(searchController.searchBar.text?.isEmpty ?? true)
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension NotesViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isSearching ? filteredNotes.count : viewModel.numberOfNotes()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NoteCell", for: indexPath) as! NoteCell
        guard let originalNote = viewModel.note(at: indexPath.row) else { return UICollectionViewCell() }
        let note = isSearching ? filteredNotes[indexPath.row] : originalNote
        cell.titleLabel.text = note.title
        cell.contentLabel.text = note.content
        cell.dateLabel.text = DateFormatter.localizedString(from: note.createdTime, dateStyle: .short, timeStyle: .short)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let originalNote = viewModel.note(at: indexPath.row) else { return  }
        let note = isSearching ? filteredNotes[indexPath.row] : originalNote
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
        guard let originalNote = viewModel.note(at: indexPath.row) else { return }
        let note = isSearching ? filteredNotes[indexPath.row] : originalNote
        if isSearching {
            filteredNotes = filteredNotes.filter { $0 != note }
        }
        viewModel.deleteNote(note)
    }
}

// MARK: - UISearchResultsUpdating
extension NotesViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        searchTimer?.invalidate() // Cancel previous timer
        searchTimer = Timer.scheduledTimer(
            withTimeInterval: 0.3, // 300ms delay
            repeats: false
        ) { [weak self] _ in
            guard let self = self else { return }
            guard let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespaces), !query.isEmpty else {
                self.filteredNotes = []
                self.collectionView.reloadData()
                self.showEmptyStateIfNeeded()
                return
            }
            
            // Case-insensitive search
            let predicate = NSPredicate(format: "content CONTAINS[cd] %@ OR title CONTAINS[cd] %@", query, query)
            self.filteredNotes = self.viewModel.fetchNotes(with: predicate)
            self.collectionView.reloadData()
            self.showEmptyStateIfNeeded()
        }
    }
}

// MARK: - NoteDetailViewControllerDelegate
extension NotesViewController: NoteDetailViewControllerDelegate {
    func didSaveNote() {
        viewModel.loadMoreNotes()
        collectionView.reloadData()
    }
}

// MARK: - UIScrollViewDelegate
extension NotesViewController: UIScrollViewDelegate {
    // Update scroll detection logic
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let screenHeight = scrollView.frame.size.height
        
        // Only trigger if:
        // 1. User is near bottom
        // 2. Not already loading
        // 3. Total notes > current batch
        if offsetY > contentHeight - screenHeight * 2,
           !isLoadingMoreNotes,
           viewModel.numberOfNotes() < viewModel.totalNotesCount {
            
            isLoadingMoreNotes = true
            loadingIndicator.startAnimating()
            viewModel.loadMoreNotes()
        }
    }
}

