//
//  Helpers.m
//  iOS 27 Animations — 偏好读取与共享动效实现
//  v1.0.9：动画质感优化（去掉闪黑遮罩、统一 spring 大阻尼曲线、时长加长）
//

#import "iOS27Animations.h"
#import <objc/runtime.h>

#pragma mark - 偏好读取

static NSString *IOS27PrefsPath(void) {
    static NSString *path = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSArray *candidates = @[
            @"/var/jb/var/mobile/Library/Preferences/com.ios27.animations.plist",
            @"/var/mobile/Library/Preferences/com.ios27.animations.plist"
        ];
        for (NSString *p in candidates) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:p]) { path = p; break; }
        }
        if (!path) path = candidates[0];
    });
    return path;
}

static NSDictionary *IOS27Prefs(void) {
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:
                              [NSDictionary dictionaryWithContentsOfFile:IOS27PrefsPath()] ?: @{}];
    if (!d[@"enabled"])       d[@"enabled"]       = @YES;
    if (!d[@"appTransition"]) d[@"appTransition"] = @YES;
    if (!d[@"island"])        d[@"island"]        = @YES;
    if (!d[@"lockscreen"])    d[@"lockscreen"]    = @YES;
    if (!d[@"home"])          d[@"home"]          = @YES;
    return d;
}

BOOL IOS27Enabled(void)       { return [IOS27Prefs()[@"enabled"] boolValue]; }
BOOL IOS27AppTransition(void) { return [IOS27Prefs()[@"appTransition"] boolValue]; }
BOOL IOS27IslandEnabled(void) { return [IOS27Prefs()[@"island"] boolValue]; }
BOOL IOS27Lockscreen(void)    { return [IOS27Prefs()[@"lockscreen"] boolValue]; }
BOOL IOS27Home(void)          { return [IOS27Prefs()[@"home"] boolValue]; }

#pragma mark - 通用动画辅助（统一 iOS 风格 spring 参数）

CABasicAnimation *IOS27SpringScale(CGFloat from, CGFloat to) {
    CASpringAnimation *s = [CASpringAnimation animationWithKeyPath:@"transform.scale"];
    s.fromValue   = @(from);
    s.toValue     = @(to);
    s.damping     = 16.0;      // 更大阻尼 → 不抖
    s.stiffness   = 170.0;
    s.mass        = 1.0;
    s.initialVelocity = 0.0;
    s.duration    = s.settlingDuration;
    return s;
}

// 图标弹跳：幅度收敛、曲线改 easeOut、时长加长（比原来的 easeInEaseOut + 1.09 更柔）
void IOS27BounceLayer(CALayer *layer) {
    CAKeyframeAnimation *pop = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    pop.values    = @[@1.0, @1.055, @0.992, @1.0];
    pop.keyTimes  = @[@0.0, @0.34, @0.68, @1.0];
    pop.duration  = 0.52;
    pop.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [layer addAnimation:pop forKey:@"ios27bounce"];
}

// 锁屏整体入场：轻微缩放 + 柔和渐显（改为大阻尼 spring，时长 0.5s）
void IOS27AnimateLockScreenIn(UIView *view) {
    view.alpha = 0.45;
    view.transform = CGAffineTransformMakeScale(1.035, 1.035);
    [UIView animateWithDuration:0.5 delay:0
         usingSpringWithDamping:0.84 initialSpringVelocity:0.18
                        options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        view.transform = CGAffineTransformIdentity;
        view.alpha = 1.0;
    } completion:nil];
}

// 通知横幅滑入 + 轻回弹（位移收敛 44→32，阻尼加大）
void IOS27AnimateBannerIn(UIView *view) {
    view.layer.transform = CATransform3DMakeTranslation(0, -32, 0);
    view.alpha = 0.0;
    [UIView animateWithDuration:0.52 delay:0
         usingSpringWithDamping:0.80 initialSpringVelocity:0.30
                        options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        view.layer.transform = CATransform3DIdentity;
        view.alpha = 1.0;
    } completion:nil];
}

#pragma mark - 应用开合转场覆盖层（去掉黑遮罩，改为柔和缩放淡出/淡入）

@implementation IOS27ZoomOverlay {
    UIView *_overlay;
    BOOL _appIsOpen;
}

+ (instancetype)shared {
    static IOS27ZoomOverlay *instance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ instance = [[self alloc] init]; });
    return instance;
}

- (UIView *)topWindowView {
    UIApplication *app = [UIApplication sharedApplication];
    UIWindow *w = app.keyWindow;
    if (!w) w = [app windows].firstObject;
    return w;
}

- (UIImage *)snapshotOfView:(UIView *)host {
    UIGraphicsBeginImageContextWithOptions(host.bounds.size, NO, 0);
    [host drawViewHierarchyInRect:host.bounds afterScreenUpdates:NO];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

// 关键：背景改为透明（不再纯黑），消除“闪黑/压暗”的生硬感
- (UIView *)makeOverlayOnHost:(UIView *)host {
    UIView *ov = [[UIView alloc] initWithFrame:host.bounds];
    ov.backgroundColor = [UIColor clearColor];
    ov.userInteractionEnabled = NO;
    UIImage *img = [self snapshotOfView:host];
    if (img) {
        UIImageView *iv = [[UIImageView alloc] initWithFrame:host.bounds];
        iv.image = img;
        iv.contentMode = UIViewContentModeScaleAspectFill;
        [ov addSubview:iv];
    }
    return ov;
}

// App 即将打开：旧画面轻微放大 + 柔和淡出，露出 App（无闪黑，spring 0.4s）
- (void)appWillOpen {
    if (!IOS27Enabled() || !IOS27AppTransition()) return;
    _appIsOpen = YES;

    UIView *host = [self topWindowView];
    if (!host) return;
    if (_overlay) { [_overlay removeFromSuperview]; _overlay = nil; }

    UIView *ov = [self makeOverlayOnHost:host];
    ov.alpha = 1.0;
    ov.transform = CGAffineTransformIdentity;
    [host addSubview:ov];
    _overlay = ov;

    [UIView animateWithDuration:0.40 delay:0
         usingSpringWithDamping:0.92 initialSpringVelocity:0.15
                        options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        ov.transform = CGAffineTransformMakeScale(1.06, 1.06);
        ov.alpha = 0.0;
    } completion:^(BOOL finished) {
        [ov removeFromSuperview];
        if (_overlay == ov) _overlay = nil;
    }];
}

// 回到桌面：画面从略小柔和展开 + 渐显，随后缓慢淡出露出桌面（全程 spring）
- (void)appDidReturnHome {
    if (!_appIsOpen) return;
    _appIsOpen = NO;
    if (!IOS27Enabled() || !IOS27AppTransition()) return;

    UIView *host = [self topWindowView];
    if (!host) return;
    if (_overlay) { [_overlay removeFromSuperview]; _overlay = nil; }

    UIView *ov = [self makeOverlayOnHost:host];
    ov.alpha = 0.0;
    ov.transform = CGAffineTransformMakeScale(0.94, 0.94);
    [host addSubview:ov];
    _overlay = ov;

    [UIView animateWithDuration:0.42 delay:0
         usingSpringWithDamping:0.88 initialSpringVelocity:0.22
                        options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        ov.transform = CGAffineTransformIdentity;
        ov.alpha = 1.0;
    } completion:^(BOOL finished) {
        // 停留一小段，再用较长时长缓慢淡出（避免突然消失）
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.20 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.26 delay:0
                                  options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                ov.alpha = 0.0;
            } completion:^(BOOL f2) {
                [ov removeFromSuperview];
                if (_overlay == ov) _overlay = nil;
            }];
        });
    }];
}

@end

#pragma mark - 灵动岛（展开阻尼收敛，收起改 easeOut 平滑）

@implementation IOS27Island {
    UIView *_pill;
    UILabel *_label;
    BOOL _visible;
}

+ (instancetype)shared {
    static IOS27Island *instance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ instance = [[self alloc] init]; });
    return instance;
}

- (void)ensurePill {
    if (_pill) return;
    UIApplication *app = [UIApplication sharedApplication];
    UIWindow *w = app.keyWindow ?: [app windows].firstObject;
    if (!w) return;

    CGFloat ww = w.bounds.size.width;
    CGFloat ph = 34.0;
    CGRect frame = CGRectMake(ww/2 - 100, 12, 200, ph);

    UIView *p = [[UIView alloc] initWithFrame:frame];
    p.backgroundColor = [UIColor blackColor];
    p.layer.cornerRadius = ph/2;
    p.layer.masksToBounds = YES;
    p.alpha = 0.0;

    _label = [[UILabel alloc] initWithFrame:p.bounds];
    _label.textAlignment = NSTextAlignmentCenter;
    _label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    _label.textColor = [UIColor whiteColor];
    _label.text = @"● ● ●";
    [p addSubview:_label];

    [w addSubview:p];
    _pill = p;
}

- (void)presentAnimated:(BOOL)animated text:(NSString *)text {
    if (!IOS27Enabled() || !IOS27IslandEnabled()) return;
    [self ensurePill];
    if (!_pill) return;

    if (text && text.length) _label.text = text;
    _visible = YES;
    _pill.hidden = NO;
    _pill.alpha = 1.0;
    _pill.transform = CGAffineTransformMakeScale(0.55, 0.55);

    CGRect target = _pill.frame;
    target.size.width = 216;

    void (^expand)(void) = ^{
        _pill.frame = target;
        _pill.transform = CGAffineTransformIdentity;
    };
    void (^complete)(BOOL) = ^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.2 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            if (_visible) [self dismissAnimated:YES];
        });
    };

    if (animated) {
        [UIView animateWithDuration:0.55 delay:0
             usingSpringWithDamping:0.74 initialSpringVelocity:0.35
                            options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                         animations:expand completion:complete];
    } else {
        expand();
        complete(YES);
    }
}

- (void)dismissAnimated:(BOOL)animated {
    _visible = NO;
    if (!_pill) return;
    void (^collapse)(void) = ^{
        _pill.transform = CGAffineTransformMakeScale(0.35, 0.35);
        _pill.alpha = 0.0;
    };
    void (^complete)(BOOL) = ^(BOOL finished) {
        _pill.hidden = YES;
        _pill.transform = CGAffineTransformIdentity;
    };
    if (animated) {
        [UIView animateWithDuration:0.36 delay:0
             usingSpringWithDamping:0.94 initialSpringVelocity:0.15
                            options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                         animations:collapse completion:complete];
    } else {
        collapse();
        complete(YES);
    }
}

- (void)toggleWithText:(NSString *)text {
    if (_visible) [self dismissAnimated:YES];
    else [self presentAnimated:YES text:text];
}

@end
