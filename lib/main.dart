import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
class TaskCubit extends Cubit<List<Map<String, dynamic>>> {
  TaskCubit() : super([]);
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  void fetchItems() {
    CollectionReference collection = firestore.collection('items');
    collection.snapshots().listen((snapshot) {
      List<Map<String, dynamic>> items = [];
      for (var doc in snapshot.docs) {
        items.add({'id': doc.id, ...doc.data() as Map<String, dynamic>});
      }
      emit(items);
    });
  }

  void deleteItem(String id) async {
    await firestore.collection('items').doc(id).delete();
  }

  void addItem(String name) async {
    await firestore.collection('items').add({'name': name});
  }

  void editItem(String id, String name) async {
    await firestore.collection('items').doc(id).update({'name': name});
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TaskCubit()..fetchItems(),
      child: MaterialApp(
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({super.key});

  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Firebase Task'),
      ),
      body: BlocBuilder<TaskCubit, List<Map<String, dynamic>>>(
          builder: (context, items) {
        return items.isEmpty
            ? Center(
                child: Text('No Data Found'),
              )
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  var item = items[index];
                  return ListTile(
                    title: Text(item['name']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            onPressed: () {
                              MyDialog(context, item['id'], item['name']);
                            },
                            icon: Icon(Icons.edit)),
                        IconButton(
                            onPressed: () {
                              context.read<TaskCubit>().deleteItem(item['id']);
                            },
                            icon: Icon(Icons.delete)),
                      ],
                    ),
                  );
                });
      }),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            MyDialog(context, null, '');
          }),
    );
  }

  void MyDialog(BuildContext context, String? id, String initialName) {
    _controller.text = initialName;
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(id == null ? "Add Task" : "Edit Task"),
              content: TextField(controller: _controller),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel")),
                TextButton(
                    onPressed: () {
                      if (_controller.text.trim().isEmpty) return;
                      final taskCubit = context.read<TaskCubit>();
                      if (id == null) {
                        taskCubit.addItem(_controller.text.trim());
                      } else {
                        taskCubit.editItem(id, _controller.text.trim());
                      }
                      Navigator.pop(context);
                    },
                    child: Text("Save"))
              ],
            ));
  }
}
