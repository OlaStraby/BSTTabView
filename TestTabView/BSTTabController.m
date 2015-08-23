//
//  BSTTabController.m
//  TestTabView
//
//  Created by Familjen on 2015-08-22.
//  Copyright (c) 2015 Ola Straby. All rights reserved.
//

#import "BSTTabController.h"
#import "BSTMainWindowController.h"

@implementation BSTTabController

-(id)init {
    
    self = [super init];
 
    if (self) {
        _tag = @"Unnamed";
    }
    return self;

}


-(void)setTabView:(BSTTabView *)tabView {
    
    NSLog(@"Attaching tabView");
    
    if (tabView == _tabView) {
        return;
    }
    
    NSLog(@"Setting delegate etc.");

    _tabView = tabView;
    tabView.delegate = self;
    tabView.target = self;
    tabView.action = @selector(gotClick:);
    
    while (tabView.count > 0) {  // Remove all existing tabs
        [tabView removeTabAtIndex:0];
    }
    
     [self.tabView addTabWithLabel:@"+" tag:@"addKey"];  // Make a + tab
}


#pragma mark - TabView Delegate methods

-(BOOL)tabWithIndexWillBecomeSelected:(NSInteger)index{
    
    return YES;
}


-(void)tabWithIndexDidBecomeSelected:(NSInteger)index {
    
    
    NSLog(@"Tab no %li did become selected",index);
}


-(void)selectedTabChangedIndexTo:(NSInteger)index{
    
    NSLog(@"%@: Selected tab changed index to %li",self.tag, index);
}


-(BOOL)labelWillChangeTo:(NSString *)newLabel forTabAtIndex:(NSUInteger)index{
    
    return YES;
}


-(void)spaceIsInsufficientToDisplayAllTabs {
    
    NSLog(@"%@: Space is insufficient message received", self.tag);
}



-(BOOL)editingWillBeginForTabAtIndex:(NSUInteger)index {
    
    NSString *dict = [self.tabView tagForTabAtIndex:index];
    if (dict && [dict isEqualToString:@"addKey"]) {  // The + tab was clicked
        return NO;
    }
    return YES;
}


-(void)labelDidChangeForTabAtIndex:(NSUInteger)index {
    
    NSLog(@"%@: Label of tab %lu changed to %@",self.tag, index,[self.tabView labelForTabAtIndex:index] );
}


-(BOOL)draggingWillBeginForTabWithIndex:(NSUInteger)index {
    
    NSLog(@"%@: Dragging will begin for tab %ld",self.tag, (long)index);
    
    NSString *dict = [self.tabView tagForTabAtIndex:index];
    if (dict && [dict isEqualToString:@"addKey"]) {  // The + tab was clicked
        
        return NO;  // Dont drag + tab
    }
    return YES;
}

-(void)draggingFinishedForTabWithLabel:(NSString *)label tag:(NSString *)tag success:(BOOL)success{
    
    NSLog(@"%@: Dragging of %@ ended with %@",self.tag, label, (success ? @"success" : @"failure"));
}


-(BOOL)draggedTabWillBeInsertedAtIndex:(NSUInteger)index withLabel:(NSString *)label tag:(NSString *)tag sourceExternal:(BOOL)external {
    
    NSLog(@"%@: Dragged tab will be inserted at index %ld",self.tag, index);
    
    if (index == self.tabView.count) {  // last index
        NSLog(@"last - denied");
        return NO;
    }
    return YES;
}


#pragma mark - action methods


-(IBAction)gotClick:(id)sender {
    NSInteger clkTab =self.tabView.lastClickedTab;
    NSLog(@"%@: Got click action on tab %li clicks:%ld",self.tag, clkTab, (long)self.tabView.clickCount);
    [[(BSTMainWindowController *)self.owner box] setFillColor:self.tabView.selectedFieldColor];
    
    
    NSString *tabTag = [self.tabView tagForTabAtIndex:clkTab];
    if (tabTag && [tabTag isEqualToString:@"addKey"]) {  // The + tab was clicked
        
        
        NSUInteger i = [self.tabView addTabWithLabel:[NSString stringWithFormat:@"New%li",clkTab] tag:[NSString stringWithFormat:@"Hidden%li",clkTab] atIndex:clkTab];
//        [self.tabView setTag:[NSString stringWithFormat:@"Hidden%li",clkTab] ForTabAtIndex:i];
        [self.tabView setSelectedTab:i];  // Shift selection to new tab
    }
    
}




@end
