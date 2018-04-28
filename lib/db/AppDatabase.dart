import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/Label.dart';
import 'package:flutter_app/models/Project.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_app/models/Tasks.dart';

class AppDatabase {
  static final AppDatabase _appDatabase = new AppDatabase._internal();

  AppDatabase._internal();

  Database _database;

  static AppDatabase get() {
    return _appDatabase;
  }

  bool didInit = false;

  /// Use this method to access the database, because initialization of the database (it has to go through the method channel)
  Future<Database> _getDb() async {
    if (!didInit) await _init();
    return _database;
  }

  Future _init() async {
    // Get a location using path_provider
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "tasks.db");
    _database = await openDatabase(path, version: 6,
        onCreate: (Database db, int version) async {
      // When creating the db, create the table
      await _createTaskTable(db);
      await _createProjectTable(db);
      await _createLabelTable(db);
    }, onUpgrade: (Database db, int oldVersion, int newVersion) async {
      await db.execute("DROP TABLE ${Tasks.tblTask}");
      await db.execute("DROP TABLE ${Project.tblProject}");
      await _createTaskTable(db);
      await _createProjectTable(db);
      await _createLabelTable(db);
    });
    didInit = true;
  }

  Future _createProjectTable(Database db) {
    return db.transaction((Transaction txn) async {
      txn.execute("CREATE TABLE ${Project.tblProject} ("
          "${Project.dbId} INTEGER PRIMARY KEY AUTOINCREMENT,"
          "${Project.dbName} TEXT,"
          "${Project.dbColorName} TEXT,"
          "${Project.dbColorCode} INTEGER);");
      txn.rawInsert('INSERT INTO '
          '${Project.tblProject}(${Project.dbId},${Project.dbName},${Project
          .dbColorName},${Project.dbColorCode})'
          ' VALUES(1, "Inbox", "Grey", ${Colors.grey.value});');
    });
  }

  Future _createLabelTable(Database db) {
    return db.execute("CREATE TABLE ${Label.tblLabel} ("
        "${Label.dbId} INTEGER PRIMARY KEY AUTOINCREMENT,"
        "${Label.dbName} TEXT,"
        "${Label.dbColorName} TEXT,"
        "${Label.dbColorCode} INTEGER);");
  }

  Future _createTaskTable(Database db) {
    return db.execute("CREATE TABLE ${Tasks.tblTask} ("
        "${Tasks.dbId} INTEGER PRIMARY KEY AUTOINCREMENT,"
        "${Tasks.dbTitle} TEXT,"
        "${Tasks.ddComment} TEXT,"
        "${Tasks.dbDueDate} LONG,"
        "${Tasks.dbPriority} LONG,"
        "${Tasks.dbProjectID} INTEGER,"
        "FOREIGN KEY(${Tasks.dbProjectID}) REFERENCES ${Project
        .tblProject}(${Project.dbId}) ON DELETE CASCADE;");
  }

  Future<List<Tasks>> getTasks() async {
    var db = await _getDb();
    var result = await db.rawQuery('SELECT * FROM ${Tasks.tblTask}');
    List<Tasks> tasks = new List();
    for (Map<String, dynamic> item in result) {
      var myTask = new Tasks.fromMap(item);
      tasks.add(myTask);
    }
    return tasks;
  }

  Future<List<Project>> getProjects() async {
    var db = await _getDb();
    var result = await db.rawQuery('SELECT * FROM ${Project.tblProject}');
    List<Project> projects = new List();
    for (Map<String, dynamic> item in result) {
      var myProject = new Project.fromMap(item);
      projects.add(myProject);
    }
    return projects;
  }

  Future<List<Label>> getLabels() async {
    var db = await _getDb();
    var result = await db.rawQuery('SELECT * FROM ${Label.tblLabel}');
    List<Label> projects = new List();
    for (Map<String, dynamic> item in result) {
      var myProject = new Label.fromMap(item);
      projects.add(myProject);
    }
    return projects;
  }

  /// Inserts or replaces the task.
  Future updateTask(Tasks task) async {
    var db = await _getDb();
    await db.transaction((Transaction txn) async {
      await txn.rawInsert('INSERT OR REPLACE INTO '
          '${Tasks.tblTask}(${Tasks.dbId},${Tasks.dbTitle},${Tasks
          .ddComment},${Tasks.dbDueDate},${Tasks.dbPriority})'
          ' VALUES(${task.id}, "${task.title}", "${task
          .comment}", ${task.dueDate},${task.priority.index})');
    });
  }

  Future updateProject(Project project) async {
    var db = await _getDb();
    await db.transaction((Transaction txn) async {
      await txn.rawInsert('INSERT OR REPLACE INTO '
          '${Project.tblProject}(${Project.dbId},${Project.dbName},${Project
          .dbColorCode},${Project.dbColorName})'
          ' VALUES(${project.id},"${project.name}", ${project
          .colorValue}, "${project.colorName}")');
    });
  }

  Future updateLabels(Label label) async {
    var db = await _getDb();
    await db.transaction((Transaction txn) async {
      await txn.rawInsert('INSERT OR REPLACE INTO '
          '${Label.tblLabel}(${Label.dbName},${Label
          .dbColorCode},${Label.dbColorName})'
          ' VALUES("${label.name}", ${label
          .colorValue}, "${label.colorName}")');
    });
  }

  Future deleteProject(int projectID) async {
    var db = await _getDb();
    await db.transaction((Transaction txn) async {
      await txn.rawDelete('DELETE FROM ${Project.tblProject} WHERE ${Project
          .dbId}==$projectID;');
    });
  }
}
