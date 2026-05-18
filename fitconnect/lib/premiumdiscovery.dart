import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

class PremiumDiscovery extends StatelessWidget {
  final List<Map<String, String>> athletes;
  final CardSwiperController controller;

  const PremiumDiscovery({super.key, required this.athletes, required this.controller});

  @override
  Widget build(BuildContext context) {
    return CardSwiper(
      controller: controller,
      cardsCount: athletes.length,
      numberOfCardsDisplayed: 3,
      backCardOffset: const Offset(0, 40),
      padding: const EdgeInsets.all(20.0),
      isLoop: true,
      cardBuilder: (context, index, h, v) {
        final player = athletes[index % athletes.length];
        return ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              Positioned.fill(child: Image.asset(player['img']!, fit: BoxFit.cover)),
              Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black])))),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(player['name']!, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(player['sport']!.toUpperCase(), style: const TextStyle(color: Color(0xFF39FF14), fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}