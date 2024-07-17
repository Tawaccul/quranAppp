import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:quranapp/consts/colors.dart';
import 'package:quranapp/models/models.dart';
import 'package:quranapp/providers/timer_provider.dart';
import 'package:quranapp/screens/splash_screen.dart';

class MatchGame extends StatefulWidget {
  final VoidCallback onGameCompleted;
  final Level level;
  final String selectedLanguage;

  MatchGame({
    required this.onGameCompleted,
    required this.level,
    required this.selectedLanguage,
  });

  @override
  _MatchGameState createState() => _MatchGameState();
}

class _MatchGameState extends State<MatchGame> with TickerProviderStateMixin {
  List<ItemModel> items = [];
  late AnimationController _controller;
  late Animation<double> _animation;
  int _timeElapsed = 0;

  bool _isPairBeingChecked = false;
  bool _levelCompleted = false;
  late int score;
  late bool gameOver;

  late ItemModel selectedArabicWord;
  late ItemModel selectedTranslationWord;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    initGame();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isPairBeingChecked = false;
        });
      }
    });

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.addListener(() {
      setState(() {}); // Redraw on each animation frame
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> playSound(String path) async {
    await _audioPlayer.play(AssetSource(path));
  }

  void completeGame() {
    playSound('assets/audios/correct2.mp3');
    _showStatisticsDialog();
  }

  void _showStatisticsDialog() {
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    int totalWords = widget.level.words.length;
    int studiedWords = items.where((item) => item.isMatched).length ~/ 2;
    double studiedPercentage = (studiedWords / totalWords) * 100;
    int timeElapsed = timerProvider.seconds;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.only(
              top: 20.0,
              left: 20.0,
              right: 20.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Уровень завершен!',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20.0),
              Text(
                'Изученные слова: $studiedWords из $totalWords',
                style: TextStyle(
                  fontSize: 18.0,
                ),
              ),
              Text(
                'Процент изученных слов: ${studiedPercentage.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 18.0,
                ),
              ),
              Text(
                'Время на изучение: $timeElapsed секунд',
                style: TextStyle(
                  fontSize: 18.0,
                ),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SplashScreen()));
                  widget.onGameCompleted();
                },
                child: Text('Продолжить'),
              ),
            ],
          ),
        );
      },
    );

    // Save the time elapsed and studied words to Firestore
  }

  void initGame() {
    for (var word in widget.level.words) {
      items.add(ItemModel(
        original: word.ar,
        translation:
            word.toMap()['translation'][widget.selectedLanguage] ?? "Unknown",
      ));
      items.add(ItemModel(
        original:
            word.toMap()['translation'][widget.selectedLanguage] ?? "Unknown",
        translation: word.ar,
      ));
    }

    items.shuffle();

    gameOver = false;
    score = 0;
    selectedArabicWord = ItemModel(
      original: '',
      translation: '',
      buttonColor: Colors.greenAccent,
    );
    selectedTranslationWord = ItemModel(
      original: '',
      translation: '',
      buttonColor: Colors.greenAccent,
    );

    if (items.isEmpty) {
      gameOver = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         foregroundColor: Color(0xff4B4B4B),
          backgroundColor: Colors.transparent,
          leading: Padding(
            padding: const EdgeInsets.only(top: 15),
            child: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () async {
                bool exitConfirmed = await _showExitConfirmationDialog();
                if (exitConfirmed) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        title: Padding(
          padding: const EdgeInsets.only(top: 15),
          child: Center(
            child: LinearProgressIndicator(
              value: 17 / 18,
              color: Color(0xff58CC02),
              backgroundColor: Color(0xff4B4B4B),
              minHeight: 5,
            ),
          ),
        ),
        actions: [
          Consumer<TimerProvider>(
            builder: (context, timer, child) {
              return Padding(
                padding: EdgeInsets.only(top: 15, right: 15),
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1000),
                    border: Border.fromBorderSide(
                      BorderSide(
                        color: mainGreen,
                        style: BorderStyle.solid,
                        width: 1.0,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text('${timer.seconds}', style: TextStyle(fontSize: 12)),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color.fromRGBO(241, 253, 241, 100),
                  const Color.fromRGBO(241, 253, 241, 100),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * _animation.value,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color.fromRGBO(175, 210, 164, 1),
                    const Color.fromRGBO(195, 252, 186, 1),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(22.0),
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      ItemModel item = items[index];

                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shadowColor:
                              const Color.fromARGB(0, 105, 240, 175),
                          foregroundColor: item == selectedArabicWord ||
                                  item == selectedTranslationWord
                              ? Colors.green
                              : Colors.grey,
                          backgroundColor: item == selectedArabicWord ||
                                  item == selectedTranslationWord
                              ? Colors.greenAccent
                              : Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            side: BorderSide(
                              width: 2,
                              color: item.isMatched || item.isSelected
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        onPressed: item.isMatched
                            ? null
                            : () {
                                _onWordClick(item);
                              },
                        child: Text(
                          item.original,
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.normal,
                            color: item.isMatched || item.isSelected
                                ? Colors.green
                                : Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onWordClick(ItemModel item) {
    setState(() {
      if (item.isMatched || item.isSelected) {
        return;
      }

      if (selectedArabicWord.original.isEmpty) {
        selectedArabicWord = item;
        selectedArabicWord.isSelected = true;
      } else {
        selectedTranslationWord = item;
        selectedTranslationWord.isSelected = true;

        if (selectedArabicWord.translation ==
                selectedTranslationWord.original &&
            selectedTranslationWord.translation == selectedArabicWord.original) {
          score += 10;

          selectedArabicWord.isMatched = true;
          selectedTranslationWord.isMatched = true;

          final timerProvider = Provider.of<TimerProvider>(context, listen: false);
          int timeElapsed = timerProvider.seconds;
          saveWordToFirestore(selectedArabicWord, selectedTranslationWord, timeElapsed);

          playSound('assets/audios/click.mp3'); // Play correct pair sound

          if (items.every((item) => item.isMatched)) {
            _controller.forward();
            completeGame();
            timerProvider.resetTimer();

            gameOver = true;
          }
        } else {
          if (selectedArabicWord.original.isNotEmpty &&
              selectedTranslationWord.original.isNotEmpty &&
              item.original == item.translation) {
            score -= 5;
          }

          selectedArabicWord.isSelected = false;
          selectedTranslationWord.isSelected = false;
        }

        selectedArabicWord = ItemModel(
            original: '', translation: '', buttonColor: Colors.greenAccent);
        selectedTranslationWord = ItemModel(
            original: '', translation: '', buttonColor: Colors.greenAccent);
      }
    });
  }

  void saveWordToFirestore(
      ItemModel arabicWord, ItemModel translationWord, int timeElapsed) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Сохраняем только один раз для каждого слова
        final batch = FirebaseFirestore.instance.batch();
        for (var word in widget.level.words) {
          final querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('studied_words')
              .where('ar', isEqualTo: word.ar)
              .where('che', isEqualTo: word.che)
              .where('ru', isEqualTo: word.ru)
              .where('en', isEqualTo: word.en)
              .get();

          if (querySnapshot.docs.isEmpty) {
            final docRef = FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('studied_words')
                .doc();
            batch.set(docRef, {
              'ar': word.ar,
              'che': word.che,
              'ru': word.ru,
              'en': word.en,
              'percent' : widget.level.procent,
              'timeElapsed': timeElapsed, // Add the time elapsed to Firestore
              'timestamp': FieldValue.serverTimestamp(),
            });
          }
        }
        await batch.commit();
      } catch (e) {
        print('Error saving word to Firestore: $e');
      }
    } else {
      print('User is not authenticated');
    }
  }

   Future<bool> _showExitConfirmationDialog() async {
    return (await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Подтверждение'),
        content: Text('Вы действительно хотите вернуться на главный экран? Уровень будет прерван, и придется начинать сначала.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Нет'),
          ),
          TextButton(
            onPressed: () { Navigator.of(context).pop(true); 
                    Provider.of<TimerProvider>(context, listen: false).resetTimer();

            },
            child: Text('Да'),
          ),
        ],
      ),
    )) ?? false;
  }
}

class ItemModel {
  final String original;
  final String translation;
  Color buttonColor;
  bool isSelected;
  bool isMatched;

  ItemModel({
    required this.original,
    required this.translation,
    this.buttonColor = Colors.greenAccent,
    this.isSelected = false,
    this.isMatched = false,
  });
}
