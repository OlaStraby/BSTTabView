//
//  BSTMainWindowController.h
//  StockTracker
//
//  Created by Familjen on 2015-06-11.
//  Copyright (c) 2015 OlaStraby. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BSTMainWindowController : NSWindowController

-(IBAction)tellTab:(id)sender;   // Responder to menu actions
-(IBAction)removeTab:(id)sender; // Responder to menu actions

@property (strong, nonatomic) IBOutlet NSBox* box;

@end
