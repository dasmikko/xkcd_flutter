import 'package:flutter/material.dart';
import 'package:xkcd_flutter/Models/ComicProgressModel.dart';
import 'dart:async';
import 'package:xkcd_flutter/Database/Providers/ComicProvider.dart';

class ProgressDialogInnerWidget extends StatefulWidget {
  final Stream comicStream;
  final ComicProvider comicProvider;

  ProgressDialogInnerWidget(
      {@required this.comicStream, @required this.comicProvider});

  @override
  _ProgressDialogInnerWidgetState createState() =>
      _ProgressDialogInnerWidgetState();
}

class _ProgressDialogInnerWidgetState extends State<ProgressDialogInnerWidget> {
  double _comicProgress;
  StreamSubscription streamSub;

  @override
  initState() {
    super.initState();
    _comicProgress = 0;

    streamSub = widget.comicStream.listen((onData) {
      ComicProgressModel model = onData;
      _setProgress(model.comic.num / model.totalComics);
    });
  }

  @override
  dispose() {
    streamSub.cancel();
    super.dispose();
  }

  void _setProgress(double progress) {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _comicProgress = progress;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          new CircularProgressIndicator(
            value: _comicProgress,
          ),
          new Text('${(_comicProgress * 100).round()}% done')
        ],
      ),
    );
  }
}
