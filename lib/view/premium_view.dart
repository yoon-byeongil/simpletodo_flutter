import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../const/app_strings.dart';
import '../const/app_colors.dart';
import '../view_model/settings_view_model.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.workspace_premium, size: 80, color: AppColors.premiumIcon),
            const SizedBox(height: 24),
            Text(
              AppStrings.premiumTitle,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 10),
            Text(
              AppStrings.premiumSubTitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: subTextColor, fontSize: 14),
            ),
            const SizedBox(height: 40),

            _buildBenefitItem(Icons.block, AppStrings.benefitAd, AppStrings.benefitAdDesc, textColor, subTextColor),
            _buildBenefitItem(Icons.push_pin, AppStrings.benefitPin, AppStrings.benefitPinDesc, textColor, subTextColor),
            _buildBenefitItem(Icons.cloud_sync, AppStrings.benefitCloud, AppStrings.benefitCloudDesc, textColor, subTextColor),

            const Spacer(),

            Consumer<SettingsViewModel>(
              builder: (context, vm, child) {
                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      bool success = await vm.buyPremium();
                      if (success && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text(
                      AppStrings.buyButton,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () async {
                final vm = context.read<SettingsViewModel>();
                await vm.restorePurchase();
                if (context.mounted && vm.isPremium) {
                  Navigator.pop(context);
                }
              },
              child: Text(AppStrings.restorePurchase, style: TextStyle(color: subTextColor)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String desc, Color titleColor, Color descColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.premiumBg, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: titleColor),
              ),
              Text(desc, style: TextStyle(color: descColor, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
