import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('settings');
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDark = false;

  @override
  void initState() {
    super.initState();
    var box = Hive.box('settings');
    isDark = box.get('isDark', defaultValue: false);
  }

  void toggleTheme() {
    setState(() {
      isDark = !isDark;
      Hive.box('settings').put('isDark', isDark);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToDo Liste SQLite',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: TodoListScreen(
        isDark: isDark,
        toggleTheme: toggleTheme,
      ),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback toggleTheme;

  const TodoListScreen({
    super.key,
    required this.isDark,
    required this.toggleTheme,
  });

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<TaskModel> tasks = [];
  List<TaskModel> archiveTasks = [];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  String selectedCategory = 'Maison';
  String selectedType = 'Personnel';
  DateTime? selectedDate;
  String selectedStatus = 'À faire';
  int? editingId;

  final List<String> categories = ['Maison', 'Travail', 'Urgent', 'Divers'];
  final List<String> types = ['Personnel', 'Professionnel', 'Loisir'];
  final List<String> statuses = ['À faire', 'En cours', 'En progression', 'Fait'];

  @override
  void initState() {
    super.initState();
    _refreshTasks();
  }

  Future<void> _refreshTasks() async {
    final actives = await DBHelper().getTasks(archived: 0);
    final archives = await DBHelper().getTasks(archived: 1);
    setState(() {
      tasks = actives;
      archiveTasks = archives;
    });
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate() || selectedDate == null) return;
    final String dateStr = "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";

    TaskModel task = TaskModel(
      id: editingId,
      title: _titleController.text,
      category: selectedCategory,
      duration: int.tryParse(_durationController.text) ?? 0,
      type: selectedType,
      date: dateStr,
      status: selectedStatus,
      isArchived: 0,
    );

    if (editingId == null) {
      await DBHelper().insertTask(task);
    } else {
      await DBHelper().updateTask(task);
    }
    await _refreshTasks();
    _clearForm();
    Navigator.pop(context);
  }

  void _clearForm() {
    _titleController.clear();
    _durationController.clear();
    selectedCategory = categories[0];
    selectedType = types[0];
    selectedStatus = statuses[0];
    selectedDate = null;
    editingId = null;
  }

  void _showTaskForm({TaskModel? task}) {
    if (task != null) {
      editingId = task.id;
      _titleController.text = task.title;
      _durationController.text = task.duration.toString();
      selectedCategory = task.category;
      selectedType = task.type;
      selectedStatus = task.status;
      final parts = task.date.split('-').map((e) => int.parse(e)).toList();
      selectedDate = DateTime(parts[0], parts[1], parts[2]);
    } else {
      _clearForm();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(task == null ? 'Ajouter une tâche' : 'Modifier la tâche'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: 'Titre'),
                    validator: (value) => value == null || value.isEmpty ? 'Entrez un titre' : null,
                  ),
                  SizedBox(height: 10),
                  Text('Catégorie :'),
                  Column(
                    children: categories.map((c) => RadioListTile(
                      title: Text(c),
                      value: c,
                      groupValue: selectedCategory,
                      onChanged: (String? val) => setStateDialog(() => selectedCategory = val!),
                    )).toList(),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Durée (minutes)'),
                    validator: (value) => value == null || int.tryParse(value) == null ? 'Entrez une durée valide' : null,
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'Type'),
                    value: selectedType,
                    items: types.map((String t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (String? val) { if (val != null) setStateDialog(() => selectedType = val); },
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text('Date : '),
                      Expanded(
                        child: Text(
                          selectedDate == null
                              ? 'Non choisie'
                              : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: Icon(Icons.calendar_today_outlined),
                        label: Text('Choisir'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo[100],
                            foregroundColor: Colors.black87,
                            textStyle: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          DateTime now = DateTime.now();
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? now,
                            firstDate: DateTime(now.year - 2),
                            lastDate: DateTime(now.year + 5),
                          );
                          if (picked != null) setStateDialog(() => selectedDate = picked);
                        },
                      ),
                    ],
                  ),
                  if (selectedDate == null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Veuillez choisir une date",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'Statut'),
                    value: selectedStatus,
                    items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (String? val) { if (val != null) setStateDialog(() => selectedStatus = val); },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(child: Text('Annuler'), onPressed: () {
            _clearForm();
            Navigator.of(context).pop();
          }),
          ElevatedButton(
            child: Text(task == null ? 'Ajouter' : 'Enregistrer'),
            onPressed: _saveTask,
          ),
        ],
      ),
    );
  }

  Future<void> _archiveTask(TaskModel task) async {
    TaskModel updated = TaskModel(
      id: task.id,
      title: task.title,
      category: task.category,
      duration: task.duration,
      type: task.type,
      date: task.date,
      status: task.status,
      isArchived: 1,
    );
    await DBHelper().updateTask(updated);
    await _refreshTasks();
  }

  Future<void> _updateTaskStatus(TaskModel task, String newStatus) async {
    TaskModel updated = TaskModel(
      id: task.id,
      title: task.title,
      category: task.category,
      duration: task.duration,
      type: task.type,
      date: task.date,
      status: newStatus,
      isArchived: task.isArchived,
    );
    await DBHelper().updateTask(updated);
    await _refreshTasks();
  }

  void _showStatusDialog(TaskModel t) {
    String tempStatus = t.status;
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Statut de la tâche'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: statuses.map((s) => RadioListTile(
                  title: Text(s),
                  value: s,
                  groupValue: tempStatus,
                  onChanged: (String? val) {
                    if (val != null) setDialogState(() => tempStatus = val);
                  },
                )).toList(),
              );
            },
          ),
          actions: [
            TextButton(child: Text("Annuler"), onPressed: () => Navigator.pop(context)),
            ElevatedButton(
              child: Text("Mettre à jour"),
              onPressed: () async {
                await _updateTaskStatus(t, tempStatus);
                Navigator.pop(context);
              },
            ),
          ],
        )
    );
  }

  void _showArchive() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Tâches archivées'),
        content: Container(
          width: double.maxFinite,
          child: archiveTasks.isEmpty
              ? Text('Aucune tâche archivée.')
              : ListView.separated(
            shrinkWrap: true,
            itemCount: archiveTasks.length,
            separatorBuilder: (context, i) => Divider(),
            itemBuilder: (context, index) {
              TaskModel t = archiveTasks[index];
              final parts = t.date.split('-');
              final dateFr = "${parts[2]}/${parts[1]}/${parts[0]}";
              return ListTile(
                title: Text(
                  t.title,
                  style: TextStyle(decoration: TextDecoration.lineThrough),
                ),
                subtitle: Text(
                  'Catégorie: ${t.category}\nType: ${t.type}\nDurée: ${t.duration} min\nDate: $dateFr\nStatut: ${t.status}',
                  style: TextStyle(fontSize: 13),
                ),
                leading: Icon(Icons.archive, color: Colors.orangeAccent),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            child: Text('Fermer'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ma ToDo Liste - SQLite'),
        centerTitle: true,
        backgroundColor: Colors.indigo[600],
        actions: [
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: "Changer de thème",
            onPressed: widget.toggleTheme,
          ),
          IconButton(
            icon: Icon(Icons.archive_outlined),
            tooltip: "Voir les archives",
            onPressed: _showArchive,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Card(
                  color: Colors.indigo[50],
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    child: Column(
                      children: [
                        Text(
                          'Tâches',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                        ),
                        Text(
                          '${tasks.length}',
                          style: TextStyle(fontSize: 24, color: Colors.indigo, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _showArchive,
                  child: Card(
                    color: Colors.orange[50],
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      child: Column(
                        children: [
                          Text(
                            'Archives',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                          Text(
                            '${archiveTasks.length}',
                            style: TextStyle(
                                fontSize: 24,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.archive),
                    label: Text('Archiver sélectionnées'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: tasks.any((t) => t.isArchived == 0)
                        ? () async {
                      for (var t in tasks.where((t) => t.isArchived == 0)) {
                        // à adapter pour sélection multiple si besoin
                      }
                    }
                        : null,
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Ajouter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[400],
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => _showTaskForm(),
                ),
              ],
            ),
          ),
          Divider(thickness: 1),
          Expanded(
            child: tasks.isEmpty
                ? Center(child: Text("Aucune tâche à faire."))
                : ListView.separated(
              itemCount: tasks.length,
              separatorBuilder: (_, __) => Divider(),
              itemBuilder: (context, index) {
                TaskModel t = tasks[index];
                final parts = t.date.split('-');
                final dateFr = "${parts[2]}/${parts[1]}/${parts[0]}";
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                    side: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    title: Text(t.title, style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 3),
                        Text("Catégorie : ${t.category}", style: TextStyle(fontSize: 13)),
                        Text("Type : ${t.type} | Durée : ${t.duration} min", style: TextStyle(fontSize: 13)),
                        Text("Date : $dateFr", style: TextStyle(fontSize: 12)),
                        Row(
                          children: [
                            Icon(Icons.flag, size: 16, color: Colors.indigo),
                            SizedBox(width: 6),
                            Text("Statut : ${t.status}", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        )
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.archive, color: Colors.orange),
                          tooltip: 'Archiver',
                          onPressed: () async {
                            await _archiveTask(t);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.edit_outlined, color: Colors.indigo),
                          onPressed: () => _showTaskForm(task: t),
                        ),
                      ],
                    ),
                    onTap: () => _showStatusDialog(t),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}