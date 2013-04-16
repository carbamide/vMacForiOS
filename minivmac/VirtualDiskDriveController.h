//
//  VirtualDiskDriveController.h
//  Mini vMac
//
//  Created by Josh on 2/27/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VirtualDiskDrive.h"
#import <AudioToolbox/AudioToolbox.h>

@interface VirtualDiskDriveController : NSObject <VirtualDiskDrive>
{
    NSFileHandle *drives[6];
    NSString *drivePath[6];
}
@property (nonatomic) SystemSoundID ejectSound;
@property (nonatomic) FILE *newImageFile;
@property (nonatomic) int newImageSize;

+ (id)sharedInstance;
- (BOOL)initDrives;
- (NSArray *)availableDiskImages;

@end
