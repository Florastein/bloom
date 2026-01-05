import 'package:bloom/constants/colors.dart';
import 'package:bloom/data/mood_data.dart';
import 'package:bloom/models/mood_log.dart';
import 'package:bloom/screens/dashboard.dart';
import 'package:bloom/services/db_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:lottie/lottie.dart';
import 'package:smart_edge_alert/smart_edge_alert.dart';
import '../widgets/custom_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late LiquidController _liquidController;
  final TextEditingController _aboutDay = TextEditingController();
  int _currentPage = 0;

  void pageChangeCallback(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _logMood(
    BuildContext context,
    String mood, {
    String? note,
  }) async {
    try {
      final moodLog = MoodLog(
        mood: mood,
        note: note,
        timestamp: DateTime.now(),
      );
      debugPrint("Mood Log: $moodLog.toString()");

      await HiveDBService.saveMoodLog(moodLog);

      SmartEdgeAlert.show(
        context,
        title: 'Mood Logged Successfully',
        titleFontSize: 20,
        description: 'Mood "$mood" logged successfully!',
        descriptionFontSize: 16,
        gravity: SmartEdgeAlert.top,
        closeButtonColor: Colors.white,
        duration: SmartEdgeAlert.lengthVeryLong,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging mood: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void initState() {
    _liquidController = LiquidController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          LiquidSwipe.builder(
            itemCount: moodData.length,
            itemBuilder: (context, index) {
              final data = moodData[index % moodData.length];
              return Container(
                width: double.infinity,
                color: _getPageColor(index),
                child: Stack(
                  children: [
                    Positioned(
                      top: index == 1
                          ? MediaQuery.of(context).size.height * 0.3
                          : MediaQuery.of(context).size.height * 0.4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Lottie.asset(
                          data.asset,
                          width: index == 1 ? 300 : 250,
                          height: index == 1 ? 300 : 250,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.33,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          data.moodText,
                          style: TextStyle(color: Colors.black, fontSize: 30),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            liquidController: _liquidController,
            onPageChangeCallback: pageChangeCallback,
            waveType: WaveType.liquidReveal,
            fullTransitionValue: 880,
            enableSideReveal: true,
            preferDragFromRevealedArea: true,
            enableLoop: true,
            ignoreUserGestureWhileAnimating: true,
            positionSlideIcon: 0.8,
            slideIconWidget: Icon(Icons.arrow_back_ios),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 140.0),
              child: Text(
                'Tell me how you feel today',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.black,
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomButton(
                  buttonText: moodData[0].buttonText,
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) {
                        return StatefulBuilder(
                          builder: (BuildContext context, StateSetter setState) {
                            final bottomInsets = MediaQuery.of(
                              context,
                            ).viewInsets.bottom;
                            final bool isKeyboardOpen = bottomInsets > 0;

                            return Padding(
                              padding: EdgeInsets.only(bottom: bottomInsets),
                              child: SafeArea(
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(24),
                                      topRight: Radius.circular(24),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 20,
                                        offset: Offset(0, -4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Drag handle with better styling
                                      Container(
                                        margin: const EdgeInsets.only(top: 12),
                                        width: 60,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Header section
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Tell me more...",
                                                  style:
                                                      GoogleFonts.plusJakartaSans(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 20,
                                                        color: Colors.black87,
                                                      ),
                                                ),
                                                IconButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  icon: Icon(
                                                    Icons.close_rounded,
                                                    color: Colors.grey[600],
                                                    size: 24,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(
                                                        minWidth: 40,
                                                        minHeight: 40,
                                                      ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 8),

                                            // Subtitle
                                            Text(
                                              "Share what's on your mind",
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                            ),

                                            const SizedBox(height: 20),

                                            // Text field with improved styling
                                            Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF8F9FA),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFE9ECEF,
                                                  ),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: TextField(
                                                controller: _aboutDay,
                                                maxLines: isKeyboardOpen
                                                    ? 5
                                                    : 4,
                                                style: GoogleFonts.workSans(
                                                  color: Colors.black87,
                                                  fontSize: 16,
                                                  height: 1.4,
                                                ),
                                                decoration: InputDecoration(
                                                  hintText:
                                                      "Tell me about your day, what made you feel this way?",
                                                  hintStyle:
                                                      GoogleFonts.workSans(
                                                        color: const Color(
                                                          0xFF6C757D,
                                                        ),
                                                        fontSize: 15,
                                                      ),
                                                  border: InputBorder.none,
                                                  contentPadding:
                                                      const EdgeInsets.all(16),
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 8),

                                            // Character count or helper text
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  "Optional",
                                                  style:
                                                      GoogleFonts.plusJakartaSans(
                                                        fontSize: 12,
                                                        color: Colors.grey[500],
                                                      ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 24),

                                            // Improved button design
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  // Handle save action
                                                  _logMood(
                                                    context,
                                                    moodData[_currentPage]
                                                        .moodText,
                                                    note: _aboutDay.text,
                                                  );
                                                  Navigator.pop(context);
                                                  Navigator.of(context).push(
                                                    CupertinoPageRoute(
                                                      builder: (context) =>
                                                          DashboardScreen(),
                                                    ),
                                                  );
                                                  _aboutDay.clear();
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFF10B981,
                                                  ),
                                                  foregroundColor: Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 32,
                                                        vertical: 16,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                  elevation: 0,
                                                  shadowColor:
                                                      Colors.transparent,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      Icons
                                                          .emoji_emotions_outlined,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      "Save Mood",
                                                      style:
                                                          GoogleFonts.plusJakartaSans(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 16,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 8),

                                            // Secondary action
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: Text(
                                                "Maybe later",
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                    /*
                     Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: Duration(milliseconds: 1500),
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            MoodScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.ease;

                              var tween = Tween(
                                begin: begin,
                                end: end,
                              ).chain(CurveTween(curve: curve));
                              var offsetAnimation = animation.drive(tween);

                              return SlideTransition(
                                position: offsetAnimation,
                                child: child,
                              );
                            },
                      ),
                    );
                     */
                  },
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/animations/swipe_left.json',
                      width: 48,
                      height: 48,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Swipe',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 25),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPageColor(int index) {
    switch (index) {
      case 0:
        return const Color.fromARGB(255, 161, 247, 164);
      case 1:
        return AppColors.yellow;
      case 2:
        return AppColors.blue;
      case 3:
        return AppColors.indigo;
      case 4:
        return AppColors.orange;
      default:
        return AppColors.pink;
    }
  }
}
