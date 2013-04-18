#import "SettingsView.h"
#import "AppDelegate.h"
#import "EmulationManager.h"
#import <QuartzCore/QuartzCore.h>

#define kToolbarHeight 44
#define kNavBarHeight  32

@implementation SettingsView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _layouts = [[EmulationManager sharedManager] availableKeyboardLayouts];
        
        _layoutIDs = [[_layouts allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        
        _switchPrefKeys = [NSMutableArray arrayWithCapacity:5];
        
        _navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, kNavBarHeight)];
        
        UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:nil];
        UIBarButtonItem *button = nil;
        
        [_navBar pushNavigationItem:navItem animated:NO];
        
        button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:14 target:self action:@selector(hide)];
        [navItem setLeftBarButtonItem:button animated:NO];
        
        [self addSubview:_navBar];
        
        [[self layer] setShadowColor:[[UIColor blackColor] CGColor]];
		[[self layer] setShadowOffset:CGSizeMake(10, 0)];
		[[self layer] setShadowRadius:5];
		[[self layer] setShadowOpacity:0.8];
        
        CGRect tableRect = CGRectMake(0.0, kNavBarHeight, frame.size.width, frame.size.height - kNavBarHeight - kToolbarHeight);
        
        _table = [[UITableView alloc] initWithFrame:tableRect style:UITableViewStyleGrouped];
        [_table setDelegate:self];
        [_table setDataSource:self];
        
        [self addSubview:_table];
        
        CGRect toolbarRect;
        
        toolbarRect = CGRectMake(0.0, 768.0 - kToolbarHeight, frame.size.width, kToolbarHeight);
        
        UIBarButtonItem *interruptButton, *resetButton;
        
        interruptButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"PSInterrupt.png"]
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(macInterrupt)];
        
        resetButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"PSReset.png"]
                                                       style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(macReset)];
        
        _toolbar = [[UIToolbar alloc] initWithFrame:toolbarRect];
        [_toolbar setBarStyle:UIBarStyleDefault];
        [_toolbar setItems:@[interruptButton, resetButton] animated:NO];
        [self addSubview:_toolbar];
    }
    
    return self;
}

- (void)hide
{
    [UIView animateWithDuration:SettingsViewAnimationDuration
                     animations:^{
                         [self setFrame:SettingsViewFrameHidden];
                     }];
}

- (void)show
{
    NSIndexPath *selectedRow = [_table indexPathForSelectedRow];
    
    if (selectedRow) {
        [_table deselectRowAtIndexPath:selectedRow animated:NO];
    }
    
    [UIView animateWithDuration:SettingsViewAnimationDuration
                     animations:^{
                         [self setFrame:SettingsViewFrameVisible];
                     }
     
                     completion:^(BOOL finished) {
                         [_table reloadData];
                     }];
}

- (void)macInterrupt
{
    WantMacInterrupt = YES;
}

- (void)macReset
{
    WantMacReset = YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return settingsGroupCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case settingsGroupKeyboard:
            return [_layouts count] + 1;
            
        case settingsGroupMouse:
            return 1;
            
        case settingsGroupSound:
            return 3;
            
        case settingsGroupDisk:
            return 1;
    }
    
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case settingsGroupKeyboard:
            return NSLocalizedString(@"SettingsKeyboard", nil);
            
        case settingsGroupMouse:
            return NSLocalizedString(@"SettingsMouse", nil);
            
        case settingsGroupSound:
            return NSLocalizedString(@"SettingsSound", nil);
            
        case settingsGroupDisk:
            return NSLocalizedString(@"SettingsDisk", nil);
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section + 1 < settingsGroupCount) {
        return nil;
    }
    
    return @"©2013 Jukaela Enterprises";
}

- (UITableViewCell *)cellWithIdentifier:(NSString *)cellIdentifier forTableView:(UITableView *)tableView
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    UISlider *slider = nil;
    
    NSInteger group = indexPath.section;
    NSInteger row = [indexPath row];
    
    if (group == settingsGroupKeyboard) {
        if ((row - [_layoutIDs count]) == 0) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            
            slider = [[UISlider alloc] initWithFrame:CGRectMake(96.0f, 4.0f, 120.0f, 40.0f)];
            [slider addTarget:self action:@selector(keyboardAlphaChanged:) forControlEvents:UIControlEventValueChanged];
            [slider setMinimumValue:0.2];
            [slider setMaximumValue:1.0];
            [slider setValue:[[NSUserDefaults standardUserDefaults] floatForKey:@"KeyboardAlpha"]];
            [slider setContinuous:YES];
            
            [[cell textLabel] setText:NSLocalizedString(@"SettingsKeyboardOpacity", nil)];
            [cell.contentView addSubview:slider];
        }
        else {
            cell = [self cellWithIdentifier:@"keyboardLayout" forTableView:tableView];
            [cell setAccessoryType:[_layoutIDs[row] isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"KeyboardLayout"]] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone];
            
            [[cell textLabel] setText:_layouts[_layoutIDs[row]]];
        }
    }
    else if (group == settingsGroupMouse) {
        cell = [self switchCellWithTitle:NSLocalizedString(@"SettingsMouseTrackpadMode", nil) forPrefsKey:@"TrackpadMode"];
    }
    else if (group == settingsGroupSound) {
        switch (row) {
            case 0: // mac sound
                cell = [self switchCellWithTitle:NSLocalizedString(@"SettingsSoundEnable", nil) forPrefsKey:@"SoundEnabled"];
                
                break;
                
            case 1: // disk eject sound
                cell = [self switchCellWithTitle:NSLocalizedString(@"SettingsSoundDiskEject", nil) forPrefsKey:@"DiskEjectSound"];
                
                break;
                
            case 2: // keyboard sound
                cell = [self switchCellWithTitle:NSLocalizedString(@"SettingsKeyboardSound", nil) forPrefsKey:@"KeyboardSound"];
                
                break;
        }
    }
    else if (group == settingsGroupDisk) {
        switch (row) {
            case 0:
                cell = [self switchCellWithTitle:NSLocalizedString(@"SettingsDiskDelete", nil) forPrefsKey:@"CanDeleteDiskImages"];
                
                break;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == settingsGroupKeyboard && ([indexPath row] < [_layoutIDs count])) {
        [[NSUserDefaults standardUserDefaults] setObject:_layoutIDs[[indexPath row]] forKey:@"KeyboardLayout"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [_table reloadData];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == settingsGroupKeyboard && ([indexPath row] < [_layoutIDs count])) {
        return indexPath;
    }
    
    return nil;
}

- (void)keyboardAlphaChanged:(UISlider *)slider
{
    [[NSUserDefaults standardUserDefaults] setFloat:[slider value] forKey:@"KeyboardAlpha"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (UITableViewCell *)switchCellWithTitle:(NSString *)title forPrefsKey:(NSString *)key
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(117, 8, 0, 0)];
    
    [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    
    [[cell textLabel] setText:title];
    [[cell contentView] addSubview:sw];
    
    [sw setOn:[[NSUserDefaults standardUserDefaults] boolForKey:key] animated:NO];
    
    if (![_switchPrefKeys containsObject:key]) {
        [_switchPrefKeys addObject:key];
    }
    
    [sw setTag:[_switchPrefKeys indexOfObject:key]];
    
    return cell;
}

- (void)switchChanged:(UISwitch *)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:[sender isOn] forKey:_switchPrefKeys[sender.tag]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}
@end
