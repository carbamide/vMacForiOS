#import "MainView.h"
#import "PROGMAIN.h"
#import "VirtualDiskDriveController.h"
#import "VirtualMouseController.h"
#import "EmulationManager.h"

@interface MainView ()
@property (nonatomic) CGFloat initialTouchPositionX;
@property (nonatomic) CGFloat initialHoizontalCenter;

@end
@implementation MainView

- (id)initWithFrame:(CGRect)rect
{
    if (self = [super initWithFrame:rect]) {
        [self didChangePreferences:nil];
        [self setMultipleTouchEnabled:YES];
        
        CGRect screenRect = kScreenRectFullScreen;
        
        _screenView = [[SurfaceView alloc] initWithFrame:screenRect pixelFormat:kPixelFormat565L surfaceSize:CGSizeMake(vMacScreenWidth, vMacScreenHeight) scalingFilter:kCAFilterLinear];
        
        [self addSubview:_screenView];
        
        [_screenView setUserInteractionEnabled:NO];
        
        _gScreenView = _screenView;
        
        _updateColorMode = NSSelectorFromString(@"useColorMode:");
        
        SurfaceScrnBuf = [_screenView pixels];
        
        _screenSizeToFit = YES;
        _screenPosition = [[NSUserDefaults standardUserDefaults] integerForKey:@"ScreenPosition"];
        
        [self scrollScreenViewTo:_screenPosition];
        
        _keyboardView = nil;
        
        [self _createInsertDiskView];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangePreferences:) name:NSUserDefaultsDidChangeNotification object:nil];
        
        UISwipeGestureRecognizer *up = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(twoFingerSwipeGesture:)];
        UISwipeGestureRecognizer *down = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(twoFingerSwipeGesture:)];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizer:)];
        
        [up setNumberOfTouchesRequired:2];
        [up setDirection:UISwipeGestureRecognizerDirectionUp];
        [up setCancelsTouchesInView:NO];
        
        [down setNumberOfTouchesRequired:2];
        [down setDirection:UISwipeGestureRecognizerDirectionDown];
        [down setCancelsTouchesInView:NO];
        
        [pan requireGestureRecognizerToFail:up];
        [pan requireGestureRecognizerToFail:down];

        [pan setMinimumNumberOfTouches:2];
        [pan setMaximumNumberOfTouches:2];
        [pan setCancelsTouchesInView:NO];
        
        [self addGestureRecognizer:up];
        [self addGestureRecognizer:down];
        [self addGestureRecognizer:pan];
        
    }
    
    return self;
}

- (void)didChangePreferences:(NSNotification *)aNotification
{
    _trackpadMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"TrackpadMode"];
}

- (void)_createKeyboardView
{
    if (_keyboardView) {
        return;
    }
    
    _keyboardView = [[KeyboardView alloc] initWithFrame:KeyboardViewFrameHidden];
    [_keyboardView setSearchPaths:[[Helpers sharedInstance] searchPaths]];
    [_keyboardView setLayout:[[NSUserDefaults standardUserDefaults] objectForKey:@"KeyboardLayout"]];
    
    [self addSubview:_keyboardView];
    
    [_keyboardView setDelegate:[EmulationManager sharedManager]];
}

- (void)_createInsertDiskView
{
    _insertDiskView = [[InsertDiskView alloc] initWithFrame:InsertDiskViewFrameHidden];
    
    [self addSubview:_insertDiskView];
    
    [_insertDiskView setDiskDrive:[VirtualDiskDriveController sharedInstance]];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([[event allTouches] count] > 1) {
        _mouseTouch = nil;
        
        if (_inGesture) {
            return;
        }
        
        _inGesture = YES;
        _mouseDrag = NO;
        
        [AppDelegate cancelPreviousPerformRequestsWithTarget:[VirtualMouseController sharedInstance] selector:@selector(setMouseButtonDown) object:nil];
        [[VirtualMouseController sharedInstance] setMouseButtonUp];
        
        _gestureStart = CGPointCenter([[[event.allTouches allObjects] objectAtIndex:0] locationInView:self], [[[event.allTouches allObjects] objectAtIndex:1] locationInView:self]);
        
        return;
    }
    
    _mouseTouch = [touches anyObject];
    
    CGPoint tapLoc = [_mouseTouch locationInView:self];
    
    if (!_screenSizeToFit) {
        CGPoint screenLoc = [_screenView frame].origin;
        
        Direction scrollTo = 0;
        
        if (IPAD()) {
            if (tapLoc.x < kScreenEdgeSize && screenLoc.x != 0.0) {
                scrollTo |= dirLeft;
            }
            
            if (tapLoc.y < kScreenEdgeSize && screenLoc.y != 0.0) {
                scrollTo |= dirUp;
            }
            
            if (tapLoc.x > (1024 - kScreenEdgeSize) && screenLoc.x == 0.0) {
                scrollTo |= dirRight;
            }
            
            if (tapLoc.y > (768 - kScreenEdgeSize) && screenLoc.y == 0.0) {
                scrollTo |= dirDown;
            }
        }
        else {
            if (tapLoc.x < kScreenEdgeSize && screenLoc.x != 0.0) {
                scrollTo |= dirLeft;
            }
            
            if (tapLoc.y < kScreenEdgeSize && screenLoc.y != 0.0) {
                scrollTo |= dirUp;
            }
            
            if (tapLoc.x > (480-kScreenEdgeSize) && screenLoc.x == 0.0) {
                scrollTo |= dirRight;
            }
            if (tapLoc.y > (480-kScreenEdgeSize) && screenLoc.y == 0.0) {
                scrollTo |= dirDown;
            }
        }
        
        
        if (scrollTo) {
            [self scrollScreenViewTo:scrollTo];
            return;
        }
    }
    
    Point loc = [self mouseLocForCGPoint:tapLoc];
    
    NSTimeInterval mouseTime = event.timestamp;
    NSTimeInterval mouseDiff = mouseTime - _lastMouseClick;
    
    if (_trackpadMode) {
        _trackpadClick = YES;
        
        if ((mouseDiff <= TRACKPAD_DRAG_DELAY) && (PointDistanceSq(loc, _lastMouseLoc) < MOUSE_LOC_THRESHOLD)) {
            _mouseDrag = YES;
            
            [[VirtualMouseController sharedInstance] setMouseButtonDown];
        }
    }
    else {
        if ((mouseDiff < MOUSE_DBLCLICK_TIME) && (PointDistanceSq(loc, _lastMouseLoc) < MOUSE_LOC_THRESHOLD)) {
            loc = _lastMouseLoc;
        }
        
        [[VirtualMouseController sharedInstance] setMouseLoc:loc];
        [[VirtualMouseController sharedInstance] performSelector:@selector(setMouseButtonDown) withObject:nil afterDelay:MOUSE_CLICK_DELAY];
    }
    
    _lastMouseLoc = loc;
    _lastMouseTime = _lastMouseClick = mouseTime;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ((_mouseTouch == nil) || (![touches containsObject:_mouseTouch])) {
        if (!_inGesture) {
            return;
        }
        
        _inGesture = NO;
        
        CGPoint gestureEnd = [touches.anyObject locationInView:self];
        
        Direction swipeDirection = 0;
        CGPoint delta = CGPointMake(_gestureStart.x - gestureEnd.x, _gestureStart.y - gestureEnd.y);
        
        if (delta.x > kSwipeThresholdHorizontal) {
            swipeDirection |= dirLeft;
        }
        
        if (delta.x < -kSwipeThresholdHorizontal) {
            swipeDirection |= dirRight;
        }
        
        if (delta.y > kSwipeThresholdVertical) {
            swipeDirection |= dirUp;
        }
        
        if (delta.y < -kSwipeThresholdVertical) {
            swipeDirection |= dirDown;
        }
        
        return;
    }
    
    Point loc = [self mouseLocForCGPoint:[_mouseTouch locationInView:self]];
    
    NSTimeInterval mouseTime = [event timestamp];
    NSTimeInterval mouseDiff = mouseTime - _lastMouseClick;
    
    if (_trackpadMode) {
        if (_trackpadClick && (mouseDiff <= TRACKPAD_CLICK_TIME)) {
            [self scheduleMouseClickAt:[[VirtualMouseController sharedInstance] mouseLoc]];
        }
        
        _trackpadClick = NO;
        
        if (_mouseDrag) {
            [[VirtualMouseController sharedInstance] setMouseButtonUp];
            
            _mouseDrag = NO;
        }
    }
    else {
        if (PointDistanceSq(loc, _lastMouseLoc) < MOUSE_LOC_THRESHOLD) {
            loc = _lastMouseLoc;
        }
        
        [[VirtualMouseController sharedInstance] setMouseLoc:loc];
        [[VirtualMouseController sharedInstance] performSelector:@selector(setMouseButtonUp) withObject:nil afterDelay:MOUSE_CLICK_DELAY];
        
        _mouseDrag = NO;
    }
    
    _lastMouseLoc = loc;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_inGesture) {
        return;
    }
    
    if ((_mouseTouch == nil) || (![touches containsObject:_mouseTouch])) {
        return;
    }
    
    NSTimeInterval mouseTime = event.timestamp;
    
    Point loc = [self mouseLocForCGPoint:[_mouseTouch locationInView:self]];
    
    if (_trackpadMode) {
        Point locDiff = loc;
        
        locDiff.h -= _lastMouseLoc.h;
        locDiff.v -= _lastMouseLoc.v;
        
        NSTimeInterval timeDiff = 100 * (mouseTime - _lastMouseTime);
        NSTimeInterval accel = TRACKPAD_ACCEL_N / (TRACKPAD_ACCEL_T + ((timeDiff * timeDiff) / TRACKPAD_ACCEL_D));
        
        locDiff.h *= accel;
        locDiff.v *= accel;
        
        _trackpadClick = NO;
        
        [[VirtualMouseController sharedInstance] moveMouse:locDiff button:_mouseDrag];
    }
    else {
        if (!_mouseDrag) {
            [AppDelegate cancelPreviousPerformRequestsWithTarget:[VirtualMouseController sharedInstance] selector:@selector(setMouseButtonDown) object:nil];
            
            [[VirtualMouseController sharedInstance] setMouseButton:YES];
            
            DoEmulateOneTick();
            DoEmulateOneTick();
            
            CurEmulatedTime += 2;
            
            _mouseDrag = YES;
        }
        
        [[VirtualMouseController sharedInstance] setMouseLoc:loc];
    }
    
    _lastMouseTime = mouseTime;
    _lastMouseLoc = loc;
}
- (Point)mouseLocForCGPoint:(CGPoint)point
{
    Point pt;
    
    if (_trackpadMode) {
        // same location
        pt.h = point.x;
        pt.v = point.y;
    }
    else if (_screenSizeToFit) {
        if (IPAD()) {
            pt.h = point.x * (vMacScreenWidth / 1024.0);
            pt.v = point.y * (vMacScreenHeight / 768.0);
        }
        else {
            pt.h = point.x * (vMacScreenWidth / 568);
            pt.v = point.y * (vMacScreenHeight / 320.0);
        }
    }
    else {
        pt.h = point.x - _mouseOffset.h;
        pt.v = point.y - _mouseOffset.v;
    }
    
    return pt;
}

- (void)scheduleMouseClickAt:(Point)loc
{
    if (_clickScheduled) {
        [MainView cancelPreviousPerformRequestsWithTarget:self selector:@selector(mouseClick) object:nil];
        
        [self mouseClick];
    }
    
    _clickScheduled = YES;
    _clickLoc = loc;
    
    [self performSelector:@selector(mouseClick) withObject:nil afterDelay:TRACKPAD_CLICK_DELAY];
}

- (void)cancelMouseClick
{
    _clickScheduled = NO;
    
    [MainView cancelPreviousPerformRequestsWithTarget:self selector:@selector(mouseClick) object:nil];
}

- (void)mouseClick
{
    _clickScheduled = NO;
    
    if (_mouseDrag) {
        return;
    }
    
    [[VirtualMouseController sharedInstance] setMouseLoc:_clickLoc button:YES];
    
    DoEmulateOneTick();
    DoEmulateOneTick();
    
    [[VirtualMouseController sharedInstance] setMouseButtonUp];
    
    CurEmulatedTime += 2;
}

- (void)toggleScreenSize
{
    [UIView animateWithDuration:NewDiskViewAnimationDuration animations:^{
        _screenSizeToFit = !_screenSizeToFit;
        
        if (_screenSizeToFit) {
            [_screenView setFrame:kScreenRectFullScreen];
        }
        else {
            [_screenView setFrame:kScreenRectRealSize];
            
            [self scrollScreenViewTo:_screenPosition];
        }
    }
     
                     completion:^(BOOL finished) {
                         [[NSUserDefaults standardUserDefaults] setBool:_screenSizeToFit forKey:@"ScreenSizeToFit"];
                         [[NSUserDefaults standardUserDefaults] synchronize];
                     }];
}

- (void)scrollScreenViewTo:(Direction)scroll
{
    CGRect screenFrame = _screenView.frame;
    
    _mouseOffset.h = screenFrame.origin.x;
    _mouseOffset.v = screenFrame.origin.y;
    
    return;
}

- (void)twoFingerSwipeGesture:(id)sender
{
    UISwipeGestureRecognizer *tempGesture = sender;
    
    if ([tempGesture direction] == UISwipeGestureRecognizerDirectionDown) {
        if (_keyboardView) {
            [_keyboardView hide];
        }
    }
    else if ([tempGesture direction] == UISwipeGestureRecognizerDirectionUp) {
        if (_keyboardView == nil) {
            [self _createKeyboardView];
        }
        
        [_keyboardView show];
        
        [self bringSubviewToFront:_keyboardView];
    }
    else if ([tempGesture direction] == UISwipeGestureRecognizerDirectionLeft) {
        if (_insertDiskView == nil) {
            [self _createInsertDiskView];
        }
        
        [_insertDiskView show];
        
        [self bringSubviewToFront:_insertDiskView];
    }
    else {
        [_insertDiskView hide];
    }
}

-(void)panGestureRecognizer:(UIPanGestureRecognizer *)recognizer
{
    //All the magic numbers here were getting unwiedly, so I made some defines.  Yay for me!
    
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint currentVelocityPoint = [recognizer velocityInView:self];
        CGFloat currentVelocityX = currentVelocityPoint.x;
                
        if (IPAD()) {
            if (_insertDiskView.frame.origin.x <= IPAD_INSERT_VIEW_THRESHOLD && currentVelocityX < NO_VELOCITY) {
                return;
            }
        }
        else if (_insertDiskView.frame.origin.x <= IPHONE_INSERT_VIEW_THRESHOLD && currentVelocityX < NO_VELOCITY) {
            return;
        }
        
        CGPoint centerPoint = self.insertDiskView.frame.origin;
        CGPoint newPoint = [recognizer translationInView:self];
        CGPoint finalPoint = CGPointMake(centerPoint.x + newPoint.x, centerPoint.y + newPoint.y);
        
        if (finalPoint.x >= IPAD() ? IPAD_INSERT_VIEW_THRESHOLD : IPHONE_INSERT_VIEW_THRESHOLD) {
            [_insertDiskView setFrame:CGRectMake(finalPoint.x, 0, INSERT_VIEW_WIDTH, IPAD() ? IPAD_INSERT_VIEW_HEIGHT : IPHONE_INSERT_VIEW_HEIGHT)];
            
            [recognizer setTranslation:CGPointZero inView:self];
        }
        else {
            [recognizer setTranslation:CGPointZero inView:self];
            
            return;
        }
    }
    else if ([recognizer state] == UIGestureRecognizerStateEnded) {
        if (IPAD()) {
            if (_insertDiskView.frame.origin.x > IPAD_HIDE_THRESHOLD) {
                [_insertDiskView hide];
            }
            else {
                [_insertDiskView show];
            }
        }
        else {
            if (_insertDiskView.frame.origin.x < IPHONE_SHOW_THESHOLD) {
                [_insertDiskView show];
            }
            else {
                [_insertDiskView hide];
            }
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}
@end