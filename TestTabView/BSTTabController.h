//
//  BSTTabController.h
//  TestTabView
//
//  Created by Familjen on 2015-08-22.
//  Copyright (c) 2015 Ola Straby. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BSTTabView.h"


@interface BSTTabController : NSObject<BSTTabViewDelegate>

@property (strong, readwrite, nonatomic) IBOutlet NSWindowController *owner;
@property (strong, readwrite, nonatomic) IBOutlet BSTTabView *tabView;
@property (strong, readwrite, nonatomic) NSString *tag;


-(IBAction)gotClick:(id)sender;  // Action method


@end
