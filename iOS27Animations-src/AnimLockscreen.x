//
//  AnimLockscreen.x — 锁屏玻璃浮起 + 通知玻璃滑入
//
#import "iOS27Animations.h"

@interface SBLockScreenViewController : UIViewController @end
@interface SBDashBoardViewController : UIViewController @end
@interface NCNotificationBannerView : UIView @end

%hook SBLockScreenViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (!IOS27Enabled() || !IOS27Lockscreen()) return;
    IOS27AnimateLockScreenIn(self.view);
}
%end

%hook SBDashBoardViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (!IOS27Enabled() || !IOS27Lockscreen()) return;
    IOS27AnimateLockScreenIn(self.view);
}
%end

%hook NCNotificationBannerView
- (void)didMoveToWindow {
    %orig;
    if (!IOS27Enabled() || !IOS27Lockscreen()) return;
    if (self.window) IOS27AnimateBannerIn(self);
}
%end
