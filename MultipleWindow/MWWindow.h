//
//  MWWindow.h
//  MultipleWindow
//
//  Created by Jeremy Templier on 2/8/14.
//  Copyright (c) 2014 Jeremy Templier. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MWWindow : UIWindow
@property (nonatomic, readonly) UIWindow *superWindow;
@property (nonatomic, readonly) UIWindow *nextWindow;
@end
