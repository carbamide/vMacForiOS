#import "NewDiskView.h"
#import "AppDelegate.h"
#import "VirtualDiskDriveController.h"

float NewDiskViewAnimationDuration = 0.3;
CGRect NewDiskViewFrameHidden = { { 272.0, -158.0 }, { 480, 158.0 } };
CGRect NewDiskViewFrameVisible = { { 272.0, 0.0 }, { 480, 158.0 } };

@implementation NewDiskView
- (id)initWithFrame:(CGRect)rect
{
    if ((self = [super initWithFrame:rect]) != nil) {
        [self setBackgroundColor:[UIColor whiteColor]];
        
        _navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0, 0.0, rect.size.width, 48.0)];
        
        UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:nil];
        UIBarButtonItem *button = nil;
        
        button = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(hide)];
        [navItem setLeftBarButtonItem:button animated:NO];
        
        button = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"CreateDiskImage", nil) style:UIBarButtonItemStyleDone target:self action:@selector(createDiskImage)];
        [navItem setRightBarButtonItem:button animated:NO];
        
        [_navBar pushNavigationItem:navItem animated:NO];
        [self addSubview:_navBar];
        
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 63, 80, 21)];
        [_nameLabel setText:NSLocalizedString(@"Name:", nil)];
        [self addSubview:_nameLabel];
        
        _secondSizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 104, 80, 21)];
        [_secondSizeLabel setText:NSLocalizedString(@"Size:", nil)];
        [self addSubview:_secondSizeLabel];
        
        _sizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(380, 104, 80, 21)];
        [self addSubview:_sizeLabel];
        
        _iconView = [[UIImageView alloc] initWithFrame:CGRectMake(380, 57, 32, 32)];
        [self addSubview:_iconView];
        
        _nameField = [[UITextField alloc] initWithFrame:CGRectMake(108, 60, 264, 31)];
        [_nameField setBorderStyle:UITextBorderStyleRoundedRect];
        [self addSubview:_nameField];
        
        _sizeSlider = [[UISlider alloc] initWithFrame:CGRectMake(106, 104, 268, 23)];
        [_sizeSlider addTarget:self action:@selector(sizeSliderChanged:) forControlEvents:UIControlEventValueChanged];
        [_sizeSlider setMinimumValue:0.0];
        [_sizeSlider setMaximumValue:50.0];
        [_sizeSlider setValue:3.0];
        [_sizeSlider setContinuous:YES];
        
        [self addSubview:_sizeSlider];
    }
    
    return self;
}

- (void)hide
{
    [UIView animateWithDuration:NewDiskViewAnimationDuration
                     animations:^{
                         [self setFrame:NewDiskViewFrameHidden];
                     }
     
                     completion:^(BOOL finished) {
                         [_nameField resignFirstResponder];
                     }];
}

- (void)show
{
    [self sizeSliderChanged:_sizeSlider];
    
    [UIView animateWithDuration:NewDiskViewAnimationDuration
                     animations:^{
                         [self setFrame:NewDiskViewFrameVisible];
                     }
     
                     completion:^(BOOL finished) {
                         [_nameField becomeFirstResponder];
                     }];
}

- (void)createDiskImage
{
    [_nameField setText:[[_nameField text] stringByReplacingOccurrencesOfString:@"/" withString:@":"]];
    
    [[VirtualDiskDriveController sharedInstance] createDiskImage:[_nameField text] size:[self selectedImageSize]];
}

- (void)sizeSliderChanged:(UISlider *)slider
{
    int value = round(slider.value);
    
    if (value < 3) {
        value = 0;         // 400K
    }
    else if (value < 8) {
        value = 4;    // 800K
    }
    else if (value < 11) {
        value = 10;  // 1440K
    }
    
    [slider setValue:value];
    
    int imageSize = [self selectedImageSize];
    
    NSString *sizeString;
    
    if (imageSize < 2048) {
        sizeString = [NSString stringWithFormat:@"%d KiB", imageSize];
    }
    else {
        sizeString = [NSString stringWithFormat:@"%d MiB", imageSize / 1024];
    }
    
    [_sizeLabel setText:sizeString];
    
    if (imageSize <= 1440) {
        [_iconView setImage:[UIImage imageNamed:@"DiskListFloppy.png"]];
    }
    else {
        [_iconView setImage:[UIImage imageNamed:@"DiskListHD.png"]];
    }
}

- (int)selectedImageSize
{
    int value = [_sizeSlider value];
    
    int imageSize; // KiB
    
    if (value <= 9) {
        imageSize = (400 + value * 100);
    }
    else if (value == 10) {
        imageSize = 1440;
    }
    else if (value <= 29) {
        imageSize = (value - 9) * 1024;
    }
    else {
        imageSize = (25 + 5 * (value - 30)) * 1024;
    }
    
    return imageSize;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}
@end
