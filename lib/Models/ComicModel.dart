class ComicModel {
  final int num;
  final String title;
  final String alt;
  final String img;

  ComicModel(this.num, this.img, this.title, this.alt);

  ComicModel.fromJson(Map<String, dynamic> json)
      : img = json['img'],
        num = json['num'],
        title = json['title'],
        alt = json['alt'];

  Map<String, dynamic> toJson() => {
        'num': num,
        'img': img,
      };

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'num': num,
      'img': img,
      'title': title,
      'alt': alt
    };
    return map;
  }

  ComicModel.fromMap(Map<String, dynamic> map)
      : num = map['num'],
        img = map['img'],
        title = map['title'],
        alt = map['alt'];
}
