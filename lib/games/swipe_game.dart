import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:quranapp/consts/colors.dart';
import 'package:quranapp/models/models.dart';

class SwipeGame extends StatefulWidget {
  final VoidCallback onGameCompleted;
  final Word word;
  final List<Level> allLevels;

  const SwipeGame({
    Key? key,
    required this.onGameCompleted,
    required this.word,
    required this.allLevels,
  }) : super(key: key);

  @override
  State<SwipeGame> createState() => _SwipeGameState();
}

class _SwipeGameState extends State<SwipeGame> {
  late String word;
  late String imageUrl;
  late bool isCorrectImage;

  @override
  void initState() {
    super.initState();
    word = widget.word.ar.isNotEmpty ? widget.word.ar : '';
    initializeGame();
  }

  void initializeGame() {
    // Решаем случайно, показывать ли правильное изображение или случайное изображение из других уровней
    isCorrectImage = Random().nextBool();

    if (isCorrectImage) {
      imageUrl = widget.word.picture;
    } else {
      imageUrl = getRandomImageFromOtherLevels(widget.word.picture);
    }
  }

  String getRandomImageFromOtherLevels(String correctImage) {
    final List<String> allImages = [];

    // Получаем все изображения из других уровней, кроме правильного изображения
    for (var level in widget.allLevels) {
      allImages.addAll(
        level.words.where((w) => w.picture != correctImage).map((w) => w.picture).toList(),
      );
    }

    // Перемешиваем список изображений и выбираем первое
    allImages.shuffle();
    return allImages.isNotEmpty ? allImages.first : correctImage;
  }

  void checkAnswer(bool isCorrectSelected) {
    if (isCorrectSelected == isCorrectImage) {
      print('ПРАВИЛЬНО');
      widget.onGameCompleted();
    } else {
      print('НЕПРАВИЛЬНО');
      // Не обновляем изображение, если ответ неправильный
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          // Отображение слова
          Text(
            word,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w500,
              color: mainGrey,
              decoration: TextDecoration.none,
            ),
          ),
          // Отображение изображения
          imageUrl.isNotEmpty
              ? Container(
                  child: CachedNetworkImage(
                    imageUrl: 'https://firebasestorage.googleapis.com/v0/b/quranapp-words1123.appspot.com/o/$imageUrl?alt=media',
                    height: 200, // Скорректированный размер для лучшей видимости
                    width: 200, // Скорректированный размер для лучшей видимости
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                  decoration: BoxDecoration(
                    color: bgForCards,
                    borderRadius: BorderRadius.circular(30.0),
                    border: Border.all(
                      color: mainGreen,
                      width: 1,
                    ),
                  ),
                )
              : Container(),
          // Кнопки для выбора правильности изображения
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              // Кнопка "Неправильно"
              ElevatedButton(
                style: ButtonStyle(
                  fixedSize: MaterialStateProperty.all<Size>(Size(120, 120)),
                  elevation: MaterialStateProperty.all<double>(0.0),
                  backgroundColor: MaterialStateProperty.all<Color>(bgForRedButtons),
                  foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(1000.0),
                      side: BorderSide(color: mainRed),
                    ),
                  ),
                ),
                onPressed: () {
                  checkAnswer(false);
                },
                child: Icon(
                  Icons.close,
                  size: 40,
                  color: mainRed,
                ),
              ),
              // Кнопка "Правильно"
              ElevatedButton(
                style: ButtonStyle(
                  fixedSize: MaterialStateProperty.all<Size>(Size(120, 120)),
                  elevation: MaterialStateProperty.all<double>(0.0),
                  backgroundColor: MaterialStateProperty.all<Color>(bgForGreenButtons),
                  foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(1000.0),
                      side: BorderSide(color: mainGreen),
                    ),
                  ),
                ),
                onPressed: () {
                  checkAnswer(true);
                },
                child: Icon(
                  Icons.check,
                  size: 40,
                  color: mainGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
