//
//  BPViewController.m
//  BlurEffect
//
//  Created by Justin C. Beck on 1/17/14.
//  Copyright (c) 2014 BeckProduct. All rights reserved.
//

#import "BPViewController.h"

#import "UIImage+ImageEffects.h"

#define drawerOpenX 795
#define drawerClosedX 970
#define drawerDeltaX (drawerClosedX - drawerOpenX) / 2
#define drawerMidX (drawerClosedX + drawerOpenX) / 2

@interface BPViewController ()
{
    UIView *_drawerView;
    UInt8 *_maskData;
    CGImageRef _maskRef;
    
    UIImageView *_backgroundImageView;
    UIImageView *_forgroundImageView;
}

@end

@implementation BPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImage *backgroundImage = [UIImage imageNamed:@"New-York-City-Colors.jpg"];
    
    _backgroundImageView = [[UIImageView alloc] initWithImage:backgroundImage];
    [_backgroundImageView setFrame:CGRectMake(0.0, 0.0, 1024.0, 768.0)];
    [[self view] addSubview:_backgroundImageView];
    
    _maskRef = [self createMask];
    
    UIGraphicsBeginImageContextWithOptions(_backgroundImageView.bounds.size, YES, [UIScreen mainScreen].scale);
    [backgroundImage drawInRect:CGRectMake(0.0, 0.0, 1024.0, 768.0)];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    UIColor *tintColor = [UIColor colorWithWhite:1.0 alpha:0.3];
    UIImage *blurredImage = [img applyBlurWithRadius:10 tintColor:tintColor saturationDeltaFactor:1.8 maskImage:nil];

    [_backgroundImageView setImage:blurredImage];
    
    UIImage *foregroundImage = [UIImage imageNamed:@"New-York-City-Colors.jpg"];
    CGImageRef maskedImageRef = CGImageCreateWithMask([foregroundImage CGImage], _maskRef);
    
    UIImage *maskedImage = [UIImage imageWithCGImage:maskedImageRef];
    
    _forgroundImageView = [[UIImageView alloc] initWithImage:maskedImage];
    [_forgroundImageView setFrame:CGRectMake(0.0, 0.0, 1024.0, 768.0)];
    
    [[self view] addSubview:_forgroundImageView];

    _drawerView = [[UIView alloc] initWithFrame:CGRectMake(drawerClosedX, 0.0, 1024.0, 768.0)];
    [_drawerView setBackgroundColor:[UIColor whiteColor]];
    [_drawerView setAlpha:0.2];
    [[self view] addSubview:_drawerView];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(actionDrawerPan:)];
    [panGesture setMinimumNumberOfTouches:1];
    [panGesture setMaximumNumberOfTouches:1];
    
    [_drawerView addGestureRecognizer:panGesture];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)actionDrawerPan:(UIPanGestureRecognizer *)panGesture
{
    UIView *actionsDrawerView = [panGesture view];
    CGRect drawerFrame = [actionsDrawerView frame];
    
    if ([panGesture state] == UIGestureRecognizerStateChanged)
    {
        CGPoint point = [panGesture translationInView:actionsDrawerView.superview];
        
        if (drawerFrame.origin.x + point.x < drawerClosedX && drawerFrame.origin.x + point.x > drawerOpenX)
        {
            _maskRef = [self updateMaskFrom:drawerFrame.origin.x to:drawerFrame.origin.x + point.x];
            
            UIImage *foregroundImage = [UIImage imageNamed:@"New-York-City-Colors.jpg"];
            CGImageRef maskedImageRef = CGImageCreateWithMask([foregroundImage CGImage], _maskRef);
            
            UIImage *maskedImage = [UIImage imageWithCGImage:maskedImageRef];
            [_forgroundImageView setImage:maskedImage];
            
            drawerFrame.origin.x += point.x;
        }
        
        [actionsDrawerView setFrame:drawerFrame];
        [panGesture setTranslation:CGPointZero inView:actionsDrawerView.superview];
    }
}

- (CGImageRef)createMask
{
    int width = 1024;
    int height = 768;
    int length = width * height * 4;
    
    _maskData = (UInt8 *)malloc(length * sizeof(UInt8));
    
    for (int j = 0; j < height; j++)
    {
        for (int i = 0; i < width; i++)
        {
            float red = 0.0;
            float green = 0.0;
            float blue = 0.0;
            float alpha = 1.0;
            
            if (i >= drawerClosedX)
            {
                red = 1.0;
                green = 1.0;
                blue = 1.0;
            }
            
            int index = 4 * (i + j * width);
            
            _maskData[index] = 255 * red;
            _maskData[++index] = 255 * green;
            _maskData[++index] = 255 * blue;
            _maskData[++index] = 255 * alpha;
        }
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, _maskData, length, NULL);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef imageRef = CGImageCreate(width, height, 8, 32, width * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast, provider, NULL, true, kCGRenderingIntentDefault);
    CGImageRef actualMask = CGImageMaskCreate(CGImageGetWidth(imageRef),
                                              CGImageGetHeight(imageRef),
                                              CGImageGetBitsPerComponent(imageRef),
                                              CGImageGetBitsPerPixel(imageRef),
                                              CGImageGetBytesPerRow(imageRef),
                                              CGImageGetDataProvider(imageRef), NULL, false);
    
    CGColorSpaceRelease(colorspace);
    CGDataProviderRelease(provider);
    
    return actualMask;
}

- (CGImageRef)updateMaskFrom:(float)originalX to:(float)newX
{
    int start = 0;
    int stop = 0;
    int length = 1024 * 768 * 4;
    BOOL opening = YES;
    
    if (originalX > newX)
    {
        start = newX;
        stop = originalX;
    }
    else
    {
        start = originalX;
        stop = newX;
        opening = NO;
    }
    
    for (int j = 0; j < 768; j++)
    {
        for (int i = start; i < stop; i++)
        {
            int index = 4 * (i + j * 1024);
            
            NSNumber *openingNum = [NSNumber numberWithBool:opening];
            float val = [openingNum floatValue];
            
            _maskData[index] = 255 * val;
            _maskData[++index] = 255 * val;
            _maskData[++index] = 255 * val;
        }
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, _maskData, length, NULL);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef imageRef = CGImageCreate(1024, 768, 8, 32, 1024 * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast, provider, NULL, true, kCGRenderingIntentDefault);
    CGImageRef actualMask = CGImageMaskCreate(CGImageGetWidth(imageRef),
                                              CGImageGetHeight(imageRef),
                                              CGImageGetBitsPerComponent(imageRef),
                                              CGImageGetBitsPerPixel(imageRef),
                                              CGImageGetBytesPerRow(imageRef),
                                              CGImageGetDataProvider(imageRef), NULL, false);
    
    CGColorSpaceRelease(colorspace);
    CGDataProviderRelease(provider);
    
    return actualMask;
}

@end
