//
//  VirtualDiskDrive.h
//  Mini vMac
//
//  Created by Josh on 2/24/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VirtualDiskDrive <NSObject>

- (BOOL)diskIsInserted:(NSString *)path;
- (BOOL)insertDisk:(NSString *)path;
- (short)sonyTransfer:(short)n isWrite:(BOOL)isWrite start:(unsigned long)start count:(unsigned long)count actCount:(unsigned long *)actCount buffer:(void *)buffer;
- (short)sizeOfDrive:(short)drive count:(unsigned long *)count;
- (BOOL)ejectDrive:(short)drive;
- (BOOL)createDiskImage:(NSString *)name size:(int)size;
#ifdef IncludeSonyGetName
- (NSString *)nameOfDrive:(short)drive;
#endif
#ifdef IncludeSonyNew
- (BOOL)ejectAndDeleteDrive:(short)drive;
#endif

@property (nonatomic, readonly) NSInteger insertedDisks;
@property (nonatomic, readonly) BOOL canCreateDiskImages;
@property (nonatomic, readonly) NSString *pathToDiskImages;

@end
