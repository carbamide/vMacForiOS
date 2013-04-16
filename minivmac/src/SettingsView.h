#import <UIKit/UIKit.h>
#import <UIKit/UISwitch.h>


@interface SettingsView : UIView <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UINavigationBar *navBar;
@property (strong, nonatomic) UITableView *table;
@property (strong, nonatomic) UIToolbar *toolbar;
@property (strong, nonatomic) NSDictionary *layouts;
@property (strong, nonatomic) NSArray *layoutIDs;
@property (strong, nonatomic) NSMutableArray *switchPrefKeys;

- (void)hide;
- (void)show;
- (UITableViewCell *)cellWithIdentifier:(NSString *)cellIdentifier forTableView:(UITableView *)tableView;
- (UITableViewCell *)switchCellWithTitle:(NSString *)title forPrefsKey:(NSString *)key;
- (void)switchChanged:(UISwitch *)sender;
@end