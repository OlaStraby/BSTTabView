//
//  BSTTabView.m
//  StockTracker
//
//  Created by Familjen on 2015-07-11.
//  Copyright (c) 2015 OlaStraby. All rights reserved.
//

#import "BSTTabView.h"
@class BSTTabViewTab;



NSString const * BSTDragStringHeader = @"bst.tabview.1.0";

#define MINTABWIDTH 15.0
#define STDYOFFSET 2.0

@interface BSTTabView ()<NSTextViewDelegate,NSDraggingSource,NSDraggingDestination> {
    
    
@private // private iVars
    
    NSMutableParagraphStyle *style;  // fixed text style
    
    CGFloat currentWidth;   // The overall view width last used when rendering it
    CGFloat currentHeight; // The overall view height last used when rendering it
    
    NSTextView *labelEditor;  // Reference to the label editor when in use
    BSTTabViewTab *editedTab;  // reference to the tab beeing edited
    
    NSImage *dragImage;  // Constant image for drag pointer
    
    // State managing variables for drag source
    NSEvent *dragStartMouseEvent;  // The strat mouse event
    BOOL dragInProgress;  // flag from source if drag is in progress - set to NO by destination if drag is short circuited
    BSTTabViewTab *dragSourceTab; // The tab beeing dragged;
    
    // State managing variables for drag destination
    BOOL validDragInDest; // flag in destination if a valid drag is in scope
    NSDragOperation destinationDragOperation; // Current allowed drag insert op
    NSInteger dragInsertPoint;  // Position of visal cue for drag insert (after this tab or first if -1)
}

// private properties used by the helper class BSTTabViewTab
@property (strong,readwrite,nonatomic) NSDictionary *defaultTextOptions;
@property (strong,readwrite,nonatomic) NSDictionary *selectedTextOptions;
@property (strong,readwrite,nonatomic) NSDictionary *rolloverTextOptions;
@property (readwrite, nonatomic) CGFloat preferredTextHeight;
@property (readonly, nonatomic, strong) NSFont *textFont;
@property (readwrite, nonatomic) CGFloat tabHeight;

// State tracking properties
@property (nonatomic, readwrite, weak) BSTTabViewTab *currentRollover;
@property (nonatomic, readwrite) BOOL geometryIsInvalid; // Flag to recalculate widths

// The array of tabs
@property (strong,readwrite,nonatomic) NSMutableArray *tabs; // The array of tabs


// Private methods used internally
// ===============================
-(NSInteger)moveTabAtIndex:(NSUInteger)fromIndex toIndex: (NSUInteger)toIndex;  // Move a tab

-(void)setAllTabWidthsAndStartPos;  // Reallocate space and strat coordinates for tabs

-(CGFloat)widthForLabelOrEditorForTab:(BSTTabViewTab *)tab; // The preferred width that is suffient for both label and field editor

-(BOOL)beginEditLabelInteractiveForTab:(NSInteger)index;  // Edit the label interactively using the window field editor

-(NSImage *)createDragImage;  // Method to generate a suitable image for dragging
-(NSString *)dragStringForTabWithIndex:(NSInteger)index; // Create the string for pasteboard placement used in dragging
-(BOOL)validateDragString:(NSString *)dragString; // Validate dragString is a valid drag string
-(NSInteger)indexFromDragString:(NSString *)dragString; // Extract the encoded index from a  drag string
-(NSString*)labelFromDragString:(NSString *)dragString; // Extract the encoded label from a drag string
-(NSString*)tagFromDragString:(NSString *)dragString; // extract the encoded index from a drag string


@end

#pragma mark - <<<<<<<<<< HELPER CLASS  >>>>>>>>>>>>>>
@interface BSTTabViewTab : NSObject
{  // private ivars
@private
    NSBezierPath *boundaryCurve;   // The precalualeted boundary shape of the tab
    NSTrackingArea *trackingArea;  // The current tracking area
    BOOL rollover;                 // is rolled over flag
    CGFloat currentTabHt;          // The height the tab is currently drawn to
}

// Properties
// ==========
// Referencing properties
@property (weak, nonatomic, readwrite) BSTTabView *owner;  // The referencing tabView

// Data properties
@property (strong, nonatomic, readwrite) NSString *tag;  // The attached tag
@property (strong,nonatomic,readwrite) NSString *label; // The text label

// Graphical properties
@property (readwrite, nonatomic) CGFloat coreWidth; // The allocated width of the core part of the tab (between spacers)
@property (readwrite, nonatomic) CGFloat startX;  // Start point of core area



// Methods
// ========

-(id)initWithOwner:(BSTTabView *)owner;  // Initialiser

// Desired width returning methods
-(CGFloat)widthForLabelString;  // The preferred width for the current label string rendered in teh current font

// Drawing methods
-(void)drawSelf:(BOOL)selected;  // Draw self - as selected if paramerter is YES
-(void)recreateBoundaryCurve; // Recalualte the bezier path
-(BOOL)xLocIsBeforeFirstHalfOfTab:(CGFloat)xLoc; // Returns YES if the passed in location is before halfway (including all preceeding tabs) of this tab and NO if not

@end



@implementation BSTTabViewTab

#pragma mark - lifetime methods

-(id)initWithOwner:(BSTTabView *)owner {
    
    self = [super init];
    if (self) {
        _owner = owner;
        currentTabHt = -1;
    }
    return self;
}


-(void)dealloc {
    
    if (trackingArea) {
        [self.owner removeTrackingArea:trackingArea];  // Remove the previous tracking area
        rollover = NO;  // Remove rollover if TA changed
        trackingArea = nil;
    }
    // release iVars
    boundaryCurve = nil;
}

#pragma mark - custom accessors


-(void)setCoreWidth:(CGFloat)coreWidth {  // Custom as need to recreate bezier on change
    
    if ((coreWidth == _coreWidth) && (currentTabHt == self.owner.tabHeight)) {  // No change = no action
        return;
    }
    
    _coreWidth = coreWidth;  // New width - need to recreate the bezier
    [self recreateBoundaryCurve];
}



-(void)setStartX:(CGFloat)startX {  // Custom as need to recreate bezier on change
    
    if (startX == _startX) {
        return;
    }
    
    _startX = startX;
    
    /*
     * The below is a trick to enforce regen of the curve on the call to setCoreWidth even if the core width is unchanged,
     * which is called after setStartX by the space allocation procedure. Change in tab height will be validated by
     * the setCoreWidth: method. Thus two passes through the curve generation method is avoided.
     */
    currentTabHt = -1;
}



#pragma mark - methods

// The preferred width for the current label string rendered in the current font
-(CGFloat)widthForLabelString{
    
    CGFloat w = 0.0;
    if (self.label) {
        NSSize size = [self.label sizeWithAttributes:self.owner.defaultTextOptions];
        w = size.width + 2.0;
    }
    
    return (w < MINTABWIDTH ? MINTABWIDTH : w);
}



// Recreate the boundary path and also sets the tracking area
-(void)recreateBoundaryCurve {
    
    NSBezierPath *path = [[NSBezierPath alloc] init];
    [path setLineWidth:1.0];
    NSPoint pt;
    NSPoint cp1;
    
    currentTabHt = self.owner.tabHeight;
    
    pt.x = self.startX - self.owner.spacerWidth;
    pt.y = 0.0;
    [path moveToPoint:pt];
    
    pt.x = self.startX - self.owner.tabCornerRadius;
    pt.y = 0.0 + currentTabHt - self.owner.tabCornerRadius;
    [path lineToPoint:pt];
    
    pt.x = self.startX + self.owner.tabCornerRadius;
    pt.y = 0.0 + currentTabHt;
    
    cp1.x = self.startX;
    cp1.y = 0.0 + currentTabHt;
    [path curveToPoint:pt controlPoint1:cp1 controlPoint2:cp1];
    
    
    pt.x = self.startX + self.coreWidth - self.owner.tabCornerRadius;
    pt.y = 0.0 + currentTabHt;
    [path lineToPoint:pt];
    
    pt.x = self.startX + self.coreWidth  + self.owner.tabCornerRadius;
    pt.y = 0.0 + currentTabHt - self.owner.tabCornerRadius;
    cp1.x = self.startX + self.coreWidth;
    cp1.y = 0.0 + currentTabHt;
    [path curveToPoint:pt controlPoint1:cp1 controlPoint2:cp1];
    
    
    pt.x = self.startX + self.coreWidth + self.owner.spacerWidth;
    pt.y = 0.0;
    [path lineToPoint:pt];
    
    boundaryCurve = path;
    
    
    // Set the tracking area
    if (trackingArea) {
        [self.owner removeTrackingArea:trackingArea];  // Remove the previous tracking area
        rollover = NO;  // Remove rollover if TA changed
    }
    NSRect rect = NSMakeRect(self.startX, 0.0, self.coreWidth, currentTabHt);
    trackingArea = [[NSTrackingArea alloc] initWithRect:rect options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp)  owner:self userInfo:nil];
    [self.owner addTrackingArea:trackingArea];
}


-(void)drawSelf:(BOOL)selected {
    
    NSColor *fillColor;
    NSColor *borderColor;
    NSDictionary *txtAttr;
    
    if (selected) {
        fillColor = self.owner.selectedFieldColor;
        borderColor = self.owner.selectedBorderColor;
        txtAttr = self.owner.selectedTextOptions;
        
    } else if (rollover && self.owner.rolloverEnabled)  {  // Rollover enabled, rollover actually always active just not shown by color change
        fillColor = self.owner.rolloverFieldColor;
        borderColor = self.owner.rolloverBorderColor;
        txtAttr = self.owner.rolloverTextOptions;
        
    } else {
        fillColor = self.owner.backgroundColor;
        borderColor = self.owner.borderColor;
        txtAttr = self.owner.defaultTextOptions;
    }
    
    [fillColor set];
    [boundaryCurve fill];
    
    // Make a rect for text, height as required fro font if possible but never more than height of tab - 4 (2 top + 2 bottom margin)
    NSRect textRect = NSMakeRect(self.startX + 1.0, STDYOFFSET, self.coreWidth -1.0, ((currentTabHt < (self.owner.preferredTextHeight-4)) ? (currentTabHt-4) : self.owner.preferredTextHeight));
    [self.label drawInRect:textRect withAttributes:txtAttr];
    
    [borderColor set];
    [boundaryCurve stroke];
}

-(BOOL)xLocIsBeforeFirstHalfOfTab:(CGFloat)xLoc{
    
    
    if (xLoc > (self.startX + (self.coreWidth / 2)) ) {
        return NO;
    } else {
        return YES;
    }
}


#pragma mark - Mouse Tracking methods

// Called in tracking area
-(void)mouseEntered:(NSEvent *)theEvent {
    
    rollover = YES;
    self.owner.currentRollover = self;
}



-(void)mouseExited:(NSEvent *)theEvent {
    
    rollover = NO;
    if (self.owner.currentRollover == self) {  // unset if this is the currently set rollover
        self.owner.currentRollover = nil;
    }
}

@end





#pragma mark - <<<<<<<<<<<<<< MAIN CLASS >>>>>>>>>>>>>>>>>


@implementation BSTTabView

#pragma mark - lifetime methods




-(id)initWithFrame:(NSRect)frameRect{
    
    self = [super initWithFrame:frameRect];
    
    if (self) {
        [self setupDefaults];
    }
    return self;
}



-(void)setupDefaults {
    
    if (_tabs) {  // already initailised
        return;
    }
    
    _tabs = [[NSMutableArray alloc]initWithCapacity:5];   // Create the property
    _selectedTab = -1;  // No selected tab
    labelEditor = nil; // No editor active
    
    _lastClickedTab = -1;
    _clickCount = 1;

    
    _delegate =nil;
    
    _topEdge = YES;
    _rolloverEnabled = YES;
    _doubleClickEditEnabled = NO;
    _userTabDraggingEnabled = BSTTabViewDragNone;
    
    _spacerWidth = 5.0;
    _tabHeight = ((self.bounds.size.height > 10.0) ? (self.bounds.size.height -5.0) : self.bounds.size.height-2.0);
    _tabCornerRadius = 1.0;

    style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setLineBreakMode:NSLineBreakByTruncatingMiddle];
    [style setAlignment:NSCenterTextAlignment];
    
    _textFont = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
    
    _backgroundColor = [NSColor windowFrameColor];
    _borderColor = [NSColor gridColor];
    [self setTextColorPrimitive:_borderColor];  // also sets the _defaultTextOptions
    
    _selectedFieldColor = [NSColor highlightColor];
    _selectedBorderColor = _selectedFieldColor;
    [self setSelectedTextColorPrimitive:[NSColor controlShadowColor]];
    
    _rolloverFieldColor = [NSColor controlHighlightColor];
    _rolloverBorderColor = _rolloverFieldColor;
    [self setRolloverTextColorPrimitive:[NSColor controlShadowColor]];
    
    _editingColor = [NSColor blackColor];
    
    NSSize size = [@"Dummy|" sizeWithAttributes:_defaultTextOptions];
    _preferredTextHeight = size.height;
    
    currentWidth = self.bounds.size.width;
    currentHeight = self.bounds.size.height;
    
    dragImage = [self createDragImage];
    dragInProgress = NO;
    validDragInDest = NO;
    [self registerForDraggedTypes:[NSArray arrayWithObject:NSStringPboardType]];

    _geometryIsInvalid = YES;
}




-(void)dealloc {
    
    [self.tabs removeAllObjects];
}




#pragma mark - setters and getters



-(NSUInteger)count {
    return self.tabs.count;
}




-(void)setTopEdge:(BOOL)topEdge {

    
    if (topEdge == _topEdge) {
        return;  // No change
    }
    
    _topEdge = topEdge;

    [self setNeedsDisplay:YES];
}



-(void)setSpacerWidth:(CGFloat)spacerWidth {
    
    if (spacerWidth == _spacerWidth) {
        return;  // No change
    }
    
    if (self.tabCornerRadius > spacerWidth) {  // Reset corener radius if too big
        _tabCornerRadius = spacerWidth;
    }
    
    _spacerWidth = spacerWidth;
    
    [self setNeedsDisplay:YES];
}


-(void)setMaxTabHeight:(CGFloat)tabHeight {
    
    if (tabHeight == _maxTabHeight) {
        return;  // No change
    }
    _maxTabHeight = tabHeight;
    self.tabHeight = tabHeight;  // Set the actual tab height
    
    [self setNeedsDisplay:YES];
}



-(void)setTabHeight:(CGFloat)tabHeight {
    
    // Called from the draw routine so must not do setNeedsDisplay:YES here. Any other caller to this method should do so.
    // Not the user facing method is setMaxtabHeight:
    
    CGFloat newHt = (tabHeight > self.bounds.size.height ? self.bounds.size.height : tabHeight);
    if (newHt == _tabHeight) {  // no change
        return;
    }
    _tabHeight = newHt;
    
    self.geometryIsInvalid = YES;
}



-(void)setTabCornerRadius:(CGFloat)tabCornerRadius {
    
    if (tabCornerRadius == _tabCornerRadius) {
        return;  // No change
    }
    
    CGFloat r = (tabCornerRadius < 0.0 ? 0.0 : tabCornerRadius);
    if (r > self.spacerWidth) {
        r = self.spacerWidth;
    }
    _tabCornerRadius = r;
    
    [self setNeedsDisplay:YES];
}


-(void)setBackgroundColor:(NSColor *)backgroundColor {
    
    if ([backgroundColor isEqual: _backgroundColor]) {
        return;  // No change
    }
    
    _backgroundColor = backgroundColor;
    
    [self setNeedsDisplay:YES];
}


-(void)setBorderColor:(NSColor *)borderColor {
    
    if ([borderColor isEqual: _borderColor]) {
        return;  // No change
    }
    
    _borderColor = borderColor;
    
    [self setNeedsDisplay:YES];
}



-(void)setTextColor:(NSColor *)textColor {
    
    if ([textColor isEqual: _textColor]) {
        return;  // No change
    }
    
    [self setTextColorPrimitive:textColor];
    
    [self setNeedsDisplay:YES];
}



-(void)setSelectedFieldColor:(NSColor *)selectedFieldColor {
    
    if ([selectedFieldColor isEqual: _selectedFieldColor]) {
        return;  // No change
    }
    
    _selectedFieldColor = selectedFieldColor;
    dragImage = [self createDragImage];  // Recreate the drag image in new color scheme

    
    [self setNeedsDisplay:YES];
}


-(void)setSelectedBorderColor:(NSColor *)selectedBorderColor {
    
    if ([selectedBorderColor isEqual: _selectedBorderColor]) {
        return;  // No change
    }
    
    _selectedBorderColor = selectedBorderColor;
    dragImage = [self createDragImage]; // Recreate the drag image in new color scheme
    
    [self setNeedsDisplay:YES];
}



-(void)setSelectedTextColor:(NSColor *)selectedTextColor {
    
    if ([selectedTextColor isEqual: _selectedTextColor]) {
        return;  // No change
    }
    
    [self setSelectedTextColorPrimitive:selectedTextColor ];
    
    [self setNeedsDisplay:YES];
}



-(void)setRolloverFieldColor:(NSColor *)rolloverFieldColor {
    
    if ([rolloverFieldColor  isEqual: _rolloverFieldColor ]) {
        return;  // No change
    }
    
    _rolloverFieldColor  = rolloverFieldColor;
    
    [self setNeedsDisplay:YES];
}


-(void)setRolloverBorderColor:(NSColor *)rolloverBorderColor{
    
    if ([rolloverBorderColor isEqual: _rolloverBorderColor]) {
        return;  // No change
    }
    
    _rolloverBorderColor = rolloverBorderColor;
    
    [self setNeedsDisplay:YES];
}



-(void)setRolloverTextColor:(NSColor *)rolloverTextColor {
    
    if ([rolloverTextColor isEqual: _rolloverTextColor]) {
        return;  // No change
    }
    
    [self setRolloverTextColorPrimitive:rolloverTextColor];
    
    [self setNeedsDisplay:YES];
}



// Sets both the text color ivar and the member in the textOptions dictionary
-(void)setTextColorPrimitive:(NSColor *)color {
    
    
    _defaultTextOptions = @{NSFontAttributeName            : _textFont ,
                            NSForegroundColorAttributeName : color ,
                            NSParagraphStyleAttributeName  : style};
    _textColor = color;
}


-(void)setSelectedTextColorPrimitive:(NSColor *)color {
    
    
    _selectedTextOptions = @{NSFontAttributeName            : _textFont  ,
                             NSForegroundColorAttributeName : color ,
                             NSParagraphStyleAttributeName  : style};
    _selectedTextColor = color;
}


-(void)setRolloverTextColorPrimitive:(NSColor *)color {
    
    
    _rolloverTextOptions = @{NSFontAttributeName            : _textFont ,
                             NSForegroundColorAttributeName : color ,
                             NSParagraphStyleAttributeName  : style};
    _rolloverTextColor = color;
}





-(void)setSelectedTab:(NSInteger)selectedTab {
    
    if ((selectedTab > ((NSInteger)self.tabs.count -1)) || (selectedTab < -1)) {
        return;  // Abort on illegal input
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(tabWithIndexWillBecomeSelected:)]) {
        if (![self.delegate tabWithIndexWillBecomeSelected:selectedTab]) {
            return;  // Abort if delegate denies change
        }
    }
    
    if (labelEditor && ![self.window makeFirstResponder:self.window]) {  // Editing in progress ensure it is concluded or abort
        return;
    }
    
    _selectedTab = selectedTab;
    [self setNeedsDisplay:YES];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(tabWithIndexDidBecomeSelected:)]) {
        [self.delegate tabWithIndexDidBecomeSelected:selectedTab];
    }
}



-(void)setCurrentRollover:(BSTTabViewTab *)currentRollover {
    
    if (currentRollover) {  // Set a rollover tab
        
        if ([_currentRollover isEqual:currentRollover]) { // No change
            return;
        }
        _currentRollover = currentRollover;
        [self setNeedsDisplay:YES];
        
    } else {   // unsetting the rollover
        
        if (!_currentRollover) {  // Not the rollover tab is not currently set - do not unset
            return;
        }
        _currentRollover = nil;
        [self setNeedsDisplay:YES];
    }
}


#pragma mark - drawing

// Drawing callback to see if coordinate system is inverted, used for bottom display
-(BOOL)isFlipped{
 
    return !self.topEdge;    // Flip all drawing coordinates if bottom edge
}




// Main drawing - draw all allways
- (void)drawRect:(NSRect)dirtyRect {
    
    [super drawRect:dirtyRect];
    
    NSRect bounds = [self bounds];
    
    // Check if width has changed - height should be constant
    if (bounds.size.width != currentWidth) {
        currentWidth = bounds.size.width;
        self.geometryIsInvalid = YES;
    }
    
    if (bounds.size.height != currentHeight) {
        currentHeight = bounds.size.height;
        self.tabHeight = self.maxTabHeight;  // reset the tab height - possibly
    }
    
    // Draw background
    [self.backgroundColor set];
    [NSBezierPath fillRect:bounds];
    
    if (self.geometryIsInvalid) {  // Recalc geometry if needed
        [self setAllTabWidthsAndStartPos];
    }
    
    // Draw tabs
    for (NSUInteger i = 0; i < self.tabs.count; i++) {   // For each tab call draw
        if (i != self.selectedTab) {     //Delay selected - Draw selected last to be on top
            [(BSTTabViewTab *)[self.tabs objectAtIndex:i] drawSelf:NO];
        }
    }
    if (self.selectedTab >= 0) {
        [(BSTTabViewTab *)[self.tabs objectAtIndex:self.selectedTab] drawSelf:YES];  // Finally draw selected tab
    }
    
    // Draw insert point
    if (validDragInDest) {
        NSBezierPath* bp = [[NSBezierPath alloc] init];;
        NSPoint pt;
        CGFloat baseX;
        
        if (dragInsertPoint == -1) {  // Insert first
            baseX = (self.spacerWidth / 2);
        } else {  // Insert after tab nr dragInsertPoint
            BSTTabViewTab *tab = [self.tabs objectAtIndex:dragInsertPoint];
            baseX = tab.startX + tab.coreWidth + (self.spacerWidth / 2);
        }
        
        if (currentHeight < 10) {  // The small insert
            
            pt.x = baseX;
            pt.y = 0;
            [bp moveToPoint:pt];
            
            pt.x = baseX;
            pt.y = currentHeight;
            [bp lineToPoint:pt];
            
        } else {  // The bigger insert
            CGFloat ht = ((self.maxTabHeight + 2) > currentHeight ? currentHeight : self.maxTabHeight + 2);
            pt.x = baseX;
            pt.y = ht - 8;
            [bp moveToPoint:pt];
            
            pt.x = baseX;
            pt.y = ht-5;
            [bp lineToPoint:pt];
            
            pt.x = baseX - 2;
            pt.y = ht;
            [bp lineToPoint:pt];

            pt.x = baseX + 2;
            pt.y = ht;
            [bp lineToPoint:pt];

            pt.x = baseX;
            pt.y = ht-5;
            [bp lineToPoint:pt];

        } // end big mark
        
        [self.editingColor set];
        [bp stroke];
        
    }  // end draw mark code
}





// Method to (re)allocate widths to tabs

-(void)setAllTabWidthsAndStartPos{
    
    CGFloat totalRequested = self.spacerWidth;  // Start with one spacer with to the left side
    CGFloat longestRequested = MINTABWIDTH + 1.0; // In case all tabs are shorter than min to prevent warning for insufficinet size
    CGFloat tabWidth;  // intermediate value
    CGFloat w;
    BSTTabViewTab *tab;
    
    // Add up ideal width
    for (NSUInteger i = 0; i < self.tabs.count; i++) {
        tab = [self.tabs objectAtIndex:i];
        tabWidth = [self widthForLabelOrEditorForTab:tab];
        
        if (tabWidth > longestRequested) {  // Track the longest individual one
            longestRequested = tabWidth;
        }
        totalRequested = totalRequested + tabWidth + self.spacerWidth;  // and the accumulated sum
    }
    
    // Compress space if required (until it fits or all tabs are smaller or equal to min)
    while ((totalRequested > currentWidth) && (longestRequested > MINTABWIDTH)) {
        
        longestRequested = longestRequested - 1.0;  // Reduce longest allowed by 5 and recalc
        totalRequested = self.spacerWidth;  // restart with one spacer with to the left side
        
        for (NSUInteger i = 0; i < self.tabs.count; i++) {
            tab = [self.tabs objectAtIndex:i];
            if ((self.selectedTab >= 0) && (self.selectedTab == i) ) {  // The seletced tab
                tabWidth = [self widthForLabelOrEditorForTab:tab];  // it gets its full width
            } else {
                w = [self widthForLabelOrEditorForTab:tab];
                tabWidth = (w > longestRequested ? longestRequested : w);
            }
            totalRequested = totalRequested + tabWidth + self.spacerWidth;
        } // end for
    }  // end while longestRequested has been compressed
    
    if (longestRequested <= MINTABWIDTH) {  // Not all will fit even with compression display will be truncated - notify delegate
       if (self.delegate && [self.delegate respondsToSelector:@selector(spaceIsInsufficientToDisplayAllTabs)]) {
            [self.delegate spaceIsInsufficientToDisplayAllTabs];
        }

    }
    
    // allocate actual width to tabs - all get their requested but not more than longestRequested
    // Set startpoint and width
    CGFloat accumulatedX = self.spacerWidth;
    
    for (NSUInteger i = 0; i < self.tabs.count; i++) {
        tab = [self.tabs objectAtIndex:i];
        tab.startX = accumulatedX;
        if ((self.selectedTab >= 0) && (self.selectedTab == i) ) {  // The seletced tab
            tabWidth = [self widthForLabelOrEditorForTab:tab];  // it gets its full width
        } else {
            w = [self widthForLabelOrEditorForTab:tab];
            tabWidth = (w > longestRequested ? longestRequested : w);
        }
        
        if (tab == editedTab) {  // Editing is ongoing, align the editor start
            [labelEditor setFrameOrigin:NSMakePoint(accumulatedX + 1.0,STDYOFFSET)];
        }
        
        tab.coreWidth = roundf(tabWidth);
        accumulatedX = accumulatedX + tabWidth + self.spacerWidth;
    }
    self.geometryIsInvalid = NO;
    return;
}




-(CGFloat)widthForLabelOrEditorForTab:(BSTTabViewTab *)tab {
    
    CGFloat wlabel = [tab widthForLabelString];
    
    // ask owner for width of field editor, will be -1 if field editor is not assigned to this tab
    CGFloat weditor;
    if (editedTab != tab) { // This is not the edited tab
        weditor = -1.0;
    } else {
    // Edit in progress for the requested tab
      NSRect rect = labelEditor.frame;
      weditor = rect.size.width + 2.0;
    }
    
    return (weditor > wlabel ? weditor : wlabel);  // take the max
}


#pragma mark - event handlers

-(void)mouseDown:(NSEvent *)theEvent {
    BOOL displayDirty = NO;
    
    dragStartMouseEvent = theEvent; // Keep this event for dragging purposes - initiated from mouseDragged: message
    
    NSInteger cnt = [theEvent clickCount];
    NSInteger rolloverIndex = [self indexForRolloverTab];  // Get the index of current rollover if any, else -1
    
    // If doubleclick edit is enabled and this is a double click then launch interactive edit
    if (self.doubleClickEditEnabled && (cnt > 1) && self.currentRollover) {
        
        BOOL allowed = YES;
        if (self.delegate && [self.delegate respondsToSelector:@selector(editingWillBeginForTabAtIndex:)]) {  // delegate check
            allowed = [self.delegate editingWillBeginForTabAtIndex:rolloverIndex];
        }
        
        if (allowed) {
            if ([self beginEditLabelInteractiveForTab:rolloverIndex]) {   // call edit on active tab
                displayDirty = YES;
            }
        }
    }

    // Postprocess - redraw as needed
    if (displayDirty) {
        [self setAllTabWidthsAndStartPos];
    }
}



-(void)mouseUp:(NSEvent *)theEvent {

    BOOL displayDirty = NO;

    NSInteger rolloverIndex = [self indexForRolloverTab];  // Get the index of current rollover if any, else -1

    // If this is a single click and there is a current rollover that is not same as selected then change selection
    if (([theEvent clickCount] == 1) && (self.currentRollover) && (rolloverIndex != self.selectedTab)) {
        self.selectedTab = rolloverIndex;
        displayDirty = YES;
    }
    
    // Set the click related properties
    _lastClickedTab = rolloverIndex;
    _clickCount = [theEvent clickCount];
    
    // Send the target action message
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
     
     if (_target && _action) {
     [_target performSelector:_action withObject:self afterDelay:0.0];
     }
    
#pragma clang diagnostic pop
    
    // Postprocess - redraw as needed
    if (displayDirty) {
        [self setAllTabWidthsAndStartPos];
    }
}



-(void)mouseDragged:(NSEvent *)theEvent {
    
    // Used for initiating dragging after some distance (2)
    if ((!dragInProgress) && (self.userTabDraggingEnabled > BSTTabViewDragNone) && self.currentRollover) {   // Investiage if a drag should start
        
        CGFloat deltX = [dragStartMouseEvent locationInWindow].x - [theEvent locationInWindow].x;
        CGFloat deltY = [dragStartMouseEvent locationInWindow].y - [theEvent locationInWindow].y;
        CGFloat draggedDist = (deltX * deltX) + (deltY * deltY);
        if (draggedDist >= 4) {  // begin drag after sqrt(4) distance
            
            // Check with delegate
            if (self.delegate && [self.delegate respondsToSelector:@selector(draggingWillBeginForTabWithIndex:)]) {
                if (![self.delegate draggingWillBeginForTabWithIndex:[self indexForRolloverTab]]) {
                    return;
                }
            }
            
            // Set up the drag
            dragSourceTab = self.currentRollover;
            NSString *dragString =[self dragStringForTabWithIndex:[self indexForRolloverTab]];
            
            NSDraggingItem *di = [[NSDraggingItem alloc] initWithPasteboardWriter:dragString];
            NSPoint stPt = [self convertPoint:[dragStartMouseEvent locationInWindow] fromView:nil];
            NSRect r = NSMakeRect(stPt.x + 2, stPt.y + 2, dragImage.size.width, dragImage.size.height);
            [di setDraggingFrame:r contents:dragImage];

            dragInProgress = YES;
            [self beginDraggingSessionWithItems:[NSArray arrayWithObject:di] event:dragStartMouseEvent source:self];
        }
    }
}


-(void)cancelOperation:(id)sender {
    
    [labelEditor setString:editedTab.label];
    [self.window makeFirstResponder:self.window];
    [self setAllTabWidthsAndStartPos];
    [self setNeedsDisplay:YES];
}


#pragma mark - Editing and NSTextViewDelegate methods

-(BOOL)beginEditLabelInteractiveForTab:(NSInteger)index {
    
    if (![self.window makeFirstResponder:self.window]) {  // Try to make window first responder to ensure the shared field editor is available.
        return NO;
    };
    
    
    NSTextView *tv = (NSTextView *)[self.window fieldEditor:YES forObject:nil]; // take the shared field editor and configure it
    
    if (!tv) {  // Did not get the field editor
        return NO;
    }
    
    // Set font and location
    [tv setVerticallyResizable:NO];
    [tv setFont:self.textFont];
    [tv setBackgroundColor:self.selectedFieldColor];
    [tv setTextColor:self.editingColor];
    [tv setEditable:YES];

    editedTab = [self.tabs objectAtIndex:index];
    tv.string = editedTab.label;         // Set text
    
    CGFloat w = editedTab.coreWidth + 2.0; // Slightly larger to fit the cursor
    CGFloat h = (self.tabHeight < (self.preferredTextHeight-4)) ? (self.tabHeight-4) : self.preferredTextHeight; // Text height or tab ht - 4 whichever is less
    [tv setFrameSize:NSMakeSize(w,h)];
    // x poistion is set in owner draw method to match location of tab
    
    tv.textContainer.lineFragmentPadding = 0; // remove padding for alignment with text below
    
    // Set delegate
    tv.delegate = self;
    // Insert into view hierarchy
    [self addSubview:tv];
    [self.window makeFirstResponder:tv];
    
    labelEditor = tv;  // Store a reference also used as a flag
    return YES;
}


-(void)textDidEndEditing:(NSNotification *)notification {
    
    
    // textview editing did end
    NSTextView *tv = [notification object];
    
    [self setLabel:[NSString stringWithString:tv.string] forTabAtIndex:[self.tabs indexOfObject:editedTab]];
    
    // Remove the field editor
    [tv removeFromSuperview];
    tv.delegate = nil;
    labelEditor = nil;
    editedTab = nil;
}


-(void)textDidChange:(NSNotification *)notification {
    
    NSTextView *tv = [notification object];
    CGFloat w = [tv.string sizeWithAttributes:self.selectedTextOptions].width + 2.0;  // Increase the length to follow added text
    CGFloat h = tv.frame.size.height; // Reuse the old height, will not change
    NSSize siz = NSMakeSize( (w < [editedTab widthForLabelString] ? [editedTab widthForLabelString] : w) , h);  // Set a new size (width) but never less than original (otherwise text below is exposed)
    [tv setFrameSize:siz];
    self.geometryIsInvalid = YES;
    [self setNeedsDisplay:YES];
}

#pragma mark - Drag and Drop methods


-(NSImage *)createDragImage{
    
    NSSize siz = NSMakeSize(20, 7);
    NSImage *img = [[NSImage alloc]initWithSize:siz];
    
    
    NSBezierPath *path = [[NSBezierPath alloc] init];
    [path setLineWidth:1.0];
    NSPoint pt;
    
    CGFloat spcr = 3.0;
    
    pt.x = 0.0;
    pt.y = 0.0;
    [path moveToPoint:pt];
    
    pt.x = spcr;
    pt.y = siz.height;
    [path lineToPoint:pt];
    
    pt.x = siz.width - spcr;
    pt.y = siz.height;
    [path lineToPoint:pt];
    
    pt.x = siz.width;
    pt.y = 0.0;
    [path lineToPoint:pt];
    
    // drawing code
    [img lockFocus];
    [self.selectedFieldColor set];
    [path fill];
    
    [self.selectedBorderColor set];
    [path stroke];
    [img unlockFocus];
    
    return img;
}

/** 
 * The dragString is encoded following the following format
 * "H I LL L T, meaning"
 * H - Header 15 characters followed by one space - header shall be bst.tabview.1.0 to be valid
 * I - tab index integer 4 digits, with leading zeroes as needed followed by 1 space
 * LL - Label length integer 4 digits, with leading zeroes as needed followed by 1 space
 * L - Label as many characters as given in LL, followed by 1 space
 * T - Tag remainder of string
 * This means tags with index above 9999 or with label length more than 9999 characters cannot be encoded.
 * Method will return nil for these cases
 *
 * @param index The tab to be encoded
 *
 * @return The encoded string
 *
 */

-(NSString *)dragStringForTabWithIndex:(NSInteger)index{
    
    if ((index > 9999) || (index < 0) || (index >= self.tabs.count)) {  // invalid index
        return nil;
    }
    
    NSString  *lab =[self labelForTabAtIndex:index];
    if (!lab) {
        lab = @"";
    }
    if ([lab length] > 9999) {
        return nil;
    }
    
    NSString *tag =[self tagForTabAtIndex:index];
    if (!tag) {
        tag = @"";
    }
    
    NSString *s = [NSString stringWithFormat:@"%@ %04ld %04ld %@ %@",BSTDragStringHeader, (long)index,(long)[lab length],lab,tag];
    return s;
}

-(BOOL)validateDragString:(NSString *)dragString{
    
    
    if (!dragString || (dragString.length < 27)) {// Check min length 15+1+4+1+4+1+1
        return NO;
    }
    NSString *s;
    NSRange r;
    
    // Check header
    r = NSMakeRange(0, 15);
    s = [dragString substringWithRange:r];  // Extract header
    if (![BSTDragStringHeader isEqualToString:s]) {  // invalid dragString
        return NO;
    }
    
    NSCharacterSet *unwantedCharacters = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];

    // Check index
    
    r = NSMakeRange(16, 4);
    s = [dragString substringWithRange:r];  // Extract index
    
    if ([s length] != 4) {
        return NO;
    }
    
    if ([s rangeOfCharacterFromSet:unwantedCharacters].location != NSNotFound) {
        return NO;
    }
    
    // Check label length
    r = NSMakeRange(21, 4);
    s = [dragString substringWithRange:r];  // Extract index
    
    if ([s length] != 4) {
        return NO;
    }
    
    if ([s rangeOfCharacterFromSet:unwantedCharacters].location != NSNotFound) {
        return NO;
    }
    
    return YES;
}




-(NSInteger)indexFromDragString:(NSString *)dragString{
    
    if (![self validateDragString:dragString]) {
        return -1;
    }
    NSRange r = NSMakeRange(16, 4);
    NSString *s =[dragString substringWithRange:r];

    return [s integerValue];
}



-(NSString*)labelFromDragString:(NSString *)dragString{

    if (![self validateDragString:dragString]) {
        return nil;
    }
    NSRange r = NSMakeRange(21, 4);
    NSString *s =[dragString substringWithRange:r];
    
    NSInteger len = [s integerValue];
    
    if (len == 0) {
        return @"";
    }
    
    if ([dragString length] < (27 + len)) {  // Something is wrong
        return nil;
    }
    
    r = NSMakeRange(26, len);
    return [dragString substringWithRange:r];
}



-(NSString*)tagFromDragString:(NSString *)dragString{
    
    if (![self validateDragString:dragString]) {
        return nil;
    }
    NSRange r = NSMakeRange(21, 4);
    NSString *s =[dragString substringWithRange:r];
    
    NSInteger len = [s integerValue];
    
    if ([dragString length] <= (27 + len)) {  // Something is wrong or there were no tag
        return nil;
    }
    
    r = NSMakeRange( 27+len, ([dragString length] - (27+len)) );
    return [dragString substringWithRange:r];
}


// DarggingSource methods

-(NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
    
    switch(context) {
        case NSDraggingContextOutsideApplication:
            if (self.userTabDraggingEnabled >= BSTTabViewDragGlobal) {
                return NSDragOperationMove;
            } else {
                return NSDragOperationNone;
            }
            break;
            
        case NSDraggingContextWithinApplication:
        default:
            if (self.userTabDraggingEnabled >= BSTTabViewDragInternal) {
                return NSDragOperationMove;
            } else {
                return NSDragOperationNone;
            }
            break;
    }
}




-(BOOL)ignoreModifierKeysForDraggingSession:(NSDraggingSession *)session {
    return YES;
}



-(void)draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation {
    
    BOOL success = (operation == NSDragOperationMove ? YES : NO);

    if (success && dragInProgress) {  // The move ewas successful and the insert and remove operation has not been short circuited

        [self removeTabAtIndex:[self.tabs indexOfObject:dragSourceTab]];
    }
    
    // Inform delegate
    if (self.delegate && [self.delegate respondsToSelector:@selector(draggingFinishedForTabWithLabel:tag:success:)]) {
        [self.delegate draggingFinishedForTabWithLabel:dragSourceTab.label tag:dragSourceTab.tag success:success];
    }

    dragSourceTab = nil;
    dragInProgress = NO;
    dragStartMouseEvent = nil;
    self.geometryIsInvalid = YES;
    [self setNeedsDisplay:YES];
}



// DraggingDestination metthods

-(NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    
    /*
     * This method determines the response for dragging inside the control and stores that in the state managing variables
     * the state managing varaibles are used to indicate that a inswrt opoint is to be drawn 
     * and whre a tab should be inserted on a successful conclude operation.
     * The state managing variables are unset on a successful conclusion or on exit
     */
    
    if (self.userTabDraggingEnabled == BSTTabViewDragNone) {  // No dragging allowed return early
      destinationDragOperation = NSDragOperationNone;
        return destinationDragOperation;
    }
    
    id src = [sender draggingSource]; // Find the source of the drag and compare to the settings flag
    if (!src) {  // This is coming from other application
        
        if (self.userTabDraggingEnabled >= BSTTabViewDragGlobal) {  // Corss app dragging is permitted, check if we have dragString
            NSArray *ar = [sender.draggingPasteboard readObjectsForClasses:[NSArray arrayWithObject:[NSString class]] options:nil];
            
            if ((ar.count == 1) && [self validateDragString:(NSString *)[ar firstObject]]) {  // The pasteboard has a valid dragString
                destinationDragOperation = NSDragOperationMove & [sender draggingSourceOperationMask];
            } else {  // Not drag string
                destinationDragOperation = NSDragOperationNone;
            }
        } else { // Cross app drag not allowed
            destinationDragOperation = NSDragOperationNone;
        }
        
    } else {  // there is a source object means source is in same application
        
        if ([src isKindOfClass:[BSTTabView class]]) {  // sender is a BSTTabView - required
            if ((self.userTabDraggingEnabled >= BSTTabViewDragLocal) && ([(BSTTabView *)src userTabDraggingEnabled] >= BSTTabViewDragLocal) ) { // any sender in same app is ok, but we need to check the sender allows cross control drags also
                destinationDragOperation = NSDragOperationMove & [sender draggingSourceOperationMask];
            } else { // == BSTTabViewDragInternal
                if (src == self) {  // must be same sender
                    destinationDragOperation = NSDragOperationMove & [sender draggingSourceOperationMask];
                } else {
                    destinationDragOperation = NSDragOperationNone;
                }
            }
        } else {
            destinationDragOperation = NSDragOperationNone; // Sender is some other class - not valid
        };
    }
    if (destinationDragOperation == NSDragOperationMove) {
        validDragInDest = YES; // Set the other state managing variables
        dragInsertPoint = -1; // Placeholder to before first tab - will change on first draggging Updated message.
        [self setNeedsDisplay:YES];
    }
    
    return destinationDragOperation;
}



-(BOOL)wantsPeriodicDraggingUpdates {
    
    return NO; // Only get updates on move
}




-(NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
    
    /*
     * This method is used to determine the insert point in case the drag operation were to conclude next
     * it is recalculating every time and storing the reult in a state varaible.  A short circuit could 
     * be considered to check if the previous value is valid before going into the full calculation
     * but given the rarity of drags this is felt unneeded until a performace issue is seen
     */

    
    if (validDragInDest) {   // Calculate the point of the visual feedback if the drag is valid
        NSPoint drPt = [self convertPoint:[sender draggingLocation] fromView:nil];
        NSInteger insPoint;
        
        // Find location
        insPoint = self.tabs.count - 1;  // Start by assuming after last tab
        NSInteger i = 0;
        while (i<self.tabs.count) {  // Search all tabs
            if ([(BSTTabViewTab*)[self.tabs objectAtIndex:i] xLocIsBeforeFirstHalfOfTab:drPt.x]) {
                insPoint = i - 1;  // insPoint is defined as tab before insert point (-1 == before first)
                i = self.tabs.count; // Found the point, break out of while loop
            }
            i++;
        }
        if (dragInsertPoint != insPoint) {   // if point changed, update state variable and request redraw
            dragInsertPoint = insPoint;
            [self setNeedsDisplay:YES];
        }

    }
    
    return destinationDragOperation;
}




-(void)draggingExited:(id<NSDraggingInfo>)sender {
    
    // Unset the state managing variables
    validDragInDest = NO;
    dragInsertPoint = -1;
    [self setNeedsDisplay:YES];
}




-(BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {
    
    NSArray *ar = [sender.draggingPasteboard readObjectsForClasses:[NSArray arrayWithObject:[NSString class]] options:nil];

    if (( ar.count != 1 ) || (![self validateDragString:(NSString *)[ar firstObject]])) {  // Something is wrong, there should be one and only one valid string on the pasteboard
        validDragInDest = NO;  // unset the state variable if we are going to deny drag
        [self setNeedsDisplay:YES];
        return NO;
    }
    
    // There is a valid dragString in Ask delegate if ok to insert
    NSString *ds =[ar firstObject];
    if (self.delegate && [self.delegate respondsToSelector:@selector(draggedTabWillBeInsertedAtIndex:withLabel:tag:sourceExternal:)]) {
        return [self.delegate draggedTabWillBeInsertedAtIndex:(dragInsertPoint+1) withLabel:[self labelFromDragString:ds] tag:[self tagFromDragString:ds] sourceExternal:([sender draggingSource] ? NO : YES)];
    }
    
    return YES;  // Default return if no delegate method
}




-(BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    
    // if we get here we are good to go, validation done in prepareForDragOperation
    
    BOOL success = YES;

    if ([sender draggingSource] == self ) {  // This drag can be short-circuited by using the moveTab method
        
        NSInteger frm =[self.tabs indexOfObject:dragSourceTab];
        NSInteger to =(dragInsertPoint+1);
        
        [self moveTabAtIndex:frm toIndex:(to > frm ? (to - 1) : to)]; 
        dragInProgress = NO; // Flag the sender (== self) that no delete is needed
        
    } else { // Do a proper new insert and assume the sender will do a delete

        NSString *ds = [[sender.draggingPasteboard readObjectsForClasses:[NSArray arrayWithObject:[NSString class]] options:nil] firstObject];
        
        if ([self addTabWithLabel:[self labelFromDragString:ds] tag: nil atIndex:(dragInsertPoint + 1)] == -1) {  // Try insert
            success = NO;
        }
        
        NSString *tg = [self tagFromDragString:ds];
        
        if (tg && success) {
            success = [self setTag:tg ForTabAtIndex:(dragInsertPoint + 1)];
        }
        
    }
    
    // Done - unset the state managing variables
    validDragInDest = NO;
    self.geometryIsInvalid = YES;
    [self setNeedsDisplay:YES];
    
    return success;
}



-(void)concludeDragOperation:(id<NSDraggingInfo>)sender {
    
    // Do nothing here
}




#pragma mark - Action methods


-(NSInteger)addTabWithLabel:(NSString *)label tag:(NSString *)tag {
    
    return [self addTabWithLabel:label tag: tag atIndex:self.tabs.count];
}


-(NSInteger)addTabWithLabel:(NSString *)label tag:(NSString *)tag atIndex:(NSUInteger)requestedIndex{
    
    NSInteger newIndex = ((requestedIndex > self.tabs.count) ? self.tabs.count : requestedIndex); // Set to end if higher then end
    
    // End editing and if not abort
    if (labelEditor && ![self.window makeFirstResponder:self.window]) {
        return -1;
    }

    BSTTabViewTab *tab = [[BSTTabViewTab alloc] initWithOwner:self];
    tab.label = label;
    tab.tag = tag;
    [self.tabs insertObject:tab atIndex:newIndex];
    
    // Check if selected tab index change and notify
    if (self.selectedTab >= newIndex) {  // At or after insertion point will increase by one
        
        [self willChangeValueForKey:@"selectedTab"];  // Do key value calls without the setter to prevent delegate calls
        _selectedTab = _selectedTab + 1;
        [self didChangeValueForKey:@"selectedTab"];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(selectedTabChangedIndexTo:)]) {
            [self.delegate selectedTabChangedIndexTo:self.selectedTab];
        }
    }
    
    self.geometryIsInvalid = YES;
    [self setNeedsDisplay:YES];
    return (newIndex);
}




-(BOOL)removeTabAtIndex:(NSUInteger)index {
    
    if (index >= self.tabs.count) {
        return NO;  // Invalid index
    }
    
    // End editing and if not abort
    if (labelEditor && ![self.window makeFirstResponder:self.window]) {
        return NO;
    }

    // Check selected tab status and notify
    if (self.selectedTab == index) {  // Removing selected tab
        self.selectedTab = -1;  // Try to change to selection - triggers delegate notification methods
        if (self.selectedTab != -1) {  // Change was denied by deleagte - abort
            return NO;
        }
    }
    
    // Remove it
    [self.tabs removeObjectAtIndex:index];
    
    // Check if selected tab index change and notify
    if (self.selectedTab > (NSInteger)index) {  // After removal point will reduce by one
        
        [self willChangeValueForKey:@"selectedTab"];  // Do key value calls without the setter to prevent delegate calls
        _selectedTab = _selectedTab - 1;
        [self didChangeValueForKey:@"selectedTab"];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(selectedTabChangedIndexTo:)]) {
            [self.delegate selectedTabChangedIndexTo:self.selectedTab];
        }
    }
    
    self.geometryIsInvalid = YES;
    [self setNeedsDisplay:YES];
    return YES;
}



-(NSInteger)moveTabAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex {
    
    // Validate intended indexes
    if ((fromIndex >= self.tabs.count) || (toIndex >= self.tabs.count)) {
        return -1;  // Invalid index
    }
    
    if (fromIndex == toIndex) {  // No move - abort
        return (NSInteger)fromIndex;
    }
    
    // End editing and if not abort
    if (labelEditor && ![self.window makeFirstResponder:self.window]) {
        return -1;
    }

    // Do the move
    BSTTabViewTab *tab = [self.tabs objectAtIndex:fromIndex];
    [self.tabs removeObjectAtIndex:fromIndex];
    [self.tabs insertObject:tab atIndex:toIndex];
    
    // Calculate if the selected tab index will change - change and delegate notify
    NSInteger newSelected = self.selectedTab;
    
    if (fromIndex == self.selectedTab) {   // The selected tab is moving
        
        newSelected = toIndex;
        
    } else {  // The selected tab is not moving
        
        if (self.selectedTab > fromIndex  ) {  // Selected tab is after removal point will step one down
            newSelected = newSelected - 1;
        }
        
        if (newSelected >= toIndex) {  // Selected tab is at or after insertion point will step one up
            newSelected = newSelected + 1;
        }
    }
    
    if (newSelected != self.selectedTab) {  // Selected tab is moving
        
        [self willChangeValueForKey:@"selectedTab"];  // Do key value calls without the setter to prevent delegate calls
        _selectedTab = newSelected;
        [self didChangeValueForKey:@"selectedTab"];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(selectedTabChangedIndexTo:)]) {
            [self.delegate selectedTabChangedIndexTo:newSelected];
        }
    }
    
    self.geometryIsInvalid = YES;
    [self setNeedsDisplay:YES];

    return toIndex;
}



-(NSInteger)moveTabAtIndex:(NSUInteger)index oneStepRight:(BOOL)right{
    
    if (index >= self.tabs.count) {
        return -1;  // Invalid index
    }
    
    NSUInteger newIndex;
    if (right) {
        if (index == (self.tabs.count - 1)) {  // Already at right
            newIndex = index;
        } else {
            newIndex = index + 1;
        }
    } else {  // left
        if (index == 0) {
            newIndex = index;
        } else {
            newIndex = index - 1;
        }
    }
    
    return [self moveTabAtIndex:index toIndex:newIndex];
}


-(NSString *)labelForTabAtIndex:(NSUInteger)index{
    
    if (index >= self.tabs.count ) {
        return nil;
    }
    return [(BSTTabViewTab *)[self.tabs objectAtIndex:index] label];
}



-(BOOL)setLabel:(NSString *)label forTabAtIndex:(NSUInteger)index{
    
    if ((index >= self.tabs.count) || (!label)) {  // nil values not permitted
        return NO;
    }
    
    BSTTabViewTab *tab = [self.tabs objectAtIndex:index];

    if ([tab.label isEqualToString:label]) {  // No change - most likely an interactive edit cancel
        self.geometryIsInvalid = YES;
        [self setNeedsDisplay:YES];
        return YES;
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(labelWillChangeTo:forTabAtIndex:)]) {
        if (![self.delegate labelWillChangeTo:label forTabAtIndex:index]) {
            return NO;  // Abort if delegate denies change
        }
    }
    
    tab.label = label;

    
    if (self.delegate && [self.delegate respondsToSelector:@selector(labelDidChangeForTabAtIndex:)]) {
        [self.delegate labelDidChangeForTabAtIndex:index];
    }
    
    self.geometryIsInvalid = YES;
    [self setNeedsDisplay:YES];

    return YES;
}




-(NSInteger)indexForTabWithLabel:(NSString *)label{
    
    BSTTabViewTab *tab;
    for (NSUInteger i = 0; i < self.tabs.count; i++) {
        tab = [self.tabs objectAtIndex:i];
        if ([tab.label isEqualToString:label]) {
            return i;
        }
    }
    return -1; // Can only get here if not found
}





-(NSString *)tagForTabAtIndex:(NSUInteger)index{
    
    if (index >= self.tabs.count ) {
        return nil;
    }
    return [(BSTTabViewTab *)[self.tabs objectAtIndex:index] tag];
}




-(BOOL)setTag:(NSString *)tag ForTabAtIndex:(NSUInteger)index{
 
    
    if (index >= self.tabs.count ) {
        return NO;
    }
    BSTTabViewTab *tab = [self.tabs objectAtIndex:index];
    tab.tag = tag;
    return YES;
}




-(NSInteger)indexForRolloverTab{
    
    if (!self.currentRollover) {
        return -1;
    }
    
    return [self.tabs indexOfObject:self.currentRollover];
}


@end
