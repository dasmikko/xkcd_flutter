import 'package:xkcd_flutter/Models/ComicModel.dart';
import 'package:xkcd_flutter/Models/ComicProgressModel.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:xkcd_flutter/Database/Providers/ComicProvider.dart';

class ComicManager {
  Future<ComicModel> getLatestComic() async {
    http.Response response = await http.get('https://xkcd.com/info.0.json');
    Map comicmap = json.decode(response.body);
    var comic = new ComicModel.fromJson(comicmap);

    return comic;
  }

  Stream<ComicProgressModel> getAllComicsStream(
      ComicProvider comicProvider) async* {
    ComicModel latestComic = await getLatestComic();

    var client = new http.Client();

    List<ComicModel> comics = await comicProvider.getComics();

    int startingPoint = 0;

    if (comics.length == 0) {
      startingPoint = 1;
    } else {
      startingPoint = comics.last.num;
    }

    print(startingPoint);
    print(latestComic.num);
    // Only fetch if there are none more
    if (startingPoint != latestComic.num) {
      // Fetch comics
      for (var i = startingPoint; i <= latestComic.num; i++) {
        try {
          http.Response response =
              await client.get('https://xkcd.com/${i}/info.0.json');

          Map comicmap = json.decode(response.body);
          var comic = new ComicModel.fromJson(comicmap);
          yield new ComicProgressModel(comic, latestComic.num);

          // Notify here that we have fetched a comic

        } catch (ex) {
          // Comic could apparently not be parsed, skip it.
        }
      }
    } else {
      print('No new comics!');
    }

    client.close();
  }
}
