//
//  AnimIsland.x — 灵动岛：通知到达时弹出玻璃胶囊
//
#import "iOS27Animations.h"

@interface SBNotificationBannerDestination : NSObject
- (void)presentBannerForNotificationRequest:(id)request;
@end

%hook SBNotificationBannerDestination
- (void)presentBannerForNotificationRequest:(id)request {
    %orig;
    if (!IOS27Enabled() || !IOS27IslandEnabled()) return;
    NSString *text = nil;
    if ([request respondsToSelector:NSSelectorFromString(@"title")]) {
        text = [request valueForKey:@"title"];
    }
    [[IOS27Island shared] presentAnimated:YES text:(text.length ? text : @"● ● ●")];
}
%end
