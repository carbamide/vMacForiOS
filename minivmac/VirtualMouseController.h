//
//  VirtualMouseController.h
//  Mini vMac
//
//  Created by Josh on 2/27/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VirtualMouse.h"

@interface VirtualMouseController : NSObject <VirtualMouse>

+ (id)sharedInstance;

@end
