import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';

enum Status { none, done, pass }

class TodoScreen extends StatefulWidget {
  @override
  _TodoScreenState createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'my todo list',
          style: TextStyle(color: Colors.grey[900]),
        ),
        /* # memo:
        Only widgets that implement [PreferredSizeWidget]
        can be used at the bottom of an app bar
        */
        bottom: PreferredSize(
          child: AppBarBottomView(),
          preferredSize: Size.fromHeight(100),
        ),
        backgroundColor: Colors.white.withOpacity(0.95),
        centerTitle: true,
        actions: <Widget>[
          FlatButton(
            onPressed: () {},
            child: Text('편집', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
      body: TodoListView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          debugPrint('click add button');
        },
        child: Icon(
          Icons.add,
          color: Colors.grey[900],
        ),
        backgroundColor: Colors.white,
      ),
    );
  }
}

class AppBarBottomView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        child: Text(
          '2020-03-12',
          style: TextStyle(fontSize: 30),
        ),
      ),
    );
  }
}

// # ListTile.divideTiles vs ListView.separated
// 참고 url:
// https://stackoverflow.com/questions/50687633/flutter-divider-how-could-i-add-divider-between-each-line-in-my-code
// https://stackoverflow.com/questions/52207612/how-to-use-dividetiles-in-flutter
// - short static list: divideTiles, long dynamic list: separated를 사용
//  -> 이유: 소스코드를 보면 아래와 같이 설명 되어있음
//    * large number of item and separator children
//    * because the builders are only called for the children that are actually visible.
class TodoListView extends StatefulWidget {
  @override
  _TodoListViewState createState() => _TodoListViewState();
}

class _TodoListViewState extends State<TodoListView> {
  Database _db;
  List<Todo> _todolist = <Todo>[];

  @override
  void initState() {
    initData();
  }

  void initData() async {
    _db = await DB.open();
    insert();
    _todolist = await select();
    debugPrint('###### todo' + _todolist.toString());
  }

  @override
  void dispose() {
    _db.close();
    debugPrint('---> dispose database');
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemBuilder: (context, index) {
        Todo _todo = _todolist[index];
        return ListTile(
          title: Text('$index, ${_todo.content}, ${_todo.status}'),
          trailing: Icon(Todo.iconData(_todo.status)),
        );
      },
      separatorBuilder: (_, index) {
        return Divider();
      },
      itemCount: _todolist.length,
    );
  }

  Future<List<Todo>> select() async {
    List<Map<String, dynamic>> _result = await _db.query('t_todo');
    return List.generate(_result.length, (i) {
      Map<String, dynamic> _td = _result[i];
      return Todo(
        _td['content'],
        status: _td['status'],
        dueDttm: _td['dueDttm'],
      );
    });
  }

  void insert() {
    Todo _td = Todo('insert todo');
    _db.insert('t_todo', _td.toResultMap());
  }
}

class Todo {
  String content;
  Status status;
  DateTime dueDttm;

  Todo(String content, {Status status, DateTime dueDttm}) {
    this.content = content;
    this.status = status ?? Status.none;
    this.dueDttm = dueDttm ?? DateTime.now();
  }

  @override
  String toString() {
    return 'Todo{content: $content, status: $status, dueDttm: $dueDttm}';
  }

  Map<String, dynamic> toResultMap() {
    return {
      'content': content,
      'status': status.index,
      'due_dttm': dueDttm.millisecondsSinceEpoch,
    };
  }

  static IconData iconData(Status status) {
    switch (status) {
      case Status.none:
        return Icons.change_history;
      case Status.done:
        return Icons.check;
      case Status.pass:
        return Icons.arrow_forward;
    }
  }
}

class DB {
  static Future<Database> open() async {
    debugPrint('---> open database');
    String _path = join(await getDatabasesPath(), 'todo.db');
    await deleteDatabase(_path);
    return openDatabase(
      _path,
      version: 1,
      onCreate: (db, version) {
        debugPrint('---> on create database');
        return db.execute(
          '''create table t_todo(
            no integer primary key autoincrement
            ,content text not null
            ,status text default 0
            ,due_dttm integer default (datetime('now', 'localtime'))
          )''',
        );
      },
    );
  }
}
