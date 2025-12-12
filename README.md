
# Flutter ToDo List App

A simple, beautiful, and persistent ToDo list Flutter application that supports dark/light theme switching and data storage with SQLite & Hive.

![screenshot](doc/sample_screenshot.png) <!-- You can add/replace with your app screenshot path if needed -->

---

## ✨ Features

- Add, edit, delete ToDos
- Archive and view archived tasks
- Categories, types, status, due date, and duration for each task
- Modern Material 3 UI (indigo theme)
- **Dark/Light mode**, with user selection and automatic save using Hive
- Data persistence using **SQLite** (for tasks) and **Hive** (for theme)

---

## 🚀 Getting Started

### 1. Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Git](https://git-scm.com/)

### 2. Clone the Repository

```sh
git clone https://github.com/eyaalimi/Flutter_todo_list.git
cd Flutter_todo_list
```

### 3. Install Dependencies

```sh
flutter pub get
```

### 4. Run the Application

```sh
flutter run
```

> The app supports Android, iOS, web, Windows, macOS, and Linux (as per Flutter support level).

---

## 🛠️ Project Structure

```
lib/
 ├── main.dart               # Main app entry point, theme management
 ├── db_helper.dart          # SQLite helper and TaskModel
 └── ...                     # Other .dart files and logic
```
- **`db_helper.dart`**: All SQLite access logic, TaskModel definition
- **`main.dart`**: UI, theme logic, navigation, Hive integration

---

## 📦 Dependencies

- [flutter](https://flutter.dev/)
- [hive](https://pub.dev/packages/hive)
- [hive_flutter](https://pub.dev/packages/hive_flutter)
- [sqflite](https://pub.dev/packages/sqflite)
- [path_provider](https://pub.dev/packages/path_provider)

See [`pubspec.yaml`](pubspec.yaml) for full list and versions.

---

## 🌒 Theme Persistence

- The theme (dark or light) is set via the UI (app bar icon)
- User choice is saved in Hive (`settings/isDark`)
- Theme is restored automatically when you restart the app

---

## 📝 Screenshots

<!-- Replace with your own screenshots if needed -->
| Light mode                | Dark mode                  |
|---------------------------|----------------------------|
| ![light mode](doc/light.png) | ![dark mode](doc/dark.png) |

---

## 🤝 Contributions

Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

---

## 📄 License

[MIT](LICENSE)

---

## 👤 Author

- **eya alimi**  
  [GitHub: @eyaalimi](https://github.com/eyaalimi)

---

*Built with ❤️ using [Flutter](https://flutter.dev/)*
