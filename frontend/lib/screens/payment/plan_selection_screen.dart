import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/payment/plan_card.dart';
import '../../models/plan.dart';
// import './purchase_screen.dart'; // 次の画面への遷移用

/// サブスクリプションプラン選択画面
class PlanSelectionScreen extends StatefulWidget {
  const PlanSelectionScreen({super.key});

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen> {
  Plan? _selectedPlan;

  @override
  void initState() {
    super.initState();
    // 画面表示時にプランをロード（初回のみ）
    // WidgetsBinding.instance.addPostFrameCallback((_) =>
    //   context.read<SubscriptionProvider>().loadAvailablePlans()
    // );
     // initState内で直接Providerを呼ぶ場合は listen: false を使う
     Future.microtask(() =>
        context.read<SubscriptionProvider>().loadAvailablePlans()
     );
  }

  void _onPlanSelected(Plan plan) {
    setState(() {
      _selectedPlan = plan;
    });
  }

  void _navigateToPurchaseScreen() {
    if (_selectedPlan != null) {
      // Navigator.push(context, MaterialPageRoute(
      //   builder: (context) => PurchaseScreen(selectedPlan: _selectedPlan!)
      // ));
      print("Navigating to purchase screen with plan: ${_selectedPlan!.name}");
      // TODO: 実際の画面遷移を実装
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('${_selectedPlan!.name} を選択しました。購入画面へ進みます（未実装）')),
       );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('プランを選択してください。')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final plans = subscriptionProvider.availablePlans;
    final isLoading = subscriptionProvider.isLoadingPlans;
    final error = subscriptionProvider.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('プランを選択'),
      ),
      body: _buildBody(context, isLoading, plans, error),
      bottomNavigationBar: _selectedPlan != null
        ? Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _navigateToPurchaseScreen,
            child: const Text('このプランで進む'),
            style: ElevatedButton.styleFrom(
               padding: const EdgeInsets.symmetric(vertical: 16.0)
            ),
          ),
        )
        : null,
    );
  }

  Widget _buildBody(BuildContext context, bool isLoading, List<Plan> plans, String? error) {
     if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && plans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Text('エラー: $error', textAlign: TextAlign.center),
               const SizedBox(height: 16),
               ElevatedButton(onPressed: () => context.read<SubscriptionProvider>().loadAvailablePlans(), child: const Text('再試行'))
             ],
          ),
        ),
      );
    }

    if (plans.isEmpty) {
      return const Center(child: Text('利用可能なプランがありません。'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: PlanCard(
            plan: plan,
            isSelected: _selectedPlan?.id == plan.id,
            onTap: () => _onPlanSelected(plan),
          ),
        );
      },
    );
  }
}