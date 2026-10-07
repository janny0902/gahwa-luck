/// Play 상품이 활성화되고 서비스 계정이 연결된 뒤에 결제가 완료된다.
const shopPurchasesEnabled = true;

class ShopProduct {
  const ShopProduct({
    required this.id,
    required this.title,
    required this.detail,
    required this.listPrice,
    required this.section,
  });

  final String id;
  final String title;
  final String detail;
  final String listPrice;
  final String section;
}

const shopProducts = <ShopProduct>[
  ShopProduct(
    id: 'amulet_1',
    title: '부적 1개',
    detail: '운세 1회',
    listPrice: '800원',
    section: '부적',
  ),
  ShopProduct(
    id: 'amulet_10',
    title: '부적 10개',
    detail: '운세 10회',
    listPrice: '5,000원',
    section: '부적',
  ),
  ShopProduct(
    id: 'amulet_30',
    title: '부적 30개',
    detail: '운세 30회',
    listPrice: '11,000원',
    section: '부적',
  ),
  ShopProduct(
    id: 'rice_1',
    title: '쌀알 1개',
    detail: '추가 질문 1회',
    listPrice: '100원',
    section: '쌀알',
  ),
  ShopProduct(
    id: 'rice_10',
    title: '쌀알 10개',
    detail: '추가 질문 10회',
    listPrice: '700원',
    section: '쌀알',
  ),
  ShopProduct(
    id: 'rice_30',
    title: '쌀알 30개',
    detail: '추가 질문 30회',
    listPrice: '1,500원',
    section: '쌀알',
  ),
  ShopProduct(
    id: 'pass_30d',
    title: '30일 패스',
    detail: '매일 부적 5개, 쌀알 15개. 하단 배너를 숨깁니다.',
    listPrice: '3,300원',
    section: '패스',
  ),
];
