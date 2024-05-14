#import "MSHFPrefsListController.h"

@implementation MSHFPrefsListController
- (instancetype)init {
    self = [super init];

    if (self) {
        UIBarButtonItem *respringItem =
        [[UIBarButtonItem alloc] initWithTitle:@"Apply" style:UIBarButtonItemStylePlain target:self action:@selector(respring:)];
        self.navigationItem.rightBarButtonItem = respringItem;

		UINavigationBarAppearance *scrollEdgeAppearance = [[UINavigationBarAppearance alloc] init];
		[scrollEdgeAppearance configureWithOpaqueBackground];
		self.navigationItem.scrollEdgeAppearance = scrollEdgeAppearance;

		self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,200,200)];

		#ifdef THEOS_PACKAGE_INSTALL_PREFIX
		UIImageView *headerImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"/var/jb/Library/PreferenceBundles/MitsuhaSixPrefs.bundle/Banner.png"]];
		#else
		UIImageView *headerImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/MitsuhaSixPrefs.bundle/Banner.png"]];
		#endif
        headerImageView.contentMode = UIViewContentModeScaleAspectFill;
        headerImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.headerView addSubview:headerImageView];

		UILabel *titleLabel = [self createLabelWithFontSize:36 weight:UIFontWeightBold];
        titleLabel.text = @"Mitsuha Six";

        UILabel *versionLabel = [self createLabelWithFontSize:18 weight:UIFontWeightRegular];
        versionLabel.text = @"Version 1.0.0";

        UILabel *authorLabel = [self createLabelWithFontSize:12 weight:UIFontWeightLight];
        authorLabel.text = @"By Ryan Nair";

        [headerImageView addSubview:titleLabel];
        [headerImageView addSubview:versionLabel];
        [headerImageView addSubview:authorLabel];

		[NSLayoutConstraint activateConstraints:@[
            [headerImageView.topAnchor constraintEqualToAnchor:self.headerView.topAnchor],
            [headerImageView.leadingAnchor constraintEqualToAnchor:self.headerView.leadingAnchor],
            [headerImageView.trailingAnchor constraintEqualToAnchor:self.headerView.trailingAnchor],
            [headerImageView.bottomAnchor constraintEqualToAnchor:self.headerView.bottomAnchor],
			[titleLabel.centerXAnchor constraintEqualToAnchor:headerImageView.centerXAnchor],
			[titleLabel.topAnchor constraintEqualToAnchor:headerImageView.topAnchor constant:25],
			[versionLabel.centerXAnchor constraintEqualToAnchor:headerImageView.centerXAnchor],
			[versionLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:10],
			[authorLabel.centerXAnchor constraintEqualToAnchor:headerImageView.centerXAnchor],
       		[authorLabel.topAnchor constraintEqualToAnchor:versionLabel.bottomAnchor constant:5]
        ]];

		// Work in progress
		// MSHFJelloView *waveView = [[MSHFJelloView alloc] initWithFrame:headerImageView.bounds audioSource:nil];
		// [waveView.displayLink setPaused:false];
		// dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		// 	char bufferData[1024];
		// 	while (true) {
		// 		for (int i = 0; i < 1024; i++) {
		// 			bufferData[i] = (float)arc4random_uniform(2001) / 1000.0f;
		// 		}
		// 		[waveView updateBuffer:(float *)bufferData withLength:1024];
		// 		usleep(10000);
		// 	}
		// });
		// [headerImageView addSubview:waveView];
    }

    return self;
}

- (UILabel *)createLabelWithFontSize:(CGFloat)fontSize weight:(UIFontWeight)weight {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:fontSize weight:weight];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    return label;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    tableView.tableHeaderView = self.headerView;
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (NSArray *)specifiers {
    if(!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Prefs" target:self];
    }
    return _specifiers;
}

- (void)loadFromSpecifier:(PSSpecifier *)specifier {
    _specifiers = [self loadSpecifiersFromPlistName:@"Prefs" target:self];

    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *directory = MSHFAppSpecifiersDirectory;
    NSArray *appPlists = [manager contentsOfDirectoryAtPath:directory error:nil];
    NSMutableArray *appSpecifiers = [NSMutableArray new];
    
    for (NSString *filename in appPlists) {
        NSString *path = [directory stringByAppendingPathComponent:filename];
        NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:path];

        if (plist) {
            NSString *name = plist[@"name"] ?: [filename stringByReplacingOccurrencesOfString:@".plist" withString:@""];
            NSString *title = plist[@"title"] ?: name;
            PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:title target:nil set:nil get:nil detail:[MSHFAppPrefsListController class] cell:2 edit:nil];
            [spec setProperty:name forKey:@"MSHFApp"];
            
            if (plist[@"important"]) {
                [appSpecifiers insertObject:spec atIndex:0];
            } else {
				[appSpecifiers addObject:spec];
            }
        }
    }

    for (PSSpecifier *spec in [appSpecifiers reverseObjectEnumerator]) {
        [self insertSpecifier:spec afterSpecifierID:@"apps"];
    }

    [self setTitle:@"Mitsuha 6"];
    [self.navigationItem setTitle:@"Mitsuha 6"];
}

- (void)setSpecifier:(PSSpecifier *)specifier {
	[self loadFromSpecifier:specifier];
	[super setSpecifier:specifier];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

    self.table.separatorColor = [UIColor colorWithWhite:0 alpha:0];

    UIWindow *keyWindow = [[[UIApplication sharedApplication] windows] firstObject];
        
	keyWindow.tintColor = [UIColor colorWithRed:238.0f / 255.0f
											green:100.0f / 255.0f
											blue:92.0f / 255.0f
											alpha:1]; 

    [UISwitch appearanceWhenContainedInInstancesOfClasses:@[self.class]].onTintColor = [UIColor colorWithRed:238.0f / 255.0f
                                            green:100.0f / 255.0f
                                            blue:92.0f / 255.0f
                                            alpha:1]; 
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];

	UIWindow *keyWindow = [[[UIApplication sharedApplication] windows] firstObject];
	keyWindow.tintColor = nil;
}

- (void)resetPrefs:(id)sender {	
	NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.ryannair05.mitsuhasix"];
	[defaults removePersistentDomainForName:@"com.ryannair05.mitsuhasix"];
	[defaults synchronize];

    [self respring:sender];
}

- (bool)shouldReloadSpecifiersOnResume {
    return NO;
}

- (void)respring:(id)sender {
	pid_t pid;
    const char* args[] = {"killall", "backboardd", NULL};
	#ifdef THEOS_PACKAGE_INSTALL_PREFIX
	posix_spawn(&pid, "/var/jb/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
	#else
	posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
	#endif
}

- (void)restartmsd:(id)sender {
	pid_t pid;
    const char* args[] = {"killall", "mediaserverd", NULL};
	#ifdef THEOS_PACKAGE_INSTALL_PREFIX
	posix_spawn(&pid, "/var/jb/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
	#else
	posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
	#endif
}
@end

@implementation MSHFTintedTableCell

- (void)tintColorDidChange {
	[super tintColorDidChange];

	self.textLabel.textColor = [UIColor colorWithRed: 0.93 green: 0.39 blue: 0.36 alpha: 1.00];
	self.textLabel.highlightedTextColor = [UIColor colorWithRed: 0.93 green: 0.39 blue: 0.36 alpha: 1.00];
}

- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
	[super refreshCellContentsWithSpecifier:specifier];

	self.textLabel.textColor = [UIColor colorWithRed: 0.93 green: 0.39 blue: 0.36 alpha: 1.00];
	self.textLabel.highlightedTextColor = [UIColor colorWithRed: 0.93 green: 0.39 blue: 0.36 alpha: 1.00];
}

@end

@implementation MSHFLinkTableCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier specifier:specifier];

	if (self) {
		_avatarURL = [NSURL URLWithString:specifier.properties[@"avatarURL"]];

		self.selectionStyle = UITableViewCellSelectionStyleBlue;

		#ifdef THEOS_PACKAGE_INSTALL_PREFIX
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"/var/jb/Library/PreferenceBundles/MitsuhaSixPrefs.bundle/safari.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
		#else
		UIImageView *imageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"/Library/PreferenceBundles/MitsuhaSixPrefs.bundle/safari.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
		#endif
		imageView.tintColor = [UIColor systemGray3Color];
		self.accessoryView = imageView;

		self.detailTextLabel.text = specifier.properties[@"subtitle"] ?: @"";
		self.detailTextLabel.textColor = [UIColor secondaryLabelColor];

		self.specifier = specifier;
		if (self.shouldShowAvatar) {
			NSLog(@"avatar? %i %@", self.shouldShowAvatar, self.specifier.properties);
			CGFloat size = 29.f;

			UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, [UIScreen mainScreen].scale);
			specifier.properties[@"iconImage"] = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();

			avatarView = [[UIView alloc] initWithFrame:self.imageView.bounds];
			avatarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			avatarView.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1];
			avatarView.userInteractionEnabled = NO;
			avatarView.clipsToBounds = YES;
			[self.imageView addSubview:avatarView];

			avatarImageView = [[UIImageView alloc] initWithFrame:avatarView.bounds];
			avatarImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			avatarImageView.alpha = 0;
			avatarImageView.userInteractionEnabled = NO;
			avatarImageView.layer.minificationFilter = kCAFilterTrilinear;
			[avatarView addSubview:avatarImageView];

			[self loadAvatarIfNeeded];

			avatarView.layer.cornerRadius = size / 2;
		}
	}

	return self;
}


#pragma mark - Avatar

- (UIImage *)avatarImage {
	return avatarImageView.image;
}

- (void)setAvatarImage:(UIImage *)avatarImage {
	avatarImageView.image = avatarImage;

	if (avatarImageView.alpha == 0) {
		[UIView animateWithDuration:0.15 animations:^{
			avatarImageView.alpha = 1;
		}];
	}
}

- (BOOL)shouldShowAvatar {
	return self.specifier.properties[@"showAvatar"] || self.specifier.properties[@"avatarURL"] != nil;
}

- (void)loadAvatarIfNeeded {
	if (_avatarURL == nil || self.avatarImage != nil) {
		return;
	}
}
- (void)setSelected:(BOOL)arg1 animated:(BOOL)arg2
{
    if (arg1) [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.specifier.properties[@"url"]] options:@{} completionHandler:nil];
}
@end

@implementation MSHFTwitterCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];

    if (self) {
        UIImageView *imageView = (UIImageView *)self.accessoryView;
		#ifdef THEOS_PACKAGE_INSTALL_PREFIX
        imageView.image = [[UIImage imageNamed:@"/var/jb/Library/PreferenceBundles/MitsuhaSixPrefs.bundle/twitter.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		#else
		imageView.image = [[UIImage imageNamed:@"/Library/PreferenceBundles/MitsuhaSixPrefs.bundle/twitter.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		#endif
        
        [imageView sizeToFit];

        _user = [specifier.properties[@"user"] copy];
        NSAssert(_user, @"User name not provided");

        specifier.properties[@"url"] = [@"https://mobile.twitter.com/" stringByAppendingString:_user];

        self.detailTextLabel.text = [@"@" stringByAppendingString:_user];

        [self loadAvatarIfNeeded];
    }

    return self;
}

#pragma mark - Avatar

- (BOOL)shouldShowAvatar {
	return YES;
}

- (void)loadAvatarIfNeeded {
	if (!_user || self.avatarImage) {
		return;
	}

	[UIImage _loadImageFromURL:[NSURL URLWithString:@"https://pbs.twimg.com/profile_images/1161080936836018176/4GUKuGlb_200x200.jpg"] completionHandler:^(UIImage *image) {
		dispatch_async(dispatch_get_main_queue(), ^{
			self.avatarImage = image;
		});
	}];
}

@end