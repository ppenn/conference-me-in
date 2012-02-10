//
//  CMIEventSystem.m
//  ConferenceMeIn
//
//  Created by philip penn on 1/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CMIEventSystem.h"

@implementation CMIEventSystem

@synthesize eventStore = _eventStore;
@synthesize fetchAllEvents = _fetchAllEvents;
@synthesize calendarType = _calendarType;
@synthesize defaultCalendar = _defaultCalendar;
@synthesize daysEvents = _daysEvents;
@synthesize eventDays = _eventDays;

- (id) init
{
    self = [super init];
    
    if (self != nil)
    {
        // your code here
        _eventStore = [[EKEventStore alloc] init];
        // Get the default calendar from store.
        _defaultCalendar = [_eventStore defaultCalendarForNewEvents];
        _calendarType = allCalendars;
        _fetchAllEvents = false;
        _daysEvents = [[NSMutableDictionary alloc] init];
        _eventDays = [[NSMutableArray alloc] init];
    }
    
    return self;    
}

- (BOOL)isSameDay:(NSDate*)date1 atDate2:(NSDate*)date2 {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    NSDateComponents* comp1 = [calendar components:unitFlags fromDate:date1];
    NSDateComponents* comp2 = [calendar components:unitFlags fromDate:date2];
    
    return [comp1 day]   == [comp2 day] &&
    [comp1 month] == [comp2 month] &&
    [comp1 year]  == [comp2 year];
}
+ (NSDate*) getOffsetDate:(NSDate*)today atOffsetDays:(NSInteger)offsetDays
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *offset = [[NSDateComponents alloc] init];
    
    [offset setDay:offsetDays];
    NSDate* nextDate = [calendar dateByAddingComponents:offset toDate:today options:0];
    
    return nextDate;
}


- (NSString*)formatDateAsDay:(NSDate*)date
{
	static NSDateFormatter *dateFormatter = nil;
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"EEEE MMMM d"];
	}

    NSDate *now = [[NSDate alloc] init];    
    NSDate* tomorrow = [CMIEventSystem getOffsetDate:now atOffsetDays:1];
    NSDate* yesterday = [CMIEventSystem getOffsetDate:now atOffsetDays:-1];
    NSString *dateString;
    
    if ([self isSameDay:now atDate2:date] == true) {
        dateString = @"Today";
    }
    else if ([self isSameDay:tomorrow atDate2:date] == true) {
        dateString = @"Tomorrow";
    } 
    else if ([self isSameDay:yesterday atDate2:date] == true) {
        dateString = @"Yesterday";
    } 
    else {
        dateString = [dateFormatter stringFromDate:date];        
    }
    
    return dateString;
}

+ (BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate
{
    if ([date compare:beginDate] == NSOrderedAscending)
        return NO;
    
    if ([date compare:endDate] == NSOrderedDescending) 
        return NO;
    
    return YES;
}

- (NSDate*) getMidnightDate:(NSDate*) date
{
    //TODO: centralize
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyyMMdd"];
    
    NSString* dateFormattedMidnight = [dateFormat stringFromDate:date];
    NSDate* eventDay = [dateFormat dateFromString:dateFormattedMidnight];  	

    return eventDay;
}

- (void) assignCMIEventsToDayEvents:(NSDate*)startDate atEndDate:(NSDate*)endDate atEvents:(NSArray*)events
{

    // Get the days together
    [self calculateDaysEvents:startDate atEndDate:endDate];

    // Now populate the number
    for (EKEvent* event in events) {
        // Need to convert date into day
        NSDate* eventDay = [self getMidnightDate:event.startDate];  	
        NSMutableArray *events = [_daysEvents objectForKey:eventDay];
        // Should we be creating CMIEvent?
        CMIEvent* cmiEvent = [[CMIEvent alloc] initWithEKEvent:event];
        [events addObject:cmiEvent];
        [_daysEvents setObject:events forKey:eventDay];        
    }

}

+ (BOOL)createTestEvent:(EKEventStore*)eventStore startDate:(NSDate*) startDate endDate:(NSDate*)endDate title:(NSString*)title withConfNumber:(BOOL)withConfNumber
{
    EKEvent *event = [EKEvent eventWithEventStore:eventStore];
    
    event.title = title; 
    
    event.startDate = startDate;
    event.endDate = endDate;// 
    event.location = withConfNumber ? @"1800 123 4567 xx 123456789" : @"nada" ; 
    [event setCalendar:[eventStore defaultCalendarForNewEvents]];
    NSError *err;
    BOOL isSuccess=[eventStore saveEvent:event span:EKSpanThisEvent error:&err];
    
    return isSuccess;
}

+ (void)removeAllSimulatorEvents:(EKEventStore*)eventStore
{
    NSDate *startDate = nil;
    NSString *dateStrStart = @"20120101";    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyyMMdd"];
    startDate = [dateFormat dateFromString:dateStrStart];  	
        
    NSDate* now = [[NSDate alloc] init];
    NSDate* endDate = [self getOffsetDate:now atOffsetDays:5];
        
    NSPredicate *predicate;
    predicate = [eventStore predicateForEventsWithStartDate:startDate endDate:endDate 
                                                               calendars:nil]; 
                    
        // Fetch all events that match the predicate.
    NSArray *events = [eventStore eventsMatchingPredicate:predicate];

      NSError* error = nil;
    for (EKEvent* event in events) {
        [eventStore removeEvent:event span:EKSpanThisEvent error:&error];
    }
            
}

+ (void)createTestEvents:(EKEventStore*)eventStore
{

#if TARGET_IPHONE_SIMULATOR
    // Simulator specific code
    
    [CMIEventSystem removeAllSimulatorEvents:eventStore];
    // Create some events
    
    NSDate* startDate = [[NSDate alloc] init];
    NSDate* endDate = [[NSDate alloc] initWithTimeInterval:60*60 sinceDate:startDate];
    NSDate* beforeStartDate = [[NSDate alloc] initWithTimeInterval:-(60*60) sinceDate:startDate];
    NSDate* beforeBeforeStartDate = [[NSDate alloc] initWithTimeInterval:-(2*60*60) sinceDate:beforeStartDate];
    
    [self createTestEvent:eventStore startDate:startDate endDate:endDate title:@"testtitle2" withConfNumber:TRUE];    
    [self createTestEvent:eventStore startDate:beforeStartDate endDate:startDate title:@"testtitle1" withConfNumber:TRUE];
    [self createTestEvent:eventStore startDate:beforeStartDate endDate:startDate title:@"NoConfNumEvent" withConfNumber:FALSE];
    [self createTestEvent:eventStore startDate:beforeBeforeStartDate endDate:beforeStartDate title:@"testtitle0" withConfNumber:TRUE];
    
    
#else // TARGET_IPHONE_SIMULATOR
    // Device specific code
#endif // TARGET_IPHONE_SIMULATOR    
    
}


- (void) calculateDaysEvents:(NSDate*)startDate atEndDate:(NSDate*)endDate
{
    [_daysEvents removeAllObjects];
    [_eventDays removeAllObjects];
    
    NSDate *nextDay=[startDate copy];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *offset = [[NSDateComponents alloc] init];
    
    int i = 0;

    while (([nextDay compare:endDate] == NSOrderedAscending))
    {
//        NSInteger numEvents = 0; //TODO: get # of events for that "day". going to need to get day range
        NSMutableArray* events = [[NSMutableArray alloc] init];
        NSDate* nextDayMidnight = [self getMidnightDate:nextDay];
        [_daysEvents setObject:events forKey:nextDayMidnight];
        [_eventDays addObject:nextDayMidnight];

        // Move to next day
        i++;
        [offset setDay:i];
        nextDay = [calendar dateByAddingComponents:offset toDate:startDate options:0];
    }

}

- (CMIEvent*)getCMIEvent:(NSInteger)dayEventIndex eventIndex:(NSInteger)eventIndex
{
    NSMutableArray* events = [_daysEvents objectForKey:[_eventDays objectAtIndex:dayEventIndex]];
    
    return (CMIEvent*)[events objectAtIndex:eventIndex];
}


- (NSArray *)fetchEvents
{
	NSDate *startDate = nil;
    if (_fetchAllEvents == true)
    {
        //TODO: date arithmetic
        NSString *dateStrStart = @"20120101";    
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyyMMdd"];
        startDate = [dateFormat dateFromString:dateStrStart];  	
    }
    else
    {
        startDate = [self getMidnightDate:[NSDate date]];
    }
	
    NSDate* now = [[NSDate alloc] init];
	NSDate* endDate = [CMIEventSystem getOffsetDate:now atOffsetDays:1];
	
    
    NSArray* calendarArray = nil; // All calendars
    NSPredicate *predicate;
    if (_calendarType == defaultCalendarType)
    {
        calendarArray = [NSArray arrayWithObject:_defaultCalendar];
        predicate = [self.eventStore predicateForEventsWithStartDate:startDate endDate:endDate 
                                                           calendars:calendarArray]; 
    }
    else
    {
        predicate = [self.eventStore predicateForEventsWithStartDate:startDate endDate:endDate 
                                                           calendars:nil]; 
        
    }
	
	// Fetch all events that match the predicate.
	NSArray *events = [self.eventStore eventsMatchingPredicate:predicate];
    NSArray *sortedEvents =
    [events sortedArrayUsingSelector:@selector(compareStartDateWithEvent:)];

    if (sortedEvents != nil && sortedEvents.count > 0) {
       startDate = [[sortedEvents objectAtIndex:0] startDate];
    }
    //    NSString *nsString = [((EKCalendarItem*)[events objectAtIndex:0]) notes];
    [self assignCMIEventsToDayEvents:startDate atEndDate:endDate atEvents:sortedEvents];
    
	return sortedEvents;
    
}

@end
