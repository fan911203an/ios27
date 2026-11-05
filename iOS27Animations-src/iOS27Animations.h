//
//  iOS27Animations.h
//  iOS 26 / Liquid Glass 风格动效 — 共享接口
//

#ifndef iOS27Animations_h
#define iOS27Animations_h

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

// ---- 偏好开关 ----
BOOL IOS27Enabled(void);        // 总开关
BOOL IOS27AppTransition(void);  // 应用开合(zoom 转场)
BOOL IOS27IslandEnabled(void);  // 灵动岛/状态栏
BOOL IOS27Lockscreen(void);     // 锁屏与通知
BOOL IOS27Home(void);           // 桌面与图标

// ---- 通用动效辅助 ----
void IOS27BounceLayer(CALayer *layer);      // 图标液态回弹 + 光泽
void IOS27AnimateLockScreenIn(UIView *view); // 锁屏玻璃浮起
void IOS27AnimateBannerIn(UIView *view);     // 通知玻璃滑入

// ---- 应用开合 zoom 转场（Liquid Glass）----
@interface IOS27ZoomOverlay : NSObject
+ (instancetype)shared;
- (void)appWillOpen;        // App 即将打开：桌面缩向中心圆角消失
- (void)appDidReturnHome;   // 回到桌面：玻璃从一点放大展开
@end

// ---- 灵动岛（液态玻璃胶囊）----
@interface IOS27Island : NSObject
+ (instancetype)shared;
- (void)presentAnimated:(BOOL)animated text:(NSString *)text;
- (void)dismissAnimated:(BOOL)animated;
- (void)toggleWithText:(NSString *)text;
@end

#endif /* iOS27Animations_h */
