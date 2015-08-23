//
//  BSTTabViewTab.h
//  TestTabView
//
//  Created by Familjen on 2015-08-09.
//  Copyright (c) 2015 Ola Straby. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class BSTTabView;


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
