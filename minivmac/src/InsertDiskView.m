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
        
        [_navBar pushNavigationItem:navItem animated:NO];
        
        [self addSubview:_navBar];
        
		[[self layer] setShadowColor:[[UIColor blackColor] CGColor]];
		[[self layer] setShadowOffset:CGSizeMake(0, 0)];
		[[self layer] setShadowRadius:15];
		[[self layer] setShadowOpacity:0.8];
        
        UIBezierPath *navBarMaskPath = [UIBezierPath bezierPathWithRoundedRect:[_navBar bounds] byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight) cornerRadii:CGSizeMake(8.0, 8.0)];
        UIBezierPath *tableMaskPath = [UIBezierPath bezierPathWithRoundedRect:[_table bounds] byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerBottomRight) cornerRadii:CGSizeMake(8.0, 8.0)];

        CAShapeLayer *navBarMaskLayer = [[CAShapeLayer alloc] init];
        CAShapeLayer *tableMaskLayer = [[CAShapeLayer alloc] init];

        [navBarMaskLayer setFrame:[_navBar bounds]];
        [navBarMaskLayer setPath:[navBarMaskPath CGPath]];
        [tableMaskLayer setFrame:[_table bounds]];
        [tableMaskLayer setPath:[tableMaskPath CGPath]];
        
        [[_navBar layer] setMask:navBarMaskLayer];
        [[_table layer] setMask:tableMaskLayer];
        
        
        [self setBackgroundColor:[UIColor clearColor]];
        [self setOpaque:NO];
        
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
    
    if ([_diskDrive diskIsInserted:_diskFiles[[indexPath row]]]) {
        [[cell textLabel] setTextColor:[UIColor darkGrayColor]];
    }
    else {
        [[cell textLabel] setTextColor:[UIColor blackColor]];
    }
    
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
    @try {
        id diskFile = _diskFiles[[indexPath row]];
        
        if ([_diskDrive diskIsInserted:diskFile]) {
            return;
        }
        
        [_diskDrive insertDisk:diskFile];
        
        [self hide];
    }
    @catch (NSException *e) {
        NSLog(@"An exception has occured in InsertDiskView while selecting the row");
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    @try {
        id diskFile = _diskFiles[[indexPath row]];
        
        if ([_diskDrive diskIsInserted:diskFile]) return nil;
        
        return indexPath;
    }
    @catch (NSException *e) {
        NSLog(@"An exception has occured in InsertDiskView when a row was about to enter the selected state");
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

@end