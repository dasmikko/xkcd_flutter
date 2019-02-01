import 'package:xkcd_flutter/Models/ComicModel.dart';
import 'package:sqflite/sqflite.dart';

final String tableComic = 'comics';
final String columnId = '_id';
final String columnNum = 'num';
final String columnTitle = 'title';
final String columnImg = 'img';
final String columnAlt = 'alt';

class ComicProvider {
  Database db;

  Future open(String path) async {
    db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute('''
        create table $tableComic (
          $columnId integer primary key autoincrement,
          $columnNum integer not null,
          $columnTitle text not null,
          $columnImg text not null,
          $columnAlt text not null)
        ''');
    });
  }

  Future<ComicModel> insert(ComicModel comic) async {
    await db.insert(tableComic, comic.toMap());
    return comic;
  }

  Future<ComicModel> getComic(int num) async {
    List<Map> maps = await db.query(tableComic,
        columns: [columnNum, columnTitle, columnImg, columnAlt],
        where: '$columnNum = ?',
        whereArgs: [num]);
    if (maps.length > 0) {
      return ComicModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<ComicModel>> getComics() async {
    List<Map> maps = await db.query(tableComic,
        columns: [columnNum, columnTitle, columnImg, columnAlt]);

    if (maps == null) {
      return new List<ComicModel>();
    }

    return maps.map((map) => ComicModel.fromMap(map)).toList();
  }

  Future<int> delete(int id) async {
    return await db.delete(tableComic, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> update(ComicModel comic) async {
    return await db.update(tableComic, comic.toMap(),
        where: '$columnNum = ?', whereArgs: [comic.num]);
  }

  Future close() async => db.close();
}
