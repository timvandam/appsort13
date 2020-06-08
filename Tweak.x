#import <libactivator/libactivator.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AppList/AppList.h>
#include <RemoteLog.h>

@interface UIImage (AppSort13)
-(float)hue;
+(float)computeHueR:(float)r G:(float)G B:(float)B;
@end

@implementation UIImage (AppSort13)
-(float)hue {
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

	RLog(@"Hex = %02x%02x%02x",
		rgba[0],
		rgba[1],
		rgba[2]);

	float r = (float) rgba[0] / 255;
	float g = (float) rgba[1] / 255;
	float b = (float) rgba[2] / 255;

	RLog(@"%f %f %f", r, g, b);
	RLog(@"%d %d %d", rgba[0], rgba[1], rgba[2]);

	return [UIImage computeHueR:r G:g B:b];
}
+(float)computeHueR:(float)R G:(float)G B:(float)B {
	if (R >= G) {
		if (G >= B) return 60 * (G-B)/(R-B);
		else if (B > G) return 60 * (6 - (B-G)/(R-G));
	}
	if (G > R) {
		if (R >= B) return 60 * (2 - (R-B)/(G-B));
		else if (G >= B) return 60 * (2 + (B-R)/(G-R));
	}
	if (B > G) {
		if (G > R) return 60 * (4 - (G-R)/(B-R));
		else if (R >= G) return 60 * (4 + (R-G)/(B-G));
	}
	return 0;
}
@end

@interface SBIcon
-(id)applicationBundleID;
-(NSString *)displayName;
-(BOOL)isFolderIcon;
@property (copy,readonly) NSString * description;
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
@property (getter=_currentFolderController,nonatomic,readonly) SBFolderController * currentFolderController;
@end

%hook SBIconController
%new
-(void)sort {
	// TODO: Dictionary of all icons, then sort and re-place them
	// Each icon is either an application or a folder (or an internet shortcut ig)
	for (SBIconListView* listView in [self._currentFolderController iconListViews]) {
		RLog(@"There are %d icons", [[listView icons] count]);
		for (SBIcon* icon in [listView icons]) {
			float hue = 0;
			if ([icon isFolderIcon]) {
				RLog(@"Folder = %@", [icon displayName]); // folders have an -(SBFolder)folder
			} else {
				RLog(@"Icon = %@", [icon displayName]);
				SBIconView* iconView = [listView iconViewForIcon: icon];
				UIImage* image  = iconView.iconImageSnapshot;
				hue = [image hue];
			}
			RLog(@"Description = %@", [icon description]);
			RLog(@"Hue = %f", hue);
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
