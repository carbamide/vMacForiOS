#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#import <QuartzCore/CALayer.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>



typedef const char * PixelFormat;
extern PixelFormat kPixelFormat565L;
extern PixelFormat kPixelFormatARGB;

@interface SurfaceView : UIView
{
    void *pixels;
}

@property (strong, nonatomic) CALayer *surfaceLayer;
@property (nonatomic) PixelFormat pixelFormat;
@property (nonatomic) CVImageBufferRef surfaceBuffer;
@property (nonatomic) CGSize surfaceSize;
@property (nonatomic) CGRect fakeFrame;
@property (nonatomic, readonly) void *pixels;
@property (nonatomic, readonly) int pixelSize;
@property (nonatomic, strong) NSString *magnificationFilter;
@property (nonatomic, strong) NSString *minificationFilter;

- (id)initWithFrame:(CGRect)frame pixelFormat:(PixelFormat)pxf;
- (id)initWithFrame:(CGRect)frame pixelFormat:(PixelFormat)pxf surfaceSize:(CGSize)size;
- (id)initWithFrame:(CGRect)frame pixelFormat:(PixelFormat)pxf scalingFilter:(NSString *)scalingFilter;
- (id)initWithFrame:(CGRect)frame pixelFormat:(PixelFormat)pxf surfaceSize:(CGSize)size scalingFilter:(NSString *)scalingFilter;
- (id)initWithFrame:(CGRect)frame pixelFormat:(PixelFormat)pxf magnificationFilter:(NSString *)magnificationFilter minificationFilter:(NSString *)minificationFilter;
- (id)initWithFrame:(CGRect)frame pixelFormat:(PixelFormat)pxf surfaceSize:(CGSize)size magnificationFilter:(NSString *)magnificationFilter minificationFilter:(NSString *)minificationFilter;
- (CGRect)fixFrame:(CGRect)frame;
- (void)useColorMode:(BOOL)useColor;
@end
