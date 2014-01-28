//
//  BPViewController.m
//  BlurEffect
//
//  Created by Justin C. Beck on 1/17/14.
//  Copyright (c) 2014 BeckProduct. All rights reserved.
//

#import "BPViewController.h"

#import "UIImage+ImageEffects.h"

#define width 1024
#define maskWidth 1198
#define height 768
#define drawerOpenX 850
#define drawerClosedX 970
#define drawerDeltaX (drawerClosedX - drawerOpenX) / 2
#define drawerMidX (drawerClosedX + drawerOpenX) / 2

@interface BPViewController ()
{
    UIScrollView *_scrollView;
    NSNumber *_length;
    
    UIView *_drawerView;
    UInt8 *_maskData;
    CGImageRef _maskRef;
    CGImageRef _maskedImageRef;
    
    UIImageView *_backgroundImageView;
    UIImageView *_forgroundImageView;
    UIView *_controlView;
    UIView *_overlayView;
}

@end

@implementation BPViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        _length = [NSNumber numberWithInt:1198 * 1638 * 4];
        _maskData = malloc(sizeof(UInt8) * _length.intValue);
        _maskRef = [self createMask];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, 1024.0, 768.0)];
    [_scrollView setContentSize:CGSizeMake(1024.0, 1638.0)];
    [_scrollView setBounces:NO];
    [[self view] addSubview:_scrollView];
    
    UIImage *backgroundImage = [UIImage imageNamed:@"Wallpaper-of-Chess-World"];
    
    _backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, width, 1638.0)];
    [_scrollView addSubview:_backgroundImageView];
    
    UIGraphicsBeginImageContextWithOptions(_backgroundImageView.bounds.size, YES, [UIScreen mainScreen].scale);
    [backgroundImage drawInRect:CGRectMake(0.0, 0.0, width, 1638.0)];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    UIColor *tintColor = [UIColor colorWithWhite:1.0 alpha:0.3];
    UIImage *blurredImage = [img applyBlurWithRadius:10 tintColor:tintColor saturationDeltaFactor:1.8 maskImage:nil];

    [_backgroundImageView setImage:blurredImage];
    
    UIImage *mask = [UIImage imageWithCGImage:_maskRef];
    
    CALayer *maskLayer = [CALayer layer];
    [maskLayer setFrame:CGRectMake(0.0, 0.0, maskWidth, 1638)];
    [maskLayer setContents:(id) mask.CGImage];
    
    _forgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, width, 1638.0)];
    [_forgroundImageView setImage:[UIImage imageNamed:@"Wallpaper-of-Chess-World"]];
    _forgroundImageView.layer.mask = maskLayer;
    
    [_scrollView addSubview:_forgroundImageView];
    
    _controlView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, width, 1638.0)];
    [_controlView setBackgroundColor:[UIColor clearColor]];
    [_scrollView addSubview:_controlView];
    
    UIButton *forgroundButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [forgroundButton setFrame:CGRectMake(452.0, 120.0, 120.0, 40.0)];
    [forgroundButton addTarget:self action:@selector(pushTheButton:) forControlEvents:UIControlEventTouchUpInside];
    [forgroundButton setTitle:@"Tap me!" forState:UIControlStateNormal];
    [forgroundButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [[forgroundButton layer] setBorderWidth:1.0];
    [[forgroundButton layer] setBorderColor:[UIColor whiteColor].CGColor];
    [[forgroundButton layer] setCornerRadius:3.0];
    
    [_controlView addSubview:forgroundButton];
    
    _drawerView = [[UIView alloc] initWithFrame:CGRectMake(drawerClosedX, 0.0, 230.0, height)];
    [_drawerView setBackgroundColor:[UIColor clearColor]];
    [self addButtons];
    [[self view] addSubview:_drawerView];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(actionDrawerPan:)];
    [panGesture setMinimumNumberOfTouches:1];
    [panGesture setMaximumNumberOfTouches:1];
    
    [_drawerView addGestureRecognizer:panGesture];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionDrawerSnap:)];
    [_drawerView addGestureRecognizer:tapGesture];
}

- (void)addButtons
{
    UIButton *redButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [redButton setFrame:CGRectMake(7.0, 230.0, 40.0, 40.0)];
    [redButton addTarget:self action:@selector(redButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [[redButton layer] setCornerRadius:20.0];
    [[redButton layer] setBorderWidth:1.0];
    [[redButton layer] setBorderColor:[UIColor redColor].CGColor];
    
    UILabel *redLabel = [[UILabel alloc] initWithFrame:CGRectMake(57.0, 238.0, 150.0, 25.0)];
    [redLabel setText:@"It's RED"];
    [redLabel setTextColor:[UIColor redColor]];
    
    [_drawerView addSubview:redButton];
    [_drawerView addSubview:redLabel];
    
    UIButton *orangeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [orangeButton setFrame:CGRectMake(7.0, 300.0, 40.0, 40.0)];
    [orangeButton addTarget:self action:@selector(orangeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [[orangeButton layer] setCornerRadius:20.0];
    [[orangeButton layer] setBorderWidth:1.0];
    [[orangeButton layer] setBorderColor:[UIColor orangeColor].CGColor];
    
    UILabel *orangeLabel = [[UILabel alloc] initWithFrame:CGRectMake(57.0, 308.0, 150.0, 25.0)];
    [orangeLabel setText:@"It's ORANGE"];
    [orangeLabel setTextColor:[UIColor orangeColor]];
    
    [_drawerView addSubview:orangeButton];
    [_drawerView addSubview:orangeLabel];
    
    UIButton *yellowButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [yellowButton setFrame:CGRectMake(7.0, 370.0, 40.0, 40.0)];
    [yellowButton addTarget:self action:@selector(yellowButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [[yellowButton layer] setCornerRadius:20.0];
    [[yellowButton layer] setBorderWidth:1.0];
    [[yellowButton layer] setBorderColor:[UIColor yellowColor].CGColor];
    
    UILabel *yellowLabel = [[UILabel alloc] initWithFrame:CGRectMake(57.0, 378.0, 150.0, 25.0)];
    [yellowLabel setText:@"It's YELLOW"];
    [yellowLabel setTextColor:[UIColor yellowColor]];
    
    [_drawerView addSubview:yellowButton];
    [_drawerView addSubview:yellowLabel];
    
    UIButton *greenButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [greenButton setFrame:CGRectMake(7.0, 440.0, 40.0, 40.0)];
    [greenButton addTarget:self action:@selector(greenButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [[greenButton layer] setCornerRadius:20.0];
    [[greenButton layer] setBorderWidth:1.0];
    [[greenButton layer] setBorderColor:[UIColor greenColor].CGColor];
    
    UILabel *greenLabel = [[UILabel alloc] initWithFrame:CGRectMake(57.0, 448.0, 150.0, 25.0)];
    [greenLabel setText:@"It's GREEN"];
    [greenLabel setTextColor:[UIColor greenColor]];
    
    [_drawerView addSubview:greenButton];
    [_drawerView addSubview:greenLabel];
}

- (void)redButtonTapped:(id)sender
{
    [self flashColor:[UIColor redColor]];
}

- (void)orangeButtonTapped:(id)sender
{
    [self flashColor:[UIColor orangeColor]];
}

- (void)yellowButtonTapped:(id)sender
{
    [self flashColor:[UIColor yellowColor]];
}

- (void)greenButtonTapped:(id)sender
{
    [self flashColor:[UIColor greenColor]];
}

- (void)pushTheButton:(id)sender
{
    [self flashColor:[UIColor whiteColor]];
}

- (void)flashColor:(UIColor *)color
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, width, height)];
    [view setBackgroundColor:color];
    [view setAlpha:0.3];
    
    [[self view] addSubview:view];
    
    [UIView animateWithDuration:0.5 animations:^{
        [view setAlpha:0.0];
    } completion:^(BOOL finished) {
        [view removeFromSuperview];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)actionDrawerPan:(UIPanGestureRecognizer *)panGesture
{
    UIView *actionsDrawerView = [panGesture view];
    CGRect drawerFrame = [actionsDrawerView frame];
    CGRect maskFrame = _forgroundImageView.layer.bounds;
    
    float numerator = drawerFrame.origin.x - drawerOpenX;
    float denominator = drawerClosedX - drawerOpenX;
    float multiplier = 1 - (numerator / denominator);
    float alpha = 0.4 * multiplier;

    if ([panGesture state] == UIGestureRecognizerStateBegan)
    {
        if (drawerFrame.origin.x == drawerClosedX)
        {
            _overlayView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, width, 1638)];
            [_overlayView setBackgroundColor:[UIColor blackColor]];
            [_overlayView setAlpha:alpha];
            [_overlayView setUserInteractionEnabled:YES];
            
            [[self view] insertSubview:_overlayView belowSubview:_drawerView];
        }
    }
    else if ([panGesture state] == UIGestureRecognizerStateChanged)
    {
        CGPoint point = [panGesture translationInView:actionsDrawerView.superview];
        
        if (drawerFrame.origin.x + point.x < drawerClosedX && drawerFrame.origin.x + point.x > drawerOpenX)
        {
            maskFrame.origin.x -= point.x;
            drawerFrame.origin.x += point.x;
            
            float numerator = drawerFrame.origin.x - drawerOpenX;
            float denominator = drawerClosedX - drawerOpenX;
            float multiplier = 1 - (numerator / denominator);
            alpha = 0.4 * multiplier;
        }
        
        _forgroundImageView.layer.bounds = maskFrame;
        [actionsDrawerView setFrame:drawerFrame];
        [panGesture setTranslation:CGPointZero inView:actionsDrawerView.superview];
        [_overlayView setAlpha:alpha];
    }
    else if ([panGesture state] == UIGestureRecognizerStateEnded)
    {
        [self snapDrawer:drawerFrame.origin.x < drawerMidX];
    }
}

- (void)actionDrawerSnap:(UITapGestureRecognizer *)tapGesture
{
    CGRect drawerFrame = [_drawerView frame];
    if (drawerFrame.origin.x == drawerOpenX)
    {
        [self snapDrawer:NO];
    }
    else
    {
        _overlayView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, width, 1638)];
        [_overlayView setBackgroundColor:[UIColor blackColor]];
        [_overlayView setAlpha:0.0];
        [_overlayView setUserInteractionEnabled:YES];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionDrawerSnap:)];
        [_overlayView addGestureRecognizer:tapGesture];
        
        [[self view] insertSubview:_overlayView belowSubview:_drawerView];
        
        [self snapDrawer:YES];
    }
}

- (void)snapDrawer:(BOOL)open
{
    CGRect drawerFrame = [_drawerView frame];
    CGRect layerFrame = _forgroundImageView.layer.bounds;
    float alpha = 0.0;
    float duration = 0.0;
    
    if (open)
    {
        duration = (ABS(drawerFrame.origin.x - drawerOpenX) / drawerDeltaX)  * 0.3;
        drawerFrame.origin.x = drawerOpenX;
        layerFrame.origin.x = 120.0;
        alpha = 0.4;
    }
    else
    {
        duration = (ABS(drawerFrame.origin.x - drawerClosedX) / drawerDeltaX)  * 0.3;
        drawerFrame.origin.x = drawerClosedX;
        layerFrame.origin.x = 0;
    }
    
    [UIView animateWithDuration:duration animations:^{
        [_drawerView setFrame:drawerFrame];
        _forgroundImageView.layer.bounds = layerFrame;
        [_overlayView setAlpha:alpha];
    } completion:^(BOOL finished) {
        if (!open)
        {
            [_overlayView removeFromSuperview];
            _overlayView = nil;
        }
        else
        {
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionDrawerSnap:)];
            [_overlayView addGestureRecognizer:tapGesture];
        }
    }];
}

- (CGImageRef)createMask
{
    for (int j = 0; j < 1638; j++)
    {
        for (int i = 0; i < maskWidth; i++)
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
            
            int index = 4 * (i + j * maskWidth);
            
            _maskData[index] = 255 * red;
            _maskData[++index] = 255 * green;
            _maskData[++index] = 255 * blue;
            _maskData[++index] = 255 * alpha;
        }
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, _maskData, _length.intValue, NULL);
    CGImageRef actualMask = CGImageMaskCreate(maskWidth, 1638, 8, 32, maskWidth * 4, provider, NULL, false);
    
    CGDataProviderRelease(provider);
    
    return actualMask;
}

@end
