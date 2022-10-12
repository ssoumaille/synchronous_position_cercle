import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'circle/circle.dart';

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

final StreamProvider streamProvider = StreamProvider((ref) => FirebaseFirestore.instance
    .collection(Collection.position.name).snapshots().map((event) {
      event.docs.map((e) {
        return Circle(
          x: e.data()["x"],
          y: e.data()["y"],
        );
      });
}));

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
      body: const DragGame());
}

class DragGame extends StatefulWidget {
  const DragGame({super.key});

  @override
  _DragGameState createState() => _DragGameState();
}

class _DragGameState extends State<DragGame> {

  @override
  void initState() {
    super.initState();
  }

  @override
  build(_) =>
      Container(
          constraints: const BoxConstraints.expand(),
          color: Colors.grey,
          child: DraggableWidget()
      );
}

class DraggableWidget extends ConsumerWidget {
  DraggableWidget({Key? key}) : super(key: key);

  late int boxNumberIsDragged;
  late String docId;

  Widget _buildBox(Color color, Offset offset, {bool onlyBorder: false}) {
    return CircleAvatar(
      backgroundColor: color,
    );
  }

  @override
  build(_, ref) {
    return Draggable(
      maxSimultaneousDrags:
      1 == boxNumberIsDragged ? 1 : 0,
      feedback: _buildBox(Colors.red, Offset.),
      childWhenDragging:
      _buildBox(Color.fromRGBO(0, 0, 0, 0), offset, onlyBorder: true),
      onDragStarted: () {
        FirebaseFirestore.instance.collection(Collection.position.name).add({
          "x": 0,
          "y": 0,
        }).then((value) => docId = value.id);
      },
      onDragCompleted: () {
      },
      onDragUpdate: (details) {
        // print(details.localPosition);
        if (docId.isNotEmpty) {
          FirebaseFirestore.instance.collection(Collection.position.name).doc(docId).update(
              {
                "x": details.localPosition.dx,
                "y": details.localPosition.dy,
              });
        }
      },
      onDraggableCanceled: (_, __) {
      },
      child: _buildBox(Colors.white, const Offset(30.0, 100.0)),
    );
  }
}
