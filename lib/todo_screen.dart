import 'package:flutter/material.dart';

enum Status { none, complete, pass }

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
        // Only widgets that implement [PreferredSizeWidget]
        // can be used at the bottom of an app bar
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
  List<Todo> _todolist = [];

  @override
  void initState() {
    Todo _t = Todo('todolist 만들기', Status.none, DateTime.now());
    Todo _t2 = Todo('todolist 만들기', Status.pass, DateTime.now());
    Todo _t3 = Todo('todolist 만들기', Status.complete, DateTime.now());
    _todolist.addAll([_t, _t2, _t3]);
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
}

class Todo {
  final String content;
  final Status status;
  final DateTime datetime;

  Todo(this.content, this.status, this.datetime);

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'status': status,
      'DateTime': datetime,
    };
  }

  static IconData iconData(Status status) {
    switch (status) {
      case Status.none:
        return Icons.change_history;
      case Status.complete:
        return Icons.check;
      case Status.pass:
        return Icons.arrow_forward;
    }
  }
}
