#import <libactivator/libactivator.h>
#import <AudioToolbox/AudioToolbox.h>
#include <RemoteLog.h>
#import <IconImageProcessing.h>
#import <SBInterfaces.h>
#import <AlertWindow.h>

#define MAX3(a, b, c) MAX(MAX(a, b), c)
#define MIN3(a, b, c) MIN(MIN(a, b), c)

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
