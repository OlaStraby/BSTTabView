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
 * mechanism for feedback from the control. The control do not support binding or notifications
 * but KVO should work (not extensively tested)
 *
 * There are no checks with delegate ethoids before insert or delete actions. This is because these
 * are always initiated by direct calls from the controller of the BSTTabView with the exception of
 * drags between controlds (where allowed). In thse instances there are delegate methods that will allow
 * the controller to prevent the drag and react to the new tab inserted. 
 */

@protocol BSTTabViewDelegate <NSObject>

@optional
/**
 * Method called before the selected tab is changed, return NO to deny the change
 *
 * @param index The index of the tab that will become selected, -1 if no tab will be selected
 *
 * @return YES if delegte accepts the change and NO if the change should be prevented
 */
-(BOOL)tabWithIndexWillBecomeSelected:(NSInteger)index;


/**
 * Method called after the selected tab is changed.
 *
 * @param index The index of the tab that became selected, -1 if no tab will be selected
 */
-(void)tabWithIndexDidBecomeSelected:(NSInteger)index;


/**
 * Method called when the index of the selected tab is changed but remains the same tab.
 * i.e. if a new tab is inserted before the current tab. 
 * Note in general the window controller should not have to keep track of the indexes.
 * it is better to store the identity of each tab in an userData struct and only react to
 * tabWithIndexDidBecomeSelected: callbacks
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
 */
-(void)labelDidChangeForTabAtIndex:(NSUInteger)index;


/**
 * Method that is called if there is insufficient space to display even compressed versionsm of the tabs
 * The BSTTabVie control has no further mechanism to deal with this beyond displaying as many tabs as possible
 * and then truncating. There is no guarantee the selected tab vill be visible
 *
 */
-(void)spaceIsInsufficientToDisplayAllTabs;
 


/**
 * Method called before interactive editing of a tab label is begun, return NO to deny editing
 *
 * @param index The index of the tab that will change
 * @param newLabel The intended new label of the tab
 *
 * @return YES if delegte accepts the change and NO if the change should be prevented
 */
-(BOOL)editingWillBeginForTabAtIndex:(NSUInteger)index;


/**
 * Method called on the dragging source delegate before a dragging of a tab begins, return NO to deny dragging this tab
 *
 * @param index The index of the tab that will be inserted
 * @param label The label of the dragged tab
 * @param tag The tag string of the dragged tab
 * @param external YES if the source is from another application and NO if from within this application
 * but not neccessarily from same control
 *
 * @return YES if delegte accepts the drag and NO if the drag should be prevented
 */
-(BOOL)draggingWillBeginForTabWithIndex:(NSUInteger)index;


/**
 * Method called on the dragging source delegate after dragging of a tab concludes.
 *
 * @param label The label of the tab that was dragged
 * @param tag The tag of the tab that was dragged
 * @param success YES if the drag was successful and NO if it was reveresed
 *
 */
-(void)draggingFinishedForTabWithLabel:(NSString *)label tag:(NSString *)tag success:(BOOL)success;



/**
 * Method called before a dragged tab is inserted, return NO to deny the insert
 *
 * @param index The index of the tab that will be inserted
 * @param label The label of the dragged tab
 * @param tag The tag string of the dragged tab
 * @param external YES if the source is from another application and NO if from within this application 
 * but not neccessarily from same control
 *
 * @return YES if delegte accepts the drag and NO if the drag should be prevented
 */
-(BOOL)draggedTabWillBeInsertedAtIndex:(NSUInteger)index withLabel:(NSString *)label tag:(NSString *)tag sourceExternal:(BOOL)external;



@end







typedef NS_ENUM(NSInteger, BSTTabViewDragOptions) {
    BSTTabViewDragNone,
    BSTTabViewDragInternal,
    BSTTabViewDragLocal,
    BSTTabViewDragGlobal
};

/**
 * The BSTTabView is a custom control that implements a tab band to be located at the top or bottom of another control
 * it a tab interface with arbitrary number of tabs. One and only one tab is selected at any one time. The tabs are aligned with
 * the top or bottom edge as appropriate. The tabs will autshrink if space is insufficient.
 * Clicking on a tab selects it.
 * Doubleclicking enables edit of the tab label
 * The tabView also implements rollovers and custom colors
 * The tabView can be initialised from a nib or by init. In both cases all settings are configured to default as per below.
 * The tab view control do not implement undo
 */

@interface BSTTabView : NSView


/**
 * property count reflects the number of tabs in the tabView */
@property (readonly, nonatomic) NSUInteger count;


/**
 * property selectedTab that reflect the index of the currently selected tab
 */
@property (readwrite, nonatomic) NSInteger selectedTab;


/**
 * The target property defines the control's target for action message
 */
@property (readwrite, nonatomic, weak)id target;


/**
 * The action property defines the control's action message, which is sent to the target
 * upon receipt of this action it is possible to query which tab was clicked by polling for the
 * selected tab or for current rollover, the latter enables detection of a click outside
 * the tabs in teh control area and is the recommended way
 */
@property (readwrite, nonatomic)SEL action;


/**
 * property lastClickedTab that reflect the index of the last clicked tab or -1 if last click in control was outside any tab
 * This property can be polled after the reception of the target-action message
 * The value of this property is undefined at any other time than directly after a target -action
 * message call.
 */
@property (readonly, nonatomic) NSInteger lastClickedTab;


/**
 * property clickCount that reflect the nymber of quick repetitive clicks last detected. 
 * This property can be polled after the reception of the target-action message
 * The value of this property is undefined at any other time than directly after a target -action
 * message call.
 */
@property (readonly, nonatomic) NSInteger clickCount;


/**
 * property delegate allows setting and object to receive the callback functions in the BSTTabViewDelegate protocol.
 */
@property (readwrite, nonatomic, weak) id<BSTTabViewDelegate> delegate;


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
 * property userTabDraggingEnabled is a boolean that defines if drag and drop to rearrange tabs is allowed, default to 0
 * 
 * State is as follows
 * BSTTabViewDragNone - no user dragging allowed
 * BSTTabViewDragInternal - user dragging within control allowed
 * BSTTabViewDragLocal - User dragging within same application allowed
 * BSTTabViewDragGlobal - User dragging allowed also between apps
 */

@property (readwrite, nonatomic) BSTTabViewDragOptions userTabDraggingEnabled;



/**
 * The spacerWidth property defines the distance between each tab in the band. The spacer is filled by a sloping
 * edges of the tabs partially overlapping. Defaults to 5.0 on initialisation if not set explictly.
 */
@property (readwrite, nonatomic) CGFloat spacerWidth;

/**
 * The maxTabHeight property defines the max height of each tab in the band. Deafult is control height - 5.0. When space is 
 * insufficuent tabs become control height
 */
@property (readwrite, nonatomic) CGFloat maxTabHeight;

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
 * The rolloverFieldColor color property defines the background color of the rollover tab, default is controlHighlightColor
 */
@property (readwrite, nonatomic, strong)NSColor *rolloverFieldColor;

/**
 * The rolloverBorderColor color property defines the edge outline color of the rollover tab, default is controlHighlightColor
 */
@property (readwrite, nonatomic, strong)NSColor *rolloverBorderColor;

/**
 * The rolloverTextColor color property defines the text color of the rollover tab, default is controlShadowColor
 */
@property (readwrite, nonatomic, strong)NSColor *rolloverTextColor;


/**
 * The editingColor color property defines the color of interactive text edits and drag insert marks, default is black
 */
@property (readwrite, nonatomic, strong)NSColor *editingColor;





/**
 * Method to add a new tab at the end of the tab list
 * 
 * @param label The text label of teh new tab
 *
 * @return the index of the new tab -1 if insert failed
 */

-(NSInteger)addTabWithLabel:(NSString *)label tag:(NSString *)tag;

/**
 * Method to add a new tab at a specific index in the tab list. Tabs after the new tab will have their
 * index increased by one. If index is beyond the end then the tab will be added at the last index
 *
 * @param label The text label of the new tab
 * @param requestedIndex The desired index of the new tab
 *
 * @return the index allocated to the new tab -1 if failed
 */
-(NSInteger)addTabWithLabel:(NSString *)label tag:(NSString *)tag atIndex:(NSUInteger)requestedIndex;


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
 * Method to return the tag string associated with the tab at index. If index does not exist then the nil will be returned
 
 * @param index The index of the tab to be queried
 *
 * @return the tag string of the tab or nil if index do not exist.
 */
-(NSString *)tagForTabAtIndex:(NSUInteger)index;


/**
 * Method to set a tag associated with the tab at index. If index does not exist then NO will be returned
 
 * @param index The index of the tab to be queried
 * @param tag The string to be stored with the tab
 *
 * @return YES if suvccessful or NO if tab with index do not exist.
 */
-(BOOL)setTag:(NSString *)tag ForTabAtIndex:(NSUInteger)index;



/**
 * Method to return the index of the tab the mouse pointer is currently hovering over. If none then -1 will be returned
 *
 * @return the index of the tab the mouse pointer is hovering over or -1 if none.
 */
-(NSInteger)indexForRolloverTab;


@end
