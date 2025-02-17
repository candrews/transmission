// This file Copyright © 2011-2022 Transmission authors and contributors.
// It may be used under the MIT (SPDX: MIT) license.
// License text can be found in the licenses/ folder.

#import "GlobalOptionsPopoverViewController.h"

@implementation GlobalOptionsPopoverViewController

- (instancetype)initWithHandle:(tr_session*)handle
{
    if ((self = [super initWithNibName:@"GlobalOptionsPopover" bundle:nil]))
    {
        fHandle = handle;

        fDefaults = NSUserDefaults.standardUserDefaults;
    }

    return self;
}

- (void)awakeFromNib
{
    fUploadLimitField.intValue = [fDefaults integerForKey:@"UploadLimit"];
    fDownloadLimitField.intValue = [fDefaults integerForKey:@"DownloadLimit"];

    fRatioStopField.floatValue = [fDefaults floatForKey:@"RatioLimit"];
    fIdleStopField.integerValue = [fDefaults integerForKey:@"IdleLimitMinutes"];

    [self.view setFrameSize:self.view.fittingSize];
}

- (IBAction)updatedDisplayString:(id)sender
{
    [NSNotificationCenter.defaultCenter postNotificationName:@"RefreshTorrentTable" object:nil];
}

- (IBAction)setDownSpeedSetting:(id)sender
{
    tr_sessionLimitSpeed(fHandle, TR_DOWN, [fDefaults boolForKey:@"CheckDownload"]);

    [NSNotificationCenter.defaultCenter postNotificationName:@"SpeedLimitUpdate" object:nil];
}

- (IBAction)setDownSpeedLimit:(id)sender
{
    NSInteger const limit = [sender integerValue];
    [fDefaults setInteger:limit forKey:@"DownloadLimit"];
    tr_sessionSetSpeedLimit_KBps(fHandle, TR_DOWN, limit);

    [NSNotificationCenter.defaultCenter postNotificationName:@"UpdateSpeedLimitValuesOutsidePrefs" object:nil];
    [NSNotificationCenter.defaultCenter postNotificationName:@"SpeedLimitUpdate" object:nil];
}

- (IBAction)setUpSpeedSetting:(id)sender
{
    tr_sessionLimitSpeed(fHandle, TR_UP, [fDefaults boolForKey:@"CheckUpload"]);

    [NSNotificationCenter.defaultCenter postNotificationName:@"UpdateSpeedLimitValuesOutsidePrefs" object:nil];
    [NSNotificationCenter.defaultCenter postNotificationName:@"SpeedLimitUpdate" object:nil];
}

- (IBAction)setUpSpeedLimit:(id)sender
{
    NSInteger const limit = [sender integerValue];
    [fDefaults setInteger:limit forKey:@"UploadLimit"];
    tr_sessionSetSpeedLimit_KBps(fHandle, TR_UP, limit);

    [NSNotificationCenter.defaultCenter postNotificationName:@"SpeedLimitUpdate" object:nil];
}

- (IBAction)setRatioStopSetting:(id)sender
{
    tr_sessionSetRatioLimited(fHandle, [fDefaults boolForKey:@"RatioCheck"]);

    //reload main table for seeding progress
    [NSNotificationCenter.defaultCenter postNotificationName:@"UpdateUI" object:nil];

    //reload global settings in inspector
    [NSNotificationCenter.defaultCenter postNotificationName:@"UpdateGlobalOptions" object:nil];
}

- (IBAction)setRatioStopLimit:(id)sender
{
    CGFloat const value = [sender floatValue];
    [fDefaults setFloat:value forKey:@"RatioLimit"];
    tr_sessionSetRatioLimit(fHandle, value);

    [NSNotificationCenter.defaultCenter postNotificationName:@"UpdateRatioStopValueOutsidePrefs" object:nil];

    //reload main table for seeding progress
    [NSNotificationCenter.defaultCenter postNotificationName:@"UpdateUI" object:nil];

    //reload global settings in inspector
    [NSNotificationCenter.defaultCenter postNotificationName:@"UpdateGlobalOptions" object:nil];
}

- (IBAction)setIdleStopSetting:(id)sender
{
    tr_sessionSetIdleLimited(fHandle, [fDefaults boolForKey:@"IdleLimitCheck"]);

    //reload main table for remaining seeding time
    [NSNotificationCenter.defaultCenter postNotificationName:@"UpdateUI" object:nil];

    //reload global settings in inspector
    [NSNotificationCenter.defaultCenter postNotificationName:@"UpdateGlobalOptions" object:nil];
}

- (IBAction)setIdleStopLimit:(id)sender
{
    NSInteger const value = [sender integerValue];
    [fDefaults setInteger:value forKey:@"IdleLimitMinutes"];
    tr_sessionSetIdleLimit(fHandle, value);

    [NSNotificationCenter.defaultCenter postNotificationName:@"UpdateIdleStopValueOutsidePrefs" object:nil];

    //reload main table for remaining seeding time
    [NSNotificationCenter.defaultCenter postNotificationName:@"UpdateUI" object:nil];

    //reload global settings in inspector
    [NSNotificationCenter.defaultCenter postNotificationName:@"UpdateGlobalOptions" object:nil];
}

- (BOOL)control:(NSControl*)control textShouldBeginEditing:(NSText*)fieldEditor
{
    fInitialString = control.stringValue;

    return YES;
}

- (BOOL)control:(NSControl*)control didFailToFormatString:(NSString*)string errorDescription:(NSString*)error
{
    NSBeep();
    if (fInitialString)
    {
        control.stringValue = fInitialString;
        fInitialString = nil;
    }
    return NO;
}

@end
