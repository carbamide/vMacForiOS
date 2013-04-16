//
//  Helpers.h
//  Mini vMac
//
//  Created by Josh on 3/2/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Helpers : NSObject

+ (id)sharedInstance;

- (BOOL)isRetinaDisplay;

- (NSArray *)searchPaths;

- (NSString *)defaultSearchPath;
- (NSString *)documentsPath;

- (void)warnMessage:(NSString *)message title:(NSString *)title;
- (void)warnMessage:(NSString *)message;

@end
