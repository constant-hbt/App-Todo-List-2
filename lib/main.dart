import 'dart:convert' as convert;
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

void main() {
  runApp(
    const MaterialApp(
      home: Home(),
    ),
  );
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController taskController = TextEditingController();
  List _toDoList = [];
  Map<String, dynamic>? _lastRemoved;
  int? _lastRemovedPos;

  @override
  void initState() {
    super.initState();

    _readData()
        .then((value) => convert.jsonDecode(value))
        .then((value) =>
        setState(() {
          print(value);
          _toDoList = value;
        }));
  }

  void addToDo() {
    String newTask = taskController.text;
    if (newTask.isEmpty) {
      return;
    }

    Map<String, dynamic> newTodo = <String, dynamic>{
      'title': newTask,
      'ok': false
    };

    taskController.text = '';
    setState(() {
      _toDoList.add(newTodo);
      _saveData();
    });
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/tasks.json');
  }

  Future<File> _saveData() async {
    String data = convert.jsonEncode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsStringSync();
    } catch (e) {
      print('Erro ao ler os dados');
    }

    return '[]';
  }

  void delete(int index){
    _lastRemoved = Map.from(_toDoList[index]);
    _lastRemovedPos = index;

    setState(() {
      _toDoList.removeAt(index);
      _saveData();
    });

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        'Tarefa ${_lastRemoved?['title']} foi removida com sucesso',
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.blueAccent,
      action: SnackBarAction(
        label: 'Desfazer',
        textColor: Colors.white,
        onPressed: () {
          setState(() {
            _toDoList.insert(_lastRemovedPos!, _lastRemoved!);
            _saveData();
          });
        },
      ),
      duration: const Duration(seconds: 5),
    ));
  }

  Future<void> _refresh() async{
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _toDoList.sort((first, second){
        if(first['ok'] && !second['ok']) {
          return 1;
        } else if(!first['ok'] && second['ok']) {
          return -1;
        } else {
          return 0;
        }
      });

      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Tarefas'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(17, 1, 7, 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: taskController,
                    decoration: const InputDecoration(
                      labelText: 'Nova Tarefa',
                      labelStyle: TextStyle(
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: addToDo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: const Text(
                    'ADD',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                    padding: const EdgeInsets.only(top: 10),
                    itemCount: _toDoList.length,
                    itemBuilder: buildItem
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      background: Container(
      color: Colors.red,
      child: const Align(
          alignment: Alignment(-0.9, 0),
          child: Icon(Icons.delete, color: Colors.white,),
        ),
      ),
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction){
        delete(index);
      },
      child: CheckboxListTile(
        title: Text(_toDoList[index]['title'] ?? ''),
        value: _toDoList[index]['ok'] ?? false,
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]['ok'] ?? false
              ? Icons.check
              : Icons.error),
        ),
        onChanged: (checked) {
          setState(() {
            _toDoList[index]['ok'] = checked;
            _saveData();
          });
        },
      ),
    );
  }
}