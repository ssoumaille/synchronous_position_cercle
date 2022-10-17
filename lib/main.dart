import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import 'firebase_options.dart';
import 'circle/circle.dart';

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  firestore = FirebaseFirestore.instance;

  await initApp();

  runApp(const ProviderScope(child: MyApp()));
}

initApp() async {
  issync = false;

  // final document =
  // await firestore.collection(Collection.position.name).doc(idCircle).get();
  // myCircle = Circle(
  //     idCircle,
  //     document.data()!['x'],
  //     document.data()!['y'],
  //     document.data()!['color']);

  throttler.throttleTime(const Duration(milliseconds: 100)).forEach((element) {
    issync =true;
    element();
  });
}

late FirebaseFirestore firestore;
final idCircle = '123459876'; //'''${Random().nextInt(9999999)}';
// late Player player = Player('9999999', '');
enum Collection { position }

late bool issync;
// Random color for circles
final color = (Random().nextDouble() * 0xFFFFFF).toInt();
final randomColor = Color(color).withOpacity(1.0);

// Throttler
final throttler = PublishSubject<Function()>();
Offset myThrottledOffset = const Offset(20, 20);
late Circle myCircle;

// Providers
final offsetProvider = StateProvider<Offset>((ref) => const Offset(40, 40));
final loginProvider = StateProvider<Player?>((ref) {
  return null;
});


final firestoreSCircleProvider = StreamProvider<List<Circle>>((ref) =>
    firestore.collection(Collection.position.name).snapshots().map((event) {
      return event.docs.where((ee) => ee.id != idCircle).map((e) {
        return Circle(
          e.id,
          e.data()['x'],
          e.data()['y'],
          e.data()['color'],
            e.data()['name'] ?? e.id,
        );
      }).toList();
    }));

// final int colorval = 0;
// final colorProvider = StreamProvider((ref) => Stream.periodic(Duration(seconds: 1), (count) =>  count%2));

Offset limitingMovementToWindowOnly(Offset position) {
  myThrottledOffset = position;
  if (myThrottledOffset.dy > 480) {
    myThrottledOffset = Offset(myThrottledOffset.dx, 480);
  }
  if (myThrottledOffset.dy < 40) {
    myThrottledOffset = Offset(myThrottledOffset.dx, 40);
  }
  if (position.dx < 20) {
    myThrottledOffset = Offset(40, myThrottledOffset.dy);
  }
  if (position.dx > 460) {
    myThrottledOffset = Offset(480, myThrottledOffset.dy);
  }
  return myThrottledOffset;
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  build(context, ref) {
     Player? user =ref.watch(loginProvider);

        return MaterialApp(
            home: Scaffold(
                body: user != null ? const DragGame(): const LoginPage())
        );
  }

}
final myController = TextEditingController();

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  build(context, ref) =>
      Center(
        child: SizedBox(
          height: 200,
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: TextFormField(
                  controller: myController,
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'Enter your username',
                  ),
                ),
              ),
              Center(child: ElevatedButton(onPressed: (){
                ref.read(loginProvider.notifier).update((state) => Player(idCircle, myController.text));
                firestore
                    .collection(Collection.position.name)
                    .doc(idCircle)
                    .set({"x": 20, "y": 20, "color": color, "name": myController.text});

              }, child: const Text("Jouer")))
            ],
          ),
        ),
      );
}


class DragGame extends ConsumerWidget {
  const DragGame({super.key});

  @override
  build(_, ref) {
    final listCircle = ref
        .watch(firestoreSCircleProvider)
        .value ?? [];
    return Stack(
      children: [
        Positioned(
          top: 0,
          child: Container(
            width: 520,
            height: 20,
            color: Colors.red.shade400,
          ),
        ),
        Positioned(
          left: 0,
          child: Container(
            width: 20,
            height: 520,
            color: Colors.red.shade400,
          ),
        ),
        Positioned(
          top: 500,
          child: Container(
            width: 520,
            height: 20,
            color: Colors.red.shade400,
          ),
        ),
        Positioned(
          left: 500,
          child: Container(
            width: 20,
            height: 500,
            color: Colors.red.shade400,
          ),
        ),
        Positioned(
          top: 520,
          left: 200,
          child: ElevatedButton(
            child: const Text("add user"),
            onPressed: () {
              firestore
                  .collection(Collection.position.name)
                  .doc((Random().nextInt(99999)).toInt().toString())
                  .set({
                "x": Random().nextInt(460),
                "y": Random().nextInt(460),
                "color": (Random().nextDouble() * 0xFFFFFF).toInt()
              });
            },
          ),
        ),
        for (Circle circle in listCircle) CirclesFromFirestore(circle),
        const MyDraggableCircle(),
      ],
    );
  }
}

class CirclesFromFirestore extends ConsumerWidget {
  final Circle circle;

  const CirclesFromFirestore(this.circle, {Key? key}) : super(key: key);

  Widget _buildCircle(int color) {
    Color ccolor = Color(color).withOpacity(0.8);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          backgroundColor:ccolor ,
        ),
        Positioned(top: -15,
          child: Center(
            child: Text(circle.name,
              style:  TextStyle(color: ccolor),
            ),
          ),
        ),

      ],
    ) ;
    // CircleAvatar(
    //   backgroundColor: _color,
    // );
  }

  @override
  build(_, ref) =>
      Positioned(
        top: circle.y.toDouble(),
        left: circle.x.toDouble(),
        child: _buildCircle(circle.color),
      );
}

updatePositionFirestore() {
  return firestore.collection(Collection.position.name).doc(idCircle).update({
    "x": myThrottledOffset.dx - 20,
    "y": myThrottledOffset.dy - 20,
  });
}

class MyDraggableCircle extends ConsumerStatefulWidget {
  // final Circle circle;

  const MyDraggableCircle( {Key? key}) : super(key: key);

  @override
  MyDraggableCircleState createState() => MyDraggableCircleState();
}

class MyDraggableCircleState extends ConsumerState<MyDraggableCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorTween;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )
      ..repeat();

    _colorTween =
        ColorTween(begin: randomColor, end: Colors.transparent ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildCircle(Color color) =>
      CircleAvatar(
        backgroundColor: color,
      );

  @override
  Widget build(BuildContext context) {
    String username =ref.watch(loginProvider)!.name;
    return Positioned(
        top: ref
            .watch(offsetProvider)
            .dy-20,
        left: ref
            .watch(offsetProvider)
            .dx-20,
        child: Draggable(
          feedback: buildCircle(const Color.fromRGBO(0, 0, 0, 0)),
          childWhenDragging: buildCircle(randomColor.withOpacity(0.5)),
          onDragUpdate: (details) {
            limitingMovementToWindowOnly(details.localPosition);
            throttler.add(updatePositionFirestore);
            ref
                .read(offsetProvider.notifier)
                .update((state) => myThrottledOffset);
          },

          child:  AnimatedBuilder(
            animation: _colorTween,
            builder: (BuildContext _, Widget? __) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    backgroundColor: _colorTween.value!,
                  ),
                  Positioned(top: -15,
                      child: Center(
                        child: Text(username,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ),

                ],
              ) ;
            },
          ),
        ),
      );
  }
}
