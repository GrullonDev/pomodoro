import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sets up all Firebase mocks required for unit tests that indirectly touch
/// [FirebaseAuth.instance] (e.g. via [SessionRepository.addSession]).
///
/// Call once in [setUpAll] and then `await Firebase.initializeApp()`.
///
/// This mocks:
///   • firebase_core Pigeon channels → via the official [setupFirebaseCoreMocks]
///   • firebase_auth Pigeon channels for the two listener-registration calls
///     that [MethodChannelFirebaseAuth]'s constructor fires asynchronously.
///     Without these mocks the constructor's `.then()` futures throw an
///     unhandled [PlatformException] which fails the test.
void setupAllFirebaseMocks() {
  // Official firebase_core mock (from firebase_core_platform_interface/test.dart)
  setupFirebaseCoreMocks();

  // Raw binary mock for firebase_auth listener-registration channels.
  // The MethodChannelFirebaseAuth constructor calls registerIdTokenListener
  // and registerAuthStateListener (both return Future<String>) via Pigeon.
  // We return a List<Object?> containing a dummy String encoded with the
  // standard codec — Pigeon decodes it as the listener channel name.
  final codec = const StandardMessageCodec();
  final listenerIdResponse = codec.encodeMessage(<Object?>['mock_listener']);

  for (final channelName in [
    'dev.flutter.pigeon.firebase_auth_platform_interface.FirebaseAuthHostApi.registerIdTokenListener',
    'dev.flutter.pigeon.firebase_auth_platform_interface.FirebaseAuthHostApi.registerAuthStateListener',
  ]) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(channelName, (_) async => listenerIdResponse);
  }
}
