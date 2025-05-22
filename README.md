# Flutter Home Widget Quotes

## Screenshots

Below are some screenshots demonstrating the app features and UI. Please ensure new screenshots are added for every pull request as per the contributing guidelines.

| Home Page                        | Widget Example                    |
|:---------------------------------:|:---------------------------------:|
| **Main Quotes List**              | **Home Screen Widget**            |
| ![feature-homepage](screenshots/feature-homepage.png) | ![feature-widget](screenshots/feature-widget.png) |

<!-- Add more screenshots as needed, following the format above. For example:
| **Login Screen** | **Settings Page** |
| ![feature-login](screenshots/feature-login.png) | ![feature-settings](screenshots/feature-settings.png) |
-->

---

## Project Description

Flutter Home Widget Quotes is a Flutter application that allows users to view, manage, and interact with inspirational quotes. The app integrates with home screen widgets, enabling users to quickly access and update quotes directly from their device's home screen.

## Features

- View a list of inspirational quotes.
- Add, edit, and delete quotes.
- Tag quotes for easy organization.
- Home screen widget integration (Android/iOS).
- Persistent storage using Hive database.
- Interactive widget actions (increment, clear, etc.).
- Responsive and modern UI.

## Getting Started

Follow these steps to set up the project locally:

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/flutter_home_widget_quotes.git
   cd flutter_home_widget_quotes
   ```

2. **Install Flutter**
   - Ensure you have [Flutter](https://flutter.dev/docs/get-started/install) installed.

3. **Install Dependencies**
   ```bash
   flutter pub get
   ```

4. **Run the App**
   - For Android:
     ```bash
     flutter run
     ```
   - For iOS (requires Xcode):
     ```bash
     flutter run
     ```

5. **(Optional) Setup Hive Database**
   - No manual setup required; the app initializes Hive on startup.

6. **(Optional) Widget Setup**
   - For widget functionality, ensure you grant necessary permissions and follow platform-specific setup as described in the [home_widget](https://pub.dev/packages/home_widget) package documentation.

## Roadmap

- [ ] Add user authentication.
- [ ] Cloud sync for quotes and tags.
- [ ] Improved widget customization.
- [ ] Localization and multi-language support.
- [ ] Enhanced search and filter features.
- [ ] UI/UX improvements.

## Contributing

We welcome contributions! Please read the [Contributing Guidelines](#contributing-guidelines) below before submitting a pull request.

---

## Project Overview for New Contributors

This section provides a high-level overview of the codebase to help new contributors get started quickly.

### Architecture

The project is a Flutter application with the following main components:

- **Frontend (Flutter UI):** Handles all user interactions, displays quotes, and manages navigation.
- **Widget Integration:** Uses the `home_widget` package to communicate between the app and home screen widgets.
- **Local Database:** Uses Hive for persistent storage of quotes and tags.
- **State Management:** Uses the `provider` package for managing app state (quotes, tags).

### Major Folders and Files

- `lib/`
  - `main.dart`: App entry point, widget setup, and main logic.
  - `models/`: Data models for quotes and tags.
  - `provider/`: State management for quotes and tags.
  - `quote_home_page.dart`: Main UI for viewing and managing quotes.
  - `dash_with_sign.dart`: Custom widget for displaying the counter.
  - `helper/`: Utility functions and platform-specific bridges.
- `screenshots/`: Contains screenshots for documentation and PRs.
- `pubspec.yaml`: Project dependencies and metadata.

### How Components Interact

- The app starts from `main.dart`, initializing Hive and setting up providers.
- UI components interact with providers to read/write data.
- Widget actions (increment, clear) are handled via callbacks and update both the UI and the widget.
- The database (Hive) persists all quotes and tags locally.

---

## Getting Started for New Developers

1. **Fork and Clone the Repository**
   - Use the GitHub UI to fork, then clone your fork locally.

2. **Install Flutter and Dependencies**
   - See the [Getting Started](#getting-started) section above.

3. **Explore the Codebase**
   - Start with `lib/main.dart` to understand app initialization.
   - Review models in `lib/models/` and providers in `lib/provider/`.
   - UI logic is mainly in `lib/quote_home_page.dart`.

4. **Run and Test**
   - Use `flutter run` to launch the app on an emulator or device.

5. **Make Changes**
   - Follow best practices for Flutter and Dart.
   - Test your changes thoroughly.

6. **Submit a Pull Request**
   - See [Contributing Guidelines](#contributing-guidelines) below.

---

## Contributing Guidelines

- **Screenshots Required:** Every pull request (PR) must include relevant app screenshots showing the changes made.
  - Add screenshots to the `screenshots/` folder in the repository.
  - Update the [Screenshots](#screenshots) section in the README to include the new screenshots with appropriate captions or context.
  - Ensure screenshots are clearly labeled (e.g., `feature-login.png`, `fix-navbar-bug.png`) and correspond to the PR functionality.
  - Use the table format in the Screenshots section to display images side by side responsively.

- **Code Style:** Follow Dart and Flutter best practices.

- **Testing:** Ensure your changes do not break existing functionality.

- **Pull Request Template:**
  - Description of changes.
  - Screenshots before/after (added to `screenshots/`).
  - Any relevant issue numbers.

- **Communication:** If you have questions, open an issue or start a discussion.

---

Happy coding! 🚀
