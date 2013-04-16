#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIEvent.h>
#import "AppDelegate.h"
#import "SurfaceView.h"
#import "InsertDiskView.h"
#import "SettingsView.h"
#import "KeyboardView.h"

@interface MainView : UIView

@property (strong, nonatomic) SurfaceView *screenView;
@property (strong, nonatomic) KeyboardView *keyboardView;
@property (strong, nonatomic) InsertDiskView *insertDiskView;
@property (strong, nonatomic) SettingsView *settingsView;
@property (strong, nonatomic) UITouch *mouseTouch;
@property (nonatomic) Direction screenPosition;
@property (nonatomic) BOOL screenSizeToFit;
@property (nonatomic) BOOL trackpadMode;
@property (nonatomic) BOOL trackpadClick;
@property (nonatomic) BOOL clickScheduled;
@property (nonatomic) BOOL mouseDrag;
@property (nonatomic) BOOL inGesture;

@property (nonatomic) Point clickLoc;
@property (nonatomic) Point lastMouseLoc;
@property (nonatomic) Point mouseOffset;

@property (nonatomic) NSTimeInterval lastMouseTime;
@property (nonatomic) NSTimeInterval lastMouseClick;
@property (nonatomic) CGPoint gestureStart;

- (void)didChangePreferences:(NSNotification *)aNotification;
- (void)_createKeyboardView;
- (void)_createInsertDiskView;
- (void)_createSettingsView;

- (Point)mouseLocForCGPoint:(CGPoint)point;
- (void)scheduleMouseClickAt:(Point)mouseLoc;
- (void)cancelMouseClick;
- (void)mouseClick;

- (void)toggleScreenSize;
- (void)scrollScreenViewTo:(Direction)scroll;

- (void)twoFingerSwipeGesture:(id)sender;
- (void)twoFingerTapGesture:(UIEvent *)event;

@end