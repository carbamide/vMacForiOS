//
//  VirtualKeyboard.h
//  Mini vMac
//
//  Created by Josh on 3/2/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VirtualKeyboard <NSObject>
- (void)vKeyDown:(int)scancode;
- (void)vKeyUp:(int)scancode;
@end
