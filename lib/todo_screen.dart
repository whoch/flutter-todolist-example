import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

DBHelper dbHelper;
enum Mode { init, add, edit }
enum Status { none, done, pass }

IconData todoIconData(Status status) {
  switch (status) {
    case Status.none:
      return Icons.change_history;
    case Status.done:
      return Icons.check;
    case Status.pass:
      return Icons.arrow_forward;
  }
}

class TodoScreen extends StatefulWidget {
  @override
  _TodoScreenState createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  Mode _mode;
  EventHandler _handler;
  List<Todo> _todolist = <Todo>[];

  @override
  void initState() {
    _mode = Mode.init;
    _handler = EventHandler(_todoListHandler);
    initDatabase();
    debugPrint('--> init State!');
  }

  void initDatabase() async {
    dbHelper = DBHelper.instance;
    await dbHelper.open();
    _todolist = await dbHelper.select();
  }

  @override
  void dispose() {
    dbHelper.close();
    debugPrint('---> dispose database');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('parent build!');
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
      body: TodoListView(_mode, _handler, _todolist),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return Container(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: '무엇을 할까요?',
                      suffixIcon: Icon(Icons.add),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (String content) {
                      _handler.add(content);
                      Navigator.pop(context);
                    },
                  ),
                );
              });
        },
        child: Icon(
          Icons.add,
          color: Colors.grey[900],
        ),
        backgroundColor: Colors.white,
      ),
    );
  }

  void _todoListHandler(List<Todo> todoList) {
    setState(() {
      _todolist = todoList;
    });
  }
}

class EventHandler {
  final ValueChanged<List<Todo>> _handler;
  EventHandler(this._handler);

  Future<void> _fetch() async {
    List<Todo> result = await dbHelper.select();
    _handler(result);
  }

  Future<void> add(String content) async {
    int row = await dbHelper.insert(content: content);
    await _fetch();
    debugPrint('# insert $row rows, content: $content');
  }

  Future<void> toggleStatus(int targetNo, Status targetStatus) async {
    Status changeStatus =
        (targetStatus == Status.none ? Status.done : Status.none);
    int row = await dbHelper.updateStatus(no: targetNo, status: changeStatus);
    await _fetch();
    debugPrint(
        '# update $row rows, no: $targetNo, status: $targetStatus -> $changeStatus');
  }

  Future<void> modify(int targetNo, String changeContent) async {
    int row =
        await dbHelper.updateContent(no: targetNo, content: changeContent);
    await _fetch();
    debugPrint(
        '# update $row rows, no: $targetNo, change content: $changeContent');
  }

  Future<void> delete(int targetNo) async {
    int row = await dbHelper.delete(no: targetNo);
    await _fetch();
    debugPrint('# delete $row rows, no: $targetNo');
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

class TodoListView extends StatelessWidget {
  final Mode _mode;
  final EventHandler _handler;
  final List<Todo> _todolist;

  TodoListView(this._mode, this._handler, this._todolist);

  @override
  Widget build(BuildContext context) {
    debugPrint('child build!');
    return ListView.separated(
      itemBuilder: (context, index) {
        Todo _todo = _todolist[index];
        return ListTile(
          leading: _mode == Mode.edit
              ? IconButton(
                  icon: Icon(Icons.remove_circle),
                  onPressed: () {
                    _handler.delete(_todo.no);
                  },
                )
              : null,
          title:
              Text('<${_mode}> ${_todo.no}, ${_todo.content}, ${_todo.status}'),
          trailing: _mode == Mode.init
              ? IconButton(
                  icon: Icon(todoIconData(_todo.status)),
                  onPressed: () {
                    _handler.toggleStatus(_todo.no, _todo.status);
                  },
                )
              : _mode == Mode.edit
                  ? IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        debugPrint('edit click: ${_todo.no}');
                        showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              TextEditingController _controller =
                                  TextEditingController(text: _todo.content);
                              return Column(
                                children: <Widget>[
                                  Container(
                                    color: Colors.grey[200],
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        FlatButton(
                                          child: Text('닫기'),
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                        ),
                                        FlatButton(
                                          child: Text('저장'),
                                          onPressed: () {
                                            _handler.modify(
                                                _todo.no, _controller.text);
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextField(
                                    controller: _controller,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ],
                              );
                            });
                      },
                    )
                  : null,
        );
      },
      separatorBuilder: (_, index) {
        return Divider();
      },
      itemCount: _todolist.length,
    );
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

  // 위에랑 뭐가 다르지
  factory Todo.fromMap2(Map<String, dynamic> map) => Todo(
        no: map['no'],
        status: Status.values[map['status']],
        content: map['content'],
        dueDttm: DateTime.fromMillisecondsSinceEpoch(map['due_dttm']),
      );
}

class DBHelper {
  // Create a singleton
  DBHelper._();

  static final DBHelper instance = DBHelper._();
  Database _database;

  Future<Database> open() async {
    debugPrint('--> open database');
    String path = join(await getDatabasesPath(), 'todo.db');
//    await deleteDatabase(_path);
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        debugPrint('--> on create database');
        await db.execute(
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

  Future<void> close() async => _database.close();

  Future<List<Todo>> select() async {
    List<Map<String, dynamic>> _todoList = await _database.query('t_todo');
    debugPrint('$_todoList');
    return List.generate(_todoList.length, (i) {
      Map<String, dynamic> _map = _todoList[i];
      return Todo.fromMap(_map);
    });
  }

  Future<int> insert({@required String content}) async {
    Todo _td = Todo.add(content);
    return await _database.insert('t_todo', _td.toMap());
  }

  Future<int> updateStatus({@required int no, @required Status status}) async {
    Todo t = Todo(status: status);
    return await _database
        .update('t_todo', t.toMap(), where: 'no = ?', whereArgs: [no]);
  }

  Future<int> updateContent(
      {@required int no, @required String content}) async {
    Todo t = Todo(content: content);
    return await _database
        .update('t_todo', t.toMap(), where: 'no = ?', whereArgs: [no]);
  }

  Future<int> delete({@required int no}) async {
    return await _database.delete('t_todo', where: 'no = ?', whereArgs: [no]);
  }
}
