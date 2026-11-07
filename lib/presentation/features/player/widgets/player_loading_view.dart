import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../theme/app_theme.dart';

class PlayerLoadingView extends StatefulWidget {
  const PlayerLoadingView({super.key});

  static const animationAsset = 'assets/animations/film_reel.json';

  @override
  State<PlayerLoadingView> createState() => _PlayerLoadingViewState();
}

class _PlayerLoadingViewState extends State<PlayerLoadingView> {
  static const _phrases = [
    'Writing Dialogues',
    'Preparing the Scene',
    'Setting up the Projector',
    'Casting the Crew',
    'Rolling the Credits',
    'Adjusting the Lights',
    'Tuning the Sound',
    'Loading the Reel',
    'Almost there...',
  ];
  static const _phraseDuration = Duration(seconds: 2);

  late final Timer _phraseTimer;
  int _phraseCount = 0;

  @override
  void initState() {
    super.initState();
    _phraseTimer = Timer.periodic(
      _phraseDuration,
      (_) => setState(() => _phraseCount++),
    );
  }

  @override
  void dispose() {
    _phraseTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: SizedBox.square(
                dimension: 200,
                child: Lottie.asset(
                  PlayerLoadingView.animationAsset,
                  fit: BoxFit.contain,
                  animate: !AppMotion.reduced(context),
                  backgroundLoading: true,
                ),
              ),
            ),
            AppSpacing.vGapXxl,
            AnimatedSwitcher(
              duration: AppMotion.of(context, AppDurations.medium),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              child: Text(
                _phrases[_phraseCount % _phrases.length],
                key: ValueKey(_phraseCount),
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
