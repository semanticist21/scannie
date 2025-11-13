import 'package:flutter/material.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _isProcessing = false;
  String _selectedPlan = 'monthly'; // 'monthly' or 'lifetime'

  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.picture_as_pdf,
      'title': '무제한 PDF 생성',
      'description': '하루 3개 제한 없이 무제한으로 PDF를 생성하세요',
    },
    {
      'icon': Icons.high_quality,
      'title': '이미지 업스케일링',
      'description': '저화질 이미지를 고화질로 변환',
    },
    {
      'icon': Icons.ad_units_off,
      'title': '광고 제거',
      'description': '모든 광고 없이 깔끔한 경험',
    },
    {
      'icon': Icons.cloud_upload,
      'title': '클라우드 저장',
      'description': '스캔한 문서를 클라우드에 안전하게 저장 (예정)',
    },
    {
      'icon': Icons.support_agent,
      'title': '우선 지원',
      'description': '빠른 고객 지원 서비스',
    },
  ];

  Future<void> _purchasePlan(String plan) async {
    setState(() {
      _isProcessing = true;
    });

    // TODO: 실제 In-App Purchase 구현
    // 현재는 시뮬레이션
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });

      // 구매 성공 다이얼로그
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🎉 구매 완료!'),
          content: const Text(
            '프리미엄 멤버십이 활성화되었습니다.\n'
            '모든 프리미엄 기능을 이용하실 수 있습니다.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // 다이얼로그 닫기
                Navigator.pop(context); // 프리미엄 화면 닫기
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('프리미엄 업그레이드'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 헤더
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue[700]!,
                    Colors.blue[500]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Scannie Premium',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '모든 기능을 무제한으로',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 기능 목록
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '프리미엄 기능',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._features.map((feature) => _buildFeatureItem(
                        icon: feature['icon'],
                        title: feature['title'],
                        description: feature['description'],
                      )),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 가격 플랜
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildPricingCard(
                    plan: 'monthly',
                    title: '월간 구독',
                    price: '\$1.00',
                    period: '/ 월',
                    description: '언제든지 취소 가능',
                    isSelected: _selectedPlan == 'monthly',
                    onTap: () {
                      setState(() {
                        _selectedPlan = 'monthly';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPricingCard(
                    plan: 'lifetime',
                    title: '평생 이용권',
                    price: '\$9.99',
                    period: '한 번만',
                    description: '가장 인기 있는 선택',
                    badge: '70% 할인',
                    isSelected: _selectedPlan == 'lifetime',
                    onTap: () {
                      setState(() {
                        _selectedPlan = 'lifetime';
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 구매 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing
                      ? null
                      : () => _purchasePlan(_selectedPlan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _selectedPlan == 'monthly'
                              ? '월간 구독 시작하기'
                              : '평생 이용권 구매하기',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 작은 글씨
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                '구독은 자동으로 갱신됩니다. 취소는 언제든지 가능합니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.blue,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard({
    required String plan,
    required String title,
    required String price,
    required String period,
    required String description,
    String? badge,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : null,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected ? Colors.blue : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        period,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
