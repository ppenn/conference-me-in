//
//  CMIDay.m
//  ConferenceMeIn
//
//  Created by philip penn on 2/10/12.
//  Copyright (c) 2012 Paleon Solutions. All rights reserved.
//

#import "CMIDay.h"
#import "CMIEvent.h"

@implementation CMIDay

@synthesize dateAtMidnight = _dateAtMidnight;
@synthesize cmiEvents = _cmiEvents;

- (id) initWithDay:(NSDate*)dateAtMidnight
{
    self = [super init];
    
    if (self != nil)
    {    
        _dateAtMidnight = dateAtMidnight;
        _cmiEvents = [[NSMutableArray alloc] init];
    }

    return self;
}


@end
