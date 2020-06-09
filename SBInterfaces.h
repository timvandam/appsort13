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

