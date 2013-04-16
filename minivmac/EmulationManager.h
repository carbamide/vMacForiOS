//
//  EmulationManager.h
//  Mini vMac
//
//  Created by Josh on 3/2/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EmulationManager : NSObject

+ (id)sharedManager;

- (BOOL)loadROM;
- (BOOL)initEmulation;

- (void)startEmulation:(id)sender;
- (void)suspendEmulation;
- (void)resumeEmulation;

- (NSDictionary *)availableKeyboardLayouts;

@end
