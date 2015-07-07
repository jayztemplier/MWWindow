//
//  MWWindow.m
//  MultipleWindow
//
//  Created by Jeremy Templier on 2/8/14.
// Copyright (c) 2014 Jeremy Templier
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MWWindow.h"

#define kRecuriveAnimationEnabled NO
#define kDuration .8
#define kDamping 0.75

@interface MWWindow() {
    CGPoint _origin;
}
@end

@implementation MWWindow

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _tapToCloseEnabled = NO;
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
        _panGesture.delegate = self;
        [self addGestureRecognizer:_panGesture];
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
        _tapGesture.delegate = self;
        [self addGestureRecognizer:_tapGesture];
        self.layer.cornerRadius = 10.0f;
        self.layer.shadowRadius = 5.0f;
        self.layer.shadowOffset = CGSizeMake(0,0);
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = .5f;
    }
    return self;
}

- (UIWindow *)superWindow
{
    NSArray * windows = [UIApplication sharedApplication].windows;
    NSInteger index = [windows indexOfObject:self];
    if (index) {
        if (![NSStringFromClass([windows[index - 1] class]) isEqualToString:@"UITextEffectsWindow"]) {
            return windows[index - 1];
        } else if ((index - 2) >= 0) {
            return windows[index - 2];
        }
    }
    return nil;
}

- (UIWindow *)nextWindow
{
    NSArray * windows = [UIApplication sharedApplication].windows;
    NSInteger index = [windows indexOfObject:self];
    if (index+1 < [windows count]) {
        return windows[index + 1];
    }
    return nil;
}

- (void)setPanGestureEnabled:(BOOL)enabled
{
    if (!enabled && [self.gestureRecognizers containsObject:_panGesture]) {
        [self removeGestureRecognizer:_panGesture];
    } else if (enabled && ![self.gestureRecognizers containsObject:_panGesture]) {
        [self addGestureRecognizer:_panGesture];
    }
}

- (void)onPan:(UIPanGestureRecognizer *)pan
{
    CGPoint translation = [pan translationInView:self];
    CGPoint velocity = [pan velocityInView:self];
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
            _origin = self.frame.origin;
            if (velocity.y == 0 || fabs(velocity.x) > fabs(velocity.y)) {
                [pan setEnabled:NO];
            } else if (self.superWindow && self.superWindow.windowLevel < UIWindowLevelStatusBar) {
                [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
            }

            if (self.superWindow) {
                UIWindow *window = self.superWindow;
                [window addSubview:window.rootViewController.view];
            }
            break;
        case UIGestureRecognizerStateChanged:
            if (_origin.y + translation.y >= 0) {
                self.transform = CGAffineTransformMakeTranslation(0, translation.y);
                CGFloat percentage = CGRectGetMinY(self.frame) /(CGRectGetHeight([UIScreen mainScreen].bounds) - kWindowHeaderHeight);
                [self updateTransitionAnimationWithPercentage:percentage];
                [self updateNextWindowTranslationIfNeeded];
            }
            break;
            
        case UIGestureRecognizerStateCancelled:
            [pan setEnabled:YES];
            break;
        case UIGestureRecognizerStateEnded:
        {
            [self transitionToDown:(velocity.y >= 0)];
        }
            break;
            
        default:
            break;
    }
}

- (void)updateTransitionAnimationWithPercentage:(CGFloat)percentage
{
    UIWindow *window = self.superWindow;
    if (window) {
        CGFloat scale = 1.0 - .05 * (1-percentage);
        window.transform = CGAffineTransformMakeScale(scale, scale);
        window.alpha = percentage;
        if (kRecuriveAnimationEnabled && [window respondsToSelector:@selector(updateTransitionAnimationWithPercentage:)]) {
            [(MWWindow *)window updateTransitionAnimationWithPercentage:percentage];
        }
    }
}

- (void)cancelTransition
{
    [self becomeKeyWindow];
    [self.rootViewController.view setUserInteractionEnabled:YES];
    UIWindow *window = self.superWindow;
    if (window) {
        window.transform = CGAffineTransformMakeScale(.95, .95);
        window.alpha = 0;
//        [window.rootViewController.view removeFromSuperview];
        if (kRecuriveAnimationEnabled && [window respondsToSelector:@selector(cancelTransition)]) {
            [(MWWindow *)window cancelTransition];
        }
    }
    UIWindow *nextWindow = self.nextWindow;
    if (nextWindow) {
        nextWindow.transform = CGAffineTransformIdentity;
    }
    [self updateStatusBarState];
}

- (void)completeTransition
{
    [self.rootViewController.view setUserInteractionEnabled:NO];
    UIWindow *window = self.superWindow;
    if (window) {
        [window becomeKeyWindow];
        window.transform = CGAffineTransformIdentity;
        window.frame = [UIScreen mainScreen].bounds;
        window.alpha = 1;
        if (kRecuriveAnimationEnabled && [window respondsToSelector:@selector(completeTransition)]) {
            [(MWWindow *)window completeTransition];
        }
    }
    [self completeNextWindowTranslation];
}

- (void)updateNextWindowTranslationIfNeeded
{
    UIWindow *nextWindow = self.nextWindow;
    if (nextWindow) {
        CGFloat diffY = fabs(CGRectGetMinY(nextWindow.frame) - CGRectGetMinY(self.frame));
        if (diffY < kWindowHeaderHeight) {
            nextWindow.transform = CGAffineTransformMakeTranslation(0, kWindowHeaderHeight-diffY);
        }
    }
}

- (void)completeNextWindowTranslation
{
    UIWindow *nextWindow = self.nextWindow;
    if (nextWindow) {
        nextWindow.transform = CGAffineTransformMakeTranslation(0, kWindowHeaderHeight);
    }
}

- (void)dismissWindowAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    void (^transitionOperations)() = ^{
        [self updateTransitionAnimationWithPercentage:1.0];
        CGRect f = self.frame;
        f.origin.y = [UIScreen mainScreen].bounds.size.height;
        self.frame = f;
    };
    
    if (animated) {
        [UIView animateWithDuration:kDuration delay:0.0 usingSpringWithDamping:kDamping initialSpringVelocity:1  options:UIViewAnimationOptionCurveEaseOut animations:^{
            transitionOperations();
        } completion:^(BOOL finished) {
            [self resignKeyWindow];
            [self removeFromSuperview];
        }];
    } else {
        transitionOperations();
        [self resignKeyWindow];
        [self removeFromSuperview];
    }
}

- (void)updateStatusBarState
{
    if ([[UIApplication sharedApplication] keyWindow].windowLevel >= UIWindowLevelStatusBar) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    }
}

- (void)presentWindowAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    void (^transitionOperations)() = ^{
        [self updateTransitionAnimationWithPercentage:0.0];
        self.frame = [UIScreen mainScreen].bounds;
    };
    
    if (animated) {
        [UIView animateWithDuration:kDuration delay:0.0 usingSpringWithDamping:kDamping initialSpringVelocity:1  options:UIViewAnimationOptionCurveEaseOut animations:^{
            transitionOperations();
        } completion:^(BOOL finished) {
            [self cancelTransition];
            completion();
        }];
    } else {
        transitionOperations();
        [self cancelTransition];
        completion();
    }
}

#pragma mark - Tap Gesture
- (void)onTap:(UITapGestureRecognizer *)gesture
{
    if (_tapToCloseEnabled) {
        [self showOrClose];
    }
}

- (void)showOrClose
{
    BOOL shouldGoDown = (self.frame.origin.y == 0);
    if (shouldGoDown) {
        if (self.superWindow && self.superWindow.windowLevel < UIWindowLevelStatusBar) {
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
        }
    }
    [self transitionToDown:shouldGoDown];
}

#pragma mark - Animated Transition
- (void)transitionToDown:(BOOL)shouldGoDown
{
    CGPoint finalOrigin = CGPointZero;
    if (shouldGoDown) {
        finalOrigin.y = CGRectGetHeight([UIScreen mainScreen].bounds) - kWindowHeaderHeight;
    }
    CGRect f = self.frame;
    f.origin = finalOrigin;
    [UIView animateWithDuration:kDuration delay:0.0 usingSpringWithDamping:kDamping initialSpringVelocity:1  options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.transform = CGAffineTransformIdentity;
        self.frame = f;
        if (shouldGoDown) {
            [self completeTransition];
        } else {
            [self cancelTransition];
        }
    } completion:^(BOOL finished) {
        if (shouldGoDown && _dismissWhenOnTheBottomOfTheScreen) {
            [self dismissWindowAnimated:NO completion:nil];
        }
    }];

}

#pragma mark Gesture Delegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (_tapGesture) {
        return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (gestureRecognizer == _panGesture) {
        if ([otherGestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
            UIScrollView *tableView = (UIScrollView *)otherGestureRecognizer.view;
            return tableView.contentOffset.y > 0;
        }
    }
    if (gestureRecognizer == _tapGesture) {
        return YES;
    }
    return NO;
}

+ (void)dismissAllMWWindows
{
    NSArray *windows = [[UIApplication sharedApplication] windows];
    for (UIWindow *window in windows) {
        if ([window isKindOfClass:[MWWindow class]]) {
            [(MWWindow *)window dismissWindowAnimated:YES completion:nil];
        }
    }
    UIWindow *window = [[UIApplication sharedApplication].delegate window];
    window.frame = [UIScreen mainScreen].bounds;
}
@end
