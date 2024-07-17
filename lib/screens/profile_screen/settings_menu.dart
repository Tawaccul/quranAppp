import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quranapp/l10n/app_locale.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:quranapp/screens/profile_screen/about.dart';
import 'package:quranapp/screens/profile_screen/providers.dart';
import 'package:quranapp/screens/lang_provider.dart';
import 'package:quranapp/auth/pages/login.dart';

class ProfileScreen extends StatefulWidget {
  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _foundUsers = [];
  int _studiedWordsCount = 0;
  static const int _maxWords = 100;
  bool _isVibrationEnabled = true;
  bool _isNotificationsEnabled = true;
  num _totalStudyTime = 0; // Total time spent
  double _totalStudyPercentage = 0.0; // Total percentage of studied words
  List<int> _weeklyUsage = [1, 3, 2, 0, 1, 2, 3]; // Mock data for weekly usage

  @override
  void initState() {
    super.initState();
    fetchStudiedWords();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void fetchStudiedWords() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedWords = prefs.getString('studiedWords');

    num totalTime = 0;
    double totalPercentage = 0.0;

    if (user != null) {
      final snapshot = await _firestore
          .collection('users')
          .doc(user!.uid)
          .collection('studied_words')
          .get();

      List<Map<String, dynamic>> words = snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();

      for (var word in words) {
        totalTime += word['timeElapsed'] ?? 0;
        totalPercentage += word['percent'] ?? 0.0;
      }

      setState(() {
        _foundUsers = words;
        _studiedWordsCount = words.length;
        _totalStudyTime = (totalTime / 4).round()  ;
        _totalStudyPercentage = totalPercentage;
      });
    }
  }

  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _toggleVibration(bool isEnabled) async {
    setState(() {
      _isVibrationEnabled = isEnabled;
    });
    if (isEnabled) {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 100);
      }
    } else {
      Vibration.cancel();
    }
  }

  void _toggleNotifications(bool isEnabled) {
    setState(() {
      _isNotificationsEnabled = isEnabled;
    });
    // Implement notification logic
  }

  void _showStatisticsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Statistics'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total study time: ${formatTime(_totalStudyTime)}'),
              const SizedBox(height: 10),
              Text('Average studied percentage: ${_totalStudyPercentage.toStringAsFixed(2)}%'),
              const SizedBox(height: 10),
              const Text('Weekly usage:'),
              const SizedBox(height: 10),
              _buildWeeklyUsageChart(),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
String formatTime(num seconds) {
  int minutes = seconds ~/ 60;
  num remainingSeconds = seconds % 60;
  String formattedMinutes = minutes.toString().padLeft(2, '0');
  String formattedSeconds = remainingSeconds.toString().padLeft(2, '0');
  return "$formattedMinutes:$formattedSeconds";
}

  Widget _buildWeeklyUsageChart() {
    List<String> daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        bool isActive = _weeklyUsage[index] > 0;
        return Column(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isActive ? Colors.green : Colors.grey,
              child: Text(
                daysOfWeek[index],
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 5),
            Text('${_weeklyUsage[index]} times'),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<UserProvider>(context).userName;
    final languageProvider = Provider.of<LanguageProvider>(context);
    double progress = _studiedWordsCount / _maxWords;

    final appLocalizations = AppLocalizations.of(context);
    if (appLocalizations == null) {
      return Center(child: Text('Localization not found'));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 150,),
              SizedBox(
                width: 120,
                height: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.asset('assets/images/account.png'),
                ),
              ),
              const SizedBox(height: 20),
              userName != null
                  ? Text(
                      userName.toUpperCase(),
                      style: TextStyle(fontSize: 17, color: const Color(0xff113356), fontWeight: FontWeight.w500),
                    )
                  : const Text(''),
              const SizedBox(height: 50),
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xffF1F1F1),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xff8DD88D)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(const Color(0xff4CAF50)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ProfileMenuWidget(
                title: appLocalizations.statistics,
                icon: Icons.star,
                onPress: () => _showStatisticsDialog(context),
              ),
              ProfileMenuSwitch(
                title: appLocalizations.notifications,
                icon: Icons.notifications,
                isSwitchOn: _isNotificationsEnabled,
                onToggle: _toggleNotifications,
              ),
              ProfileMenuSwitch(
                title: appLocalizations.vibration,
                icon: Icons.vibration,
                isSwitchOn: _isVibrationEnabled,
                onToggle: _toggleVibration,
              ),
              ProfileMenuWidget(
                title: appLocalizations.changeLanguage,
                icon: Icons.language,
                onPress: () => _showLanguageDialog(context, languageProvider),
              ),
              const SizedBox(height: 20),
              ProfileMenuWidget(
                title: appLocalizations.about,
                icon: Icons.info,
                onPress: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AboutScreen()));
                },
              ),
              ProfileMenuWidget(
                title: appLocalizations.logout,
                icon: Icons.logout,
                textColor: Colors.red,
                endIcon: false,
                onPress: () {
                  logout(context);
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, LanguageProvider languageProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Language"),
          content: DropdownButton<String>(
            value: languageProvider.locale.languageCode,
            items: [
              const DropdownMenuItem(
                value: 'ru',
                child: Text('Russian'),
              ),
              const DropdownMenuItem(
                value: 'en',
                child: Text('English'),
              ),
              const DropdownMenuItem(
                value: 'ar',
                child: Text('Arabic'),
              ),
              const DropdownMenuItem(
                value: 'che',
                child: Text('Chechen'),
              ),
            ],
            onChanged: (String? newValue) {
              if (newValue != null) {
                languageProvider.setLanguage(newValue);
              }
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}


class ProfileMenuWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onPress;
  final Color? textColor;
  final bool endIcon;

  ProfileMenuWidget({
    required this.title,
    required this.icon,
    required this.onPress,
    this.textColor,
    this.endIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xff113356)),
      title: Text(title, style: TextStyle(color: textColor ?? Colors.black)),
      trailing: endIcon ? const Icon(Icons.chevron_right, color: const Color(0xff113356)) : null,
      onTap: onPress,
    );
  }
}

class ProfileMenuSwitch extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSwitchOn;
  final ValueChanged<bool> onToggle;
  final Color? textColor;
  final bool endIcon;

  ProfileMenuSwitch({
    required this.title,
    required this.icon,
    required this.isSwitchOn,
    required this.onToggle,
    this.textColor,
    this.endIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xff113356)),
      title: Text(title, style: TextStyle(color: textColor ?? Colors.black)),
      trailing: Switch(
        value: isSwitchOn,
        activeColor: const Color(0xff113356),
        onChanged: onToggle,
      ),
      onTap: () => onToggle(!isSwitchOn),
    );
  }
}
