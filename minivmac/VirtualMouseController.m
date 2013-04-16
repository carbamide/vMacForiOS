//
//  VirtualMouseController.m
//  Mini vMac
//
//  Created by Josh on 2/27/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import "VirtualMouseController.h"
#import "MainView.h"

@implementation VirtualMouseController

IMPORTPROC MyMousePositionSet(ui4r h, ui4r v);
IMPORTPROC MyMouseButtonSet(blnr down);

+ (id)sharedInstance
{
    static VirtualMouseController *virtualMouseController = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        virtualMouseController = [[self alloc] init];
    });
    
    return virtualMouseController;
}

- (id)init
{
    if (self = [super init]) {

    }
    return self;
}

- (void)setMouseButtonDown
{
    MyMouseButtonSet(trueblnr);
}

- (void)setMouseButtonUp
{
    MyMouseButtonSet(falseblnr);
}

- (void)setMouseButton:(BOOL)pressed
{
    MyMouseButtonSet(pressed);
}

- (void)setMouseLoc:(Point)mouseLoc
{
    HaveMouseMotion = falseblnr;
    CurMouseH = CLAMP(mouseLoc.h, 0, vMacScreenWidth);
    CurMouseV = CLAMP(mouseLoc.v, 0, vMacScreenHeight);
    MyMousePositionSet(CurMouseH, CurMouseV);
}

- (void)setMouseLoc:(Point)mouseLoc button:(BOOL)pressed
{
    HaveMouseMotion = falseblnr;
    CurMouseH = CLAMP(mouseLoc.h, 0, vMacScreenWidth);
    CurMouseV = CLAMP(mouseLoc.v, 0, vMacScreenHeight);
    MyMousePositionSet(CurMouseH, CurMouseV);
    MyMouseButtonSet(pressed);
}

- (void)moveMouse:(Point)mouseMotion
{
    HaveMouseMotion = trueblnr;
    MouseMotionH = mouseMotion.h;
    MouseMotionV = mouseMotion.v;
}

- (void)moveMouse:(Point)mouseMotion button:(BOOL)pressed
{
    HaveMouseMotion = trueblnr;
    MouseMotionH = mouseMotion.h;
    MouseMotionV = mouseMotion.v;
    MyMouseButtonSet(pressed);
}

- (Point)mouseLoc
{
    Point pt;
    
    pt.h = CurMouseH;
    pt.v = CurMouseV;
    return pt;
}

- (BOOL)mouseButton
{
    return CurMouseButton;
}

@end
