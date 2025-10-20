import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FloatingCardsJournal extends StatefulWidget {
  const FloatingCardsJournal({super.key});

  @override
  State<FloatingCardsJournal> createState() => _FloatingCardsJournalState();
}

class _FloatingCardsJournalState extends State<FloatingCardsJournal>
    with TickerProviderStateMixin {
  final TextEditingController _journalController = TextEditingController();
  late AnimationController _cardAnimation;
  late Animation<double> _cardSlide;
  late Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();
    _cardAnimation = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardSlide = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _cardAnimation, curve: Curves.elasticOut),
    );
    _cardFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _cardAnimation, curve: Curves.easeIn));

    _cardAnimation.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE3F2FD),
                  Color(0xFFF3E5F5),
                  Color(0xFFE8F5E8),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Header card
                  _buildHeaderCard(),
                  const SizedBox(height: 20),

                  // Main writing card
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _cardAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _cardSlide.value),
                          child: Opacity(
                            opacity: _cardFade.value,
                            child: _buildWritingCard(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    final currentDate = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d').format(currentDate);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  color: Colors.white70,
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                const Icon(Icons.auto_awesome_rounded, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              formattedDate,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "What's on your mind?",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWritingCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // Decorative corner elements
            Positioned(
              top: 20,
              right: 20,
              child: Icon(
                Icons.edit_note_rounded,
                color: Colors.grey[200],
                size: 40,
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: Icon(
                Icons.psychology_rounded,
                color: Colors.grey[200],
                size: 30,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Writing area
                  Expanded(
                    child: TextField(
                      controller: _journalController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.black87,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText:
                            'Express yourself freely...\n\nThis is your sacred space for thoughts, dreams, and reflections.',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          height: 1.6,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),

                  // Bottom actions
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('h:mm a').format(DateTime.now()),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      FloatingActionButton(
                        onPressed: () {
                          // Save logic
                        },
                        backgroundColor: const Color(0xFF667EEA),
                        child: const Icon(
                          Icons.done_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
