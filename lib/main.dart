import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:xkcd_flutter/Managers/ComicManager.dart';
import 'package:xkcd_flutter/Models/ComicModel.dart';
import 'package:xkcd_flutter/Models/ComicProgressModel.dart';
import 'package:xkcd_flutter/ProgressDialogInnerWidget.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_advanced_networkimage/zoomable_widget.dart';
import 'package:flutter_advanced_networkimage/flutter_advanced_networkimage.dart';
import 'package:flutter_advanced_networkimage/transition_to_image.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:xkcd_flutter/Database/Providers/ComicProvider.dart';
import 'package:xkcd_flutter/Screens/ArchiveScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XKCD Flutter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'XKCD Flutter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title, this.goToPage}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final int goToPage;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Timer _timer;
  PageController controller;
  int currentpage = 0;
  int _comicProgress = 0;
  double zoomState;
  String _appBarTitle = 'XKCD Flutter';

  List<String> appBarActions = const <String>["Archive", "Go to Latest"];

  ComicProvider comicProvider;

  List<ComicModel> comics = new List<ComicModel>();

  @override
  void initState() {
    super.initState();

    print(widget.goToPage);

    if (widget.goToPage == null) {
      controller = new PageController(
        initialPage: comics.length,
        keepPage: false,
        viewportFraction: 1,
      );
    } else {
      controller = new PageController(
        keepPage: false,
        viewportFraction: 1,
      );
    }

    zoomState = 1.0;

    getDatabasesPath().then((databasesPath) {
      String path = p.join(databasesPath, 'demo.db');

      comicProvider = new ComicProvider();
      comicProvider.open(path).then((value) {
        _timer = new Timer(const Duration(milliseconds: 500), () {
          if (widget.goToPage == null) {
            _fetchJson();
          } else {
            comicProvider.getComics().then((comics) {
              _updateComicList(comics);
              controller.jumpToPage(widget.goToPage);
            });
          }
          //_setupDatabase();
        });
      });
    });
  }

  @override
  dispose() {
    controller.dispose();
    super.dispose();
  }

  void _updateComicList(newComics) {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      comics = newComics;
    });
  }

  void _updateZoomState(newState) {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      zoomState = newState;
    });
  }

  _updateLastVisitedPage(pageNumber) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('lastVisitedPage', pageNumber);
  }

  void _showBottomSheet(bcontext, index) {
    showModalBottomSheet(
        context: bcontext,
        builder: (BuildContext buildContext) {
          return new Container(
            margin: EdgeInsets.all(32.0),
            child: new Text(comics[index].alt),
          );
        });
  }

  Future<void> _showProgressDialog() async {
    Stream comicStream =
        ComicManager().getAllComicsStream(comicProvider).asBroadcastStream();

    StreamSubscription comicsub = comicStream.listen((onData) async {
      ComicProgressModel model = onData;

      // Insert comic to DB
      comicProvider.insert(model.comic);
    });

    comicsub.onDone(() async {
      List<ComicModel> list = await comicProvider.getComics();
      _updateComicList(list);

      SharedPreferences prefs = await SharedPreferences.getInstance();

      int lastVisitedPage = (prefs.getInt('lastVisitedPage') ?? 1);

      if (lastVisitedPage == 1) {
        controller.jumpToPage(list.length);
      } else {
        _appBarTitle = comics[lastVisitedPage].title;
        controller.jumpToPage(lastVisitedPage);
      }

      Navigator.of(context).pop();
    });

    switch (await showDialog<Object>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Caching comics...'),
            content: Container(
              height: 80,
              child: Column(
                children: <Widget>[
                  new ProgressDialogInnerWidget(
                      comicStream: comicStream, comicProvider: comicProvider)
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Regret'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        })) {
    }
  }

  void _fetchJson() async {
    _showProgressDialog();
  }

  void _onClickOnAppBarAction(String action) async {
    print(action);
    if (action == "Archive") {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ArchiveScreen(
                  comics: comics.reversed.toList(),
                  comicProvider: comicProvider,
                )),
      );

      print(result);

      if (result != null) {
        controller.jumpToPage(result);
      }
    }
    if (action == "Go to Latest") {
      controller.jumpToPage(comics.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(_appBarTitle),
        actions: <Widget>[
          PopupMenuButton<String>(
              onSelected: _onClickOnAppBarAction,
              itemBuilder: (BuildContext context) {
                return appBarActions.map((String action) {
                  return PopupMenuItem<String>(
                    value: action,
                    child: Text(action),
                  );
                }).toList();
              })
        ],
      ),
      body: new Container(
        child: new PageView.builder(
            onPageChanged: (value) {
              setState(() {
                _appBarTitle = comics[value].title;
                currentpage = value;
                _updateLastVisitedPage(value);
              });
            },
            physics: zoomState == 1.0
                ? new AlwaysScrollableScrollPhysics()
                : new NeverScrollableScrollPhysics(),
            itemCount: comics.length,
            controller: controller,
            itemBuilder: (context, index) => builder(context, index)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          int selection = 0 + (Random().nextInt(comics.length - 0));
          print(selection);
          controller.jumpToPage(selection);
        },
        tooltip: 'Random comic',
        child: Icon(Icons.shuffle),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  builder(BuildContext context, int index) {
    return new Container(
      child: Row(children: <Widget>[
        new Expanded(
          flex: 1,
          child: new ClipRect(
            child: Align(
              child: Container(
                margin: EdgeInsets.all(8.0),
                child: GestureDetector(
                  onLongPress: () {
                    print("Did a long press");
                    _showBottomSheet(context, index);
                  },
                  child: ZoomableWidget(
                    onZoomStateChanged: (double state) {
                      _updateZoomState(state);
                    },
                    minScale: 1.0,
                    maxScale: 2.0,
                    zoomSteps: 3,
                    autoCenter: true,
                    multiFingersPan: false,
                    bounceBackBoundary: true,
                    // default factor is 1.0, use 0.0 to disable boundary
                    panLimit: 1.0,
                    child: Container(
                      child: TransitionToImage(
                        AdvancedNetworkImage(comics[index].img,
                            timeoutDuration: Duration(minutes: 1)),
                        // This is the default placeholder widget at loading status,
                        // you can write your own widget with CustomPainter.
                        placeholder: CircularProgressIndicator(),
                        // This is default duration
                        duration: Duration(milliseconds: 300),
                      ),
                    ),
                  ),
                ),
              ),
              /*child: PhotoView(
                imageProvider: NetworkImage(comics[index].img),
                backgroundDecoration: BoxDecoration(),
                scaleStateChangedCallback: (PhotoViewScaleState scaleState) {
                  print(scaleState);
                  _updateZoomState(scaleState);
                },
                minScale: 1.0,
                maxScale: 2.0,
              ),*/
            ),
          ),
        ),
      ]),
    );
  }
}
