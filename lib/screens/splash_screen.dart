import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quranapp/models/models.dart';
import 'package:quranapp/pages/home_page.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late List<Level> levels;
  late List<Word> studiedWords;
  late List<String> _imageUrls;
  bool _isDisposed = false; // Add this flag

  @override
  void initState() {
    super.initState();
    levels = [];
    studiedWords = [];
    _imageUrls = [];

    _fetchData();
  }


  @override
  void dispose() {
    _isDisposed = true; // Set the flag to true when the widget is disposed
    super.dispose();
  }


    Future<void> _fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Attempt to load data from local storage
    await _fetchDataFromLocal(prefs);

    // If data not found in local storage, load it from Firebase and save locally
    if (levels.isEmpty || studiedWords.isEmpty) {
      await _fetchDataFromFirebase();
      await _saveDataToLocal(prefs);
    }

    // Navigate to the main screen after loading data
    _loadImages();

    if (!_isDisposed) {
      _navigateToHomeScreen(); // Check if the widget is not disposed before navigating
    }
  }

  Future<void> _fetchDataFromLocal(SharedPreferences prefs) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? levelsData = prefs.getString('levels_${user.uid}');
      print('Levels data before decoding: $levelsData');
      levels = levelsData != null
          ? (jsonDecode(levelsData) as List<dynamic>)
              .map((data) => Level.fromMap(data as Map<String, dynamic>))
              .toList()
          : [];
      print('Levels loaded from local storage: $levels');
    }
  } catch (e) {
    print('Error loading levels from local storage: $e');
    levels = [];
  }

  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? studiedWordsData = prefs.getString('studiedWords_${user.uid}');
      print('Studied words data before decoding: $studiedWordsData');
      studiedWords = studiedWordsData != null
          ? (jsonDecode(studiedWordsData) as List<dynamic>)
              .map((data) => Word.fromMap(data as Map<String, dynamic>))
              .toList()
          : [];
      print('Studied words loaded from local storage: $studiedWords');
    } else {
      studiedWords = [];
      print('User not authenticated');
    }
  } catch (e) {
    print('Error loading studied words from local storage: $e');
    studiedWords = [];
  }
}

  Future<void> _fetchDataFromFirebase() async {
    await Future.wait([
      _fetchLevelsFromRealtimeDatabase(),
      _fetchStudiedWordsFromFirestore(),
    ]);
  }

  Future<void> _saveDataToLocal(SharedPreferences prefs) async {
    await _saveLevelsToLocal(prefs);
    await _saveStudiedWordsToLocal(prefs);
  }

   Future<void> _fetchLevelsFromRealtimeDatabase() async {
    try {
      final databaseReference = FirebaseDatabase.instance.ref();
      DatabaseEvent snapshot = await databaseReference.once();

      if (snapshot.snapshot.value != null) {
        dynamic data = snapshot.snapshot.value;

        if (data is Map<dynamic, dynamic>) {
          levels = [];
          data.forEach((key, value) {
            if (value is! Map<dynamic, dynamic>) return;

            final categoryData = value['category'];
            final sentenceData = value['sentence'];
            final wordsData = (value as Map).entries
                .where((entry) => entry.key.startsWith('word'))
                .map((entry) => entry.value)
                .toList();

                print('СССЛООВАА $wordsData');

            if (categoryData == null ||
                categoryData is! Map<dynamic, dynamic> ||
                sentenceData == null ||
                sentenceData is! Map<dynamic, dynamic> ||
                wordsData.isEmpty ||
                wordsData.any((wordData) =>
                    wordData == null || wordData is! Map<dynamic, dynamic>)) {
              return;
            }

            try {
              Categories category =
                  Categories.fromMap(Map<String, dynamic>.from(categoryData));
              Sentence sentence =
                  Sentence.fromMap(Map<String, dynamic>.from(sentenceData));
              List<Word> words = wordsData
                  .map((wordData) =>
                      Word.fromMap(Map<String, dynamic>.from(wordData)))
                  .toList();
              bool? finish = value['finish'] as bool?;
              double? procent = (value['percent'] as num?)?.toDouble();
              num id = (value['id'] as num);
              levels.add(Level(
                  category: category,
                  sentence: sentence,
                  words: words,
                  finish: finish,
                  procent: procent,
                  id : id
                  ));
            } catch (e) {
              print('Ошибка при обработке данных для ключа $key: $e');

            }
          });

        } else {
          print('Ошибка: данные не являются Map');
          levels = [];
        }
      } else {
        levels = [];
        print('Данные уровней не найдены.');
      }
    } catch (e) {
      print('Ошибка загрузки уровней из Firebase: $e');
      levels = [];
    }
  }

  Future<void> _fetchStudiedWordsFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('studied_words')
            .get();

        studiedWords = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return Word(
            ar: data['ar'] ?? '',
            che: data['che'] ?? '',
            en: data['en'] ?? '',
            ru: data['ru'] ?? '',
            picture: data['picture'] ?? '',
          );
        }).toList();
      } else {
        studiedWords = [];
        print('User not authenticated');
      }
    } catch (e) {
      print('Error loading studied words from Firestore: $e');
      studiedWords = [];
    }
  }
   

 Future<void> _loadImages() async {
    try {
      print('Starting to load images...');
      final storageRef = FirebaseStorage.instance.ref();
      ListResult result = await storageRef.listAll();
      print('File list obtained, number of files: ${result.items.length}');

      if (result.items.isEmpty) {
        print('Error: Image folder is empty');
        if (!mounted) return;
        setState(() {
          _imageUrls = [];
        });
        return;
      }

      List<String> urls = [];
      for (var ref in result.items) {
        try {
          String url = await ref.getDownloadURL();
          urls.add(url);
        } catch (e) {
          print('Error getting URL for file: ${ref.fullPath}, error: $e');
        }
      }

      if (!mounted) return;
      setState(() {
        _imageUrls = urls.isEmpty ? [] : urls;
      });
      print('Loaded image URLs: $_imageUrls');
    } catch (e) {
      print('Error loading images from Firebase Storage: $e');
      if (!mounted) return;
      setState(() {
        _imageUrls = [];
      });
    }
  }



  Future<void> _saveLevelsToLocal(SharedPreferences prefs) async {
  try {
    String levelsJson = jsonEncode(levels.map((level) => level.toMap()).toList());
    print('Saving levels to local storage: $levelsJson');
    await prefs.setString('levels', levelsJson);
  } catch (e) {
    print('Error saving levels to local storage: $e');
  }
}

Future<void> _saveStudiedWordsToLocal(SharedPreferences prefs) async {
  try {
    String studiedWordsJson = jsonEncode(studiedWords.map((word) => word.toMap()).toList());
    print('Saving studied words to local storage: $studiedWordsJson');
    await prefs.setString('studiedWords', studiedWordsJson);
  } catch (e) {
    print('Error saving studied words to local storage: $e');
  }
}

void _navigateToHomeScreen() {
  if (!mounted) return;

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => MyHomeScreen(
        levels: levels,
        studiedWords: studiedWords,
        imageUrls: _imageUrls,
      ),
    ),
  );
}


    void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );


    

  
    }
  

 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}