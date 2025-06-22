import 'package:flutter/widgets.dart';

enum DeviceScreenType {
  mobileSmall,
  mobileMedium,
  mobileLarge,
  tablet,
  desktop,
}

class Responsive {
  static DeviceScreenType getDeviceType(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    if (width >= 1200) {
      return DeviceScreenType.desktop;
    } else if (width >= 900) {
      return DeviceScreenType.tablet;
    } else if (width >= 600) {
      return DeviceScreenType.mobileLarge;
    } else if (width >= 360) {
      return DeviceScreenType.mobileMedium;
    } else {
      return DeviceScreenType.mobileSmall;
    }
  }
}

extension ResponsiveExtension on BuildContext {
  DeviceScreenType get deviceType => Responsive.getDeviceType(this);

  /// Retorna true si el dispositivo es móvil pequeño
  bool get isMobileSmall => deviceType == DeviceScreenType.mobileSmall;

  /// Retorna true si el dispositivo es móvil mediano
  bool get isMobileMedium => deviceType == DeviceScreenType.mobileMedium;

  /// Retorna true si el dispositivo es móvil grande
  bool get isMobileLarge => deviceType == DeviceScreenType.mobileLarge;

  /// Retorna true si el dispositivo es tablet
  bool get isTablet => deviceType == DeviceScreenType.tablet;

  /// Retorna true si el dispositivo es desktop
  bool get isDesktop => deviceType == DeviceScreenType.desktop;

  /// Retorna true si el dispositivo es cualquier tipo de móvil
  bool get isMobile =>
      deviceType == DeviceScreenType.mobileSmall ||
      deviceType == DeviceScreenType.mobileMedium ||
      deviceType == DeviceScreenType.mobileLarge;
}
