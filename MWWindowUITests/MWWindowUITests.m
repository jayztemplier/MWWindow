//
//  MWWindowUITests.m
//  MWWindowUITests
//
//  Created by Jeremy Templier on 07/07/15.
//  Copyright © 2015 Jeremy Templier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "MWWindow.h"

@interface MWWindowUITests : XCTestCase

@end

@implementation MWWindowUITests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    [[[XCUIApplication alloc] init] launch];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCreateAndSwipeDownWindows {
    // Use recording to get started writing UI tests.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    XCUIApplication *app = [[XCUIApplication alloc] init];
    
    XCUIElement *window_1 = [app.windows elementAtIndex:app.windows.count-1];
    [window_1.buttons[@"Push Window"] tap];
    
    
    XCUIElement *window_2 = [app.windows elementAtIndex:app.windows.count-1];
    [window_2.buttons[@"Push"] tap];
    
    XCUIElement *window_3 = [app.windows elementAtIndex:app.windows.count-1];
    [window_3 swipeDown];
    [window_2 swipeDown];
    [window_2 tap];
}

@end
