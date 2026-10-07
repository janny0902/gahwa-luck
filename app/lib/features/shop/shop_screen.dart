import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../profile/user_repository.dart';
import '../wallet/wallet_api.dart';
import 'shop_products.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  StreamSubscription<List<PurchaseDetails>>? _purchases;
  final _busyTokens = <String>{};
  Map<String, ProductDetails> _details = {};
  var _storeReady = false;
  var _loading = true;
  String? _storeNote;

  @override
  void initState() {
    super.initState();
    if (!shopPurchasesEnabled || kIsWeb) {
      _loading = false;
      _storeNote = shopPurchasesEnabled
          ? '결제는 폰 앱에서 됩니다'
          : '구매는 나중에 연결됩니다. 지금은 상품과 가격만 볼 수 있습니다.';
      return;
    }
    _purchases = InAppPurchase.instance.purchaseStream.listen(_onPurchases, onError: _onStreamError);
    _loadStore();
  }

  @override
  void dispose() {
    _purchases?.cancel();
    super.dispose();
  }

  Future<void> _loadStore() async {
    final iap = InAppPurchase.instance;
    final available = await iap.isAvailable();
    if (!available) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _storeReady = false;
        _storeNote = '이 설치본에서는 플레이 결제를 열 수 없습니다. 비공개 테스트로 받은 앱에서 구매할 수 있습니다.';
      });
      return;
    }
    final response = await iap.queryProductDetails(shopProducts.map((item) => item.id).toSet());
    if (!mounted) return;
    setState(() {
      _loading = false;
      _storeReady = true;
      _details = {for (final item in response.productDetails) item.id: item};
      if (response.notFoundIDs.isNotEmpty) {
        _storeNote = '플레이에 아직 없는 상품이 있습니다. 등록된 상품만 구매할 수 있습니다.';
      }
    });
  }

  Future<void> _buy(ShopProduct product) async {
    final details = _details[product.id];
    if (details == null) {
      _toast('플레이에 등록된 상품이 아닙니다');
      return;
    }
    final started = await InAppPurchase.instance.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: details),
      autoConsume: false,
    );
    if (!started && mounted) _toast('결제 창을 열지 못했습니다');
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) continue;
      if (purchase.status == PurchaseStatus.error || purchase.status == PurchaseStatus.canceled) {
        if (purchase.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchase);
        }
        if (purchase.status == PurchaseStatus.error && mounted) {
          _toast(purchase.error?.message ?? '결제가 취소되었습니다');
        }
        continue;
      }
      final token = purchase.verificationData.serverVerificationData;
      if (token.isEmpty || _busyTokens.contains(token)) continue;
      _busyTokens.add(token);
      try {
        await ref.read(walletApiProvider).verifyPurchase(
              productId: purchase.productID,
              purchaseToken: token,
            );
        if (purchase.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchase);
        }
        ref.invalidate(appUserProvider);
        if (mounted) _toast('구매한 상품을 넣었습니다');
      } on FunctionException catch (error) {
        if (mounted) _toast(_functionMessage(error));
      } catch (error) {
        if (mounted) _toast('$error');
      } finally {
        _busyTokens.remove(token);
      }
    }
  }

  void _onStreamError(Object error) {
    if (mounted) _toast('결제 연결이 끊겼습니다');
  }

  String _functionMessage(FunctionException error) {
    final details = error.details;
    if (details is Map && details['error'] != null) return details['error'].toString();
    return '결제 확인에 실패했습니다';
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final sections = <String>['부적', '쌀알', '패스'];
    return Scaffold(
      appBar: AppBar(title: const Text('상점')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                if (_storeNote != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_storeNote!, style: const TextStyle(color: AppColors.inkSoft)),
                  ),
                for (final section in sections) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      section,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  for (final product in shopProducts.where((item) => item.section == section))
                    _ProductTile(
                      product: product,
                      price: _details[product.id]?.price ?? product.listPrice,
                      enabled: shopPurchasesEnabled && _storeReady && _details.containsKey(product.id),
                      buttonLabel: shopPurchasesEnabled ? '구매' : '준비 중',
                      onBuy: () => _buy(product),
                    ),
                ],
              ],
            ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.price,
    required this.enabled,
    required this.buttonLabel,
    required this.onBuy,
  });

  final ShopProduct product;
  final String price;
  final bool enabled;
  final String buttonLabel;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.beigeDeep,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(product.detail),
                  const SizedBox(height: 4),
                  Text(price, style: const TextStyle(color: AppColors.crimson, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: enabled ? onBuy : null,
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
