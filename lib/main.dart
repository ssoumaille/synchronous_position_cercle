import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'circle/circle.dart';

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);


  FirebaseFirestore.instance.collection(Collection.position.name)
      .doc(idCircle).set({"x" : 0, "y" : 0});

  runApp(const ProviderScope(child: MyApp()));
}

final circleProvider = StreamProvider<List<Circle>>((ref) => FirebaseFirestore.instance
    .collection(Collection.position.name).snapshots().map((event) {
    final rs = event.docs.map((e) {
      print(event.docs);
        return Circle(
          id: e.id,
          x: e.data()['x'],
          y: e.data()['y'],
        );
      }).toList();

    return rs;
}));

final idCircle = '${Random().nextInt(9999999)}';

enum Collection { position }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  build(_) => MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(title: 'Flutter Demo Home Page'),
      );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  build(_) => Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: DragGame()
  );
}

class DragGame extends ConsumerWidget {
   DragGame({super.key});

  @override
  build(_,ref) {
    final listCircle = ref.watch(circleProvider).value;

    return Container(
        constraints: const BoxConstraints.expand(),
        color: Colors.grey,
        width: 250,
        height: 250,
        child:Stack(
          children: [
            for (Circle circle in listCircle!)
              DraggableWidget(circle)
          ],
        ),
    );
  }

}

class DraggableWidget extends ConsumerWidget {
  final Circle circle;
  DraggableWidget(this.circle, {Key? key}) : super(key: key);

  // late int boxNumberIsDragged = 0;

  Widget _buildBox(Color color, Offset offset, {bool onlyBorder: false}) {
    return CircleAvatar(
      backgroundColor: color,
    );
  }

  @override
  build(_, ref) {
    return Draggable(
      feedback: _buildBox(Colors.red, Offset(circle.x.toDouble(), circle.y.toDouble())),
      childWhenDragging:
      _buildBox(Color.fromRGBO(0, 0, 0, 0), Offset(circle.x.toDouble(), circle.y.toDouble()), onlyBorder: true),
      onDragUpdate: (details) {
        FirebaseFirestore.instance.collection(Collection.position.name).doc(idCircle).update(
        {
          "x": details.localPosition.dx,
          "y": details.localPosition.dy,
        });
      },
      child: _buildBox(Colors.white, const Offset(30.0, 100.0)),
    );
  }
}
