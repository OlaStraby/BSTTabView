//
//  BSTTabView.m
//  StockTracker
//
//  Created by Familjen on 2015-07-11.
//  Copyright (c) 2015 OlaStraby. All rights reserved.
//

#import "BSTTabView.h"

#define MINTABWIDTH 15.0

@class BSTTabViewTab;

@interface BSTTabView () {
    @private
    NSMutableParagraphStyle *style;
    NSFont *textFont;
    BSTTabViewTab *currentRollover;
    CGFloat currentWidth;
}


@property (readwrite, nonatomic)NSInteger selectedTab;  // Redefine as readwrite for internal use
@property (strong,readwrite,nonatomic) NSMutableArray *tabs; // The array of tabs

@property (strong,readwrite,nonatomic) NSDictionary *defaultTextOptions;
@property (strong,readwrite,nonatomic) NSDictionary *selectedTextOptions;
@property (strong,readwrite,nonatomic) NSDictionary *rolloverTextOptions;
@property (readwrite, nonatomic) CGFloat preferredTextHeight;




-(void)rolloverEntered:(BSTTabViewTab *)rolloverTab;
-(void)rolloverExited:(BSTTabViewTab *)rolloverTab;

@end





#pragma mark - +++ HELPER CLASS BSTTabViewTab +++


@interface BSTTabViewTab : NSResponder

@property (weak, nonatomic, readwrite) BSTTabView *owner;  // The referencing tabView
@property (strong, nonatomic, readwrite) NSDictionary *userInfo;  // The attached userInfo
@property (strong,nonatomic,readwrite) NSString *label; // The text label
@property (strong, nonatomic, readwrite)NSTrackingArea * trackingArea; // The tracking area associated with the tab, added to the tabView for rollovers
@property (readwrite, nonatomic) CGFloat coreWidth; // The width of the core part of the tab (between spacers)
@property (readwrite, nonatomic) CGFloat startX;  // Start point of core
@property (strong, readwrite, nonatomic) NSBezierPath *boundaryCurve;
@property (nonatomic, readwrite) CGFloat preferredCoreWidth;  // Return the ideal core width for the label
@property (nonatomic, readwrite) BOOL rollover;  // is rolled over, i,ä.e is mouse pointer in active area


-(id)initWithOwner:(BSTTabView *)owner;  // Initialiser

-(void)drawSelfIsSelected:(BOOL)selected;  // Draw self

-(void)recreateBoundaryCurve; // Recalualte the bezier path

@end



@implementation BSTTabViewTab


-(id)initWithOwner:(BSTTabView *)owner {
    
    self = [super init];
    if (self) {
        _owner = owner;
        self.label = @"xxxx";  // Also sets preferredCoreWidth
       
        [self recreateBoundaryCurve];
    }
    return self;
}



-(void)setLabel:(NSString *)label {  // All checking to be done by sender
    
    _label = label;
    
    NSSize size = [self.label sizeWithAttributes:self.owner.defaultTextOptions];
    self.preferredCoreWidth = size.width + 2.0;
    
}



-(void)setCoreWidth:(CGFloat)coreWidth {
    
    if (coreWidth == _coreWidth) {
        return;
    }
    
    _coreWidth = coreWidth;
    [self recreateBoundaryCurve];
}



-(void)setStartX:(CGFloat)startX {
    
    if (startX == _startX) {
        return;
    }
    
    _startX = startX;
    [self recreateBoundaryCurve];
}



-(void)recreateBoundaryCurve {
    
    NSBezierPath *path = [[NSBezierPath alloc] init];
    [path setLineWidth:1.0];
    NSPoint pt;
    NSPoint cp1;
    
    pt.x = self.startX - self.owner.spacerWidth;
    pt.y = 0.0;
    [path moveToPoint:pt];
    
    pt.x = self.startX - self.owner.tabCornerRadius;
    pt.y = 0.0 + self.owner.tabHeight - self.owner.tabCornerRadius;
    [path lineToPoint:pt];
    
    pt.x = self.startX + self.owner.tabCornerRadius;
    pt.y = 0.0 + self.owner.tabHeight;
    
    cp1.x = self.startX;
    cp1.y = 0.0 + self.owner.tabHeight;
    [path curveToPoint:pt controlPoint1:cp1 controlPoint2:cp1];
    
    
    pt.x = self.startX + self.coreWidth - self.owner.tabCornerRadius;
    pt.y = 0.0 + self.owner.tabHeight;
    [path lineToPoint:pt];
    
    pt.x = self.startX + self.coreWidth  + self.owner.tabCornerRadius;
    pt.y = 0.0 + self.owner.tabHeight - self.owner.tabCornerRadius;
    cp1.x = self.startX + self.coreWidth;
    cp1.y = 0.0 + self.owner.tabHeight;
    [path curveToPoint:pt controlPoint1:cp1 controlPoint2:cp1];
    
    
    pt.x = self.startX + self.coreWidth + self.owner.spacerWidth;
    pt.y = 0.0;
    [path lineToPoint:pt];
    
    self.boundaryCurve = path;
    
    if (self.trackingArea) {
        [self.owner removeTrackingArea:self.trackingArea];  // Remove teh previous tracking area
    }
    
    
    NSRect rect = NSMakeRect(self.startX, 0.0, self.coreWidth, self.owner.tabHeight);
    self.trackingArea = [[NSTrackingArea alloc] initWithRect:rect options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp)  owner:self userInfo:nil];
    
    [self.owner addTrackingArea:self.trackingArea];
}


-(void)drawSelfIsSelected:(BOOL)selected {
    
    NSColor *fillColor;
    NSColor *borderColor;
    NSDictionary *txtAttr;
    
    if (selected) {
        fillColor = self.owner.selectedFieldColor;
        borderColor = self.owner.selectedBorderColor;
        txtAttr = self.owner.selectedTextOptions;
    } else if (self.rollover)  {
        fillColor = self.owner.rolloverFieldColor;
        borderColor = self.owner.rolloverBorderColor;
        txtAttr = self.owner.rolloverTextOptions;
    } else {
        fillColor = self.owner.backgroundColor;
        borderColor = self.owner.borderColor;
        txtAttr = self.owner.defaultTextOptions;
    }
    
    [fillColor set];
    [self.boundaryCurve fill];
    
    NSRect textRect = NSMakeRect(self.startX + 1.0, 2.0, self.coreWidth -1.0, (self.owner.tabHeight < (self.owner.preferredTextHeight-4)) ? (self.owner.tabHeight-4) : self.owner.preferredTextHeight);
    [self.label drawInRect:textRect withAttributes:txtAttr];
    
    [borderColor set];
    [self.boundaryCurve stroke];
}


-(void)mouseEntered:(NSEvent *)theEvent {
    
    self.rollover = YES;
    [self.owner rolloverEntered:self];
}



-(void)mouseExited:(NSEvent *)theEvent {
    
    self.rollover = NO;
    [self.owner rolloverExited:self];
}

@end






#pragma mark - +++ MAIN CLASS BSTTabView +++


@implementation BSTTabView

#pragma mark - lifetime methods




-(id)initWithFrame:(NSRect)frameRect{
    
    self = [super initWithFrame:frameRect];
    
    if (self) {
        [self setupDefaults];
    }
    return self;
}




-(void)awakeFromNib{
    
    [self setupDefaults];
}





-(void)setupDefaults {
    
    NSLog(@"Setting up tab view defaults");
    
    if (_tabs) {  // already initailised
        NSLog(@"Already done - aborting");
        return;
    }
    
    _tabs = [[NSMutableArray alloc]initWithCapacity:5];   // Create the property
    _selectedTab = -1;  // No selected tab

    
    _delegate =nil;
    
    _topEdge = YES;
    _rolloverEnabled = YES;
    _doubleClickEditEnabled = NO;
    
    _spacerWidth = 5.0;
    _tabHeight = ((self.bounds.size.height > 10.0) ? (self.bounds.size.height -5.0) : self.bounds.size.height);
    _tabCornerRadius = 1.0;

    style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setLineBreakMode:NSLineBreakByTruncatingMiddle];
    
    textFont = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
    
    NSSize size = [@"HELLO" sizeWithAttributes:_defaultTextOptions];
    _preferredTextHeight = size.height;
    
    _backgroundColor = [NSColor windowFrameColor];
    _borderColor = [NSColor gridColor];
    [self setTextColorPrimitive:_borderColor];
    
    _selectedFieldColor = [NSColor highlightColor];
    _selectedBorderColor = _selectedFieldColor;
    [self setSelectedTextColorPrimitive:[NSColor controlShadowColor]];
    
    _rolloverFieldColor = [NSColor controlHighlightColor];
    _rolloverBorderColor = _rolloverFieldColor;
    [self setRolloverTextColorPrimitive:[NSColor controlShadowColor]];
    
    currentWidth = self.bounds.size.width;
}



-(void)dealloc {
    
    [self.tabs removeAllObjects];
}




#pragma mark - setters and getters 

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
    
    _spacerWidth = spacerWidth;
    
    [self setNeedsDisplay:YES];
}



-(void)setTabHeight:(CGFloat)tabHeight {
    
    if (tabHeight == _tabHeight) {
        return;  // No change
    }
    
    _tabHeight = (tabHeight > self.bounds.size.height ? self.bounds.size.height : tabHeight);
    
    [self setNeedsDisplay:YES];
}



-(void)setTabCornerRadius:(CGFloat)tabCornerRadius {
    
    if (tabCornerRadius == _tabCornerRadius) {
        return;  // No change
    }
    
    _tabCornerRadius = (tabCornerRadius < 0.0 ? 0.0 : tabCornerRadius);
    
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
    
    [self setNeedsDisplay:YES];
}


-(void)setSelectedBorderColor:(NSColor *)selectedBorderColor {
    
    if ([selectedBorderColor isEqual: _selectedBorderColor]) {
        return;  // No change
    }
    
    _selectedBorderColor = selectedBorderColor;
    
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




-(void)setTextColorPrimitive:(NSColor *)color {
    
    
    _defaultTextOptions = @{NSFontAttributeName            : textFont ,
                            NSForegroundColorAttributeName : color ,
                            NSParagraphStyleAttributeName  : style};
    _textColor = color;
}


-(void)setSelectedTextColorPrimitive:(NSColor *)color {
    
    
    _selectedTextOptions = @{NSFontAttributeName            : textFont  ,
                             NSForegroundColorAttributeName : color ,
                             NSParagraphStyleAttributeName  : style};
    _selectedTextColor = color;
}


-(void)setRolloverTextColorPrimitive:(NSColor *)color {
    
    
    _rolloverTextOptions = @{NSFontAttributeName            : textFont ,
                             NSForegroundColorAttributeName : color ,
                             NSParagraphStyleAttributeName  : style};
    _rolloverTextColor = color;
}



-(void)setSelectedTab:(NSInteger)selectedTab {

    if (self.delegate && [self.delegate respondsToSelector:@selector(tabWithIndexWillBecomeSelected:)]) {
        if (![self.delegate tabWithIndexWillBecomeSelected:selectedTab]) {
            return;  // Abort if delegate denies change
        }
    }
    _selectedTab = selectedTab;
    [self setNeedsDisplay:YES];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(tabWithIndexDidBecomeSelected:)]) {
        [self.delegate tabWithIndexDidBecomeSelected:selectedTab];
    }
}





#pragma mark - drawing


-(BOOL)isFlipped{
 
    return !self.topEdge;    // Flip all drawing coordinates if bottom edge
}




- (void)drawRect:(NSRect)dirtyRect {
    
    [super drawRect:dirtyRect];
    
    NSRect bounds = [self bounds];
    
    if (bounds.size.width != currentWidth) {
        currentWidth = bounds.size.width;
        [self setAllTabWidthsAndStartPos];
    }
    
    [self.backgroundColor set];
    [NSBezierPath fillRect:bounds];
    
    for (NSUInteger i = 0; i < self.tabs.count; i++) {   // For each tab call draw
        if (i != self.selectedTab) {     // Draw selected last
            [(BSTTabViewTab *)[self.tabs objectAtIndex:i] drawSelfIsSelected:NO];
        }
    }
    if (self.selectedTab >= 0) {
        [(BSTTabViewTab *)[self.tabs objectAtIndex:self.selectedTab] drawSelfIsSelected:YES];  // Finally draw last tab

    }
}






// Method to (re)allocate widths to tabs

-(void)setAllTabWidthsAndStartPos{
    
    CGFloat totalRequested = self.spacerWidth;  // Start with one spacer with to the left side
    CGFloat longestRequested = 0.0;
    CGFloat tabWidth;
    BSTTabViewTab *tab;
    
    // Add up ideal width
    for (NSUInteger i = 0; i < self.tabs.count; i++) {
        tab = [self.tabs objectAtIndex:i];
        
        if (tab.preferredCoreWidth > longestRequested) {
            longestRequested = tab.preferredCoreWidth;
        }
        totalRequested = totalRequested + self.spacerWidth + tab.preferredCoreWidth;
    }
    
    // Compress space if required
    while ((totalRequested > self.bounds.size.width) && (longestRequested > MINTABWIDTH)) {
        
        longestRequested = longestRequested - 1.0;
        totalRequested = self.spacerWidth;  // restart with one spacer with to the left side
        
        for (NSUInteger i = 0; i < self.tabs.count; i++) {
            tab = [self.tabs objectAtIndex:i];
            if ((self.selectedTab >= 0) && (self.selectedTab == i) ) {  // The seletced tab
                tabWidth = tab.preferredCoreWidth;  // it gets its fulll width
            } else {
                tabWidth = (tab.preferredCoreWidth > longestRequested ? longestRequested : tab.preferredCoreWidth);
            }
            totalRequested = totalRequested + self.spacerWidth + tabWidth;
        } // end for
    }  // end while longestRequested has been compressed
    
    if (longestRequested <= MINTABWIDTH) {  // Display will be truncated - notify delegate
       if (self.delegate && [self.delegate respondsToSelector:@selector(spaceIsInsufficientToDisplayAllTabs)]) {
            [self.delegate spaceIsInsufficientToDisplayAllTabs];
        }

    }
    // Set startpoint and width
    CGFloat accumulatedX = self.spacerWidth;
    
    for (NSUInteger i = 0; i < self.tabs.count; i++) {
        tab = [self.tabs objectAtIndex:i];
        tab.startX = accumulatedX;
        if ((self.selectedTab >= 0) && (self.selectedTab == i) ) {  // The seletced tab
            tabWidth = tab.preferredCoreWidth;  // it gets its fulll width
        } else {
            tabWidth = (tab.preferredCoreWidth > longestRequested ? longestRequested : tab.preferredCoreWidth);
        }
        tab.coreWidth = tabWidth;
        accumulatedX = accumulatedX + tabWidth + self.spacerWidth;
    }
    
    return;
}


#pragma mark - event handlers

-(void)mouseDown:(NSEvent *)theEvent {
    
    NSInteger cnt = [theEvent clickCount];
    
    if ((cnt == 1) && (currentRollover)) {
        self.selectedTab = [self.tabs indexOfObject:currentRollover];
        [self setAllTabWidthsAndStartPos];
    }
}



#pragma mark - Action methods

-(void)rolloverEntered:(BSTTabViewTab *)rolloverTab{
    
    if ([rolloverTab isEqual:currentRollover]) {
        return;
    }
    
    currentRollover = rolloverTab;
    [self setNeedsDisplay:YES];

}



-(void)rolloverExited:(BSTTabViewTab *)rolloverTab{
    
    if (!currentRollover || ![rolloverTab isEqual:currentRollover]) {
        return;
    }
    currentRollover = nil;
    [self setNeedsDisplay:YES];

}



-(NSUInteger)addTabWithLabel:(NSString *)label {
    
    return [self addTabWithLabel:label atIndex:self.tabs.count];
}



-(NSUInteger)addTabWithLabel:(NSString *)label atIndex:(NSUInteger)requestedIndex{
    
    NSUInteger newIndex = ((requestedIndex > self.tabs.count) ? self.tabs.count : requestedIndex);

    BSTTabViewTab *tab = [[BSTTabViewTab alloc] initWithOwner:self];
    tab.label = label;
    tab.coreWidth = tab.preferredCoreWidth;
    [self.tabs insertObject:tab atIndex:newIndex];
    
    [self setAllTabWidthsAndStartPos];
    [self setNeedsDisplay:YES];
    return (newIndex);
}



-(BOOL)removeTabAtIndex:(NSUInteger)index {
    
    if (index >= self.tabs.count) {
        return NO;  // Invalid index
    }
    [self.tabs removeObjectAtIndex:index];
    [self setAllTabWidthsAndStartPos];
    
    [self setNeedsDisplay:YES];
    return YES;
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
    
    if (newIndex != index) {  // There will be a change
        BSTTabViewTab *tab = [self.tabs objectAtIndex:index];
        [self.tabs removeObjectAtIndex:index];
        [self.tabs insertObject:tab atIndex:newIndex];
        
        if (self.selectedTab == index) { // The selected tab is moving
            [self willChangeValueForKey:@"selectedTab"];  // Do key value calls without the setter to prevent delegate calls
            _selectedTab = newIndex;
            [self didChangeValueForKey:@"seletcedTab"];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(selectedTabChangedIndexTo:)]) {
                [self.delegate selectedTabChangedIndexTo:newIndex];
            }
        }
        
        [self setNeedsDisplay:YES];

    }

    return newIndex;
}


-(NSString *)labelForTabAtIndex:(NSUInteger)index{
    
    if (index >= self.tabs.count ) {
        return nil;
    }
    return [(BSTTabViewTab *)[self.tabs objectAtIndex:index] label];
}



-(BOOL)setLabel:(NSString *)label forTabAtIndex:(NSUInteger)index{
    
    if (index >= self.tabs.count) {
        return NO;
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(labelWillChangeTo:forTabAtIndex:)]) {
        if (![self.delegate labelWillChangeTo:label forTabAtIndex:index]) {
            return NO;  // Abort if delegate denies change
        }
    }
    BSTTabViewTab *tab = [self.tabs objectAtIndex:index];
    tab.label = label;
    
    [self setAllTabWidthsAndStartPos];
    [self setNeedsDisplay:YES];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(labelDidChangeForTabAtIndex:)]) {
        [self.delegate labelDidChangeForTabAtIndex:index];
    }
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




-(NSDictionary *)userInfoForTabAtIndex:(NSUInteger)index{
    
    if (index >= self.tabs.count ) {
        return nil;
    }
    return [(BSTTabViewTab *)[self.tabs objectAtIndex:index] userInfo];
}




-(BOOL)setUserInfo:(NSDictionary *)userInfo ForTabAtIndex:(NSUInteger)index{
 
    
    if (index >= self.tabs.count ) {
        return NO;
    }
    BSTTabViewTab *tab = [self.tabs objectAtIndex:index];
    tab.userInfo = userInfo;
    return YES;
}



@end
