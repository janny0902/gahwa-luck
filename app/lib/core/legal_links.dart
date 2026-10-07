import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const privacyPolicyUrl = 'https://sites.google.com/view/gahaw-luck-privacy/%ED%99%88';
const accountDeletionUrl = 'https://sites.google.com/view/gahwa-luck-idclose/%ED%99%88';

const entertainmentDisclaimer =
    '본 서비스의 운세 결과는 오락 목적이며, 전문적인 의료·법률·금융 결정을 대체할 수 없습니다.';

Future<void> openLegalPage(BuildContext context, String url) async {
  final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('페이지를 열지 못했습니다')),
    );
  }
}
