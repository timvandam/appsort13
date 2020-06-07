#import <libactivator/libactivator.h>
#import <AudioToolbox/AudioToolbox.h>

/*
1. Describe action
2. Implement it
3. allow users to change activation methods
*/

@interface AppSort13 : NSObject <LAListener>
-(void)activator:(LAActivator*)activator receiveEvent:(LAEvent*)event;
-(void)activator:(LAActivator*)activator abortEvent:(LAEvent*)event;
@end

@implementation AppSort13
-(void)activator:(LAActivator*)activator receiveEvent:(LAEvent*)event {
	AudioServicesPlaySystemSound(1519); // light haptic feedback

	[AppSort13 showAlert];

    [event setHandled: YES];
}

-(void)activator:(LAActivator*)activator abortEvent:(LAEvent*)event {
    [event setHandled: YES];
}

+(void)showAlert {
	UIAlertController* alert = [UIAlertController
		alertControllerWithTitle:@"AppSort13"
		message:@"Choose a way to sort your apps below\nThere is no going back!"
		preferredStyle:UIAlertControllerStyleActionSheet];

	UIAlertAction* hue = [UIAlertAction
		actionWithTitle:@"Hue"
		style:UIAlertActionStyleDestructive
		handler:^(UIAlertAction* action) {}];

	UIAlertAction* alphabetical = [UIAlertAction
		actionWithTitle:@"Alphabetical"
		style:UIAlertActionStyleDestructive
		handler:^(UIAlertAction* action) {}];

	UIAlertAction* cancel = [UIAlertAction
		actionWithTitle:@"Cancel"
		style:UIAlertActionStyleCancel
		handler:^(UIAlertAction* action) {}];

	[alert addAction:hue];
	[alert addAction:alphabetical];
	[alert addAction:cancel];

	UIWindow* aWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	aWindow.windowLevel = UIWindowLevelAlert;

	UIViewController* uv = [UIViewController new];
	aWindow.rootViewController = uv;

	[aWindow setBackgroundColor:[UIColor clearColor]];
	[aWindow makeKeyAndVisible];

	[uv presentViewController:alert animated:YES completion:nil];
}
@end

%ctor {
	[LASharedActivator registerListener:[[AppSort13 alloc] init] forName:@"nl.timvd.appsort13"];
}
