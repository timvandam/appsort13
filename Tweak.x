#import <libactivator/libactivator.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AppList/AppList.h>
#include <RemoteLog.h>

@interface UIImage (AppSort13)
-(NSString*)hue;
@end

@implementation UIImage (AppSort13)
-(NSString*)hue {
	CIImage* img = [[CIImage alloc] initWithImage: self];
	CIVector* extentVector = [CIVector
		vectorWithX:img.extent.origin.x
		Y:img.extent.origin.y
		Z:img.extent.size.width
		W:img.extent.size.height];

	CIFilter* filter = [CIFilter
		filterWithName:@"CIAreaAverage"
		withInputParameters: @{
			@"inputImage": img,
			@"inputExtent": extentVector
		}];
	
	CIImage* outputImg = filter.outputImage;

	uint8_t rgba[] = { 0, 0, 0, 0 };
	CIContext* context = [CIContext contextWithOptions:@{
		@"kCIContextWorkingColorSpace": [NSNull null]
	}];
	struct CGRect bounds;
	bounds.origin.x = 0;
	bounds.origin.y = 0;
	bounds.size.width = 1;
	bounds.size.height = 1;
	[context render:outputImg
		toBitmap:&rgba
		rowBytes:4
		bounds:bounds
		format:kCIFormatRGBA8
		colorSpace: nil];

	RLog(@"%02x%02x%02x",
		rgba[0],
		rgba[1],
		rgba[2]);


	return @"red"; // TODO: Return hue
}
@end

@interface SBIcon
-(id)applicationBundleID;
-(NSString *)displayName;
@end

@interface SBIconListView
@property (nonatomic,copy,readonly) NSArray* icons;

-(id)iconViewForIcon:(id)arg1;
@end

@interface SBFolderController
@property (nonatomic,copy,readonly) NSArray* iconListViews; // array of SBIconListView
@end

@interface SBRootFolderController : SBFolderController
@end

@interface SBIconView
@property (nonatomic,readonly) UIImage* iconImageSnapshot;
@end

@interface SBIconController
+(id)sharedInstance;
-(void)sort;
@property (getter=_rootFolderController,nonatomic,readonly) SBRootFolderController* rootFolderController;
@end

%hook SBIconController
%new
-(void)sort {
	for (SBIconListView* listView in [self._rootFolderController iconListViews]) {
		for (SBIcon* icon in [listView icons]) {
			RLog(@"Icon = %@", [icon displayName]);
			if ([icon applicationBundleID] == nil) return;
			SBIconView* iconView = [listView iconViewForIcon: icon];
			UIImage* image  = iconView.iconImageSnapshot;
			RLog(@"Icon = %@", [icon displayName]);
			[image hue];
		}
	}
}
%end





@interface AlertWindow : UIWindow
+(BOOL)alertShowing;
-(void)showAlert;
-(void)createAlert;

@property UIViewController* uv;
@property UIAlertController* alert;
@end

@implementation AlertWindow : UIWindow
static BOOL alertShowing = NO;
+(BOOL)alertShowing {
	return alertShowing;
}
-(instancetype)init {
	self = [super init];
	self.frame = [[UIScreen mainScreen] bounds];

	[self createAlert];

	self.uv = [[UIViewController alloc] init];

	self.windowLevel = UIWindowLevelNormal; // Alert is part of the springboard, so don't put it over other stuff
	self.rootViewController = self.uv;
	[self setBackgroundColor:[UIColor clearColor]];

	return self;
}
-(void)createAlert {
	self.alert = [UIAlertController
		alertControllerWithTitle:@"AppSort13"
		message:@"Choose a way to sort your apps below\nThere is no going back!"
		preferredStyle:UIAlertControllerStyleActionSheet];

	UIAlertAction* hue = [UIAlertAction
		actionWithTitle:@"Hue"
		style:UIAlertActionStyleDestructive
		handler:^(UIAlertAction* action) {
			RLog(@"hue");
			[[%c(SBIconController) sharedInstance] sort];
			alertShowing = NO;
		}];

	UIAlertAction* alphabetical = [UIAlertAction
		actionWithTitle:@"Alphabetical"
		style:UIAlertActionStyleDestructive
		handler:^(UIAlertAction* action) {
			RLog(@"alphabetical");
			alertShowing = NO;
		}];

	UIAlertAction* cancel = [UIAlertAction
		actionWithTitle:@"Cancel"
		style:UIAlertActionStyleCancel
		handler:^(UIAlertAction* action) {
			RLog(@"cancel");
			alertShowing = NO;
		}];

	[self.alert addAction:hue];
	[self.alert addAction:alphabetical];
	[self.alert addAction:cancel];
}
-(void)showAlert {
	alertShowing = YES;
	[self makeKeyAndVisible];
	[self.uv presentViewController:self.alert animated:YES completion:nil];
}
@end


@interface AppSort13 : NSObject <LAListener>
-(void)activator:(LAActivator*)activator receiveEvent:(LAEvent*)event;
-(void)activator:(LAActivator*)activator abortEvent:(LAEvent*)event;
@end

@implementation AppSort13
-(void)activator:(LAActivator*)activator receiveEvent:(LAEvent*)event {
	if (AlertWindow.alertShowing) return; // only show if not already showing

	AudioServicesPlaySystemSound(1519); // light haptic feedback
	RLog(@"menu will now pop up");

	/*NSDictionary* apps = [[ALApplicationList sharedApplicationList] applications];
	for (NSString* app in apps) {
		UIImage* icon = [[ALApplicationList sharedApplicationList] iconOfSize:ALApplicationIconSizeLarge forDisplayIdentifier:app];
		if (icon == nil) RLog(@"App %@ has no icon, skip it", apps[app]);
		else RLog(@"App %@ has an icon. Now implement getting the avg. color!", apps[app]);
	}*/

	[[[AlertWindow alloc] init] showAlert];

    [event setHandled: YES];
}

-(void)activator:(LAActivator*)activator abortEvent:(LAEvent*)event {
    [event setHandled: YES];
}
@end


%ctor {
	[LASharedActivator registerListener:[[AppSort13 alloc] init] forName:@"nl.timvd.appsort13"];	
}
