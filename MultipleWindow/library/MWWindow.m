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
#define kWindowHeaderHeight 80

@interface MWWindow() {
    CGPoint _origin;
}
@end

@implementation MWWindow

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
        [self addGestureRecognizer:panGesture];
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
        return windows[index - 1];
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

- (void)onPan:(UIPanGestureRecognizer *)pan
{
    CGPoint translation = [pan translationInView:self];
    CGPoint velocity = [pan velocityInView:self];
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
            _origin = self.frame.origin;
            break;
        case UIGestureRecognizerStateChanged:
            if (_origin.y + translation.y >= 0) {
                self.transform = CGAffineTransformMakeTranslation(0, translation.y);
                CGFloat percentage = CGRectGetMinY(self.frame) /(CGRectGetHeight([UIScreen mainScreen].bounds) - kWindowHeaderHeight);
                [self updateTransitionAnimationWithPercentage:percentage];
                [self updateNextWindowTranslationIfNeeded];
            }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            CGPoint finalOrigin = CGPointZero;
            if (velocity.y >= 0) {
                finalOrigin.y = CGRectGetHeight([UIScreen mainScreen].bounds) - kWindowHeaderHeight;
            }
            CGRect f = self.frame;
            f.origin = finalOrigin;
            [UIView animateWithDuration:.5 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.transform = CGAffineTransformIdentity;
                self.frame = f;
                if (velocity.y < 0) {
                    [self cancelTransition];
                } else {
                    [self completeTransition];
                }
            } completion:^(BOOL finished) {
            }];
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
    UIWindow *window = self.superWindow;
    if (window) {
        window.transform = CGAffineTransformMakeScale(.95, .95);
        window.alpha = 0;
        if (kRecuriveAnimationEnabled && [window respondsToSelector:@selector(cancelTransition)]) {
            [(MWWindow *)window cancelTransition];
        }
    }
    UIWindow *nextWindow = self.nextWindow;
    if (nextWindow) {
        nextWindow.transform = CGAffineTransformIdentity;
    }
}

- (void)completeTransition
{
    UIWindow *window = self.superWindow;
    if (window) {
        window.transform = CGAffineTransformIdentity;
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
@end
