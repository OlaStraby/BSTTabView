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

@interface BSTMainWindowController ()<BSTTabViewDelegate>

@property (strong,nonatomic,readwrite) IBOutlet NSBox *menuBox;
@property (strong,nonatomic,readwrite) IBOutlet BSTTabView *tabView;



-(IBAction)segmentButtonClick:(id)sender;


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
    
    self.tabView.delegate = self;
    self.tabView.topEdge = YES;
    
    [self.tabView addTabWithLabel:@"Test1"];
    [self.tabView addTabWithLabel:@"Test2 testetet"];
    [self.tabView addTabWithLabel:@"Test3 testetet"];
    [self.tabView addTabWithLabel:@"Test4 testetet"];
    [self.tabView addTabWithLabel:@"Test5 testetet"];
    [self.tabView addTabWithLabel:@"Test6 testetet"];
    [self.tabView addTabWithLabel:@"Test7 testetet"];


    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


#pragma mark - TabView Delegate methdos

-(void)spaceIsInsufficientToDisplayAllTabs {
    
    NSLog(@"Space is insufficient message received");
}



#pragma mark - Action methods

-(IBAction)segmentButtonClick:(id)sender{
    
    NSSegmentedControl *ctrl = (NSSegmentedControl *)sender;
    
    switch (ctrl.selectedSegment) {
        case 0:
            NSLog(@"Option 0 called");
            break;
            
        case 1:
            NSLog(@"Option 1 called");
            break;
        case 2:
            NSLog(@"Option 2 called");
            break;
        case 3:
            NSLog(@"Option 3 called");
            break;
        default:
            break;
    }
}


@end
