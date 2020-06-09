#import <AlertWindow.h>
#import <SBInterfaces.h>
#include <RemoteLog.h>

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
