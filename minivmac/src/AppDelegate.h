#import "Constants.h"

@class MainView;

@interface AppDelegate : UIApplication

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) MainView *mainView;
@property (nonatomic) BOOL initOk;

- (void)initPreferences;
- (void)didChangePreferences:(NSNotification *)aNotification;

@end

