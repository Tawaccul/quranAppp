import 'package:flutter/material.dart';
import 'package:quranapp/consts/colors.dart';
import 'package:quranapp/homed.dart';
import 'package:quranapp/models/models.dart';
import 'package:quranapp/screens/dictionary_screen/dictionary_screen.dart';
import 'package:quranapp/screens/profile_screen/settings_menu.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyHomeScreen extends StatefulWidget {
  final List<Level> levels;
  final List<Word> studiedWords;
  final List<String> imageUrls;

  MyHomeScreen({required this.levels, required this.studiedWords, required this.imageUrls});

  @override
  _MyHomeScreenState createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen> {
  int _page = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [];
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      setState(() {
        print('ВОТ СЛОВА ИЗ БД${widget.levels.first.words.map((e)=> e.ru)}');
        _pages = [
          HomeScreen(levels: widget.levels, imgUrl: widget.imageUrls),
          DictionaryScreen(studiedWords: widget.studiedWords),
          ProfileScreen(),
        ];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: CurvedNavigationBar(
        index: 0,
        height: 70.0,
        items: <Widget>[
          SvgPicture.asset('assets/images/home.svg', color: Colors.white, height: 32, width: 32, fit: BoxFit.contain,),
          SvgPicture.asset('assets/images/book.svg', color: Colors.white, height: 44, width: 44, fit: BoxFit.contain,),
          SvgPicture.asset('assets/images/profile.svg', color: Colors.white, height: 34, width: 34, fit: BoxFit.contain,),
        ],
        color: secondGreen,
        buttonBackgroundColor: mainGreen,
        backgroundColor: Colors.white,
        animationCurve: Curves.easeInOut,
        animationDuration: Duration(milliseconds: 260),
        onTap: (index) {
          setState(() {
            _page = index;
          });
        },
        letIndexChange: (index) => true,
      ),
      body: Container(
        color: Color(0xffEFF6EF),
        child: Center(
          child: _pages.isNotEmpty ? _pages[_page] : CircularProgressIndicator(color: mainGreen),
        ),
      ),
    );
  }
}
