import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:openlist/core/theme/app_colors.dart';
import 'package:openlist/core/widgets/openlist_logo.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _backgroundController;
  late AnimationController _pulseController;
  late AnimationController _exitController;
  
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFloatAnimation;
  
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  
  late Animation<double> _taglineFadeAnimation;
  late Animation<Offset> _taglineSlideAnimation;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeOutAnimation;

  @override
  void initState() {
    super.initState();
    
    // Warm up shaders to prevent jank on first frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _warmUpShaders();
    });
    
    // Logo animation controller - reduced duration for snappier feel
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Background rotation controller - disabled for better performance
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );
    
    // Pulse controller - disabled for better performance
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Exit animation controller - faster for snappier feel
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // Logo animations
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _logoScaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );
    
    _logoFloatAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );
    
    // Text animations
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    // Tagline animations
    _taglineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
      ),
    );
    
    _taglineSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
      ),
    );
    
    // Pulse animation
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Rotation animation
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      _backgroundController,
    );
    
    // Exit animations - faster and simpler
    _expandAnimation = Tween<double>(begin: 0.70, end: 1.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInOut,
      ),
    );
    
    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeIn,
      ),
    );
    
    // Start animations with delay for better timing
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _logoController.forward();
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _textController.forward();
    });
    
    _navigateToNextScreen();
  }

  // Warm up shaders to prevent first-frame jank
  void _warmUpShaders() {
    // Pre-cache gradient shader
    final rect = const Rect.fromLTWH(0, 0, 100, 100);
    final gradient = const LinearGradient(
      colors: [Color(0xFF6366F1), Color(0xFF7C3AED)],
    );
    gradient.createShader(rect);
    
    // Pre-cache radial gradient
    const RadialGradient(
      colors: [Colors.white, Color(0x1A6366F1)],
    ).createShader(rect);
  }

  Future<void> _navigateToNextScreen() async {
    // Wait for Supabase to initialize (with timeout)
    final startTime = DateTime.now();
    bool supabaseReady = false;
    
    // Poll for Supabase initialization (max 4 seconds)
    while (!supabaseReady && DateTime.now().difference(startTime).inMilliseconds < 4000) {
      try {
        // Try to access Supabase - will throw if not initialized
        Supabase.instance.client;
        supabaseReady = true;
        debugPrint('✅ Supabase ready after ${DateTime.now().difference(startTime).inMilliseconds}ms');
      } catch (e) {
        // Not ready yet, wait a bit
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    
    if (!supabaseReady) {
      debugPrint('⚠️ Supabase initialization timeout after 4 seconds');
    }
    
    // Ensure we show splash for at least 4000ms total (4 seconds)
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    if (elapsed < 4000) {
      await Future.delayed(Duration(milliseconds: 4000 - elapsed));
    }
    
    if (!mounted) return;
    
    // Start exit animation (400ms for snappier feel)
    await _exitController.forward();
    
    if (!mounted) return;
    
    // Navigate based on auth state
    bool isLoggedIn = false;
    
    if (supabaseReady) {
      try {
        final session = Supabase.instance.client.auth.currentSession;
        isLoggedIn = session != null;
      } catch (e) {
        debugPrint('Error checking auth state: $e');
      }
    }
    
    if (isLoggedIn) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _backgroundController.dispose();
    _pulseController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _exitController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeOutAnimation.value,
              child: Stack(
                children: [
                  // Simplified background - removed floating circles for performance
                  Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.0,
                        colors: [
                          Colors.white,
                          Color(0x1A6366F1),
                        ],
                      ),
                    ),
                  ),
                
                  // Main content with animated expansion
                  Column(
                    children: [
                      // Top section - White background with logo (shrinks during exit)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOut,
                        height: screenHeight * (1 - _expandAnimation.value),
                        child: Container(
                          color: Colors.white,
                          child: Stack(
                            children: [
                              // Subtle gradient overlay - cached
                              Positioned.fill(
                                child: RepaintBoundary(
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: RadialGradient(
                                        center: Alignment.center,
                                        radius: 1.0,
                                        colors: [
                                          Colors.white,
                                          Color(0x1A6366F1),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            
                              // Animated logo with RepaintBoundary for performance
                              Center(
                                child: RepaintBoundary(
                                  child: AnimatedBuilder(
                                    animation: _logoController,
                                    builder: (context, child) {
                                      return FadeTransition(
                                        opacity: _logoFadeAnimation,
                                        child: ScaleTransition(
                                          scale: _logoScaleAnimation,
                                          child: Transform.translate(
                                            offset: Offset(
                                              0,
                                              math.sin(_logoFloatAnimation.value * math.pi * 2) * 6,
                                            ),
                                            child: RepaintBoundary(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(30),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: AppColors.primary.withValues(alpha: 0.2),
                                                      blurRadius: 20,
                                                      spreadRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                                child: const OpenListLogo(size: 120),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                      // Bottom section - Gradient accent color with text (expands during exit)
                      Expanded(
                        child: RepaintBoundary(
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(_expandAnimation.value >= 0.99 ? 0 : 50),
                              topRight: Radius.circular(_expandAnimation.value >= 0.99 ? 0 : 50),
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF6366F1), // Indigo
                                    Color(0xFF7C3AED), // Purple
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // App Name with slide animation
                                    RepaintBoundary(
                                      child: AnimatedBuilder(
                                        animation: _textController,
                                        builder: (context, child) {
                                          return FadeTransition(
                                            opacity: _textFadeAnimation,
                                            child: SlideTransition(
                                              position: _textSlideAnimation,
                                              child: Text(
                                                'OpenList',
                                                style: GoogleFonts.inter(
                                                  fontSize: 42,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                  letterSpacing: -1,
                                                  height: 1.2,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Tagline with slide animation
                                    RepaintBoundary(
                                      child: AnimatedBuilder(
                                        animation: _textController,
                                        builder: (context, child) {
                                          return FadeTransition(
                                            opacity: _taglineFadeAnimation,
                                            child: SlideTransition(
                                              position: _taglineSlideAnimation,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: Colors.white.withValues(alpha: 0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  'Collaborate. Create. Get it Done.',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white.withValues(alpha: 0.95),
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
