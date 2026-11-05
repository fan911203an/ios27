//
//  AnimHome.x — 桌面与图标动效（iOS 26 液态回弹 + 玻璃高光）
//
#import "iOS27Animations.h"

@interface SBIconImageView : UIView @end
@interface SBFolderController : UIViewController @end

%hook SBIconImageView
- (void)layoutSubviews {
    %orig;
    if (!IOS27Enabled() || !IOS27Home()) return;
    static NSString *const bounced = @"ios26_iconBounced";
    if (![self.layer valueForKey:bounced]) {
        [self.layer setValue:@YES forKey:bounced];
        IOS27BounceLayer(self.layer);
    }
}
%end

// 文件夹：从略小圆角展开 → 圆角收拢（玻璃卡片的浮起感）
%hook SBFolderController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    if (!IOS27Enabled() || !IOS27Home()) return;
    self.view.alpha = 0.65;
    self.view.transform = CGAffineTransformMakeScale(0.9, 0.9);
    self.view.layer.cornerRadius = 26.0;
    self.view.layer.masksToBounds = YES;
    [UIView animateWithDuration:0.5
                          delay:0
         usingSpringWithDamping:0.85
          initialSpringVelocity:0.22
                        options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        self.view.transform = CGAffineTransformIdentity;
        self.view.layer.cornerRadius = 0.0;
        self.view.alpha = 1.0;
    } completion:nil];
}
%end
