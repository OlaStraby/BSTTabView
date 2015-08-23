//
//  BSTTabViewTab.m
//  TestTabView
//
//  Created by Familjen on 2015-08-09.
//  Copyright (c) 2015 Ola Straby. All rights reserved.
//

#import "BSTTabViewTab.h"
#import "BSTTabView+Private.h"




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
    currentTabHt = -1; // This is a trick to enforce regen of the curve on the call to setCoreWidth, which is aclled after setStartX by the space allocation procedure. Thus two curve generations are avoided
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


