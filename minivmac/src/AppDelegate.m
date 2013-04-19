#import "AppDelegate.h"
#import "MainView.h"
#import "EmulationManager.h"

@interface UIWindow (Additions)
- (void)makeKey:(id)arg1;
- (void)orderFront:(id)arg1;
- (void)setContentView:(id)arg1;
@end

@interface AppDelegate ()
@end

IMPORTFUNC blnr InitEmulation(void);

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setInitOk:[[EmulationManager sharedManager] initEmulation]];
    [self initPreferences];
    
    CGRect windowFrame;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad == YES) {
        windowFrame = CGRectMake(0, 0, 1024, 768);
    }
    else {
        windowFrame = CGRectMake(0, 0, 480, 320);
    }
    
    [self setWindow:[[UIWindow alloc] initWithFrame:windowFrame]];
    
    if (IPAD()==YES) {
        [_window setTransform:CGAffineTransformMake(0, 1, -1, 0, -128, 128)];
    }
    else {
        //this is a flaming pile of dog crap and a stupid way of doing this.
        //I think probably a curse word would help, so I'm going to curse.
        //Fuck.
        [_window setTransform:CGAffineTransformMake(0, 1, -1, 0, -80, 120)];
    }
    
    [self setMainView:[[MainView alloc] initWithFrame:windowFrame]];
    
    [_window setContentView:_mainView];
    [_window makeKeyAndVisible];
    
    if (_initOk) {
        [[EmulationManager sharedManager] startEmulation:self];
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[EmulationManager sharedManager] suspendEmulation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[EmulationManager sharedManager] resumeEmulation];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[EmulationManager sharedManager] suspendEmulation];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initPreferences
{    
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
     @"KeyboardLayout": @"US",
     @"ScreenSizeToFit": [NSNumber numberWithBool:YES],
     @"KeyboardAlpha": [NSNumber numberWithFloat:0.8],
     @"ScreenPosition": [NSNumber numberWithInt:dirUp | dirLeft],
     @"Sound Enabled": [NSNumber numberWithBool:YES],
     @"DiskEjectSound": [NSNumber numberWithBool:YES],
     @"TrackpadMode": [NSNumber numberWithBool:NO],
     @"KeyboardSound": [NSNumber numberWithBool:YES],
     @"CanDeleteDiskImages": [NSNumber numberWithBool:YES]}];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangePreferences:) name:NSUserDefaultsDidChangeNotification object:nil];
}

- (void)didChangePreferences:(NSNotification *)aNotification
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SoundEnabled"]) {
        MySound_Start();
    }
    else {
        MySound_Stop();
    }
}

@end
