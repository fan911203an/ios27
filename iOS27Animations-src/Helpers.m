//
//  Helpers.m — iOS 26 / Liquid Glass 风格动效实现
//  核心差异：应用开合改为“缩向中心/从一点展开”的 zoom 转场 + 圆角变化；
//           图标液态回弹 + 玻璃高光扫过；灵动岛改为半透明玻璃胶囊。
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

#pragma mark - 图标：液态回弹 + 玻璃高光扫过

void IOS27BounceLayer(CALayer *layer) {
    // 1) 液态回弹（幅度收敛、easeOut 收尾，接近 iOS 26 的弹性手感）
    CAKeyframeAnimation *pop = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    pop.values    = @[@1.0, @1.075, @0.985, @1.0];
    pop.keyTimes  = @[@0.0, @0.38, @0.72, @1.0];
    pop.duration  = 0.46;
    pop.timingFunctions = @[
        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],
        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]
    ];
    [layer addAnimation:pop forKey:@"ios26pop"];

    // 2) 玻璃高光斜扫（Liquid Glass 特征）
    if (layer.bounds.size.width >= 24 && layer.bounds.size.height >= 24) {
        CAGradientLayer *shine = [CAGradientLayer layer];
        shine.frame = layer.bounds;
        shine.colors = @[
            (id)[UIColor colorWithWhite:1.0 alpha:0.0].CGColor,
            (id)[UIColor colorWithWhite:1.0 alpha:0.45].CGColor,
            (id)[UIColor colorWithWhite:1.0 alpha:0.0].CGColor
        ];
        shine.startPoint = CGPointMake(0.0, 0.15);
        shine.endPoint   = CGPointMake(1.0, 1.15);
        shine.locations  = @[@0.0, @0.5, @1.0];
        shine.opacity    = 0.0;
        [layer addSublayer:shine];

        CABasicAnimation *sweep = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
        sweep.fromValue = @(-layer.bounds.size.width * 1.6);
        sweep.toValue   = @(layer.bounds.size.width * 1.6);
        sweep.duration  = 0.55;
        sweep.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        [shine addAnimation:sweep forKey:@"ios26sweep"];

        CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fade.fromValue = @0.0;
        fade.toValue   = @1.0;
        fade.autoreverses = YES;
        fade.duration  = 0.55;
        [shine addAnimation:fade forKey:@"ios26shineFade"];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [shine removeFromSuperlayer];
        });
    }
}

#pragma mark - 锁屏：玻璃浮起

void IOS27AnimateLockScreenIn(UIView *view) {
    view.alpha = 0.5;
    view.transform = CGAffineTransformMakeScale(1.045, 1.045);
    [UIView animateWithDuration:0.52 delay:0
         usingSpringWithDamping:0.86 initialSpringVelocity:0.22
                        options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        view.transform = CGAffineTransformIdentity;
        view.alpha = 1.0;
    } completion:nil];
}

#pragma mark - 通知横幅：玻璃滑入 + 轻微缩放

void IOS27AnimateBannerIn(UIView *view) {
    CATransform3D t = CATransform3DIdentity;
    t = CATransform3DTranslate(t, 0, -40, 0);
    t = CATransform3DScale(t, 0.93, 0.93, 1.0);
    view.layer.transform = t;
    view.alpha = 0.0;
    [UIView animateWithDuration:0.55 delay:0
         usingSpringWithDamping:0.80 initialSpringVelocity:0.28
                        options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        view.layer.transform = CATransform3DIdentity;
        view.alpha = 1.0;
    } completion:nil];
}

#pragma mark - 应用开合 zoom 转场

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
    ov.backgroundColor = [UIColor clearColor];
    ov.userInteractionEnabled = NO;
    ov.layer.masksToBounds = YES;
    UIImage *img = [self snapshotOfView:host];
    if (img) {
        UIImageView *iv = [[UIImageView alloc] initWithFrame:host.bounds];
        iv.image = img;
        iv.contentMode = UIViewContentModeScaleAspectFill;
        [ov addSubview:iv];
    }
    return ov;
}

// App 即将打开：整个桌面画面缩向中心 + 圆角逐渐变大 + 淡出（iOS 26 的 zoom-out 观感）
- (void)appWillOpen {
    if (!IOS27Enabled() || !IOS27AppTransition()) return;
    _appIsOpen = YES;

    UIView *host = [self topWindowView];
    if (!host) return;
    if (_overlay) { [_overlay removeFromSuperview]; _overlay = nil; }

    UIView *ov = [self makeOverlayOnHost:host];
    ov.alpha = 1.0;
    ov.transform = CGAffineTransformIdentity;
    ov.layer.cornerRadius = 0.0;
    [host addSubview:ov];
    _overlay = ov;

    CABasicAnimation *cr = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
    cr.fromValue = @0.0;
    cr.toValue   = @34.0;
    cr.duration  = 0.5;
    cr.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    ov.layer.cornerRadius = 34.0;
    [ov.layer addAnimation:cr forKey:@"ios26cr"];

    [UIView animateWithDuration:0.5 delay:0
         usingSpringWithDamping:0.9 initialSpringVelocity:0.08
                        options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        ov.transform = CGAffineTransformMakeScale(0.20, 0.20);
        ov.alpha = 0.0;
    } completion:^(BOOL finished) {
        [ov.layer removeAllAnimations];
        [ov removeFromSuperview];
        if (_overlay == ov) _overlay = nil;
    }];
}

// 回到桌面：玻璃画面从中心一点放大 + 圆角收小 + 渐显（zoom-in 观感）
- (void)appDidReturnHome {
    if (!_appIsOpen) return;
    _appIsOpen = NO;
    if (!IOS27Enabled() || !IOS27AppTransition()) return;

    UIView *host = [self topWindowView];
    if (!host) return;
    if (_overlay) { [_overlay removeFromSuperview]; _overlay = nil; }

    UIView *ov = [self makeOverlayOnHost:host];
    ov.alpha = 0.0;
    ov.transform = CGAffineTransformMakeScale(0.20, 0.20);
    ov.layer.cornerRadius = 34.0;
    [host addSubview:ov];
    _overlay = ov;

    CABasicAnimation *cr = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
    cr.fromValue = @34.0;
    cr.toValue   = @0.0;
    cr.duration  = 0.52;
    cr.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    ov.layer.cornerRadius = 0.0;
    [ov.layer addAnimation:cr forKey:@"ios26cr"];

    [UIView animateWithDuration:0.52 delay:0
         usingSpringWithDamping:0.88 initialSpringVelocity:0.12
                        options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        ov.transform = CGAffineTransformIdentity;
        ov.alpha = 1.0;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.16 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.22 delay:0
                                  options:UIViewAnimationOptionCurveEaseOut
                             animations:^{ ov.alpha = 0.0; }
                             completion:^(BOOL f2) {
                [ov removeFromSuperview];
                if (_overlay == ov) _overlay = nil;
            }];
        });
    }];
}

@end

#pragma mark - 灵动岛：半透明玻璃胶囊 + 高光

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
    // Liquid Glass：半透明深色底 + 细白边框高光 + 内层渐变
    p.backgroundColor = [UIColor colorWithWhite:0.06 alpha:0.90];
    p.layer.cornerRadius = ph/2;
    p.layer.masksToBounds = YES;
    p.layer.borderWidth = 0.8;
    p.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.16].CGColor;

    CAGradientLayer *gloss = [CAGradientLayer layer];
    gloss.frame = p.bounds;
    gloss.colors = @[
        (id)[UIColor colorWithWhite:1.0 alpha:0.20].CGColor,
        (id)[UIColor colorWithWhite:1.0 alpha:0.02].CGColor
    ];
    gloss.startPoint = CGPointMake(0.5, 0.0);
    gloss.endPoint   = CGPointMake(0.5, 0.6);
    gloss.cornerRadius = ph/2;
    [p.layer addSublayer:gloss];

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
    _pill.transform = CGAffineTransformMakeScale(0.6, 0.6);

    CGRect target = _pill.frame;
    target.size.width = 216;

    void (^expand)(void) = ^{
        _pill.frame = target;
        _pill.transform = CGAffineTransformIdentity;
    };
    void (^complete)(BOOL) = ^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.4 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            if (_visible) [self dismissAnimated:YES];
        });
    };

    if (animated) {
        [UIView animateWithDuration:0.56 delay:0
             usingSpringWithDamping:0.72 initialSpringVelocity:0.38
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
        _pill.transform = CGAffineTransformMakeScale(0.4, 0.4);
        _pill.alpha = 0.0;
    };
    void (^complete)(BOOL) = ^(BOOL finished) {
        _pill.hidden = YES;
        _pill.transform = CGAffineTransformIdentity;
    };
    if (animated) {
        [UIView animateWithDuration:0.36 delay:0
             usingSpringWithDamping:0.94 initialSpringVelocity:0.12
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
