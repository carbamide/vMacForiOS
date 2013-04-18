#import "SurfaceView.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import "CNFGGLOB.h"

PixelFormat kPixelFormat565L = "565L";
PixelFormat kPixelFormatARGB = "ARGB";

BOOL useColor;

NSLock *_lock = nil;

CGColorSpaceRef colorSpace;
CGDataProviderRef provider;
CGImageRef cgImage;
CGContextRef bitmap;
CGColorSpaceRef rgbColorSpace;

static unsigned char colorTable[] = { 0, 0, 0, 255, 255, 255, 0 };

#define kDefaultScalingFilter kCAFilterLinear

@implementation SurfaceView

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame pixelFormat:kPixelFormat565L surfaceSize:frame.size magnificationFilter:kDefaultScalingFilter minificationFilter:kDefaultScalingFilter];
}

- (id)initWithFrame:(CGRect)frame surfaceSize:(CGSize)size
{
    return [self initWithFrame:frame pixelFormat:kPixelFormat565L surfaceSize:size magnificationFilter:kDefaultScalingFilter minificationFilter:kDefaultScalingFilter];
}

- (id)initWithFrame:(CGRect)frame pixelFormat:(PixelFormat)pxf
{
    return [self initWithFrame:frame pixelFormat:pxf surfaceSize:frame.size magnificationFilter:kDefaultScalingFilter minificationFilter:kDefaultScalingFilter];
}

- (id)initWithFrame:(CGRect)frame pixelFormat:(PixelFormat)pxf surfaceSize:(CGSize)size
{
    return [self initWithFrame:frame pixelFormat:pxf surfaceSize:size magnificationFilter:kDefaultScalingFilter minificationFilter:kDefaultScalingFilter];
}

- (id)initWithFrame:(CGRect)frame pixelFormat:(PixelFormat)pxf scalingFilter:(NSString *)scalingFilter
{
    return [self initWithFrame:frame pixelFormat:pxf surfaceSize:frame.size magnificationFilter:scalingFilter minificationFilter:scalingFilter];
}

- (id)initWithFrame:(CGRect)frame pixelFormat:(PixelFormat)pxf surfaceSize:(CGSize)size scalingFilter:(NSString *)scalingFilter
{
    return [self initWithFrame:frame pixelFormat:pxf surfaceSize:size magnificationFilter:scalingFilter minificationFilter:scalingFilter];
}

- (id)initWithFrame:(CGRect)frame pixelFormat:(PixelFormat)pxf magnificationFilter:(NSString *)magnificationFilter minificationFilter:(NSString *)minificationFilter
{
    return [self initWithFrame:frame pixelFormat:pxf surfaceSize:frame.size magnificationFilter:magnificationFilter minificationFilter:minificationFilter];
}

- (id)initWithFrame:(CGRect)frame pixelFormat:(PixelFormat)pxf surfaceSize:(CGSize)size magnificationFilter:(NSString *)magnificationFilter minificationFilter:(NSString *)minificationFilter {
    // set values
    _pixelFormat = pxf;
    _surfaceSize = size;
    
    rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    if (self = [super initWithFrame:frame]) {
        int delta = 4;
        
        pixels = (unsigned char *)malloc(delta * vMacScreenNumBytes);
        
        provider = CGDataProviderCreateWithData(NULL, pixels,  delta * vMacScreenNumBytes, NULL);
        
        unsigned char *c;
        c = pixels;
        
        int i;
        
        for (i = 0; i < (delta * vMacScreenWidth * vMacScreenHeight); i++) {
            *c++ = 0;
        }
        
        _surfaceLayer = [CALayer layer];
        [_surfaceLayer setEdgeAntialiasingMask:15];
        [_surfaceLayer setFrame:frame];
        [_surfaceLayer setOpaque:YES];
        [_surfaceLayer setMagnificationFilter:magnificationFilter];
        [_surfaceLayer setMinificationFilter:minificationFilter];
        
        [[self layer] addSublayer:_surfaceLayer];
    }
    
    return self;
}

+ (id)defaultAnimationForKey:(NSString *)key
{
    return nil;
}

- (void)dealloc
{
    CGColorSpaceRelease(rgbColorSpace);
    CGDataProviderRelease(provider);
}

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    if ([event isEqualToString:@"position"] || [event isEqualToString:@"bounds"]) {
        return (id<CAAction>)[NSNull null];
    }
    
    return nil;
}

- (void)drawRect:(CGRect)rect
{
    if (!useColor) {
        colorSpace = CGColorSpaceCreateIndexed(rgbColorSpace, 1, colorTable);
        
        cgImage = CGImageCreate(
                                vMacScreenWidth,
                                vMacScreenHeight,
                                8,                   // bpc
                                8,                   // bpp
                                vMacScreenByteWidth, // bpr
                                colorSpace,
                                0,
                                provider,
                                NULL,
                                false,
                                kCGRenderingIntentDefault
                                );
        
        CGColorSpaceRelease(colorSpace);
    }
    else {
        cgImage = CGImageCreate(
                                vMacScreenWidth,
                                vMacScreenHeight,
                                8,                   // bpc
                                32,                  // bpp
                                4 * vMacScreenWidth, // bpr
                                rgbColorSpace,
                                //kCGBitmapByteOrder32Host| kCGImageAlphaNoneSkipLast,
                                kCGImageAlphaNone | kCGBitmapByteOrder32Little,
                                provider,
                                NULL,
                                NO,
                                kCGRenderingIntentDefault
                                );
    }
    
    // CoreAnimation seems to want to put a transition between each setContents
    // Set the CATransaction to disable the actions
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    [_surfaceLayer setContents:(__bridge id)cgImage];
    [CATransaction commit];
    
    CGImageRelease(cgImage);
}

- (void *)pixels
{
    return pixels;
}

- (void)useColorMode:(BOOL)color
{
    useColor = color;
}

- (PixelFormat)pixelFormat
{
    return _pixelFormat;
}

- (int)pixelSize
{
    if (_pixelFormat == kPixelFormat565L) {
        return 2;
    }
    
    return 4;
}

- (CGRect)frame
{
    return _fakeFrame;
}

- (void)setFrame:(CGRect)frame
{
    _fakeFrame = frame;
    
    frame = [self fixFrame:frame];
    
    [super setFrame:frame];
    
    if (_surfaceLayer) {
        [_surfaceLayer setFrame:frame];
    }
}

- (NSString *)magnificationFilter
{
    return [_surfaceLayer magnificationFilter];
}

- (void)setMagnificationFilter:(NSString *)magnificationFilter
{
    [_surfaceLayer setMagnificationFilter:magnificationFilter];
}

- (NSString *)minificationFilter
{
    return [_surfaceLayer minificationFilter];
}

- (void)setMinificationFilter:(NSString *)minificationFilter
{
    [_surfaceLayer setMinificationFilter:minificationFilter];
}

- (CGRect)fixFrame:(CGRect)frame
{
    int p = [self pixelSize];
    
    frame.origin.x /= p;
    frame.origin.y /= p;

    return frame;
}

@end
