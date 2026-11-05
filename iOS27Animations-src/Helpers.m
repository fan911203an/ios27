//
//  Helpers.m
//  iOS 27 Animations — 偏好读取与共享动效实现
//

#import "iOS27Animations.h"
#import <objc/runtime.h>

#pragma mark - 偏好读取

static NSString *IOS27PrefsPath(void) {
    // rootless (现代越狱, iOS 27) 优先，回退 rootful
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
    // 每次实时读取，设置里切开关即时生效，无需 respring
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

#pragma mark - 通用动画辅助

// 弹簧缩放动画
CABasicAnimation *IOS27SpringScale(CGFloat from, CGFloat to) {
    CASpringAnimation *s = [CASpringAnimation animationWithKeyPath:@"transform.scale"];
    s.fromValue = @(from);
    s.toValue = @(to);
    s.damping = 12.0;
    s.stiffness = 180.0;
    s.mass = 1.0;
    s.initialVelocity = 10.0;
    s.duration = s.settlingDuration;
    return s;
}

// 弹跳回弹（图标）
void IOS27BounceLayer(CALayer *layer) {
    CAKeyframeAnimation *pop = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    pop.values   = @[@1.0, @1.09, @0.97, @1.0];
    pop.keyTimes = @[@0.0, @0.4, @0.72, @1.0];
    pop.duration = 0.42;
    pop.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [layer addAnimation:pop forKey:@"ios27bounce"];
}

// 锁屏整体入场：缩放 + 渐显
void IOS27AnimateLockScreenIn(UIView *view) {
    view.alpha = 0.2;
    view.transform = CGAffineTransformMakeScale(1.06, 1.06);
    [UIView animateWithDuration:0.55
                          delay:0
         usingSpringWithDamping:0.85
          initialSpringVelocity:0.4
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        view.transform = CGAffineTransformIdentity;
        view.alpha = 1.0;
    } completion:nil];
}

// 通知横幅滑入 + 回弹
void IOS27AnimateBannerIn(UIView *view) {
    view.layer.transform = CATransform3DMakeTranslation(0, -44, 0);
    view.alpha = 0.0;
    [UIView animateWithDuration:0.50
                          delay:0
         usingSpringWithDamping:0.82
          initialSpringVelocity:0.6
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        view.layer.transform = CATransform3DIdentity;
        view.alpha = 1.0;
    } completion:nil];
}

#pragma mark - 应用开合转场覆盖层

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

- (UIView *)makeOverlayOnHost:(UIView *)host {
    UIView *ov = [[UIView alloc] initWithFrame:host.bounds];
    ov.backgroundColor = [UIColor blackColor];
    UIImage *img = [self snapshotOfView:host];
    if (img) {
        UIImageView *iv = [[UIImageView alloc] initWithFrame:host.bounds];
        iv.image = img;
        iv.contentMode = UIViewContentModeScaleAspectFill;
        [ov addSubview:iv];
    }
    return ov;
}

// App 即将打开：画面微微放大压暗，随后淡出露出 App —— 模拟“推入”转场
- (void)appWillOpen {
    if (!IOS27Enabled() || !IOS27AppTransition()) return;
    _appIsOpen = YES;

    UIView *host = [self topWindowView];
    if (!host) return;
    if (_overlay) { [_overlay removeFromSuperview]; _overlay = nil; }

    UIView *ov = [self makeOverlayOnHost:host];
    ov.alpha = 0.0;
    [host addSubview:ov];
    _overlay = ov;

    [UIView animateWithDuration:0.26 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        ov.alpha = 1.0;
        ov.transform = CGAffineTransformMakeScale(1.12, 1.12);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.14 animations:^{
            ov.alpha = 0.0;
        } completion:^(BOOL f2) {
            [ov removeFromSuperview];
            if (_overlay == ov) _overlay = nil;
        }];
    }];
}

// 回到桌面：从图标位弹簧放大展开 —— 模拟“开屏拉近”转场
- (void)appDidReturnHome {
    if (!_appIsOpen) return;
    _appIsOpen = NO;
    if (!IOS27Enabled() || !IOS27AppTransition()) return;

    UIView *host = [self topWindowView];
    if (!host) return;
    if (_overlay) { [_overlay removeFromSuperview]; _overlay = nil; }

    UIView *ov = [self makeOverlayOnHost:host];
    ov.alpha = 0.0;
    ov.transform = CGAffineTransformMakeScale(0.32, 0.32);
    [host addSubview:ov];
    _overlay = ov;

    [UIView animateWithDuration:0.44 delay:0
         usingSpringWithDamping:0.82 initialSpringVelocity:0.6
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        ov.transform = CGAffineTransformIdentity;
        ov.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.18 animations:^{
            ov.alpha = 0.0;
        } completion:^(BOOL f2) {
            [ov removeFromSuperview];
            if (_overlay == ov) _overlay = nil;
        }];
    }];
}

@end

#pragma mark - 灵动岛

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
    _pill.transform = CGAffineTransformMakeScale(0.4, 0.4);

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
        [UIView animateWithDuration:0.5 delay:0
             usingSpringWithDamping:0.6 initialSpringVelocity:0.8
                            options:UIViewAnimationOptionCurveEaseOut
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
        _pill.transform = CGAffineTransformMakeScale(0.2, 0.2);
        _pill.alpha = 0.0;
    };
    void (^complete)(BOOL) = ^(BOOL finished) {
        _pill.hidden = YES;
    };
    if (animated) {
        [UIView animateWithDuration:0.4 delay:0
             usingSpringWithDamping:0.9 initialSpringVelocity:0.3
                            options:UIViewAnimationOptionCurveEaseIn
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
