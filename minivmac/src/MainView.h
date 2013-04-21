#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIEvent.h>
#import "AppDelegate.h"
#import "SurfaceView.h"
#import "InsertDiskView.h"
#import "KeyboardView.h"

@interface MainView : UIView

@property (strong, nonatomic) SurfaceView *screenView;
@property (strong, nonatomic) KeyboardView *keyboardView;
@property (strong, nonatomic) InsertDiskView *insertDiskView;
@property (strong, nonatomic) UITouch *mouseTouch;
@property (nonatomic) BOOL screenSizeToFit;
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

- (void)_createKeyboardView;
- (void)_createInsertDiskView;

- (Point)mouseLocForCGPoint:(CGPoint)point;
- (void)scheduleMouseClickAt:(Point)mouseLoc;
- (void)cancelMouseClick;
- (void)mouseClick;

- (void)twoFingerSwipeGesture:(id)sender;

@end