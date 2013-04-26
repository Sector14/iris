//
//  IRAppDelegate.h
//  irmapping
//
//  Created by Gary Preston on 25/04/2013.
//  Copyright (c) 2013 Gary Preston. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "HIDRemote/HIDRemote.h"

@interface IRAppDelegate : NSObject <NSApplicationDelegate, HIDRemoteDelegate>

@property (assign) IBOutlet NSWindow *window;

@end
