//
//  AnimIsland.x — 灵动岛/状态栏
//  通知横幅出现时，灵动岛胶囊展开演示
//
#import "iOS27Animations.h"

// Hook 类的最小声明（仅为编译期类型完整）
@interface SBNotificationBannerDestination : NSObject @end

%hook SBNotificationBannerDestination
- (void)presentBannerForNotificationRequest:(id)request {
    %orig;
    if (!IOS27Enabled() || !IOS27IslandEnabled()) return;
    NSString *title = nil;
    if ([request respondsToSelector:@selector(title)]) {
        id t = [request title];
        if ([t isKindOfClass:[NSString class]]) title = t;
    }
    if (!title.length) title = @"通知";
    [[IOS27Island shared] presentAnimated:YES text:title];
}
%end
