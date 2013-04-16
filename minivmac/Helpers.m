//
//  Helpers.m
//  Mini vMac
//
//  Created by Josh on 3/2/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import "Helpers.h"

@interface Helpers ()
@property (strong, nonatomic) NSMutableSet *openAlerts;
@end
@implementation Helpers

IMPORTFUNC blnr InitEmulation(void);

+ (id)sharedInstance
{
    static Helpers *helpers = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        helpers = [[self alloc] init];
    });
    
    return helpers;
}

- (id)init
{
    if (self = [super init]) {
        _openAlerts = [NSMutableSet setWithCapacity:5];
    }
    
    return self;
}

- (void)warnMessage:(NSString *)message title:(NSString *)title
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil];
    
    [_openAlerts addObject:alert];
    
    SpeedStopped = trueblnr;
    
    [alert show];
}

- (void)warnMessage:(NSString *)message
{
    [self warnMessage:message title:NSLocalizedString(@"WarnTitle", nil)];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [_openAlerts removeObject:alertView];
    
    if (([_openAlerts count] == 0) && [kAppDelegate initOk]) {
        SpeedStopped = falseblnr;
    }
}

-(NSString *)documentsPath
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

-(BOOL)isRetinaDisplay
{
    if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&  ([[UIScreen mainScreen] scale] == 2.0)) {
        return YES;
    }
    
    return NO;
}


- (NSArray *)searchPaths
{
    return @[[[NSBundle mainBundle] resourcePath], [self documentsPath]];
}

- (NSString *)defaultSearchPath
{
    NSBundle *mb = [NSBundle mainBundle];
    
    return [mb resourcePath];
}
@end
