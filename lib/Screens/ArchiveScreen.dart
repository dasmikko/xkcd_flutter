import "package:flutter/material.dart";
import "package:xkcd_flutter/Database/Providers/ComicProvider.dart";
import "package:xkcd_flutter/Models/ComicModel.dart";
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/foundation.dart';

class ArchiveScreen extends StatefulWidget {
  final List<ComicModel> comics;
  final ComicProvider comicProvider;

  ArchiveScreen({Key key, @required this.comics, this.comicProvider})
      : super(key: key);

  @override
  _ArchiveScreenState createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  ComicProvider comicProvider;
  List<ComicModel> comicsList;
  ScrollController scrollController = new ScrollController();

  @override
  void initState() {
    comicsList = widget.comics;
    comicProvider = widget.comicProvider;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: Text("Archive"),
      ),
      body: new Container(
        child: DraggableScrollbar.semicircle(
          controller: scrollController,
          child: ListView.builder(
            controller: scrollController,
            itemExtent: 80.0,
            itemCount: comicsList.length != null ? comicsList.length : 0,
            itemBuilder: (BuildContext context, int index) {
              final item = comicsList[index];

              return Dismissible(
                key: Key(item.title),
                onDismissed: (direction) {
                  comicProvider.delete(item.num).then((onValue) {
                    // Then show a snackbar!
                    Scaffold.of(context).showSnackBar(
                        SnackBar(content: Text("${item.title} removed")));
                  });
                },
                background: Container(color: Colors.red),
                child: InkWell(
                  onTap: () {
                    print("Pressed item! ${index}");
                    Navigator.pop(context, comicsList[index].num - 1);
                  },
                  child: Container(
                    margin: EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        new Text(comicsList[index].num.toString()),
                        new Text(comicsList[index].title)
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
