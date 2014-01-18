//
//  BPViewController.m
//  BlurEffect
//
//  Created by Justin C. Beck on 1/17/14.
//  Copyright (c) 2014 BeckProduct. All rights reserved.
//

#import "BPViewController.h"

#import "BPActionsViewController.h"
#import "UIImage+ImageEffects.h"

#define drawerOpenX 795
#define drawerClosedX 970
#define drawerDeltaX (drawerClosedX - drawerOpenX) / 2
#define drawerMidX (drawerClosedX + drawerOpenX) / 2

@interface BPViewController ()
{
    BPActionsViewController *_avc;
    UInt8 *_maskData;
}
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;

@end

@implementation BPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _avc = [[self childViewControllers] objectAtIndex:0];
    CGRect avcFrame = [[_avc view] frame];
    avcFrame.origin.x = drawerClosedX;
    
    [[_avc view] setFrame:avcFrame];
    [[_avc view] setAlpha:0.5];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(actionDrawerPan:)];
    [panGesture setMinimumNumberOfTouches:1];
    [panGesture setMaximumNumberOfTouches:1];
    
    [[_avc view] addGestureRecognizer:panGesture];
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
    
    UIImageView *blurImageView;
    
    CGPoint point = [panGesture translationInView:actionsDrawerView.superview];
    CGImageRef maskRef = nil;
    
    if ([panGesture state] == UIGestureRecognizerStateBegan)
    {
        maskRef = [self createMask];
        UIImage *maskImage = [[UIImage alloc] initWithCGImage:maskRef];

        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, self.view.opaque, 0);
        [[self view] drawViewHierarchyInRect:CGRectMake(0.0, 0.0, 1024.0, 768.0) afterScreenUpdates:YES];
        UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        UIColor *tintColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        [img applyBlurWithRadius:30 tintColor:tintColor saturationDeltaFactor:1.8 maskImage:maskImage];

        blurImageView = [[UIImageView alloc] initWithImage:img];
        [blurImageView setFrame:CGRectMake(0.0, 0.0, 1024.0, 768.0)];
        [[self backgroundImageView] addSubview:blurImageView];
    }
    else if ([panGesture state] == UIGestureRecognizerStateChanged)
    {
        if (drawerFrame.origin.x + point.x < drawerClosedX && drawerFrame.origin.x + point.x > drawerOpenX)
        {
            maskRef = [self updateMaskFrom:drawerFrame.origin.x to:drawerFrame.origin.x + point.x];
            
            UIImage *maskImage = [[UIImage alloc] initWithCGImage:maskRef];
            
            UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, self.view.opaque, 0);
            [[self view] drawViewHierarchyInRect:CGRectMake(0.0, 0.0, 1024.0, 768.0) afterScreenUpdates:YES];
            UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();

            UIColor *tintColor = [UIColor colorWithWhite:1.0 alpha:0.3];
            [img applyBlurWithRadius:30 tintColor:tintColor saturationDeltaFactor:1.8 maskImage:maskImage];
            [blurImageView setImage:img];

            drawerFrame.origin.x += point.x;
        }
        
        [actionsDrawerView setFrame:drawerFrame];
        [panGesture setTranslation:CGPointZero inView:actionsDrawerView.superview];
    }
    else if([panGesture state] == UIGestureRecognizerStateEnded)
    {
        if (drawerFrame.origin.x < drawerMidX)
        {
            [self snapDrawer:YES];
        }
        else
        {
            [self snapDrawer:NO];
        }
    }
}

- (void)snapDrawer:(Boolean)open
{
    BPActionsViewController *avc = [[self childViewControllers] objectAtIndex:0];
    
    CGRect drawerFrame = [[avc view] frame];
    float duration = 0.0;
    
    if (open)
    {
        duration = (ABS(drawerFrame.origin.x - drawerOpenX) / drawerDeltaX)  * 0.3;
        drawerFrame.origin.x = drawerOpenX;
    }
    else
    {
        duration = (ABS(drawerFrame.origin.x - drawerClosedX) / drawerDeltaX)  * 0.3;
        drawerFrame.origin.x = drawerClosedX;
    }
    
    [UIView animateWithDuration:duration animations:^{
        [[avc view] setFrame:drawerFrame];
    }];
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
            
            if (i <= 900)
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
    
    CGColorSpaceRelease(colorspace);
    CGDataProviderRelease(provider);
    
    return imageRef;
}

- (CGImageRef)updateMaskFrom:(float)originalX to:(float)newX
{
    int start = 0;
    int stop = 0;
    int length = 1024 * 768 * 4;
    
    if (originalX > newX)
    {
        start = newX;
        stop = originalX;
    }
    else
    {
        start = originalX;
        stop = newX;
    }
    
    for (int j = 0; j < 768; j++)
    {
        for (int i = start; i < stop; i++)
        {
            int index = 4 * (i + j * 1024);
            
            _maskData[index] = 255 * 1.0;
            _maskData[++index] = 255 * 1.0;
            _maskData[++index] = 255 * 1.0;
        }
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, _maskData, length, NULL);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef imageRef = CGImageCreate(1024, 768, 8, 32, 1024 * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast, provider, NULL, true, kCGRenderingIntentDefault);
    
    CGColorSpaceRelease(colorspace);
    CGDataProviderRelease(provider);
    
    return imageRef;
}

@end
