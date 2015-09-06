//
//  BSTMainWindowController.m
//  StockTracker
//
//  Created by Familjen on 2015-06-11.
//  Copyright (c) 2015 OlaStraby. All rights reserved.
//

#import "BSTMainWindowController.h"
#import "AppDelegate.h"
#import "BSTTabView.h"
#import "BSTTabController.h"

NSString const *BSTTabIdKey = @"BSTTABIDKEY";


@interface BSTMainWindowController ()

@property (strong,nonatomic,readwrite) IBOutlet NSBox *menuBox;

@property (strong,nonatomic,readwrite) IBOutlet BSTTabController* tc1;
@property (strong,nonatomic,readwrite) IBOutlet BSTTabController* tc2;
@property (strong,nonatomic,readwrite) IBOutlet NSMenu *popupMenu;

@end


@implementation BSTMainWindowController


#pragma mark - Lifetime methods


-(id)init {
    
    self = [super initWithWindowNibName:@"MainWindow"];
    
    if(self) {  // Local bootstrapping
        
    }
    
    return self;
}



-(id)initWithWindowNibName:(NSString *)windowNibName {  // Overridden to ensure not initialised with wrong nib
    
    return [self init];
}


- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.tc1.tag = @"Upper TC";
    self.tc1.tabView.maxTabHeight = 20;
    self.tc1.tabView.doubleClickEditEnabled = YES;
    self.tc1.tabView.spacerWidth = 10;
    self.tc1.tabView.tabCornerRadius = 3;
    self.tc1.tabView.userTabDraggingEnabled = BSTTabViewDragLocal;
//    self.tc1.tabView.editingColor = [NSColor redColor];
    
    self.tc2.tag = @"Lower TC";
    self.tc2.tabView.topEdgeAligned = NO;
    self.tc2.tabView.maxTabHeight = 25;
    self.tc2.tabView.rolloverEnabled = NO;
    self.tc2.tabView.spacerWidth = 2;
    self.tc2.tabView.tabCornerRadius = 2;
    self.tc2.tabView.userTabDraggingEnabled = BSTTabViewDragLocal;
    self.tc2.tabView.selectedFieldColor = [NSColor whiteColor];
    self.tc2.tabView.selectedBorderColor = [NSColor whiteColor];
    self.tc2.tabView.selectedTextColor = [NSColor darkGrayColor];
    self.tc2.tabView.backgroundColor = [NSColor blueColor];
    self.tc2.tabView.borderColor= [NSColor whiteColor];
    self.tc2.tabView.textColor = [NSColor whiteColor];

    self.tc2.tabView.editingColor = [NSColor blueColor];
}


-(IBAction)tellTab:(id)sender{
    
    NSInteger i = [self.tc1.tabView indexForRolloverTab];
    BSTTabController *ctc = self.tc1;
    
    if (i == -1) {  // Try other
         i = [self.tc2.tabView indexForRolloverTab];
         ctc = self.tc2;
    }
    
    if (i>=0) {
        NSLog(@"Tab is %ld in %@",(long)i, ctc.tag);
        
    } else {
        NSLog(@"No tab is selected");
    }
}


-(IBAction)removeTab:(id)sender{
    
    NSInteger i = [self.tc1.tabView indexForRolloverTab];
    BSTTabController *ctc = self.tc1;
    
    if (i == -1) {  // Try other
        i = [self.tc2.tabView indexForRolloverTab];
        ctc = self.tc2;
    }
    
    if (i>=0 && (![[ctc.tabView tagForTabAtIndex:i] isEqualToString:@"addKey"])) {
        [ctc.tabView removeTabAtIndex:i];
    }
}



@end
