//
//  AnimLockscreen.x — 锁屏与通知动效
//  锁屏整体弹簧入场 + 通知横幅滑入回弹
//
#import "iOS27Animations.h"

// Hook 类的最小声明（仅为编译期类型完整）
@interface SBLockScreenViewController : UIViewController @end
@interface SBDashBoardViewController : UIViewController @end
@interface NCNotificationBannerView : UIView @end

// 锁屏（新旧类名都 hook，缺失时自动跳过）
%hook SBLockScreenViewController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    if (!IOS27Enabled() || !IOS27Lockscreen()) return;
    IOS27AnimateLockScreenIn(self.view);
}
%end

%hook SBDashBoardViewController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    if (!IOS27Enabled() || !IOS27Lockscreen()) return;
    IOS27AnimateLockScreenIn(self.view);
}
%end

// 通知横幅：滑入 + 回弹
%hook NCNotificationBannerView
- (void)layoutSubviews {
    %orig;
    if (!IOS27Enabled() || !IOS27Lockscreen()) return;
    static NSString *const bounced = @"ios27_bannerBounced";
    if (![self.layer valueForKey:bounced]) {
        [self.layer setValue:@YES forKey:bounced];
        IOS27AnimateBannerIn(self);
    }
}
%end
