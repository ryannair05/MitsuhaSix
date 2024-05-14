#import "MSHFAppPrefsListController.h"

@implementation MSHFAppPrefsListController

- (NSArray *)specifiers {
    return _specifiers;
}

- (void)setSpecifier:(PSSpecifier *)specifier {
    [super setSpecifier:specifier];

    self.appName = [specifier propertyForKey:@"MSHFApp"];
    if (!self.appName) return;
    NSString *prefix = [@"MSHF" stringByAppendingString:self.appName];
    NSString *title = [specifier name];
    savedSpecifiers = [[NSMutableDictionary alloc] init];

    _specifiers = [self loadSpecifiersFromPlistName:@"App" target:self];

    for (PSSpecifier *specifier in _specifiers) {
        NSString *key = [specifier propertyForKey:@"key"];
        if (key) {
            [specifier setProperty:[prefix stringByAppendingString:key] forKey:@"key"];
        }

        if ([specifier.name isEqualToString:@"%APP_NAME%"]) {
            specifier.name = title;
        }

        else if ([specifier propertyForKey:@"id"]) {
			[savedSpecifiers setObject:specifier forKey:[specifier propertyForKey:@"id"]];
		}
    }

    NSArray *extra = [self loadSpecifiersFromPlistName:[NSString stringWithFormat:@"Apps/%@", self.appName] target:self];
    if (extra) {
        for (PSSpecifier *specifier in extra) {
            [self insertSpecifier:specifier afterSpecifierID:@"otherSettings"];
        }
    }

    [self setTitle:title];
}

-(void)removeBarText:(bool)animated {
    NSArray *barSpecifiers = @[
        savedSpecifiers[@"BarText"], 
        savedSpecifiers[@"BarSpacingText"], 
        savedSpecifiers[@"BarSpacing"], 
        savedSpecifiers[@"BarRadiusText"], 
        savedSpecifiers[@"BarRadius"]
    ];
    [self removeContiguousSpecifiers:barSpecifiers animated:animated];
}

-(void)removeLineText:(bool)animated {
    NSArray *lineSpecifiers = @[
        savedSpecifiers[@"LineText"], 
        savedSpecifiers[@"LineThicknessText"], 
        savedSpecifiers[@"LineThickness"]
    ];
    [self removeContiguousSpecifiers:lineSpecifiers animated:animated];
}

-(void)viewDidLoad {
    [super viewDidLoad];

    MSHFConfig *config = [[MSHFConfig alloc] initWithAppName:self.appName];

    if (config.style != 1) {
        [self removeBarText:NO];
        if (config.style != 2) {
            [self removeLineText:NO];
        }
    } else {
        [self removeLineText:NO];
    }

    if (config.colorMode == 0) { 
        [self removeContiguousSpecifiers:@[savedSpecifiers[@"WaveColor"]] animated:NO];
    }
    else if (config.colorMode == 1) {
        [self removeContiguousSpecifiers:@[savedSpecifiers[@"AlphaText"], savedSpecifiers[@"DynamicColorAlpha"], savedSpecifiers[@"WaveColor"]] animated:NO];
    }
    else { 
        [self removeContiguousSpecifiers:@[savedSpecifiers[@"AlphaText"], savedSpecifiers[@"DynamicColorAlpha"]] animated:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
    self.table.separatorColor = [UIColor colorWithWhite:0 alpha:0];

    UIWindow *keyWindow = [[[UIApplication sharedApplication] windows] firstObject];

    if ([keyWindow respondsToSelector:@selector(setTintColor:)]) {
        keyWindow.tintColor = [UIColor colorWithRed:238.0f / 255.0f
                                                green:100.0f / 255.0f
                                                blue:92.0f / 255.0f
                                                alpha:1]; 
	}

    [UISwitch appearanceWhenContainedInInstancesOfClasses:@[self.class]].onTintColor = [UIColor colorWithRed:238.0f / 255.0f
                                            green:100.0f / 255.0f
                                            blue:92.0f / 255.0f
                                            alpha:1]; 

    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    [super setPreferenceValue:value specifier:specifier];

    if (([self.appName isEqualToString:@"HomeScreen"] || [self.appName isEqualToString:@"LockScreen"] || [self.appName isEqualToString:@"Springboard"]))  {
        
        CFStringRef notificationName = (__bridge CFStringRef) specifier.properties[@"PostNotification"];
        if (notificationName) {
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, NULL, NULL, YES);
        }
    }
    else {
        #ifdef THEOS_PACKAGE_INSTALL_PREFIX
        NSString *path = [NSString stringWithFormat:@"/var/jb/var/mobile/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
        #else
		NSString *path = [NSString stringWithFormat:@"/var/mobile/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
		#endif
        
        NSMutableDictionary *settings = [NSMutableDictionary dictionary];
        [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];

        [settings setObject:value forKey:specifier.properties[@"key"]];
        [settings writeToFile:path atomically:YES];
    }

    NSString const *key = [specifier propertyForKey:@"key"];

    if ([key containsString:@"Style"]){
        if ([value integerValue] == 1) {
            if (![self containsSpecifier:savedSpecifiers[@"BarText"]]) {
                NSArray *barSpecifiers = @[
                    savedSpecifiers[@"BarText"], 
                    savedSpecifiers[@"BarSpacingText"], 
                    savedSpecifiers[@"BarSpacing"], 
                    savedSpecifiers[@"BarRadiusText"], 
                    savedSpecifiers[@"BarRadius"]
                ];

                [self insertContiguousSpecifiers:barSpecifiers afterSpecifierID:@"NumberOfPoints" animated:YES];
                if ([self containsSpecifier:savedSpecifiers[@"LineText"]]) {
                    [self removeLineText:YES];
                }
            }
        }
        else if ([value integerValue] == 2) {

            if (![self containsSpecifier:savedSpecifiers[@"LineText"]]) {

                if ([self containsSpecifier:savedSpecifiers[@"BarText"]]) {
                    [self removeBarText:YES];
                }

                [self insertContiguousSpecifiers:@[savedSpecifiers[@"LineText"], savedSpecifiers[@"LineThicknessText"], savedSpecifiers[@"LineThickness"]] afterSpecifierID:@"NumberOfPoints" animated:YES];
            }
        }
        else if ([self containsSpecifier:savedSpecifiers[@"BarText"]]) {
            [self removeBarText:YES];
        }
        else if ([self containsSpecifier:savedSpecifiers[@"LineText"]]) {
            [self removeLineText:YES];
        }
    }
    else if ([key containsString:@"ColorMode"]) {
        if ([value integerValue] == 0) { 
            if ([self containsSpecifier:savedSpecifiers[@"WaveColor"]]) {
                [self removeContiguousSpecifiers:@[savedSpecifiers[@"WaveColor"]] animated:YES];
            }
            if (![self containsSpecifier:savedSpecifiers[@"AlphaText"]]) {
                [self insertContiguousSpecifiers:@[savedSpecifiers[@"AlphaText"], savedSpecifiers[@"DynamicColorAlpha"]] afterSpecifierID:@"ColorMode" animated:YES];
            }
        }
        else if ([value integerValue] == 1) {
            if ([self containsSpecifier:savedSpecifiers[@"AlphaText"]]) {
                [self removeContiguousSpecifiers:@[savedSpecifiers[@"AlphaText"], savedSpecifiers[@"DynamicColorAlpha"]] animated:YES];
            }
            else if ([self containsSpecifier:savedSpecifiers[@"WaveColor"]]) {
                [self removeContiguousSpecifiers:@[savedSpecifiers[@"WaveColor"]] animated:YES];
            }
        }
        else { 
            if ([self containsSpecifier:savedSpecifiers[@"AlphaText"]]) {
                [self removeContiguousSpecifiers:@[savedSpecifiers[@"AlphaText"], savedSpecifiers[@"DynamicColorAlpha"]] animated:YES];
            }
            if (![self containsSpecifier:savedSpecifiers[@"WaveColor"]]) {
                [self insertContiguousSpecifiers:@[savedSpecifiers[@"WaveColor"]] afterSpecifierID:@"ColorMode" animated:YES];
            }
        }
    }

}

- (bool)shouldReloadSpecifiersOnResume {
    return NO;
}
@end
