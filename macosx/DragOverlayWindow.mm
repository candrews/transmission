// This file Copyright © 2007-2022 Transmission authors and contributors.
// It may be used under the MIT (SPDX: MIT) license.
// License text can be found in the licenses/ folder.

#import "DragOverlayWindow.h"
#import "DragOverlayView.h"
#import "NSStringAdditions.h"

#include <libtransmission/transmission.h>
#include <libtransmission/torrent-metainfo.h>

@interface DragOverlayWindow ()

- (void)resizeWindow;

@end

@implementation DragOverlayWindow

- (instancetype)initWithLib:(tr_session*)lib forWindow:(NSWindow*)window
{
    if ((self = ([super initWithContentRect:window.frame
                                  styleMask:NSWindowStyleMaskBorderless
                                    backing:NSBackingStoreBuffered
                                      defer:NO])))
    {
        fLib = lib;

        self.backgroundColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.5];
        self.alphaValue = 0.0;
        self.opaque = NO;
        self.hasShadow = NO;

        DragOverlayView* view = [[DragOverlayView alloc] initWithFrame:self.frame];
        self.contentView = view;

        self.releasedWhenClosed = NO;
        self.ignoresMouseEvents = YES;

        fFadeInAnimation = [[NSViewAnimation alloc] initWithViewAnimations:@[
            @{ NSViewAnimationTargetKey : self, NSViewAnimationEffectKey : NSViewAnimationFadeInEffect }
        ]];
        fFadeInAnimation.duration = 0.15;
        fFadeInAnimation.animationBlockingMode = NSAnimationNonblockingThreaded;

        fFadeOutAnimation = [[NSViewAnimation alloc] initWithViewAnimations:@[
            @{ NSViewAnimationTargetKey : self, NSViewAnimationEffectKey : NSViewAnimationFadeOutEffect }
        ]];
        fFadeOutAnimation.duration = 0.5;
        fFadeOutAnimation.animationBlockingMode = NSAnimationNonblockingThreaded;

        [window addChildWindow:self ordered:NSWindowAbove];

        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(resizeWindow) name:NSWindowDidResizeNotification
                                                 object:window];
    }
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)setTorrents:(NSArray*)files
{
    uint64_t size = 0;
    NSInteger count = 0;

    NSString* name;
    NSInteger fileCount = 0;

    for (NSString* file in files)
    {
        if ([[NSWorkspace.sharedWorkspace typeOfFile:file error:NULL] isEqualToString:@"org.bittorrent.torrent"] ||
            [file.pathExtension caseInsensitiveCompare:@"torrent"] == NSOrderedSame)
        {
            auto metainfo = tr_torrent_metainfo{};
            if (metainfo.parseTorrentFile(file.UTF8String))
            {
                ++count;

                size += metainfo.totalSize();

                auto const n_files = metainfo.fileCount();
                fileCount += n_files;
                if (n_files == 1)
                {
                    name = @(metainfo.name().c_str());
                }
            }
        }
    }

    if (count <= 0)
    {
        return;
    }

    //set strings and icon
    NSString* secondString = [NSString stringForFileSize:size];
    if (count > 1)
    {
        NSString* fileString;
        if (fileCount == 1)
        {
            fileString = NSLocalizedString(@"1 file", "Drag overlay -> torrents");
        }
        else
        {
            fileString = [NSString stringWithFormat:NSLocalizedString(@"%@ files", "Drag overlay -> torrents"),
                                                    [NSString formattedUInteger:fileCount]];
        }
        secondString = [NSString stringWithFormat:@"%@, %@", fileString, secondString];
    }

    NSImage* icon;
    if (count == 1)
    {
        icon = [NSWorkspace.sharedWorkspace iconForFileType:name ? name.pathExtension : NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
    }
    else
    {
        name = [NSString stringWithFormat:NSLocalizedString(@"%@ Torrent Files", "Drag overlay -> torrents"),
                                          [NSString formattedUInteger:count]];
        secondString = [secondString stringByAppendingString:@" total"];
        icon = [NSImage imageNamed:@"TransmissionDocument.icns"];
    }

    [self.contentView setOverlay:icon mainLine:name subLine:secondString];
    [self fadeIn];
}

- (void)setFile:(NSString*)file
{
    [self.contentView setOverlay:[NSImage imageNamed:@"CreateLarge"]
                        mainLine:NSLocalizedString(@"Create a Torrent File", "Drag overlay -> file")
                         subLine:file];
    [self fadeIn];
}

- (void)setURL:(NSString*)url
{
    [self.contentView setOverlay:[NSImage imageNamed:@"Globe"] mainLine:NSLocalizedString(@"Web Address", "Drag overlay -> url")
                         subLine:url];
    [self fadeIn];
}

- (void)fadeIn
{
    //stop other animation and set to same progress
    if (fFadeOutAnimation.animating)
    {
        [fFadeOutAnimation stopAnimation];
        fFadeInAnimation.currentProgress = 1.0 - fFadeOutAnimation.currentProgress;
    }
    [fFadeInAnimation startAnimation];
}

- (void)fadeOut
{
    //stop other animation and set to same progress
    if (fFadeInAnimation.animating)
    {
        [fFadeInAnimation stopAnimation];
        fFadeOutAnimation.currentProgress = 1.0 - fFadeInAnimation.currentProgress;
    }
    if (self.alphaValue > 0.0)
    {
        [fFadeOutAnimation startAnimation];
    }
}

- (void)resizeWindow
{
    [self setFrame:self.parentWindow.frame display:NO];
}

@end
