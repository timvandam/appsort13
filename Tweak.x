#import <libactivator/libactivator.h>
#import <AudioToolbox/AudioToolbox.h>
#include <RemoteLog.h>

#define MAX3(a, b, c) MAX(MAX(a, b), c)
#define MIN3(a, b, c) MIN(MIN(a, b), c)

@interface UIImage (AppSort13)
-(uint)hue;
+(uint)computeR:(uint8_t)R G:(uint8_t)G B:(uint8_t)B;
@end

@implementation UIImage (AppSort13)
-(uint)hue {
	CIImage* img = [[CIImage alloc] initWithImage: self];
	CIVector* extentVector = [CIVector
		vectorWithX:img.extent.origin.x
		Y:img.extent.origin.y
		Z:img.extent.size.width
		W:img.extent.size.height];

	CIFilter* filter = [CIFilter
		filterWithName:@"CIAreaMaximumAlpha" // CIAreaAverage CIAreaMaximum
		withInputParameters: @{
			@"inputImage": img,
			@"inputExtent": extentVector
		}];
	
	CIImage* outputImg = filter.outputImage;

	uint8_t rgba[4] = { 0, 0, 0, 0 };
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

	// RLog(@"Hex = %02x%02x%02x",
		// rgba[0],
		// rgba[1],
		// rgba[2]);

	uint r = (uint) rgba[0];
	uint g = (uint) rgba[1];
	uint b = (uint) rgba[2];

	// RLog(@"%f %f %f", r, g, b);

	return [UIImage computeR:r G:g B:b];
}
+(uint)computeR:(uint8_t)R G:(uint8_t)G B:(uint8_t)B {
	uint result = 0;

	result += (R << 16);
	result += (G << 8);
	result += B;

	return result / (R+G+B);
}
@end

@interface SBIcon
-(id)applicationBundleID;
-(NSString *)displayName;
-(BOOL)isFolderIcon;
@property (copy,readonly) NSString * description;
@end

@interface SBIconCoordinate
@end

@interface SBIconListModel
@property (nonatomic,copy) NSArray * icons;
-(unsigned long long)indexForIcon:(id)arg1;
-(void)removeIcon:(id)arg1;
-(void)setIcons:(NSArray *)arg1;
-(void)addIcons:(NSArray *)arg1;
-(id)placeIcon:(id)arg1 atIndex:(unsigned long long)arg2;
-(void)removeAllIcons;
-(id)placeIcon:(id)arg1 atIndex:(unsigned long long)arg2 notifyingObservers:(BOOL)arg3;
-(id)insertIcon:(id)arg1 atIndex:(unsigned long long)arg2;
-(id)insertIcon:(id)arg1 atIndex:(unsigned long long)arg2 options:(unsigned long long)arg3;
-(void)removeIconAtIndex:(unsigned long long)arg1;
-(void)markIconStateClean;
-(void)markIconStateDirty;
@end

@interface SBIconListView
-(void)removeAllIconViews;
@property (nonatomic,copy,readonly) NSArray* icons;
-(id)iconViewForIcon:(id)arg1;
@property (getter=isFull,nonatomic,readonly) BOOL full;
@property (nonatomic,retain) SBIconListModel* model;
-(void)setIconsNeedLayout;
-(void)layoutIconsIfNeeded:(double)arg1 ;
-(void)layoutIconsNow;
@end

@interface SBFolderController
@property (nonatomic,copy,readonly) NSArray* iconListViews; // array of SBIconListView
-(id)addEmptyListView;
-(void)layoutIconLists:(double)arg1 animationType:(long long)arg2 forceRelayout:(BOOL)arg3;
-(id)firstIconViewForIcon:(id)arg1;
@end

@interface SBRootFolderController : SBFolderController
@end

@interface SBIconImageView
@property (nonatomic,readonly) UIImage * displayedImage;
@end

@interface SBIconView
-(SBIconImageView*)_iconImageView; // SBIconImageView
@property (nonatomic,retain) SBIcon * icon;
@end

@interface SBIconController
+(id)sharedInstance;
-(void)sort;
@property (getter=_rootFolderController,nonatomic,readonly) SBRootFolderController* rootFolderController;
@property (getter=_currentFolderController,nonatomic,readonly) SBFolderController * currentFolderController;
@end

@interface HueComparator : NSObject
@end

@implementation HueComparator
+(NSComparator)compare {
	return ^(SBIconView* icon1, SBIconView* icon2) {
		NSArray* hues = [HueComparator hueForIcons:[NSArray arrayWithObjects: icon1, icon2, nil]];

		if (hues[0] > hues[1]) return (NSComparisonResult) NSOrderedDescending;
		if (hues[0] < hues[1]) return (NSComparisonResult) NSOrderedAscending;
		return (NSComparisonResult) NSOrderedSame;
	};
}
// IconArray becomes HueArray
+(NSArray*)hueForIcons:(NSArray*)icons {
	NSMutableArray* result = [NSMutableArray arrayWithCapacity:[icons count]];
	[icons enumerateObjectsUsingBlock:^(SBIconView* iconView, NSUInteger idx, BOOL *stop) {
		uint hue = 0;
		if ([iconView.icon isFolderIcon]) {
			// RLog(@"Folder = %@", [iconView.icon displayName]); // folders have an -(SBFolder)folder. SBFolderView with SBIconScrollView to get apps
		} else {
			// RLog(@"Icon = %@", [iconView.icon displayName]);
			UIImage* image  = [iconView _iconImageView].displayedImage;
			hue = [image hue];
		}
		[result addObject:[NSNumber numberWithUnsignedInt:hue]];
	}];

	return result;
}
@end

%hook SBIconController
%new
-(void)sort {
	// Each icon is either an application or a folder (or an internet shortcut ig)
	NSMutableArray<SBIconView*>* iconViews = [NSMutableArray array]; // list of SBIconView
	for (SBIconListView* listView in self._rootFolderController.iconListViews) {
		for (SBIcon* icon in [listView icons]) {
			SBIconView* iconView = [listView iconViewForIcon:icon];
			if ([iconView icon] == nil) RLog(@"No iconView icon for %@", [icon displayName]);
			[iconViews addObject:iconView];
		}
	}
	NSArray<SBIconView*>* sortedIconViews = /* iconViews; // */[iconViews sortedArrayUsingComparator:[HueComparator compare]];
	NSMutableArray<SBIcon*>* sortedIcons = [NSMutableArray arrayWithCapacity:[sortedIconViews count]];
	[sortedIconViews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(SBIconView* iconView, NSUInteger idx, BOOL* stop) {
		[sortedIcons addObject:iconView.icon]; // NSEnumerationReverse NSEnumerationConcurrent
	}];
	RLog(@"You have %d icons!", sortedIcons.count);


	// Add icons
	int iconListViewIndex = 0;
	int iconListIndex = 0;
	SBIconListView* listView = [self._rootFolderController.iconListViews objectAtIndex:iconListViewIndex];
	[listView.model removeAllIcons];
	for (SBIcon* icon in sortedIcons) {
		if (icon == nil) RLog(@"Icon is nil! %@!", icon);
		
		if (listView.isFull) {
			iconListViewIndex++;
			iconListIndex = 0;
			[listView setIconsNeedLayout];
			[listView layoutIconsIfNeeded:1];
			[self._rootFolderController layoutIconLists:iconListViewIndex animationType:0 forceRelayout:YES];
			[listView.model markIconStateDirty];
			[listView.model markIconStateClean];
			listView = [self._rootFolderController.iconListViews objectAtIndex:iconListViewIndex];
			[listView.model removeAllIcons];
		}

		// [listView.model placeIcon:icon atIndex:iconListIndex];
		[listView.model removeIconAtIndex:iconListIndex];
		[listView.model insertIcon:icon atIndex:iconListIndex options:0];

		// TODO: Somehow save now
		
		iconListIndex++;
	}
	[listView.model markIconStateDirty];
	[listView.model markIconStateClean];

	/*
	PICK UP:
	placeIcon1 index 7
	placeIcon2 index 7 obs 1

	PUT DOWN
	inserticon1 index 6 option 0
	placeIcon2 index 6 obs 0
	*/
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

/*
%hook SBIconListModel
-(id)insertIcon:(id)arg1 atIndex:(unsigned long long)arg2 options:(unsigned long long)arg3  {
	RLog(@"inserticon1 index %d option %d", arg2, arg3);
	return %orig;
	}
-(id)insertIcon:(id)arg1 atIndex:(unsigned long long)arg2  {
	RLog(@"inserticon2 index %d", arg2);
	return %orig;
}
-(id)placeIcon:(id)arg1 atIndex:(unsigned long long)arg2 {
	RLog(@"placeIcon1 index %d", arg2);
	return %orig;
}
-(id)placeIcon:(id)arg1 atIndex:(unsigned long long)arg2 notifyingObservers:(BOOL)arg3  {
	RLog(@"placeIcon2 index %d obs %d", arg2, arg3);
	return %orig;
}
-(void)removeIconAtIndex:(unsigned long long)arg1 {
	RLog(@"Removing icon at index %d", arg1);
	%orig;
}
-(void)markIconStateClean {
	RLog(@"Marked as clean");
	%orig;
}
-(BOOL)addIcon:(id)arg1 asDirty:(BOOL)arg2 {
	RLog(@"Added icon %@ as DIRTY: %d", arg1, arg2);
	return %orig;
}
%end
*/
