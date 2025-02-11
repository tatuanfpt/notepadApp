
# Notepad App

A simple iOS app for managing notes, built with **UIKit** and **Core Data**. Supports adding, editing, deleting, and searching notes. Notes are synced with **Firestore** for cloud storage.

## Features
- **Responsive UI:** Adapts to different screen sizes (1 column on iPhone, 2 columns on iPad).
- **Search:** Search notes by title or content with debounced input.
- **Sorting:** Sort notes by creation date (ascending/descending).
- **Random Backgrounds:** App background changes dynamically with random gradients.
- **Firestore Sync:** Notes are synced with Firestore for cloud storage (optional).
- **Offline Support:** Firestore persists data locally for offline use.

## Design Decisions
1. **Architecture:** MVVM pattern is used to separate business logic (`NotesViewModel`) from the UI (`NotesViewController`).
2. **Core Data:** Used for local persistence. Notes are stored in a `NoteModel` entity.
3. **Firestore:** Optional cloud sync with anonymous authentication.
4. **Debounced Search:** A 300ms delay is added to avoid excessive filtering during typing.
5. **Empty State:** A "No results found" message is shown when the search returns no matches.
6. **Random Backgrounds:** `CAGradientLayer` is used to generate random gradients for visual appeal.

## Setup
1. Clone the repository.
2. Install dependencies using `pod install`.
3. Add your `GoogleService-Info.plist` file for Firebase integration.
4. Build and run the app.

## Future Improvements
- Add unit tests for Core Data and Firestore operations.
- Implement conflict resolution for Firestore sync.
- Add animations for note transitions.

## Screenshots
![Home Screen](screenshots/home.png)
![Search](screenshots/search.png)
