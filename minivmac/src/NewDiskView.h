#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern float NewDiskViewAnimationDuration;
extern CGRect NewDiskViewFrameHidden;
extern CGRect NewDiskViewFrameVisible;

@interface NewDiskView : UIView

@property (strong, nonatomic) UINavigationBar *navBar;
@property (strong, nonatomic) UILabel *nameLabel;
@property (strong, nonatomic) UILabel *secondSizeLabel;
@property (strong, nonatomic) UILabel *sizeLabel;
@property (strong, nonatomic) UITextField *nameField;
@property (strong, nonatomic) UISlider *sizeSlider;
@property (strong, nonatomic) UIImageView *iconView;

- (void)hide;
- (void)show;
- (void)sizeSliderChanged:(UISlider *)slider;
- (int)selectedImageSize;
@end
