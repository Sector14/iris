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
@property (assign) IBOutlet NSMenu *statusMenu;
@property (weak) IBOutlet NSMenuItem *enableRemoteMenuItem;
@property (weak) IBOutlet NSMenuItem *disableRemoteMenuItem;

@property (weak) IBOutlet NSMenuItem *announceNewRatingMenuItem;
@property (weak) IBOutlet NSMenuItem *announceUnratedMenuItem;
@property (weak) IBOutlet NSMenuItem *delayedRatingMenuItem;

- (IBAction)quitApp:(id)sender;
- (IBAction)enableIR:(id)sender;
- (IBAction)disableIR:(id)sender;

- (IBAction)toggleAnnounceNewRating:(NSMenuItem *)sender;
- (IBAction)toggleAnnounceUnrated:(NSMenuItem *)sender;
- (IBAction)toggleDelayedRating:(NSMenuItem *)sender;

@end
