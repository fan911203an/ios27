//
//  Tweak.x — 入口：通知驱动应用开合 zoom 转场
//
#import "iOS27Animations.h"

%ctor {
    // 打开 App 时 SpringBoard 失焦 → 桌面 zoom-out
    [[NSNotificationCenter defaultCenter] addObserver:[IOS27ZoomOverlay shared]
                                             selector:@selector(appWillOpen)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    // 回到桌面时 SpringBoard 获焦 → 桌面 zoom-in
    [[NSNotificationCenter defaultCenter] addObserver:[IOS27ZoomOverlay shared]
                                             selector:@selector(appDidReturnHome)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}
