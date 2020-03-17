import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

enum Status { none, done, pass }
enum Mode { init, add, edit }

class TodoScreen extends StatefulWidget {
  @override
  _TodoScreenState createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  Mode _mode;

  @override
  void initState() {
    _mode = Mode.init;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'my todo list',
          style: TextStyle(color: Colors.grey[900]),
        ),
        bottom: PreferredSize(
          child: AppBarBottomView(),
          preferredSize: Size.fromHeight(100),
        ),
        backgroundColor: Colors.white.withOpacity(0.95),
        centerTitle: true,
        actions: <Widget>[
          FlatButton(
            onPressed: () {
              bool isEditmode = (_mode == Mode.edit);
              setState(() {
                _mode = isEditmode ? Mode.init : Mode.edit;
              });
            },
            child: _mode == Mode.edit
                ? Text('완료', style: TextStyle(fontSize: 18))
                : Text('편집', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
      resizeToAvoidBottomPadding: false,
      body: TodoListView(mode: _mode),
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
  final Mode mode;

  TodoListView({@required this.mode});

  @override
  _TodoListViewState createState() => _TodoListViewState();
}

class _TodoListViewState extends State<TodoListView> {
  Database _db;
  FocusNode _focusNode;
  List<Todo> _todolist = <Todo>[];
  Todo _target;

  @override
  void initState() {
    initData();
    _focusNode = FocusNode();
    debugPrint('--> init State!');
  }

  void initData() async {
    _db = await DB.open();
    _todolist = await select();
  }

  @override
  void dispose() {
    _db.close();
    _focusNode.dispose();
    debugPrint('---> dispose database');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('--> build! ${widget.mode}');
    return Column(
      children: <Widget>[
        TextField(
          focusNode: _focusNode,
          onSubmitted: (String value) async {
            switch (widget.mode) {
              case Mode.init:
                await insert(content: value);
                break;
              case Mode.edit:
//                await update(content: value, currentNo: _target.no);
//                _target = null;
                break;
              case Mode.add:
                break;
            }
            List<Todo> result = await select();
            setState(() {
              _todolist = result;
            });
          },
        ),
        SizedBox(
          height: 400,
          child: ListView.separated(
            itemBuilder: (context, index) {
              Todo _todo = _todolist[index];
              return ListTile(
                leading: widget.mode == Mode.edit
                    ? IconButton(
                        icon: Icon(Icons.remove_circle),
                        onPressed: () async {
                          debugPrint('delete click: ${_todo.no}');
                          await delete(targetNo: _todo.no);
                          List<Todo> result = await select();
                          setState(() {
                            _todolist = result;
                          });
                        },
                      )
                    : null,
                title: Text(
                    '<${widget.mode}> ${_todo.no}, ${_todo.content}, ${_todo.status}'),
                trailing: widget.mode == Mode.init
                    ? IconButton(
                        icon: Icon(Todo.iconData(_todo.status)),
                        onPressed: () async {
                          Status _toggle = (_todo.status == Status.none
                              ? Status.done
                              : Status.none);
                          await updateStatus(
                              targetNo: _todo.no, status: _toggle);
                          List<Todo> result = await select();
                          setState(() {
                            _todolist = result;
                          });
                        },
                      )
                    : widget.mode == Mode.edit
                        ? IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              debugPrint('edit click no: ${_todo.no}');
//                              _target = _todo;
//                              _focusNode.requestFocus();
                            },
                          )
                        : null,
              );
            },
            separatorBuilder: (_, index) {
              return Divider();
            },
            itemCount: _todolist.length,
          ),
        ),
      ],
    );
  }

  Future<List<Todo>> select() async {
    List<Map<String, dynamic>> _todoList = await _db.query('t_todo');
    debugPrint('$_todoList');
    return List.generate(_todoList.length, (i) {
      Map<String, dynamic> _map = _todoList[i];
      return Todo.fromMap(_map);
    });
  }

  void insert({@required String content}) {
    Todo _td = Todo.add(content);
    _db.insert('t_todo', _td.toMap());
  }

  Future<void> updateStatus(
      {@required int targetNo, @required Status status}) async {
    Todo t = Todo(status: status);
    int rows = await _db
        .update('t_todo', t.toMap(), where: 'no = ?', whereArgs: [targetNo]);
    debugPrint('# update rows: $rows');
  }

  Future<void> delete({@required int targetNo}) async {
    int rows =
        await _db.delete('t_todo', where: 'no = ?', whereArgs: [targetNo]);
    debugPrint('# delete rows: $rows');
  }
}

class Todo {
  int no;
  String content;
  Status status;
  DateTime dueDttm;

  Todo({this.no, this.content, this.status, this.dueDttm});

  Todo.add(String content) {
    this.content = content;
    this.status = Status.none;
    this.dueDttm = DateTime.now();
  }

  @override
  String toString() {
    return 'Todo{no: $no, content: $content, status: $status, dueDttm: $dueDttm}';
  }

  // convert type: text, integer, integer
  Map<String, dynamic> toMap() {
    return {
      if (no != null) 'no': no,
      if (content != null) 'content': content,
      if (status != null) 'status': status.index,
      if (dueDttm != null) 'due_dttm': dueDttm.millisecondsSinceEpoch,
    };
  }

  // convert type: String, Status, DateTime
  Todo.fromMap(Map<String, dynamic> map) {
    no = map['no'];
    content = map['content'];
    status = Status.values[map['status']];
    dueDttm = DateTime.fromMillisecondsSinceEpoch(map['due_dttm']);
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
    debugPrint('--> open database');
    String _path = join(await getDatabasesPath(), 'todo.db');
//    await deleteDatabase(_path);
    return openDatabase(
      _path,
      version: 1,
      onCreate: (db, version) {
        debugPrint('--> on create database');
        return db.execute(
          '''create table t_todo(
            no integer primary key autoincrement
            ,content text not null
            ,status integer default 0
            ,due_dttm integer default (datetime('now', 'localtime'))
          )''',
        );
      },
    );
  }
}
