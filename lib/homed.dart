import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quranapp/consts/colors.dart';
import 'package:quranapp/games/missword_game/missword_game.dart';
import 'package:quranapp/models/models.dart';
import 'package:quranapp/providers/timer_provider.dart';
import 'package:quranapp/screens/lang_provider.dart';
import 'package:quranapp/screens/data_provider.dart';

class HomeScreen extends StatefulWidget {
  final List<Level> levels;
  final List<String> imgUrl;

  HomeScreen({required this.levels, required this.imgUrl});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _textAnimationController;
  late Animation<double> _textOpacityAnimation;
  late Animation<Offset> _textSlideAnimation;
  List<AnimationController> _controllers = [];
  List<Animation<Offset>> _slideAnimations = [];
  List<Animation<double>> _fadeAnimations = [];

  @override
  void initState() {
    super.initState();
    _textAnimationController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textAnimationController, curve: Curves.easeInOut),
    );
    _textSlideAnimation = Tween<Offset>(
      begin: Offset(-15.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textAnimationController, curve: Curves.easeInOut),
    );
    _startTextAnimation();
    _initializeAnimations();
  }

  void _startTextAnimation() async {
    await Future.delayed(Duration(seconds: 4));
    if (mounted) {
      _textAnimationController.forward();
    }
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.levels.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 500),
        vsync: this,
      ),
    );
    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: Offset(0, 1),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
    _startAnimations();
  }

  void _startAnimations() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(Duration(milliseconds: 200 * i));
      if (mounted) {
        _controllers[i].forward();
      }
    }
  }

  String _getTranslation(Categories category, String language) {
    switch (language) {
      case 'che':
        return category.che;
      case 'ru':
        return category.ru;
      case 'en':
      default:
        return category.en;
    }
  }

  @override
Widget build(BuildContext context) {
  final languageProvider = Provider.of<LanguageProvider>(context);
  final String language = languageProvider.language;

  if (widget.levels.isEmpty) {
    return Scaffold(
      body: Center(
        child: Container(),
      ),
    );
  }

  final randomIndex = Random().nextInt(widget.levels.length);
  final Map<String, List<Level>> categorizedLevels = {};

  for (var level in widget.levels) {
    final category = _getTranslation(level.category, language);
    if (!categorizedLevels.containsKey(category)) {
      categorizedLevels[category] = [];
    }
    categorizedLevels[category]!.add(level);
  }

  return Scaffold(
    body: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            alignment: Alignment.bottomLeft,
            padding: EdgeInsets.only(left: 20),
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(                    
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            verticalDirection: VerticalDirection.down,
                            children: [
                              Transform.translate(
                                offset: _textSlideAnimation.value,
                                child: Text('${widget.levels[randomIndex].procent}%', style: TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.w500)),
                              ),
                              Text(_getTranslation(widget.levels[randomIndex].category, language), style: TextStyle(color: titleColor, fontSize: 32, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        SizedBox(height: 15),
                        SizedBox(
                          height: 55,
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.play_arrow),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (BuildContext context) => MissingWordGame(
                                    level: widget.levels[randomIndex],
                                    selectedLanguage: language,
                                    onGameCompleted: () {},
                                    allLevels: widget.levels,
                                    imgUrls: widget.imgUrl,
                                  ),
                                ),
                              );
                            },
                            style: ButtonStyle(
                              backgroundColor: MaterialStateColor.resolveWith((states) => mainGreen),
                              foregroundColor: MaterialStateColor.resolveWith((states) => Colors.white),
                              shadowColor: MaterialStateColor.resolveWith((states) => Color.fromARGB(0, 0, 0, 0)),
                            ),
                            label: Text('ПРОЙТИ УРОВЕНЬ', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                              CachedNetworkImage(
                    imageUrl: 'https://firebasestorage.googleapis.com/v0/b/quranapp-words1123.appspot.com/o/${widget.levels[randomIndex].words.first.picture}?alt=media',
                    height: 120,
                    width: 120,
                    placeholder: (context, url) => CircularProgressIndicator(color: titleColor,),
                    errorWidget: (context, url, error) {
                      print("Error loading image: $error"); // Debugging print
                      return Icon(Icons.error);
                    },
                  ),
                ],
              ),
            ),
          ),
          Padding(
              padding: EdgeInsets.only(left: 20),
            child: ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: categorizedLevels.keys.length,
              itemBuilder: (context, categoryIndex) {
                final category = categorizedLevels.keys.elementAt(categoryIndex);
                final levels = categorizedLevels[category]!;
            
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 30,),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, top: 10.0),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                    ),
                    SizedBox(height: 15,),
                    Container(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: levels.length,
                        itemBuilder: (context, index) {
                          final level = levels[index];
                          final words = level.words;
            
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (BuildContext context) => MissingWordGame(
                                    level: level,
                                    selectedLanguage: language,
                                    onGameCompleted: () {},
                                    allLevels: widget.levels,
                                    imgUrls: widget.imgUrl,
                                  ),
                                ),
                              );
                            },
                            child: SlideTransition(
                              position: _slideAnimations[index],
                              child: FadeTransition(
                                opacity: _fadeAnimations[index],
                                child: Container(
                                  width: 170,
                                  margin: EdgeInsets.symmetric(horizontal: 5),
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: bgForGreenButtons,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                     
                                      SizedBox(height: 10.0),
                                      Text(
                                        words.map((e) => e.ar).join('\n'),
                                        style: TextStyle(
                                          height: 2,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          color: mainGreen,
                                        ),
                                      ),
                                      Spacer(),
                                      Text(
                                        '${level.procent?.toStringAsFixed(2) ?? 'N/A'}%',
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.bold,
                                          color: titleColor,
                                        ),
                                      ),
                                      SizedBox(height: 5.0),
                                  
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}


  @override
  void dispose() {
    _textAnimationController.dispose();
    _controllers.forEach((controller) => controller.dispose());
    super.dispose();
  }
}
