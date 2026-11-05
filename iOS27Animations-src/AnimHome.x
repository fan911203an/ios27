//
//  AnimHome.x — 桌面与图标动效
//  图标弹跳入场 + 文件夹弹簧展开
//
#import "iOS27Animations.h"

// Hook 类的最小声明（仅为编译期类型完整）
@interface SBIconImageView : UIView @end
@interface SBFolderController : UIViewController @end

// 图标：布局时做一次回弹
%hook SBIconImageView
- (void)layoutSubviews {
    %orig;
    if (!IOS27Enabled() || !IOS27Home()) return;
    static NSString *const bounced = @"ios27_iconBounced";
    if (![self.layer valueForKey:bounced]) {
        [self.layer setValue:@YES forKey:bounced];
        IOS27BounceLayer(self.layer);
    }
}
%end

// 文件夹：弹簧放大渐显（幅度收敛 0.6→0.9，阻尼加大，避免生硬）
%hook SBFolderController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    if (!IOS27Enabled() || !IOS27Home()) return;
    self.view.alpha = 0.62;
    self.view.transform = CGAffineTransformMakeScale(0.9, 0.9);
    [UIView animateWithDuration:0.48
                          delay:0
         usingSpringWithDamping:0.84
          initialSpringVelocity:0.25
                        options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        self.view.transform = CGAffineTransformIdentity;
        self.view.alpha = 1.0;
    } completion:nil];
}
%end
