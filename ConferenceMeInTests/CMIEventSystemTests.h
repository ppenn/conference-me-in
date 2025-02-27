//
//  CMIEventSystemTests.h
//  ConferenceMeIn
//
//  Created by philip penn on 1/26/12.
//  Copyright (c) 2012 Paleon Solutions. All rights reserved.
//

//  Logic unit tests contain unit test code that is designed to be linked into an independent test executable.
//  See Also: http://developer.apple.com/iphone/library/documentation/Xcode/Conceptual/iphone_development/135-Unit_Testing_Applications/unit_testing_applications.html

#import <SenTestingKit/SenTestingKit.h>
#import "CMIEventCalendar.h"
#import <EventKit/EventKit.h>
#import <TargetConditionals.h>
#import "CMIUtility.h"

@interface CMIEventSystemTests : SenTestCase

@property (strong, nonatomic) CMIEventCalendar* cmiEventSystem;


@end
