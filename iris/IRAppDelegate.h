//
//  Iris - IR Remote music rating.
//  Copyright (C) 2013 Gary Preston
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, version 3 of the License.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
