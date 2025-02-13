
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
1. Clone the repository, choose `main` branch.
3. Add your `GoogleService-Info.plist` file for Firebase integration.
4. Build and run the app.

## Future Improvements
- Add more unit tests for View Model and Firestore operations.
- Finish Firestore intergation + conflict resolution sync.
- Add animations for note transitions.

## Screenshots
![Home Screen]
![home](https://github.com/user-attachments/assets/b26cda96-ebeb-4eae-b69a-f6c79d436ec7)

![Search]
![search](https://github.com/user-attachments/assets/dadd9902-f063-4499-8309-af9092d7b4a2)


No Result
![no-result](https://github.com/user-attachments/assets/3525d306-e39d-4576-abe2-f36efa7cc0c4)
