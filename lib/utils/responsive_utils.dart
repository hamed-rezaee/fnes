import 'package:flutter/material.dart';

class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double largeDesktop = 1800;
}

enum ScreenSize {
  mobile,
  tablet,
  desktop,
  largeDesktop;

  bool get isMobile => this == ScreenSize.mobile;
  bool get isTablet => this == ScreenSize.tablet;
  bool get isDesktop => this == ScreenSize.desktop;
  bool get isLargeDesktop => this == ScreenSize.largeDesktop;
  bool get isMobileOrTablet => isMobile || isTablet;
  bool get isDesktopOrLarger => isDesktop || isLargeDesktop;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;

  double get screenHeight => MediaQuery.of(this).size.height;

  ScreenSize get screenSize {
    final width = screenWidth;
    if (width < Breakpoints.mobile) return ScreenSize.mobile;
    if (width < Breakpoints.tablet) return ScreenSize.tablet;
    if (width < Breakpoints.desktop) return ScreenSize.desktop;

    return ScreenSize.largeDesktop;
  }

  bool get isMobile => screenSize.isMobile;

  bool get isTablet => screenSize.isTablet;

  bool get isDesktop => screenSize.isDesktop;

  bool get isLargeDesktop => screenSize.isLargeDesktop;

  bool get isMobileOrTablet => screenSize.isMobileOrTablet;

  bool get isDesktopOrLarger => screenSize.isDesktopOrLarger;

  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    switch (screenSize) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenSize.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }
}

class ResponsiveSizing {
  static double nesScreenWidth(BuildContext context) =>
      (context.screenWidth - 32).clamp(128, 512);

  static double nesScreenHeight(double width) => width * 0.9375;

  static double debugPanelWidth(BuildContext context) => context.responsive(
        mobile: context.screenWidth * 0.9,
        tablet: 385,
        desktop: 385,
        largeDesktop: 450,
      );

  static double appBarTitleSize(BuildContext context) =>
      context.responsive(mobile: 12, tablet: 14, desktop: 16);

  static double appBarIconSize(BuildContext context) =>
      context.responsive(mobile: 20, tablet: 24, desktop: 24);

  static double onScreenControllerScale(BuildContext context) =>
      context.responsive(mobile: 0.6, tablet: 0.7, desktop: 0.8);

  static double fpsTextSize(BuildContext context) =>
      context.responsive(mobile: 10, tablet: 11, desktop: 12);

  static double keyBindingsTextSize(BuildContext context) =>
      context.responsive(mobile: 9, tablet: 10, desktop: 10);
}
