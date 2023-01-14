import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomePage(),
  ));
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map> todoList = [];
  Map<String, dynamic> lastRemoved = {};
  int lastRemovedPos = 0;
  String? errorMessage;

  final todoController = TextEditingController();

  @override
  void initState(){
    super.initState();
    readData().then((data){
      setState((){
        todoList = json.decode(data!);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Tarefas'),
        backgroundColor: const Color(0xff9C27B0),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                 Expanded(
                  child: TextField(
                    controller: todoController,
                    decoration: InputDecoration(
                      errorText: errorMessage,
                      labelText: 'Nova tarefa',
                      labelStyle: const TextStyle(
                        color: Color(0xff9C27B0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    backgroundColor: const Color(0xff9C27B0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: (){
                    String text = todoController.text;
                    if(text.isEmpty){
                      setState((){
                        errorMessage = 'A tarefa não pode ser vazia.';
                      });
                      return;
                    } else{
                      addToDo();
                      errorMessage = null;
                    }
                  },
                  child: const Icon(
                    Icons.add,
                    size: 30,
                  )
                ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 20),
                  itemCount: todoList.length,
                  itemBuilder: buildItem,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<File> getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

  Future<File> saveData() async {
    String data = json.encode(todoList);
    final file = await getFile();
    return file.writeAsString(data);
  }

  Future<String?> readData() async {
    try {
      final file = await getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  void addToDo(){
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo['title'] = todoController.text;
      todoController.text = "";
      newToDo['ok'] = false;
      todoList.add(newToDo);
      saveData();
    });
  }

  Widget buildItem(BuildContext context, int index){
    return Dismissible(
      key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: const Align(
          alignment: Alignment(-0.9, 0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(todoList[index]['title']),
        value: todoList[index]['ok'],
        secondary: CircleAvatar(
          backgroundColor: const Color(0xff9C27B0),
          child: Icon(
            todoList[index]['ok'] ? Icons.check : Icons.warning_amber_rounded,
            color: Colors.white,
          ),
        ),
        onChanged: (check){
          setState(() {
            todoList[index]['ok'] = check;
            saveData();
          });
        },
      ),
      onDismissed: (direction){
        setState((){
          lastRemoved = Map.from(todoList[index]);
          lastRemovedPos = index;
          todoList.removeAt(index);
          saveData();

          final snack = SnackBar(
            content: Text('Tarefa ${lastRemoved['title'].toString().toLowerCase()} removida.'),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: (){
                setState(() {
                  todoList.insert(lastRemovedPos, lastRemoved);
                  saveData();
                });
              },
            ),
            duration: const Duration(seconds: 5),
          );

          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<void> refresh() async{
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      todoList.sort((a, b){
        if(a['ok'] && !b['ok']) {
          return 1;
        } else if(!a['ok'] && b['ok']) {
          return -1;
        } else {
          return 0;
        }
      });

      saveData();
    });
  }
}