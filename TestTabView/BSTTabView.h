//
//  BSTTabView.h
//  StockTracker
//
//  Created by Familjen on 2015-07-11.
//  Copyright (c) 2015 ;. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 * The delegate protocol for the BSTTabView custom control. The delegate pattern is the main
 * mechanism fro feedback from the control. The control do not support binding or notifications
 * but KVO should work (not extensively tested)
 */

@protocol BSTTabViewDelegate <NSObject>

@optional
/**
 * Method called before the selected tab is changed, return NO to deny the change
 
 * @param index The index of the tab that will become selected, -1 if no tab will be selected
 *
 * @return YES if delegte accepts the change and NO if the change should be prevented
 */
-(BOOL)tabWithIndexWillBecomeSelected:(NSInteger)index;


/**
 * Method called after the selected tab is changed.
 
 * @param index The index of the tab that became selected, -1 if no tab will be selected
 */
-(void)tabWithIndexDidBecomeSelected:(NSInteger)index;


/**
 * Method called when the index of the selected tab is changed but remains the same tab.
 * i.e. if a new tab is inserted before the current tab. 
 * Note in general the window controller should not have to keep track of teh indexes. 
 * it is better to store the identity of each tab in an userData struct and only react to
 * tabWithIndexDidBecomeSelecred: callbacks
 *
 * @param index The new index of the selected tab
 */
-(void)selectedTabChangedIndexTo:(NSInteger)index;

/**
 * Method called before a tab label is changed, return NO to deny the change
 *
 * @param index The index of the tab that will change
 * @param newLabel The intended new label of the tab
 *
 * @return YES if delegte accepts the change and NO if the change should be prevented
 */
-(BOOL)labelWillChangeTo:(NSString *)newLabel forTabAtIndex:(NSUInteger)index;


/**
 * Method called after a tab label is changed.
 
 * @param index The index of the tab that changed
 *
 * @return YES if delegte accepts the change and NO if the change should be prevented
 */
-(BOOL)labelDidChangeForTabAtIndex:(NSUInteger)index;


/**
 * Method that is called if there is insifficient space to display even compressed versionsm of the tabs
 * The BSTTabVie control has no further mechanism to deal with this beyond displaying as many tabs as possible
 * and then truncating. There is no guarantee the selected tab vill be visible
 *
 */
-(void)spaceIsInsufficientToDisplayAllTabs;
 


@end





/**
 * The BSTTabView is a custom control that implements a tab band to be located at the top or bottom of another control
 * it a tab interface with arbitrary number of tabs. One and only one tab is selected at any one time. The tabs are aligned with
 * the top or bottom edge as appropriate. The tabs will autshrink if space is insufficient.
 * Clicking on a tab selects it.
 * Doubleclicking enables edit of the tab label
 * The tabView also implements rollovers and custom colors
 * The tabView can be initialised from a nib or by init. In both cases all settings are configured to default as per below.
 */

@interface BSTTabView : NSView

/**
 * property selectedTab is read only that report the index of the currently selected tab
 */
@property (readonly, nonatomic) NSInteger selectedTab;



/**
 * property delegate allows setting and object to receive the callback functions in the BSTTabViewDelegate protocol.
 */
@property (readwrite, nonatomic, strong) id<BSTTabViewDelegate> delegate;


/**
 * property topEdge is a boolean that defines if the tabs are oriented for a bottom fit or a top fit. YES for top edge and NO for bottom edge
 * default to YES
 */

@property (readwrite, nonatomic) BOOL topEdge;

/**
 * property rolloverEnabled is a boolean that defines if the visual Rollover feature is enabled, default to YES
 */

@property (readwrite, nonatomic) BOOL rolloverEnabled;

/**
 * property doubleClickEditEnabled is a boolean that defines if the double click to edit label feature is enabled, default to NO
 */

@property (readwrite, nonatomic) BOOL doubleClickEditEnabled;



/**
 * The spacerWidth property defines the distance between each tab in the band. The spacer is filled by a sloping
 * edges of the tabs partially overlapping. Defaults to 5.0 on initialisation if not set explictly.
 */
@property (readwrite, nonatomic) CGFloat spacerWidth;

/**
 * The tabHeight property defines the height of each tab in the band. Deafult is control height - 5.0
 */
@property (readwrite, nonatomic) CGFloat tabHeight;

/**
 * The tabCornerRadius property defines the corner rounding of each tab in the band. 0.0 creates sharp corners.
 * max is spacerWidth, bigger numbers are treated as spacerWidth. Deafult is 1.0
 */
@property (readwrite, nonatomic) CGFloat tabCornerRadius;



/**
 * The backgroundColor property defines the background color of the tab ribbon and the non-selected tabs, default is windowFrameColor
 */
@property (readwrite, nonatomic, strong)NSColor *backgroundColor;

/**
 * The BorderColor color property defines the edge outline color of the selected tab, default is gridColor
 */
@property (readwrite, nonatomic, strong)NSColor *borderColor;

/**
 * The TextColor color property defines the text color of the selected tab, default is gridColor
 */
@property (readwrite, nonatomic, strong)NSColor *textColor;



/**
 * The selectedFieldColor color property defines the background color of the selected tab, default is highlightColor
 */
@property (readwrite, nonatomic, strong)NSColor *selectedFieldColor;

/**
 * The selectedBorderColor color property defines the edge outline color of the selected tab, default is highlightColor
 */
@property (readwrite, nonatomic, strong)NSColor *selectedBorderColor;

/**
 * The selectedTextColor color property defines the text color of the selected tab, default is controlShadowColor
 */
@property (readwrite, nonatomic, strong)NSColor *selectedTextColor;


/**
 * The rolloverFieldColor color property defines the background color of the selected tab, default is controlHighlightColor
 */
@property (readwrite, nonatomic, strong)NSColor *rolloverFieldColor;

/**
 * The selectedBorderColor color property defines the edge outline color of the selected tab, default is controlHighlightColor
 */
@property (readwrite, nonatomic, strong)NSColor *rolloverBorderColor;

/**
 * The selectedTextColor color property defines the text color of the selected tab, default is controlShadowColor
 */
@property (readwrite, nonatomic, strong)NSColor *rolloverTextColor;


/**
 * Method to add a new tab at the end of the tab list
 * 
 * @param label The text label of teh new tab
 *
 * @return the index of the new tab
 */

-(NSUInteger)addTabWithLabel:(NSString *)label;

/**
 * Method to add a new tab at a specific index in the tab list. Tabs after the new tab will have their
 * index increased by one. If index is beyond the end then the tab will be added at the last index
 *
 * @param label The text label of the new tab
 * @param requestedIndex The desired index of the new tab
 *
 * @return the index allocated to the new tab
 */
-(NSUInteger)addTabWithLabel:(NSString *)label atIndex:(NSUInteger)requestedIndex;


/**
 * Method to remove a tab at a specific index in the tab list. Tabs after the new tab will have their
 * index decreased by one. If index does not exist then the no tab will be removed.
 * If the selected tab is removed then the next higher tab becomes selected or if no higher then the next lower. 
 * If this is the last tab then no tab is selected.
 
 * @param index The index of the tab to be removed
 *
 * @return YES if the removal succeded.
 */
-(BOOL)removeTabAtIndex:(NSUInteger)index;


/**
 * Method to move a tab at a specific index in the tab list one step to right or left. 
 * Tabs after and before the tab will have their index adjusted accordingly. 
 * If index does not exist then the no tab will be moved.
 *
 * @param index The index of the tab to be moved
 * @param right Direction of teh move YES for right and NO for left.
 *
 * @return the new index allocated to the tab after the move or -1 if index did not exist
 */

-(NSInteger)moveTabAtIndex:(NSUInteger)index oneStepRight:(BOOL)right;



/**
 * Method to return the name of the tab at index. If index does not exist then the nil will be returned
 
 * @param index The index of the tab to be queried
 *
 * @return the text label of the tab or nil if index do not exist.
 */
-(NSString *)labelForTabAtIndex:(NSUInteger)index;



/**
 * Method to return the name of the tab at index. If index does not exist then the nil will be returned
 
 * @param index The index of the tab to be queried
 *
 * @return the text label of the tab or nil if index do not exist.
 */
-(BOOL)setLabel:(NSString *)label forTabAtIndex:(NSUInteger)index;




/**
 * Method to return the index of the first tab with given label. If label does not exist then then -1 will be returned
 
 * @param label The label of the tab to be found
 *
 * @return the index of the tab or -1 if label do not exist.
 */
-(NSInteger)indexForTabWithLabel:(NSString *)label;


/**
 * Method to return an userInfo dictionary associated with the tab at index. If index does not exist then the nil will be returned
 
 * @param index The index of the tab to be queried
 *
 * @return the userInfo dictionary of the tab or nil if index do not exist.
 */
-(NSDictionary *)userInfoForTabAtIndex:(NSUInteger)index;


/**
 * Method to set an userInfo dictionary associated with the tab at index. If index does not exist then NO will be returned
 
 * @param index The index of the tab to be queried
 * @param userInfo The dictionary to be stored with the tab
 *
 * @return the userInfo dictionary of the tab or nil if index do not exist.
 */
-(BOOL)setUserInfo:(NSDictionary *)userInfo ForTabAtIndex:(NSUInteger)index;


@end
