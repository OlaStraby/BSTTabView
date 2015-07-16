//
//  AppDelegate.m
//  TestTabView
//
//  Created by Ola Straby on 2015-07-15.
//  Copyright (c) 2015 Ola Straby. All rights reserved.
//

#import "AppDelegate.h"
#import "BSTMainWindowController.h"


@interface AppDelegate ()

@property (strong, nonatomic, readonly) BSTMainWindowController *mainWindow;

@end




@implementation AppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    _mainWindow = [[BSTMainWindowController alloc] init];
    [self.mainWindow showWindow:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
