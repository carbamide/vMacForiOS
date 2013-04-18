//
//  Constants.h
//  Mini vMac
//
//  Created by Josh on 2/24/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import "SYSDEPNS.h"
#import "MYOSGLUE.h"

typedef enum {
    settingsGroupMouse,
    settingsGroupSound,
    settingsGroupDisk,
    settingsGroupKeyboard,
    
    settingsGroupCount
} SettingsTableGroup;


typedef enum Direction {
    dirUp =     1 << 0,
    dirDown =   1 << 1,
    dirLeft =   1 << 2,
    dirRight =  1 << 3
} Direction;


extern NSInteger numInsertedDisks;
extern blnr SpeedStopped;
extern short *SurfaceScrnBuf;
extern short *pixelConversionTable;
extern id _gScreenView;
extern SEL _updateColorMode;
extern ui5b MacDateDiff;
extern ui5b CurEmulatedTime;

bool MySound_Init(void);
GLOBALPROC MySound_Start(void);
GLOBALPROC MySound_Stop(void);
GLOBALPROC MySound_BeginPlaying(void);
void runTick(CFRunLoopTimerRef timer, void *info);
void StartUpTimeAdjust(void);
#define kAppDelegate (AppDelegate *)[[UIApplication sharedApplication] delegate]

#define IPAD() (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#define kMacEpoch             2082844800
#define MyTickDuration        (1 / 60.14742)

//FIXME This is the dumbest thing I've ever seen.
#define DeviceScreenHeight (IPAD() == YES ? 1024 : 480);
#define DeviceScreenWidth (IPAD() == YES ? 768: 320);

#define PointDistanceSq(a, b) ((((int)a.h - (int)b.h) * ((int)a.h - (int)b.h)) + (((int)a.v - (int)b.v) * ((int)a.v - (int)b.v)))
#define CGPointCenter(a, b)   CGPointMake((a.x + b.x) / 2, (a.y + b.y) / 2)
#define MOUSE_DBLCLICK_TIME   0.55      // seconds, NSTimeInterval
#define MOUSE_CLICK_DELAY     0.05      // seconds, NSTimeInterval
#define TRACKPAD_CLICK_DELAY  0.30      // seconds, NSTimeInterval
#define TRACKPAD_CLICK_TIME   0.30      // if finger is held down for longer, it's not a click
#define TRACKPAD_DRAG_DELAY   0.50      // two fast taps to engage in draggnig
#define TRACKPAD_ACCEL_N      1
#define TRACKPAD_ACCEL_T      0.2
#define TRACKPAD_ACCEL_D      20
#define MOUSE_LOC_THRESHOLD   500       // pixel distance in mac screen, squared, integer
#define kScreenEdgeSize       20        // edge size for scrolling

#define kScreenRectFullScreen   (IPAD() == YES ? \
CGRectMake(0.f, 0.f, 1024.f, 768.f) : \
CGRectMake(0.f, 0.f, 480.f, 320.f))

#define kScreenRectRealSize     (IPAD() == YES ? \
CGRectMake((1024/2)-(vMacScreenWidth/2), (768/2)-(vMacScreenHeight/2), vMacScreenWidth, vMacScreenHeight) : \
CGRectMake(0.f, 0.f, vMacScreenWidth, vMacScreenHeight))


#undef ABS
#define ABS(x)           (((x) > 0) ? (x) : -(x))

#undef CLAMP
#define CLAMP(x, lo, hi) (((x) > (hi)) ? (hi) : (((x) < (lo)) ? (lo) : (x)))


#define InsertDiskViewAnimationDuration 0.3

#define InsertDiskViewFrameHidden           (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad == YES ? \
CGRectMake(1044.0, 0.0, 240.0, 768.0) : \
CGRectMake(500.0, 0.0, 240.0, 320.0))

#define InsertDiskViewFrameVisible          (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad == YES ? \
CGRectMake(1024.0-260.0, 0.0, 240.0, 768.0) : \
CGRectMake(240.0, 0.0, 240.0, 320.0))
#define kNavBarHeight 32
#define kSwipeThresholdHorizontal 100.0
#define kSwipeThresholdVertical   70.0
#define SettingsViewAnimationDuration     0.3

#define SettingsViewFrameHidden           (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad == YES ? CGRectMake(-260.0, 0.0, 240.0, 768.0) : CGRectMake(-260.0, 0.0, 240.0, 370.0))

#define SettingsViewFrameVisible          (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad == YES ? CGRectMake(0.0, 0.0, 20.0, 768.0) : CGRectMake(0.0, 0.0, 20.0, 370.0))
#define RomFileName "vMac.ROM"
