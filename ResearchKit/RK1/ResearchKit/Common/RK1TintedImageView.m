/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 Copyright (c) 2015, Ricardo Sánchez-Sáez.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "RK1TintedImageView.h"
#import "RK1TintedImageView_Internal.h"

#import "RK1Helpers_Internal.h"


#define RK1TintedImageLog(...)

RK1_INLINE BOOL RK1IsImageAnimated(UIImage *image) {
    return image.images.count > 1;
}

UIImage *RK1ImageByTintingImage(UIImage *image, UIColor *tintColor, CGFloat scale) {
    if (!image || !tintColor || !(scale > 0)) {
        return nil;
    }
    
    RK1TintedImageLog(@"%@ %@ %f", image, tintColor, scale);
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, scale);
    CGContextRef context     = UIGraphicsGetCurrentContext();
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextSetAlpha(context, 1);
    
    CGRect r = (CGRect){{0,0},image.size};
    CGContextBeginTransparencyLayerWithRect(context, r, NULL);
    [tintColor setFill];
    [image drawInRect:r];
    UIRectFillUsingBlendMode(r, kCGBlendModeSourceIn);
    CGContextEndTransparencyLayer(context);
    
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return outputImage;
}


@interface RK1TintedImageCacheKey : NSObject

- (instancetype)initWithImage:(UIImage *)image tintColor:(UIColor *)tintColor scale:(CGFloat)scale;

@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, readonly) UIColor *tintColor;
@property (nonatomic, readonly) CGFloat scale;

@end


@implementation RK1TintedImageCacheKey {
    UIImage *_image;
    UIColor *_tintColor;
    CGFloat _scale;
}

- (instancetype)initWithImage:(UIImage *)image tintColor:(UIColor *)tintColor scale:(CGFloat)scale {
    self = [super init];
    if (self) {
        _image = image;
        _tintColor = tintColor;
        _scale = scale;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    return (RK1EqualObjects(self.image, castObject.image)
            && RK1EqualObjects(self.tintColor, castObject.tintColor)
            && RK1CGFloatNearlyEqualToFloat(self.scale, castObject.scale));
}

@end


@interface RK1TintedImageCache ()

- (UIImage *)tintedImageForImage:(UIImage *)image tintColor:(UIColor *)tintColor scale:(CGFloat)scale;

@end


@implementation RK1TintedImageCache

+ (instancetype)sharedCache
{
    static dispatch_once_t onceToken;
    static id sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (UIImage *)tintedImageForImage:(UIImage *)image tintColor:(UIColor *)tintColor scale:(CGFloat)scale {
    UIImage *tintedImage = nil;
    
    RK1TintedImageCacheKey *key = [[RK1TintedImageCacheKey alloc] initWithImage:image tintColor:tintColor scale:scale];
    tintedImage = [self objectForKey:key];
    if (!tintedImage) {
        tintedImage = RK1ImageByTintingImage(image, tintColor, scale);
        if (tintedImage) {
            [self setObject:tintedImage forKey:key];
        }
    }
    return tintedImage;
}

- (void)cacheImage:(UIImage *)image tintColor:(UIColor *)tintColor scale:(CGFloat)scale {
    [[RK1TintedImageCache sharedCache] tintedImageForImage:image tintColor:tintColor scale:scale];
}

@end


@implementation RK1TintedImageView {
    UIImage *_originalImage;
    UIImage *_tintedImage;
    UIColor *_appliedTintColor;
    CGFloat _appliedScaleFactor;
}

- (void)setShouldApplyTint:(BOOL)shouldApplyTint {
    _shouldApplyTint = shouldApplyTint;
    self.image = _originalImage;
}

- (UIImage *)imageByTintingImage:(UIImage *)image {
    if (!image || (image.renderingMode == UIImageRenderingModeAlwaysOriginal
                   || (image.renderingMode == UIImageRenderingModeAutomatic && !_shouldApplyTint))) {
        return image;
    }
    
    UIColor *tintColor = self.tintColor;
    CGFloat screenScale = self.window.screen.scale; // Use screen.scale; self.contentScaleFactor remains 1.0 until later
    if (screenScale > 0 && (![_appliedTintColor isEqual:tintColor] || !RK1CGFloatNearlyEqualToFloat(_appliedScaleFactor, screenScale))) {
        _appliedTintColor = tintColor;
        _appliedScaleFactor = screenScale;
        
        if (!RK1IsImageAnimated(image)) {
            if (_enableTintedImageCaching) {
                _tintedImage = [[RK1TintedImageCache sharedCache] tintedImageForImage:image tintColor:tintColor scale:screenScale];
            } else {
                _tintedImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
        } else {
            // Manually apply the tint for animated images (template rendering mode doesn't work: <rdar://problem/19792197>)
            NSArray *animationImages = image.images;
            NSMutableArray *tintedAnimationImages = [[NSMutableArray alloc] initWithCapacity:animationImages.count];
            for (UIImage *animationImage in animationImages) {
                UIImage *tintedAnimationImage = nil;
                if (_enableTintedImageCaching) {
                    tintedAnimationImage = [[RK1TintedImageCache sharedCache] tintedImageForImage:animationImage tintColor:tintColor scale:screenScale];
                } else {
                    tintedAnimationImage = RK1ImageByTintingImage(animationImage, tintColor, screenScale);
                }
                if (tintedAnimationImage) {
                    [tintedAnimationImages addObject:tintedAnimationImage];
                }
            }
            _tintedImage = [UIImage animatedImageWithImages:tintedAnimationImages duration:image.duration];
        }
    }
    return _tintedImage;
}

- (void)setImage:(UIImage *)image {
    _originalImage = image;
    image = [self imageByTintingImage:image];
    [super setImage:image];
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    // recompute for new tint color
    self.image = _originalImage;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    // recompute for new screen.scale
    self.image = _originalImage;
}

@end
