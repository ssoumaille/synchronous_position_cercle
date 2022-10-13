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
      .doc(idCircle).set({"x" : .0, "y" : .0});

  runApp(const ProviderScope(child: MyApp()));
}

final circleProvider = StreamProvider<List<Circle>>((ref) => FirebaseFirestore.instance
    .collection(Collection.position.name).snapshots().map((event) {
    final rs = event.docs.map((e) {
        return Circle(
          id: e.id,
          x: e.data()['x'],
          y: e.data()['y'],
        );
      }).toList();
    return rs;
}));

const idCircle = '9999997';

enum Collection { position }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  build(_) => MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(title: 'Synchronous position circle'),
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
      // appBar: AppBar(
      //   title: Text(widget.title),
      // ),
      body: const DragGame()
  );
}

class DragGame extends ConsumerWidget {
   const DragGame({super.key});

   Widget _buildCircles(AsyncValue<List<Circle>> asyncList) =>
       asyncList.when(
         data: (data) {
           List<Widget> widgetsToShow = [];
           late MyDraggableCircle? myDraggable;
           for (Circle circle in data) {
             if (circle.id == idCircle) {
               // widgetsToShow.add(MyDraggableCircle(circle));
               myDraggable = MyDraggableCircle(circle);
             } else {
               widgetsToShow.add(NonDraggableCircle(circle));
             }
           }
           if (myDraggable != null) {
             widgetsToShow.add(myDraggable);
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

  Widget _circleAvatarColor(Color color) => CircleAvatar(
      backgroundColor: color,
    );

  Widget _circleChildAvatarColor(Color color, double x, double y) => Positioned(
      top: y,
      left: x,
      child: CircleAvatar (
        backgroundColor: color,
      ),
  );

  @override
  build(_, ref) => Positioned(
    top: circle.y,
    left: circle.x,
    child: Draggable(
    feedback: _circleAvatarColor(Colors.red),
    childWhenDragging: _circleAvatarColor(const Color.fromRGBO(0, 0, 0, 0.2)),
    onDragUpdate: (details) {
      FirebaseFirestore.instance.collection(Collection.position.name).doc(idCircle).update(
          {
            "x": details.localPosition.dx,
            "y": details.localPosition.dy,
          });

    },
    // onDraggableCanceled: (_, offset) {
    //
    // },
    child: _circleAvatarColor(Colors.white),
  ),);

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
