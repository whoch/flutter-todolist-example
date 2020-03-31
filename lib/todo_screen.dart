import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

DBHelper dbHelper;
enum Mode { init, add, edit }
enum Status { none, done, pass }
final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

void showSnackBar(String text) {
  scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(text)));
}

IconData todoIconData(Status status) {
  switch (status) {
    case Status.none:
      return Icons.change_history;
    case Status.done:
      return Icons.radio_button_unchecked;
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
  TextEditingController _addController;

  @override
  void initState() {
    _mode = Mode.init;
    _handler = EventHandler(_todoListHandler);
    _addController = TextEditingController();
    initDatabase();
    debugPrint('--> init TodoScreen!');
  }

  void initDatabase() async {
    dbHelper = DBHelper.instance;
    await dbHelper.open();
    List<Todo> result = await dbHelper.select();
    setState(() {
      _todolist = result;
    });
  }

  @override
  void dispose() {
    dbHelper.close();
    _addController.dispose();
    debugPrint('---> dispose TodoScreen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
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
      ),
      resizeToAvoidBottomInset: false,
      body: TodoListView(_mode, _handler, _todolist),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              _addController.clear();
              return Container(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: TextField(
                  controller: _addController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '무엇을 할까요?',
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.add,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        _add(_addController.text);
                        Navigator.pop(context);
                      },
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (String content) {
                    _add(content);
                    Navigator.pop(context);
                  },
                ),
              );
            },
          );
        },
        child: Icon(
          Icons.add,
          color: Colors.grey[900],
        ),
        backgroundColor: Colors.white,
      ),
    );
  }

  void _add(String content) {
    if (content.length > 0) {
      _handler.add(content);
    }
  }

  void _todoListHandler(List<Todo> todoList) {
    setState(() {
      _todolist = todoList;
    });
  }
}

class AppBarBottomView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        child: Text(
          DateFormat('yyyy.MM.dd').format(DateTime.now()),
          style: TextStyle(fontSize: 30),
        ),
      ),
    );
  }
}

class TodoListView extends StatefulWidget {
  final Mode mode;
  final EventHandler handler;
  final List<Todo> todoList;

  TodoListView(this.mode, this.handler, this.todoList);

  @override
  _TodoListViewState createState() => _TodoListViewState();
}

class _TodoListViewState extends State<TodoListView> {
  SlidableController slidableController;

  @override
  void initState() {
    super.initState();
    slidableController = SlidableController();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemBuilder: (context, index) {
        Todo _todo = widget.todoList[index];
        int targetNo = _todo.no;
        return Slidable(
          key: Key('$targetNo'),
          controller: slidableController,
          actionPane: SlidableDrawerActionPane(),
          actionExtentRatio: 0.15,
          showAllActionsThreshold: 0.3,
          dismissal: SlidableDismissal(
            child: SlidableDrawerDismissal(),
            onWillDismiss: (actionType) {
              return actionType == SlideActionType.secondary;
            },
            onDismissed: (actionType) {
              widget.handler.delete(targetNo);
            },
          ),
          child: ListTile(
            leading: _todo.isPinning
                ? Icon(Icons.star, color: Colors.amberAccent[400])
                : null,
            title: Text(
              '${_todo.content}',
              style: TextStyle(
                color: _todo.status == Status.done
                    ? Colors.grey[350]
                    : Colors.grey[800],
              ),
            ),
            trailing: IconButton(
              icon: Icon(todoIconData(_todo.status)),
              onPressed: () {
                widget.handler.toggleStatus(targetNo, _todo.status);
              },
            ),
          ),
          actions: <Widget>[
            SlideAction(
              child: Icon(
                Icons.star,
                color: Colors.white,
              ),
              color: Colors.amberAccent,
              onTap: () {
                widget.handler.togglePinning(targetNo, _todo.isPinning);
              },
            ),
            SlideAction(
              child: Icon(
                Icons.edit,
                color: Colors.white,
              ),
              color: Colors.green,
              onTap: () {
                showModalBottomSheet(
                    context: context,
                    builder: (_) {
                      return EditModeView(widget.handler, _todo);
                    });
              },
            )
          ],
          secondaryActions: <Widget>[
            SlideAction(
              color: Colors.red,
              child: Icon(
                Icons.delete,
                color: Colors.white,
              ),
              closeOnTap: true,
              onTap: () {
                widget.handler.delete(targetNo);
              },
            )
          ],
        );
      },
      separatorBuilder: (_, __) {
        return Divider();
      },
      itemCount: widget.todoList.length,
    );
  }
}

class EditModeView extends StatefulWidget {
  final EventHandler handler;
  final Todo todo;

  EditModeView(this.handler, this.todo);

  @override
  _EditModeViewState createState() => _EditModeViewState();
}

class _EditModeViewState extends State<EditModeView> {
  TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController.fromValue(
      TextEditingValue(
        text: widget.todo.content,
        selection: TextSelection.collapsed(
          offset: widget.todo.content.length,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('----build');
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    if (_controller.text.length > 0) {
                      widget.handler.modify(widget.todo.no, _controller.text);
                    }
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
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

  Future<void> modify(int targetNo, String changeContent) async {
    int row =
        await dbHelper.updateContent(no: targetNo, content: changeContent);
    await _fetch();
    showSnackBar('수정 완료');
    debugPrint(
        '# update $row rows, no: $targetNo, change content: $changeContent');
  }

  Future<void> delete(int targetNo) async {
    int row = await dbHelper.delete(no: targetNo);
    await _fetch();
    showSnackBar('삭제 완료');
    debugPrint('# delete $row rows, no: $targetNo');
  }

  Future<void> toggleStatus(int targetNo, Status targetStatus) async {
    Status changeStatus =
        (targetStatus == Status.none ? Status.done : Status.none);
    int row = await dbHelper.updateStatus(no: targetNo, status: changeStatus);
    await _fetch();
    debugPrint(
        '# update $row rows, no: $targetNo, status: $targetStatus -> $changeStatus');
  }

  Future<void> togglePinning(int targetNo, bool isPinning) async {
    int row = await dbHelper.updatePinning(no: targetNo, isPinning: !isPinning);
    await _fetch();
    debugPrint(
        '# update $row rows, no: $targetNo, change pinning: ${!isPinning}');
  }
}

class Todo {
  int no;
  String content;
  Status status;
  bool isPinning;
  DateTime dueDttm;

  Todo({this.no, this.content, this.status, this.isPinning, this.dueDttm});

  Todo.add(String content) {
    this.content = content;
    this.status = Status.none;
    this.isPinning = false;
    this.dueDttm = DateTime.now();
  }

  @override
  String toString() {
    return 'Todo{no: $no, content: $content, status: $status, isPinning: $isPinning, dueDttm: $dueDttm}';
  }

  // convert type: text, integer, integer
  Map<String, dynamic> toMap() {
    return {
      if (no != null) 'no': no,
      if (content != null) 'content': content,
      if (status != null) 'status': status.index,
      if (isPinning != null) 'isPinning': isPinning ? 1 : 0,
      if (dueDttm != null) 'due_dttm': dueDttm.millisecondsSinceEpoch,
    };
  }

  // convert type: String, Status, DateTime
  Todo.fromMap(Map<String, dynamic> map) {
    no = map['no'];
    content = map['content'];
    status = Status.values[map['status']];
    isPinning = (map['isPinning'] == 1);
    dueDttm = DateTime.fromMillisecondsSinceEpoch(map['due_dttm']);
  }
}

class DBHelper {
  // Create a singleton
  DBHelper._();

  static final DBHelper instance = DBHelper._();
  Database _database;

  Future<Database> open() async {
    debugPrint('--> open database');
    String path = join(await getDatabasesPath(), 'todo.db');
//    await deleteDatabase(path);
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
            ,isPinning integer default 0
            ,due_dttm integer default (datetime('now', 'localtime'))
          )''',
        );
      },
    );
  }

  Future<void> close() async => _database.close();

  Future<List<Todo>> select() async {
    List<Map<String, dynamic>> _todoList =
        await _database.query('t_todo', orderBy: 'isPinning desc, no asc');
    return List.generate(_todoList.length, (i) {
      Map<String, dynamic> _map = _todoList[i];
      return Todo.fromMap(_map);
    });
  }

  Future<int> insert({@required String content}) async {
    Todo _td = Todo.add(content);
    return await _database.insert('t_todo', _td.toMap());
  }

  Future<int> updateContent(
      {@required int no, @required String content}) async {
    Todo t = Todo(content: content);
    return await _database
        .update('t_todo', t.toMap(), where: 'no = ?', whereArgs: [no]);
  }

  Future<int> updateStatus({@required int no, @required Status status}) async {
    Todo t = Todo(status: status);
    return await _database
        .update('t_todo', t.toMap(), where: 'no = ?', whereArgs: [no]);
  }

  Future<int> updatePinning(
      {@required int no, @required bool isPinning}) async {
    Todo t = Todo(isPinning: isPinning);
    return await _database
        .update('t_todo', t.toMap(), where: 'no = ?', whereArgs: [no]);
  }

  Future<int> delete({@required int no}) async {
    return await _database.delete('t_todo', where: 'no = ?', whereArgs: [no]);
  }
}
