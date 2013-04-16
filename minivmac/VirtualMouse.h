//
//  VirtualMouse.h
//  Mini vMac
//
//  Created by Josh on 2/24/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VirtualMouse <NSObject>
- (void)setMouseButton:(BOOL)pressed;
- (void)setMouseButtonDown;
- (void)setMouseButtonUp;
- (void)setMouseLoc:(Point)mouseLoc button:(BOOL)pressed;
- (void)setMouseLoc:(Point)mouseLoc;
- (void)moveMouse:(Point)mouseMotion;
- (void)moveMouse:(Point)mouseMotion button:(BOOL)pressed;
- (Point)mouseLoc;
- (BOOL)mouseButton;
@end
