//
//  Tweak.x — 入口：注册生命周期监听，驱动应用开合转场与灵动岛
//
#import "iOS27Animations.h"

%ctor {
    // 触发一次，确保偏好默认值载入
    (void)IOS27Enabled();

    // 应用开合：利用 SpringBoard 进程内的 UIKit 生命周期通知（稳定、跨版本）
    // willResignActive = 有 App 即将打开；didBecomeActive = 回到桌面
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        [[IOS27ZoomOverlay shared] appWillOpen];
        // 灵动岛联动演示：开应用时岛收起
        [[IOS27Island shared] dismissAnimated:YES];
    }];

    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        [[IOS27ZoomOverlay shared] appDidReturnHome];
    }];
}
