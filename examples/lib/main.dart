import 'package:flutter/material.dart';
import 'package:redux_remote_tool/redux_remote_tool.dart';

void main() {
  runApp(MyApp());
}

class IncrementAction {
  //
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  ReduxRemoteTool _reduxRemoteTool = ReduxRemoteTool();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            StreamBuilder<RemoteDevToolsStatus>(
              stream: _reduxRemoteTool.statusStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container();
                }

                final status = snapshot.data;

                return Text(
                  'redux remote status: $status',
                  style: Theme.of(context).textTheme.headline6,
                );
              },
            ),
            Text(
              'counter: $_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
            FlatButton.icon(
              onPressed: () async {
                setState(() {
                  _counter++;
                });

                _reduxRemoteTool.send(
                  state: _counter,
                  action: IncrementAction,
                  payload: _counter,
                );
              },
              icon: Icon(Icons.chat),
              label: Text('send'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _reduxRemoteTool.connect('127.0.0.1:8000');
        },
        tooltip: 'connect',
        child: Icon(Icons.cast_connected),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
