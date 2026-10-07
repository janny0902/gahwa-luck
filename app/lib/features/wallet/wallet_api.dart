import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_providers.dart';

class WalletApi {
  WalletApi(this._client);
  final SupabaseClient _client;

  Future<void> dailyGrant() async {
    await _client.functions.invoke('daily-grant');
  }

  Future<void> verifyPurchase({
    required String productId,
    required String purchaseToken,
  }) async {
    final response = await _client.functions.invoke(
      'verify-iap',
      body: {
        'product_id': productId,
        'purchase_token': purchaseToken,
      },
    );
    final data = response.data;
    if (data is Map && data['error'] != null) {
      throw Exception(data['error'].toString());
    }
  }

  Future<void> claimReward(String kind) async {
    final response = await _client.functions.invoke(
      'claim-reward',
      body: {'kind': kind},
    );
    final data = response.data;
    if (data is Map && data['error'] != null) {
      throw Exception(data['error'].toString());
    }
  }
}

final walletApiProvider = Provider<WalletApi>((ref) {
  return WalletApi(ref.watch(supabaseClientProvider));
});
