import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'circle/circle.dart';

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);


  FirebaseFirestore.instance.collection(Collection.sacha_circle.name)
      .doc(idCircle).set({"x" : .0, "y" : .0});

  runApp(const ProviderScope(child: MyApp()));
}

final circleProvider = StreamProvider<List<Circle>>((ref) => FirebaseFirestore.instance
    .collection(Collection.sacha_circle.name).snapshots().map((event) {
    final rs = event.docs.map((e) {
        return Circle(
          id: e.id,
          x: e.data()['x'],
          y: e.data()['y'],
        );
      }).toList();

    return rs;
}));

final idCircle = '${Random().nextInt(9999999)}';

enum Collection { sacha_circle }

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
      body: const DragGame()
  );
}

class DragGame extends ConsumerWidget {
   const DragGame({super.key});

   Widget _buildCircles(AsyncValue<List<Circle>> asyncList) =>
       asyncList.when(
         data: (data) {
           List<Widget> widgetsToShow = [];
           for (Circle circle in data) {
             if (circle.id == idCircle) {
               widgetsToShow.add(MyDraggableCircle(circle));
             } else {
               widgetsToShow.add(NonDraggableCircle(circle));
             }
           }
           return Stack(
             children: widgetsToShow,
           );
         },
         error: (err, stack) {
            print(err);
            return const Icon(Icons.error, color: Colors.red,);
         },
         loading: () => const LinearProgressIndicator()
     );

  @override
  build(_,ref) => Container(
        constraints: const BoxConstraints.expand(),
        color: Colors.grey,
        width: 250,
        height: 250,
        child: _buildCircles(ref.watch(circleProvider)),
    );

}

class MyDraggableCircle extends ConsumerWidget {
  final Circle circle;
  const MyDraggableCircle(this.circle, {Key? key}) : super(key: key);

  Widget _buildBox(Color color, Offset offset) => CircleAvatar(
      backgroundColor: color,
    );

  @override
  build(_, ref) => Draggable(
      feedback: _buildBox(Colors.red, Offset(30.0, 100.0)),
      childWhenDragging: _buildBox(const Color.fromRGBO(0, 0, 0, 0), Offset(30.0, 100.0)),
      onDragUpdate: (details) {
        FirebaseFirestore.instance.collection(Collection.sacha_circle.name).doc(idCircle).update(
        {
          "x": details.localPosition.dx,
          "y": details.localPosition.dy,
        });
      },
      child: _buildBox(Colors.white, const Offset(30.0, 100.0)),
    );
}

class NonDraggableCircle extends ConsumerWidget {
  const NonDraggableCircle(this.circle, {Key? key}) : super(key: key);

  final Circle circle;

  @override
  build(_, ref) => Positioned(
      top: circle.y,
      left: circle.x,
      child: const CircleAvatar(
        backgroundColor: Colors.blue,
      ),
  );
}
