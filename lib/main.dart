import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

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
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  build(_) => Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: DragGame()

    );
  }
}


class DragGame extends StatefulWidget {
  @override
  _DragGameState createState() => new _DragGameState();
}

class _DragGameState extends State<DragGame> {
  var  boxNumberIsDragged = null ;

  @override
  void initState() {
    // boxNumberIsDragged = null;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return  Container(
        constraints: BoxConstraints.expand(),
        color: Colors.grey,
        child:  Stack(
          children: <Widget>[
            buildDraggableBox(1, Colors.red, new Offset(30.0, 100.0)),

          ],
        ));
  }

  Widget buildDraggableBox(int boxNumber, Color color, Offset offset) {
    return  Draggable(
      maxSimultaneousDrags: boxNumberIsDragged == null || boxNumber == boxNumberIsDragged ? 1 : 0,
      child: _buildBox(color, offset),
      feedback: _buildBox(color, offset),
      childWhenDragging: _buildBox(color, offset, onlyBorder: true),
      onDragStarted: () {
        setState((){
          boxNumberIsDragged = boxNumber;
        });
      },
      onDragCompleted: () {
        setState((){
          boxNumberIsDragged = null;
        });
      },
      onDraggableCanceled: (_,__) {
        setState((){
          boxNumberIsDragged = null;
        });
      },
    );
  }

  Widget _buildBox(Color color, Offset offset, {bool onlyBorder: false}) {
    return CircleAvatar(
      backgroundColor: Colors.red,

    );
    Container(
      height: 50.0,
      width: 50.0,
      margin: EdgeInsets.only(left: offset.dx, top: offset.dy),
      decoration: BoxDecoration(
          color: !onlyBorder ? color : Colors.grey,
          border: Border.all(color: color)),
    );
}
