#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "NewDiskView.h"
#import "Constants.h"
#import "VirtualDiskDrive.h"

@interface InsertDiskView : UIView <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate>

@property (strong, nonatomic) NSArray *diskFiles;
@property (strong, nonatomic) UITableView *table;
@property (strong, nonatomic) UINavigationBar *navBar;
@property (strong, nonatomic) NewDiskView *disk;
@property (nonatomic, weak) id <VirtualDiskDrive> diskDrive;

- (void)hide;
- (void)show;
- (void)findDiskFiles;
- (void)didEjectDisk:(NSNotification *)aNotification;
- (void)didInsertDisk:(NSNotification *)aNotification;
- (UIImage *)iconForDiskImageAtPath:(NSString *)path;

@end