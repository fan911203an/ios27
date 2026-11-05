//
//  iOS27Animations.h
//  iOS 27 Animations — 共享接口
//

#ifndef iOS27Animations_h
#define iOS27Animations_h

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

// ---- 偏好开关 ----
BOOL IOS27Enabled(void);        // 总开关
BOOL IOS27AppTransition(void);  // 应用开合转场
BOOL IOS27IslandEnabled(void);  // 灵动岛/状态栏
BOOL IOS27Lockscreen(void);     // 锁屏与通知
BOOL IOS27Home(void);           // 桌面与图标

// ---- 通用动画辅助 ----
CABasicAnimation *IOS27SpringScale(CGFloat from, CGFloat to);
void IOS27BounceLayer(CALayer *layer);
void IOS27AnimateLockScreenIn(UIView *view);
void IOS27AnimateBannerIn(UIView *view);

// ---- 应用开合转场覆盖层 ----
@interface IOS27ZoomOverlay : NSObject
+ (instancetype)shared;
- (void)appWillOpen;        // App 即将打开
- (void)appDidReturnHome;   // 回到桌面
@end

// ---- 灵动岛 ----
@interface IOS27Island : NSObject
+ (instancetype)shared;
- (void)presentAnimated:(BOOL)animated text:(NSString *)text;
- (void)dismissAnimated:(BOOL)animated;
- (void)toggleWithText:(NSString *)text;
@end

#endif /* iOS27Animations_h */
