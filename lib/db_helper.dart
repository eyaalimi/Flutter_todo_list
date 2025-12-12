
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';



class TaskModel {
  int? id;
  String title;
  String category;
  int duration;
  String type;
  String date; // stocker en String (yyyy-MM-dd)
  String status;
  int isArchived;

  TaskModel({
    this.id,
    required this.title,
    required this.category,
    required this.duration,
    required this.type,
    required this.date,
    required this.status,
    this.isArchived = 0,
  });

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'title': title,
      'category': category,
      'duration': duration,
      'type': type,
      'date': date,
      'status': status,
      'isArchived': isArchived,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'],
      title: map['title'],
      category: map['category'],
      duration: map['duration'],
      type: map['type'],
      date: map['date'],
      status: map['status'],
      isArchived: map['isArchived'],
    );
  }
}

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'todo_my_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            category TEXT,
            duration INTEGER,
            type TEXT,
            date TEXT,
            status TEXT,
            isArchived INTEGER
          )
        ''');
      },
    );
  }

  // CRUD
  Future<int> insertTask(TaskModel task) async {
    var dbClient = await db;
    return await dbClient.insert('tasks', task.toMap());
  }

  Future<List<TaskModel>> getTasks({int archived = 0}) async {
    var dbClient = await db;
    final List<Map<String, dynamic>> maps = await dbClient.query(
        'tasks',
        where: 'isArchived = ?',
        whereArgs: [archived],
        orderBy: "id DESC"
    );
    return List.generate(maps.length, (i) => TaskModel.fromMap(maps[i]));
  }

  Future<int> updateTask(TaskModel task) async {
    var dbClient = await db;
    return await dbClient.update(
        'tasks', task.toMap(),
        where: 'id = ?', whereArgs: [task.id]
    );
  }

  Future<int> deleteTask(int id) async {
    var dbClient = await db;
    return await dbClient.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}