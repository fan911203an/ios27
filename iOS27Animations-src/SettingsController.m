//
//  SettingsController.m — 设置面板控制器
//  用 PSSpecifier 对象手动构造 specifiers（PSListController 要求的格式），
//  绕开 plist 查找/解析与 NSDictionary 无法渲染的问题，确保设置页正常显示
//
#import <UIKit/UIKit.h>

// Preferences 框架头缺失，手动声明所需类型与类
typedef NS_ENUM(NSInteger, PSCellType) {
    PSGroupCell  = 0,
    PSSwitchCell = 6
};

@interface PSSpecifier : NSObject
+ (id)groupSpecifierWithName:(NSString *)name;
+ (id)preferenceSpecifierNamed:(NSString *)name
                        target:(id)target
                           set:(SEL)set
                           get:(SEL)get
                        detail:(Class)detail
                          cell:(PSCellType)cell
                          edit:(Class)edit;
- (void)setProperty:(id)value forKey:(NSString *)key;
@end

@interface PSListController : UIViewController
- (id)specifiers;
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)spec;
- (id)readPreferenceValue:(PSSpecifier *)spec;
@end

@interface iOS27SettingsController : PSListController {
    NSArray *_ios27Specifiers;
}
@end

@implementation iOS27SettingsController

- (PSSpecifier *)_switchSpecifierWithLabel:(NSString *)label key:(NSString *)key {
    PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:label
        target:self
        set:@selector(setPreferenceValue:specifier:)
        get:@selector(readPreferenceValue:)
        detail:nil
        cell:PSSwitchCell
        edit:nil];
    [spec setProperty:@"com.ios27.animations" forKey:@"defaults"];
    [spec setProperty:key forKey:@"key"];
    [spec setProperty:@YES forKey:@"default"];
    [spec setProperty:@"com.ios27.animations/prefs.changed" forKey:@"PostNotification"];
    return spec;
}

- (id)specifiers {
    if (_ios27Specifiers == nil) {
        NSMutableArray *specs = [NSMutableArray array];

        [specs addObject:[PSSpecifier groupSpecifierWithName:@"iOS 27 动画"]];
        [specs addObject:[self _switchSpecifierWithLabel:@"总开关" key:@"enabled"]];

        [specs addObject:[PSSpecifier groupSpecifierWithName:@"效果"]];
        [specs addObject:[self _switchSpecifierWithLabel:@"应用开合转场" key:@"appTransition"]];
        [specs addObject:[self _switchSpecifierWithLabel:@"灵动岛 / 状态栏" key:@"island"]];
        [specs addObject:[self _switchSpecifierWithLabel:@"锁屏与通知" key:@"lockscreen"]];
        [specs addObject:[self _switchSpecifierWithLabel:@"桌面与图标" key:@"home"]];

        _ios27Specifiers = specs;
    }
    return _ios27Specifiers;
}

@end
