//
//  MWViewController.m
//  MultipleWindow
//
//  Created by Jeremy Templier on 2/8/14.
//  Copyright (c) 2014 Jeremy Templier. All rights reserved.
//

#import "MWViewController.h"
#import "MWWindow.h"

@interface MWViewController ()
@property (nonatomic, strong) MWWindow *nextWindow;
@end

@implementation MWViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIColor *)randomColor {
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
    return color;
}

- (IBAction)pushWindowPressed:(id)sender
{
    if (_nextWindow) {
        [_nextWindow removeFromSuperview];
    }
    _nextWindow = [[MWWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [_nextWindow setBackgroundColor:[self randomColor]];
    _nextWindow.windowLevel = UIWindowLevelStatusBar;
    MWViewController *vc = [[MWViewController alloc] initWithNibName:@"MWViewController" bundle:nil];
    vc.view.backgroundColor = [UIColor clearColor];
    _nextWindow.rootViewController = vc;
    [_nextWindow makeKeyAndVisible];

}

@end
