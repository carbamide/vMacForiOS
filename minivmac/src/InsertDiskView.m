#import "InsertDiskView.h"
#import "VirtualDiskDriveController.h"
#import "MainView.h"

@implementation InsertDiskView

- (id)initWithFrame:(CGRect)rect
{
    if ((self = [super initWithFrame:rect]) != nil) {
        _diskFiles = @[];
        
        CGRect tableRect = CGRectMake(0.0, kNavBarHeight, rect.size.width, rect.size.height - kNavBarHeight);
        
        _table = [[UITableView alloc] initWithFrame:tableRect style:UITableViewStylePlain];
        [_table setDelegate:self];
        [_table setDataSource:self];
        
        [self addSubview:_table];
        
        _navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0, 0.0, rect.size.width, kNavBarHeight)];
        
        UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:nil];
        
        UIBarButtonItem *button = nil;
        
        if ([[VirtualDiskDriveController sharedInstance] canCreateDiskImages]) {
            button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(newDiskImage)];
            
            [navItem setLeftBarButtonItem:button animated:NO];
        }
        
        button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(hide)];
        
        [navItem setRightBarButtonItem:button animated:NO];
        
        [_navBar pushNavigationItem:navItem animated:NO];
        
        [self addSubview:_navBar];
        
		[[self layer] setShadowColor:[[UIColor blackColor] CGColor]];
		[[self layer] setShadowOffset:CGSizeMake(-10, 0)];
		[[self layer] setShadowRadius:5];
		[[self layer] setShadowOpacity:0.8];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didInsertDisk:) name:@"diskInserted" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEjectDisk:) name:@"diskEjected" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didCreateDisk:) name:@"diskCreated" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:_table selector:@selector(reloadData) name:@"diskIconUpdate" object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:_table];
}

- (void)hide
{
    [UIView animateWithDuration:InsertDiskViewAnimationDuration
                     animations:^{
                         [self setFrame:InsertDiskViewFrameHidden];
                     }
     
                     completion:nil];
}

- (void)show
{
    NSIndexPath *selectedRow = [_table indexPathForSelectedRow];
    
    if (selectedRow) [_table deselectRowAtIndexPath:selectedRow animated:NO];
    
    [UIView animateWithDuration:InsertDiskViewAnimationDuration
                     animations:^{
                         [self setFrame:InsertDiskViewFrameVisible];
                     }
     
                     completion:^(BOOL finished) {
                         [self findDiskFiles];
                         [_table reloadData];
                     }];
}

- (void)didCreateDisk:(NSNotification *)aNotification
{
    BOOL success = [[aNotification object] boolValue];
    
    if (success) {
        [self findDiskFiles];
        
        [_table reloadData];
        
        [_disk hide];
    }
}

- (void)didEjectDisk:(NSNotification *)aNotification
{
    [_table reloadData];
}

- (void)didInsertDisk:(NSNotification *)aNotification
{
    [_table reloadData];
}

- (void)findDiskFiles
{
    _diskFiles = [[VirtualDiskDriveController sharedInstance] availableDiskImages];
}

- (UIImage *)iconForDiskImageAtPath:(NSString *)path
{
    
    NSDictionary *fileAttrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
    NSNumber *fileSize = [fileAttrs valueForKey:NSFileSize];
    
    UIImage *iconImage = nil;
    
    if ([fileSize longLongValue] < 1440 * 1024 + 100) {
        iconImage = [UIImage imageNamed:@"DiskListFloppy.png"];
    }
    else {
        iconImage = [UIImage imageNamed:@"DiskListHD.png"];
    }
    
    return iconImage;
}

- (void)newDiskImage
{
    if (_disk == nil) {
        _disk = [[NewDiskView alloc] initWithFrame:NewDiskViewFrameHidden];
        
        [[self superview] addSubview:_disk];
    }
    
    [_disk show];
    
    [[self superview] bringSubviewToFront:_disk];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_diskFiles count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"diskCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    NSString *diskPath = _diskFiles[[indexPath row]];
    
    [[cell imageView] setImage:[self iconForDiskImageAtPath:diskPath]];
    [[cell textLabel] setText:[diskPath lastPathComponent]];
    [[cell textLabel] setTextColor:[UIColor blackColor]];
    
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *diskPath = _diskFiles[[indexPath row]];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"CanDeleteDiskImages"] == NO) {
        return UITableViewCellEditingStyleNone;
    }
    
    if ([_diskDrive diskIsInserted:diskPath]) {
        return UITableViewCellEditingStyleNone;
    }
    
    if ([[NSFileManager defaultManager] isDeletableFileAtPath:diskPath]) {
        return UITableViewCellEditingStyleDelete;
    }
    
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *diskPath = _diskFiles[[indexPath row]];
        
        if ([[NSFileManager defaultManager] removeItemAtPath:diskPath error:NULL]) {
            [self findDiskFiles];
            
            [_table deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *tempCell = [tableView cellForRowAtIndexPath:indexPath];
    
    @try {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"Select a disk action" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
                
        NSMutableArray *tempArray = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"disks_to_load"] mutableCopy];
        
        if (![_diskDrive diskIsInserted:_diskFiles[[indexPath row]]]) {
            [alertView addButtonWithTitle:@"Mount"];
        }
        
        BOOL addRemoveAutoMountButton = NO;
        
        if ([tempArray count] > 0) {
            for (NSString *tempString in tempArray) {
                if ([tempString isEqualToString:[[tempCell textLabel] text]]) {
                    addRemoveAutoMountButton = YES;
                }
            }
        }
        
        if (addRemoveAutoMountButton) {
            [alertView addButtonWithTitle:@"Don't Automount"];
        }
        else {
            [alertView addButtonWithTitle:@"Automount"];
        }
        
        [alertView show];
    }
    @catch (NSException *e) {
        NSLog(@"An exception has occured in InsertDiskView while selecting the row");
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:@"Mount"]) {
        id diskFile = _diskFiles[[[[self table] indexPathForSelectedRow] row]];
        
        if ([_diskDrive diskIsInserted:diskFile]) {
            return;
        }
        
        [_diskDrive insertDisk:diskFile];
        
        [self hide];
    }
    else if ([buttonTitle isEqualToString:@"Automount"]) {
        UITableViewCell *tempCell = [[self table] cellForRowAtIndexPath:[[self table] indexPathForSelectedRow]];
        
        if ([[NSUserDefaults standardUserDefaults] arrayForKey:@"disks_to_load"]) {
            NSMutableArray *tempArray = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"disks_to_load"] mutableCopy];
            
            [tempArray addObject:[[tempCell textLabel] text]];
            
            [[NSUserDefaults standardUserDefaults] setObject:tempArray forKey:@"disks_to_load"];
        }
        else {
            NSMutableArray *tempArray = [[NSMutableArray alloc] init];
            
            [tempArray addObject:[[tempCell textLabel] text]];
            
            [[NSUserDefaults standardUserDefaults] setObject:tempArray forKey:@"disks_to_load"];
        }
        
        id diskFile = _diskFiles[[[[self table] indexPathForSelectedRow] row]];

        if (![_diskDrive diskIsInserted:diskFile]) {
            [_diskDrive insertDisk:diskFile];
        }
    }
    else if ([buttonTitle isEqualToString:@"Don't Automount"]) {
        UITableViewCell *tempCell = [[self table] cellForRowAtIndexPath:[[self table] indexPathForSelectedRow]];

        NSMutableArray *tempArray = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"disks_to_load"] mutableCopy];
        
        [tempArray removeObject:[[tempCell textLabel] text]];
        
        [[NSUserDefaults standardUserDefaults] setObject:tempArray forKey:@"disks_to_load"];
    }

    [self hide];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

@end