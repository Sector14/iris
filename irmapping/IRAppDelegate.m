//
//  IRAppDelegate.m
//  irmapping
//
//  Created by Gary Preston on 25/04/2013.
//  Copyright (c) 2013 Gary Preston. All rights reserved.
//

#import "IRAppDelegate.h"

#import "iTunes.h"

@interface IRAppDelegate()
@property (nonatomic, strong) iTunesApplication *iTunes;
@property (nonatomic, strong) NSSpeechSynthesizer *speechSynth;
@end

@implementation IRAppDelegate

//////////////////////////////////////////////////////////////////////////////
// Remote Delegate
//////////////////////////////////////////////////////////////////////////////
#pragma mark - Remote Delegate

- (void)hidRemote:(HIDRemote *)hidRemote eventWithButton:(HIDRemoteButtonCode)buttonCode isPressed:(BOOL)isPressed fromHardwareWithAttributes:(NSMutableDictionary *)attributes
{
	// NSLog(@"Button with code %d/%d %@", (int)hidRemote.lastSeenRemoteControlID, buttonCode, (isPressed ? @"pressed" : @"released"));
   
   if (!self.iTunes.isRunning || !isPressed)
      return;
   
   SInt32 remoteID = hidRemote.lastSeenRemoteControlID;
   
   // TODO: Add enum for remoteID/buttonCode and mapping for callbacks instead of hardcoding.
   // Standard Playback Controls
   if ((remoteID == 151 || remoteID == 152) && buttonCode == 6)
      [self.iTunes playpause];
   else if (remoteID == 151 && buttonCode == 5)
      [self.iTunes stop];
   else if (remoteID == 160 && buttonCode == 1)
      [self.iTunes previousTrack];
   else if (remoteID == 160 && buttonCode == 2)
      [self.iTunes nextTrack];
   else if (remoteID == 154 && buttonCode == 1)
      [self.iTunes rewind];
   else if (remoteID == 154 && buttonCode == 2)
      [self.iTunes fastForward];
   
   // Song Ratings
   NSInteger rating = -1;
   
   if (remoteID == 151 && buttonCode >= 1 && buttonCode <= 4)
      rating = buttonCode * 20;
   else if (remoteID == 152 && buttonCode == 3)
      rating = 100;
   else if (remoteID == 154 && buttonCode == 4)
      rating = 0;
   
   if (rating != -1 && self.iTunes.currentTrack.rating != rating)
   {
      // NSLog(@"Changing rating of %@ from %ld to %ld", self.iTunes.currentTrack.name, (long)self.iTunes.currentTrack.rating, (unsigned long)rating);
      
      // TODO: As some smart playlists with live updating can cause a currently playing song to be skipped/removed
      // from the list when the rating changes, rating changes will be cached until the track has finished playing.      
      self.iTunes.currentTrack.rating = rating;

      [self.speechSynth startSpeakingString:[NSString stringWithFormat:@"%ld star", (long)self.iTunes.currentTrack.rating/20]];
   }
   
   // Gimiky speech
   if (remoteID == 153 && buttonCode == 1)
      [self.speechSynth startSpeakingString:[NSString stringWithFormat:@"%ld star", (long)self.iTunes.currentTrack.rating/20]];
}

//////////////////////////////////////////////////////////////////////////////
// Application
//////////////////////////////////////////////////////////////////////////////
#pragma mark - Application

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
   _speechSynth = [[NSSpeechSynthesizer alloc] initWithVoice:nil];
   self.iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
   
   if (! [self.iTunes isRunning])
   {
      NSAlert *alert = [NSAlert alertWithMessageText:@"iTunes not available."
                                       defaultButton:@"OK" alternateButton:nil otherButton:nil
                           informativeTextWithFormat:@"iTunes is not running"];
      [alert runModal];
      
      return;
   }
   
   // proof of concept test code.
   if ([HIDRemote isCandelairInstallationRequiredForRemoteMode:kHIDRemoteModeExclusive])
   {
      // Candelair needs to be installed. Inform the user about it.
      NSAlert *alert = [NSAlert alertWithMessageText:@"IR Communication failed."
                                       defaultButton:@"OK" alternateButton:nil otherButton:nil
                           informativeTextWithFormat:@"Unable to communicate with IR hardware, your OS version may require Candelair installing."];
      [alert runModal];
      
   }
   else
   {
      // Start using HIDRemote ..
      [[HIDRemote sharedHIDRemote] setDelegate:self];

      if (! [[HIDRemote sharedHIDRemote] startRemoteControl:kHIDRemoteModeExclusive])
      {
         // Start failed
         NSAlert *alert = [NSAlert alertWithMessageText:@"IR Remote"
                                          defaultButton:@"OK" alternateButton:nil otherButton:nil
                              informativeTextWithFormat:@"Unable to start IR Remote in exclusive mode. Close all other IR apps?"];
         [alert runModal];
      }
   }
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
   [[HIDRemote sharedHIDRemote] stopRemoteControl];
}

//////////////////////////////////////////////////////////////////////////////

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
   return YES;
}

//////////////////////////////////////////////////////////////////////////////
@end
