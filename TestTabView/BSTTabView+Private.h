//
//  BSTTabView+Private.h
//  TestTabView
//
//  Created by Familjen on 2015-08-09.
//  Copyright (c) 2015 Ola Straby. All rights reserved.
//

/*
 * This is the private class extension for BSTTabView that contains class interface only used by the
 * BSTTabViewTab helperclass
 */

#import "BSTTabview.h"
@class BSTTabViewTab;

#ifndef TestTabView_BSTTabView_Private_h
#define TestTabView_BSTTabView_Private_h

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


#endif
