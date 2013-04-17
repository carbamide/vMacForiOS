//
//  VirtualDiskDriveController.m
//  Mini vMac
//
//  Created by Josh on 2/27/13.
//  Copyright (c) 2013 Jukaela Enterprises. All rights reserved.
//

#import "VirtualDiskDriveController.h"
#import "MainView.h"
#include <sys/param.h>
#include <sys/mount.h>

@interface VirtualDiskDriveController ()
extern NSInteger numInsertedDisks;
@end

@implementation VirtualDiskDriveController

GLOBALPROC notifyDiskEjected(ui4b Drive_No);
GLOBALPROC notifyDiskInserted(ui4b Drive_No, blnr locked);
GLOBALFUNC blnr getFirstFreeDisk(ui4b *Drive_No);

+ (id)sharedInstance
{
    static VirtualDiskDriveController *virtualDiskDriveController = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        virtualDiskDriveController = [[self alloc] init];
    });
    
    return virtualDiskDriveController;
}

- (id)init
{
    if (self = [super init]) {
        CFURLRef ejectSoundURL = (__bridge CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"diskEject" ofType:@"aiff"]];
        OSStatus err = AudioServicesCreateSystemSoundID(ejectSoundURL, &_ejectSound);
        
        if (err != noErr) {
            NSLog(@"Could not load eject sound %@ (%ld)", ejectSoundURL, err);
        }
    }
    return self;
}

-(void)dealloc
{
    AudioServicesDisposeSystemSoundID(_ejectSound);
}

- (BOOL)initDrives
{
    int i;
    
    numInsertedDisks = 0;
    
    for (i = 0; i < NumDrives; i++) {
        drives[i] = nil;
        drivePath[i] = nil;
    }
    
    return YES;
}

- (BOOL)diskIsInserted:(NSString *)path
{
    for (int i = 0; i < NumDrives; i++) {
        if ([drivePath[i] isEqualToString:path]) return YES;
    }
    
    return NO;
}

- (NSInteger)insertedDisks
{
    return numInsertedDisks;
}

- (BOOL)canCreateDiskImages
{
    return TRUE;
}

- (NSString *)pathToDiskImages
{
    return [[Helpers sharedInstance]  documentsPath];
}

- (BOOL)insertDisk:(NSString *)path
{
    NSLog(@"%@", path);
    
    BOOL isDir;
    
    short driveNum;
    
    NSFileManager *mgr = [NSFileManager defaultManager];
    
    if (!getFirstFreeDisk((unsigned short *)&driveNum)) {
        [[Helpers sharedInstance]  warnMessage:NSLocalizedString(@"TooManyDisksText", nil) title:NSLocalizedString(@"TooManyDisksTitle", nil)];
        
        return NO;
    }
    
    // check for file
    if ([mgr fileExistsAtPath:path isDirectory:&isDir] == NO) {
        return NO;
    }
    
    if (isDir) {
        return NO;
    }
    
    // check if disk is inserted
    if ([self diskIsInserted:path]){
        return NO;
    }
    
    // insert disk
    if ([mgr isWritableFileAtPath:path]) {
        drives[driveNum] = [NSFileHandle fileHandleForUpdatingAtPath:path];
        notifyDiskInserted(driveNum, falseblnr);
    }
    else {
        drives[driveNum] = [NSFileHandle fileHandleForReadingAtPath:path];
        notifyDiskInserted(driveNum, trueblnr);
    }
    
    drivePath[driveNum] = path;
    
    numInsertedDisks++;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"diskInserted" object:self];
    
    return YES;
}

- (short)sonyTransfer:(short)n isWrite:(BOOL)isWrite start:(unsigned long)start count:(unsigned long)count actCount:(unsigned long *)actCount buffer:(void *)buffer
{
    short result;
    
    ui5r NewSony_Count = count;
    
    int fd = [drives[n] fileDescriptor];
    
    lseek(fd, (off_t)start, SEEK_SET);
    
    if (isWrite) {
        write(fd, buffer, (size_t)count);
    }
    else {
        read([drives[n] fileDescriptor], buffer, (size_t)count);
    }
    
    if (nullpr != actCount) {
        *actCount = NewSony_Count;
    }
    
    return mnvm_noErr;
    
    result = 0;
    
    return result;
}

- (short)sizeOfDrive:(short)n count:(unsigned long *)count
{
    unsigned long long size = [drives[n] seekToEndOfFile];
    
    *count = (ui5b)size;
    
    return 0;
}

- (BOOL)ejectDrive:(short)n
{
    NSFileHandle *fh = drives[n];
    
    drives[n] = nil;
    drivePath[n] = nil;
    numInsertedDisks--;
    
    notifyDiskEjected(n);
    
    [fh closeFile];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DiskEjectSound"]) {
        AudioServicesPlaySystemSound(_ejectSound);
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"diskEjected" object:self];
    
    return YES;
}

- (NSArray *)availableDiskImages
{
    NSMutableArray *myDiskFiles = [NSMutableArray arrayWithCapacity:10];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *sources = [[Helpers sharedInstance] searchPaths];
    NSArray *extensions = @[@"dsk", @"img", @"DSK", @"IMG", @"image"];
    
    for (NSString *srcDir in sources) {
        NSArray *dirFiles = [[fm contentsOfDirectoryAtPath:srcDir error:NULL] pathsMatchingExtensions:extensions];
        
        for (NSString *filename in dirFiles) {
            [myDiskFiles addObject:[srcDir stringByAppendingPathComponent:filename]];
        }
    }
    
    return myDiskFiles;
}

- (BOOL)diskImageHasIcon:(NSString *)path
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // file
    if ([fm fileExistsAtPath:[[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"]]) {
        return YES;
    }
    
    return NO;
}

- (BOOL)createDiskImage:(NSString *)name size:(int)size
{
    if (name == nil || [name length] == 0) {
        return NO;
    }
    
    if (size < 400) {
        return NO;
    }
    
    if (size > 500 * 1024) {
        return NO;
    }
    
    uint64_t freeSpace;
    uint64_t needSpace;
    
    struct statfs fss;
    
    if (statfs([[self pathToDiskImages] fileSystemRepresentation], &fss)) {
        return NO;
    }
    
    freeSpace = fss.f_bavail;
    freeSpace *= fss.f_bsize;
    freeSpace /= 1024;
    
    needSpace = size + (20 * 1024);
    
    if (freeSpace < needSpace) {
        [[Helpers sharedInstance]  warnMessage:NSLocalizedString(@"NotEnoughSpaceMsg", nil)];
        
        return NO;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *imagePath = [[[self pathToDiskImages] stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"dsk"];
    
    if ([fm fileExistsAtPath:imagePath]) {
        [[Helpers sharedInstance]  warnMessage:NSLocalizedString(@"ImageAlreadyExistsMsg", nil)];
        
        return NO;
    }
    
    FILE *fp = fopen([imagePath fileSystemRepresentation], "w");
    
    if (fp == NULL) {
        [[Helpers sharedInstance]  warnMessage:NSLocalizedString(@"ImageCreationError", nil)];
        return NO;
    }
    
    _newImageFile = fp;
    _newImageSize = size;
    
    if (size > 5 * 1024) {
        [self performSelectorInBackground:@selector(writeDiskImageThread) withObject:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(writeDiskImageThreadDone:) name:@"diskCreated" object:nil];
    }
    else {
        [self writeDiskImageThread];
    }
    
    return YES;
}

- (void)writeDiskImageThread {
    int wbsize = 1024 * 100; // write in 100K blocks
    int wbytes = _newImageSize * 1024;
    
    if (_newImageSize > 2048) wbsize = 1024 * 1024; // write in 1M blocks
    
    char *buf = malloc(wbsize);
    
    while (wbytes) {
        if (wbytes < wbsize) wbsize = wbytes;
        
        if (fwrite(buf, wbsize, 1, _newImageFile) != 1) break;
        
        wbytes -= wbsize;
    }
    
    free(buf);
    fclose(_newImageFile);
    _newImageFile = NULL;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"diskCreated" object:[NSNumber numberWithBool:(wbytes ? NO : YES)]];
}

- (void)writeDiskImageThreadDone:(NSNotification *)notification
{
    BOOL success = [[notification object] boolValue];
    
    if (!success) {
        [[Helpers sharedInstance]  warnMessage:NSLocalizedString(@"ImageCreationError", nil)];
    }
}

#ifdef IncludeSonyGetName
- (NSString *)nameOfDrive:(short)n
{
    if (drivePath[n] == nil) {
        return nil;
    }
    
    return [drivePath[n] lastPathComponent];
}
#endif

#ifdef IncludeSonyNew
- (BOOL)ejectAndDeleteDrive:(short)n
{
    BOOL hadDiskEjectSound = [[NSUserDefaults standardUserDefaults] boolForKey:@"DiskEjectSound"];
    BOOL success = NO;
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"DiskEjectSound"];
    
    NSString *path = drivePath[n];
    
    if ([self ejectDrive:n]) {
        success = [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:hadDiskEjectSound forKey:@"DiskEjectSound"];
    return success;
}
#endif

@end
