//
//  EmulationManager.m
//  Mini vMac
//
//  Created by Josh on 3/2/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import "EmulationManager.h"
#import "Constants.h"
#import "VirtualDiskDriveController.h"
#import "MYOSGLUE.h"

@interface EmulationManager ()
@property (strong, nonatomic) NSData *romData;
@property (nonatomic) CFRunLoopTimerRef tickTimer;
@end

IMPORTFUNC blnr InitEmulation(void);

@implementation EmulationManager

+ (id)sharedManager
{
    static EmulationManager *emulationManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        emulationManager = [[self alloc] init];
    });
    
    return emulationManager;
}

- (id)init
{
    if (self = [super init]) {
        
    }
    
    return self;
}

- (BOOL)loadROM
{
    NSString *romPath = nil;
    NSString *romFileName = @RomFileName;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSArray *romSearchPaths = [[Helpers sharedInstance] searchPaths];
    
    for (NSString *p in romSearchPaths) {
        romPath = [p stringByAppendingPathComponent:romFileName];
        
        if ([fm isReadableFileAtPath:romPath]) {
            break;
        }
    }
    
    _romData = [NSData dataWithContentsOfFile:romPath];
    
    if (_romData == nil) {
        [[Helpers sharedInstance] warnMessage:[NSString stringWithFormat:@"Unable to load vMac.ROM from the Documents folder. Please transfer vMac.ROM using iTunes file sharing."]];
        
        return NO;
    }
    
    NSUInteger len = [_romData length];
    
    ROM = (ui3b *)malloc(len);
    
    memcpy(ROM, [_romData bytes], kROM_Size);
    
    return YES;
}

- (BOOL)initEmulation
{
    if (AllocMyMemory()) {
        if (![self loadROM]) {
            return NO;
        }
    }
    
    pixelConversionTable = malloc(sizeof(short) * 8 * 256);
    
    for (int i = 0; i < 256; i++) {
        for (int j = 0; j < 8; j++) {
            pixelConversionTable[8 * i + j] = ((i & (0x80 >> j)) ? 0x0000 : 0xFFFF);
        }
    }
    
    NSTimeZone *ntz = [NSTimeZone localTimeZone];
    
    CurMacDelta = [ntz secondsFromGMT]/3600;
    
    MacDateDiff = kMacEpoch + [ntz secondsFromGMT];
    
    CurMacDateInSeconds = time(NULL) + MacDateDiff;
    
    if (![[VirtualDiskDriveController sharedInstance] initDrives]) {
        [[Helpers sharedInstance] warnMessage:NSLocalizedString(@"WarnNoDrives", nil)];
        
        return NO;
    }
    
#if MySoundEnabled
    if (!MySound_Init()) {
        [[Helpers sharedInstance] warnMessage:NSLocalizedString(@"WarnNoSound", nil)];
    }
#endif
    
    // init emulation
    if (!InitEmulation()) {
        [[Helpers sharedInstance] warnMessage:NSLocalizedString(@"WarnNoEmu", nil)];
        
        return NO;
    }
    
    return YES;
}

- (void)startEmulation:(id)sender
{
    [self resumeEmulation];
}

- (void)resumeEmulation
{
    StartUpTimeAdjust();
    
    SpeedStopped = falseblnr;
    
    CFRunLoopTimerContext tCtx = { 0, NULL, NULL, NULL, NULL };
    
    _tickTimer = CFRunLoopTimerCreate(kCFAllocatorDefault, 0, MyTickDuration, 0, 0, runTick, &tCtx);
    
    CFRunLoopAddTimer(CFRunLoopGetMain(), _tickTimer, kCFRunLoopCommonModes);
}

- (void)suspendEmulation
{
#if MySoundEnabled
    MySound_Stop();
#endif
    SpeedStopped = trueblnr;
    
    CFRunLoopRemoveTimer(CFRunLoopGetMain(), _tickTimer, kCFRunLoopCommonModes);
}


- (void)vKeyDown:(int)key
{
    if (key >= 0 && key < 128) {
        Keyboard_UpdateKeyMap3(key, trueblnr);
    }
}

- (void)vKeyUp:(int)key
{
    if (key >= 0 && key < 128) {
        Keyboard_UpdateKeyMap3(key, falseblnr);
    }
}

- (NSDictionary *)availableKeyboardLayouts
{
    NSMutableDictionary *layouts = [NSMutableDictionary dictionaryWithCapacity:5];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSArray *sources = [[Helpers sharedInstance] searchPaths];
    NSArray *extensions = @[@"kbdlayout"];
    
    for (NSString *dir in sources) {
        NSArray *files = [[fm contentsOfDirectoryAtPath:dir error:NULL] pathsMatchingExtensions:extensions];
        
        for (NSString *file in files) {
            NSString *layoutID = [file stringByDeletingPathExtension];
            
            NSDictionary *kbFile = [NSDictionary dictionaryWithContentsOfFile:[dir stringByAppendingPathComponent:file]];
            
            id layoutName = kbFile[@"Name"];
            
            if ([layoutName isKindOfClass:[NSDictionary class]]) {
                NSString *localization = [[NSBundle mainBundle] preferredLocalizations][0];
                NSString *localizedLayoutName = layoutName[localization];
                
                if (localizedLayoutName == nil) localizedLayoutName = layoutName[@"English"];
                
                layouts[layoutID] = localizedLayoutName;
            }
            else {
                layouts[layoutID] = layoutName;
            }
        }
    }
    
    return [NSDictionary dictionaryWithDictionary:layouts];
}

@end
