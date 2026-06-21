import 'package:url_launcher/url_launcher.dart';

// Fixed deeplink map. Add new apps here — never query the TV at runtime.
class SamsungAppId {
  static const netflix = 'netflix';
  static const primevideo = 'primevideo';
  static const disneyPlus = 'disneyplus';
  static const hulu = 'hulu';
  static const max = 'max';
  static const youtube = 'youtube';
}

class SamsungAppLauncher {
  static const Map<String, String> _deeplinks = {
    SamsungAppId.netflix: 'netflix://',
    SamsungAppId.primevideo: 'com.amazon.primevideo://',
    SamsungAppId.disneyPlus: 'com.disney.disneyplus-prod://',
    SamsungAppId.hulu: 'hulu://',
    SamsungAppId.max: 'com.wbd.stream://',
    SamsungAppId.youtube: 'com.google.android.youtube.tv://',
  };

  Future<void> launchApp(String appId) async {
    final deeplink = _deeplinks[appId];
    if (deeplink == null) return;
    final uri = Uri.parse(deeplink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
