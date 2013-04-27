//
//  IRAppDelegate.m
//  irmapping
//
//  Created by Gary Preston on 25/04/2013.
//  Copyright (c) 2013 Gary Preston. All rights reserved.
//

#import "IRAppDelegate.h"

#import "iTunes.h"

#define IRiTunesNotificationStateChange @"com.apple.iTunes.playerInfo"

@interface IRAppDelegate()

@property (nonatomic, strong) iTunesApplication *iTunes;
@property (nonatomic, strong) NSSpeechSynthesizer *speechSynth;
@property (nonatomic, strong) NSStatusItem *statusItem;

@property (nonatomic, strong) iTunesTrack *trackToBeRated;
@property (nonatomic, assign) NSUInteger ratingToApply;

- (void)enableRemote;
- (void)disableRemote;
- (void)terminateApp:(id)sender;

- (void)iTunesTrackChange:(NSNotification *)notification;
@end

@implementation IRAppDelegate

//////////////////////////////////////////////////////////////////////////////
// Actions
//////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions

- (IBAction)quitApp:(id)sender
{
   [self terminateApp:sender];
}

- (IBAction)enableIR:(id)sender
{
   [self enableRemote];
}

- (IBAction)disableIR:(id)sender
{
   [self disableRemote];
}

//////////////////////////////////////////////////////////////////////////////
// Remote Delegate
//////////////////////////////////////////////////////////////////////////////
#pragma mark - Remote Delegate

- (void)hidRemote:(HIDRemote *)hidRemote eventWithButton:(HIDRemoteButtonCode)buttonCode isPressed:(BOOL)isPressed fromHardwareWithAttributes:(NSMutableDictionary *)attributes
{
   NSLog(@"%d %d, isPressed %@", hidRemote.lastSeenRemoteControlID, buttonCode, isPressed ? @"YES" : @"NO");
   
   if (! self.iTunes.isRunning)
      return;
   
   SInt32 remoteID = hidRemote.lastSeenRemoteControlID;
   
   // Stop FFwd/Rewind only if it's a held version been released.
   if (! isPressed && remoteID == 154 && (buttonCode == 65537 || buttonCode == 65538))
      [self.iTunes resume];

   if (! isPressed)
      return;
   
   // TODO: Add enum for remoteID/buttonCode and mapping for callbacks instead of hardcoding.
   
   // Standard Playback Controls
   if (remoteID == 151 && buttonCode == 6)
   {
      if (self.iTunes.playerState == iTunesEPlSFastForwarding || self.iTunes.playerState == iTunesEPlSRewinding)
         [self.iTunes resume];
      else if (self.iTunes.playerState != iTunesEPlSPlaying)
         [self.iTunes playpause];
   }
   else if (remoteID == 152 && buttonCode == 6)
   {
      if (self.iTunes.playerState == iTunesEPlSPlaying)
         [self.iTunes playpause];
   }
   else if (remoteID == 151 && buttonCode == 5)
      [self.iTunes stop];
   else if (remoteID == 160 && buttonCode == 1)
      [self.iTunes previousTrack];
   else if (remoteID == 160 && buttonCode == 2)
      [self.iTunes nextTrack];
   else if (remoteID == 154 && (buttonCode == 1 || buttonCode == 65537))
      [self.iTunes rewind];
   else if (remoteID == 154 && (buttonCode == 2 || buttonCode == 65538))
      [self.iTunes fastForward];
   
   // Song Ratings
   NSInteger rating = -1;
   
   if (remoteID == 151 && buttonCode >= 1 && buttonCode <= 4)
      rating = buttonCode * 20;
   else if (remoteID == 152 && buttonCode == 3)
      rating = 100;
   else if (remoteID == 154 && buttonCode == 4)
      rating = 0;

   if (rating != -1)
   {
      iTunesSource *lib = [self.iTunes.sources objectWithName:@"Library"];
      
      iTunesUserPlaylist *pl = [lib.userPlaylists objectWithName:self.iTunes.currentPlaylist.name];

      // Delay application of rating until track changes but only for smart playlists which could be live updating
      if (pl.exists && pl.smart && self.delayedRatingMenuItem.state == NSOnState)
      {
         self.trackToBeRated = [self.iTunes.currentTrack get];
         self.ratingToApply = rating;

         if (self.announceNewRatingMenuItem.state == NSOnState)
            [self.speechSynth startSpeakingString:[NSString stringWithFormat:@"%ld star, delayed", (long)rating/20]];
      }
      else
      {
         // No need to apply rating if it's already set to this value, however still inform user that it was set
         if (self.iTunes.currentTrack.ratingKind == iTunesERtKComputed || self.iTunes.currentTrack.rating != rating)
            self.iTunes.currentTrack.rating = rating;

         if (self.announceNewRatingMenuItem.state == NSOnState)
            [self.speechSynth startSpeakingString:[NSString stringWithFormat:@"%ld star", (long)self.iTunes.currentTrack.rating/20]];
      }
   }
   
   // "Say" the current rating
   if (remoteID == 153 && buttonCode == 1)
   {
      // Album rating is spoken if the current track has no rating set but has a user set album rating
      if (self.iTunes.currentTrack.ratingKind == iTunesERtKComputed && self.iTunes.currentTrack.albumRatingKind == iTunesERtKUser)
         [self.speechSynth startSpeakingString:[NSString stringWithFormat:@"Album rating, %ld star", (long)self.iTunes.currentTrack.albumRating/20]];
      else if (self.iTunes.currentTrack.ratingKind == iTunesERtKComputed || self.iTunes.currentTrack.rating == 0)
         [self.speechSynth startSpeakingString:@"No rating"];
      else
         [self.speechSynth startSpeakingString:[NSString stringWithFormat:@"%ld star", (long)self.iTunes.currentTrack.rating/20]];
   }
}

//////////////////////////////////////////////////////////////////////////////
// Application Delegate
//////////////////////////////////////////////////////////////////////////////
#pragma mark - Application Delegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
   _speechSynth = [[NSSpeechSynthesizer alloc] initWithVoice:nil];
   self.iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
   
   // TODO: Change this to a nice icon with greyed out version for disabled state
   self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
   [self.statusItem setMenu:self.statusMenu];
   [self.statusItem setTitle:@"Iris"];
   [self.statusItem setHighlightMode:YES];

   if ([HIDRemote isCandelairInstallationRequiredForRemoteMode:kHIDRemoteModeExclusive])
   {
      // Candelair needs to be installed. Inform the user about it.
      NSAlert *alert = [NSAlert alertWithMessageText:@"IR Communication failed."
                                       defaultButton:@"OK" alternateButton:nil otherButton:nil
                           informativeTextWithFormat:@"Unable to communicate with IR hardware. You may need to install Candelair."];
      [alert runModal];
      
      [self disableRemote];
   }
   else
      [self enableRemote];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
   [self disableRemote];
}

//////////////////////////////////////////////////////////////////////////////
// Notifications
//////////////////////////////////////////////////////////////////////////////
#pragma mark - Notifications

- (void)iTunesTrackChange:(NSNotification *)notification
{
   iTunesTrack *currentTrack = self.iTunes.currentTrack;
   iTunesTrack *oldTrack = [self.trackToBeRated get];

   // Finished playing the delayed rating track?
   if (oldTrack.exists && ! [oldTrack.persistentID isEqualToString:currentTrack.persistentID])
   {
      oldTrack.rating = self.ratingToApply;
      self.trackToBeRated = nil;
   }
   
   if (self.announceUnratedMenuItem.state == NSOnState && self.iTunes.playerState == iTunesEPlSPlaying &&
       (currentTrack.rating == 0 || currentTrack.ratingKind == iTunesERtKComputed))
      [self.speechSynth startSpeakingString:@"No rating"];
}

//////////////////////////////////////////////////////////////////////////////
// Private
//////////////////////////////////////////////////////////////////////////////
#pragma mark - Private

- (void)enableRemote
{
   if (! [[HIDRemote sharedHIDRemote] startRemoteControl:kHIDRemoteModeExclusive])
   {
      // Start failed
      NSAlert *alert = [NSAlert alertWithMessageText:@"IR Remote"
                                       defaultButton:@"OK" alternateButton:nil otherButton:nil
                           informativeTextWithFormat:@"Unable to start IR Remote in exclusive mode. Close all other IR apps then try again."];
      [alert runModal];
      
      [self.enableRemoteMenuItem setEnabled:TRUE];
      [self.disableRemoteMenuItem setEnabled:FALSE];
   }
   else
   {
      // Start using HIDRemote ..
      [[HIDRemote sharedHIDRemote] setDelegate:self];
      
      [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(iTunesTrackChange:) name:IRiTunesNotificationStateChange object:nil];
      
      [self.enableRemoteMenuItem setEnabled:FALSE];
      [self.disableRemoteMenuItem setEnabled:TRUE];
   }
}

- (void)disableRemote
{
   [[HIDRemote sharedHIDRemote] stopRemoteControl];
   [[HIDRemote sharedHIDRemote] setDelegate:nil];
   
   [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:IRiTunesNotificationStateChange object:nil];
   
   [self.enableRemoteMenuItem setEnabled:TRUE];
   [self.disableRemoteMenuItem setEnabled:FALSE];
}

- (void)terminateApp:(id)sender
{
   [[NSApplication sharedApplication] terminate:sender];
}

//////////////////////////////////////////////////////////////////////////////
@end
