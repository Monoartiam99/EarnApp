import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdHelper {
  static RewardedAd? _rewardedAd;

  static void loadAndShowAd({
    required Function onRewardEarned,
    Function? onAdFailed,
  }) {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-8587580291187103/4322558198',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              if (onAdFailed != null) onAdFailed();
            },
          );
          _rewardedAd!.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
              onRewardEarned();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('❌ Failed to load rewarded ad: $error');
          if (onAdFailed != null) onAdFailed();
        },
      ),
    );
  }
}