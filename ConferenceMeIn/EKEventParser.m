

//
//  EKEventParser.m
//  SimpleEKDemo
//
//  Created by philip penn on 1/18/12.
//  Copyright (c) 2012 Paleon Solutions. All rights reserved.
//

#import "EKEventParser.h"
#import "CMIUtility.h"

#define REGEX_PHONE_NUMBER_LOOK_BEHIND @"(?<![\\d\\/])"
#define REGEX_PHONE_NUMBER_LOOK_AHEAD @"(?!\\w)"

#define REGEX_CODE_SPECIFIC @"(?<!moderator\\s|leader\\s)\\b(pin|participant|password|passcode|code|access\\s\\#)[\\s:\\#=s\\(\\)]{1,20}\\d{3,12}[\\s-]?\\d{1,12}+[\\s-]?\\d{0,12}"

#define REGEX_CODE_GENERIC @"(?<![^\\d]\\d\\d\\d[^\\d])[\\d]{4,12}"
#define REGEX_NEWLINE @"[\\r|\\n]"

#define REGEX_SEPARATOR @"[^\\d]*"
#define REGEX_CODE_IN_FORMATTED_NUMBER @"(?<=,,)\\d{4,12}"

#define REGEX_LEADER_SEPARATOR_START @"(?<=,,)\\d{4,12}[^\\d]+"
#define REGEX_LEADER_CODE @"(?<=,,)\\d{4,12}[^\\d]+[\\d]{4,12}"

#define MAX_NEWLINES 4

static NSString* regexPhoneNumberPattern = nil;
static NSString* regexCountryTollFreePattern = nil;
static NSString* regexTollFreePattern = nil;
static NSString* regexPhoneNumberTollFreePattern = nil;

@implementation EKEventParser

//TODO: ugh, redo this.
+ (void)initializeStatics
{
    if (regexPhoneNumberPattern == nil) {
        regexPhoneNumberPattern = [CMIUtility getRegionValue:@"RegexPhoneNumberKey"];
        regexCountryTollFreePattern = [CMIUtility getRegionValue:@"RegexCountryTollFreeKey"];
        regexTollFreePattern = [CMIUtility getRegionValue:@"RegexTollFreeKey"];
        regexPhoneNumberTollFreePattern = [CMIUtility getRegionValue:@"RegexPhoneNumberTollFreeKey"];
    }
}

+ (NSString*)parseEvent:(EKEvent*)event
{
    return event.location;
}

+ (BOOL)phoneNumberContainsCode:(NSString*)phoneNumber
{
    if([phoneNumber rangeOfString:PHONE_CALL_SEPARATOR].location == NSNotFound) {
        return false;
    }
    else {
        return true;
    }

}

//NB: Can't get positive-lookbehind working for my regex :(
+ (NSString*)stripRegex:(NSString *)searchTerm regexToStrip:(NSString*)regexToStrip
{
    [CMIUtility Log:@"stripRegex()"];

	// Setup an error to catch stuff in 
	NSError *error = NULL;
	//Create the regular expression to match against
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexToStrip options:NSRegularExpressionCaseInsensitive error:&error];
	// create the new string by replacing the matching of the regex pattern with the template pattern(whitespace)
	NSString *newSearchString = [regex stringByReplacingMatchesInString:searchTerm options:0 range:NSMakeRange(0, [searchTerm length]) withTemplate:@""];	

//	NSLog(@"New string: %@",newSearchString);
	return newSearchString;
}

+ (NSString*)getLeaderSeparatorFromNumber:(NSString*)phoneNumber
{
    [CMIUtility Log:@"getLeaderSeparatorFromNumber()"];
    NSString* separator = nil;
    NSError* error = nil;
    
    NSRegularExpression *regexSeparator = [NSRegularExpression regularExpressionWithPattern:REGEX_LEADER_SEPARATOR_START
                                                                                    options:NSRegularExpressionCaseInsensitive
                                                                                      error:&error];
    
    NSRange range = [regexSeparator rangeOfFirstMatchInString:phoneNumber options:0 range:NSMakeRange(0, [phoneNumber  length])];
    if (range.location != NSNotFound) {
        separator = [EKEventParser stripRegex:[phoneNumber substringWithRange:range] regexToStrip:@"[\\d]"];
    }

    return separator;
}
+ (NSString*)getLeaderCodeFromNumber:(NSString*)phoneNumber
{
    [CMIUtility Log:@"getLeaderCodeFromNumber()"];
    NSString* leaderCode = nil;
    NSError* error = nil;
    
    NSRegularExpression *regexLeader = [NSRegularExpression regularExpressionWithPattern:REGEX_LEADER_SEPARATOR_START
                                                                                    options:NSRegularExpressionCaseInsensitive
                                                                                      error:&error];
    NSRegularExpression *regexCode = [NSRegularExpression regularExpressionWithPattern:REGEX_CODE_GENERIC
                                                                                 options:NSRegularExpressionCaseInsensitive
                                                                                   error:&error];

    NSRange range = [regexLeader rangeOfFirstMatchInString:phoneNumber options:0 range:NSMakeRange(0, [phoneNumber  length])];
    if (range.location != NSNotFound) {
        NSString* remainderText = [phoneNumber substringFromIndex:range.location];
        
        NSArray* codes = [regexCode matchesInString:remainderText options:0 range:NSMakeRange(0, [remainderText length])];
        
        if (codes != nil && [codes count] == 2) {
            NSTextCheckingResult* codeResult = (NSTextCheckingResult*)[codes objectAtIndex:1]; 
            leaderCode = [remainderText substringWithRange:codeResult.range];    
        }
    }
    
    return leaderCode;
}

+ (NSString*)getPhoneFromPhoneNumber:(NSString*)phoneText
{
    NSString* phoneNumber;

    NSRange range = [phoneText rangeOfString:PHONE_CALL_SEPARATOR];
    
    if (range.location != NSNotFound) {
        phoneNumber = [phoneText substringToIndex:range.location];
    }
    else {
        phoneNumber = phoneText;
    }    
    
    return phoneNumber;
}

+ (NSString*)getCodeFromNumber:(NSString*)phoneText
{
    [CMIUtility Log:@"getCodeFromNumber()"];

    NSString* code = nil;
    
	NSError *error = NULL;
	//Create the regular expression to match against
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:REGEX_CODE_IN_FORMATTED_NUMBER options:NSRegularExpressionCaseInsensitive error:&error];

    NSRange range = [regex rangeOfFirstMatchInString:phoneText options:0 range:NSMakeRange(0, [phoneText  length])];
    
    if (range.location != NSNotFound) {
        code = [phoneText substringWithRange:range];
    }
    return code;
}

+ (NSString*)parsePhoneNumber:(NSString*)eventText
{
    [CMIUtility Log:@"parsePhoneNumber()"];
    [EKEventParser initializeStatics];
    NSError *error = NULL;
    NSString* phoneNumber = @"";
    
    NSString* regexPattern = [@"" stringByAppendingFormat:@"%@%@%@", REGEX_PHONE_NUMBER_LOOK_BEHIND, regexPhoneNumberPattern, REGEX_PHONE_NUMBER_LOOK_AHEAD];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexPattern 
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    
    
    NSString *substringForFirstMatch = nil;
    NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:eventText options:0 range:NSMakeRange(0, [eventText  length])];
    if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
        substringForFirstMatch = [EKEventParser stripRegex:[eventText substringWithRange:rangeOfFirstMatch] regexToStrip:@"[^\\d]"];
        
        phoneNumber = [phoneNumber stringByAppendingString:substringForFirstMatch];
    }
    
    return phoneNumber;
}

+ (NSString*)tryToGetCodeSpecific:(NSString*)eventText
{
    [CMIUtility Log:@"tryToGetCodeSpecific()"];

    NSError *error = NULL;
    NSString* code = nil;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:REGEX_CODE_SPECIFIC
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    
    
    NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:eventText options:0 range:NSMakeRange(0, [eventText  length])];
    if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
        if ([EKEventParser maxNewLinesExceeded:eventText range:rangeOfFirstMatch] == NO) {
            code = [EKEventParser stripRegex:[eventText substringWithRange:rangeOfFirstMatch] regexToStrip:@"[^\\d]"];
        }
        else {
            [CMIUtility Log:@"MaxNewLines exceeded"];
        }
    }
        
    return code;
}

+ (NSString*)tryToGetCodeGeneric:(NSString*)eventText
{
    [CMIUtility Log:@"tryToGetCodeGeneric()"];
    if (eventText.length < 4)   return nil;

    NSError *error = NULL;
    NSString* PIN = nil;
    NSRegularExpression *regexPIN = [NSRegularExpression regularExpressionWithPattern:REGEX_CODE_GENERIC                                                                                                                   options:NSRegularExpressionCaseInsensitive                                                                                  error:&error];

    NSArray* possiblePINs = [regexPIN matchesInString:eventText options:0 range:NSMakeRange(0, [eventText length])];

    NSRange rangePIN;
    // for each potential pin, check it's not part of a phone number. return the first.
    for (NSTextCheckingResult* possiblePIN in possiblePINs) 
    {
        NSString* pinNumber = [eventText substringWithRange:possiblePIN.range];            
        PIN = pinNumber;
        rangePIN = possiblePIN.range;
        // Going to keep looking until I have one that doesn't look like a phone number...
        // I'll take the last one if they all look like phone numbers (potentially valid. may want to rm this)
        if ([EKEventParser textContainsPhoneNumber:pinNumber] == NO) {
            break;
        }
    }
    
    if (PIN != nil &&
        [EKEventParser maxNewLinesExceeded:eventText range:NSMakeRange(0, rangePIN.location)] == YES){            
        [CMIUtility Log:@"Maximum NewLines exceeded"];
        PIN = nil;
    }

    return PIN;
}

+ (BOOL)maxNewLinesExceeded:(NSString*)text range:(NSRange)range
{
    [CMIUtility Log:@"maxNewLinesExceeded()"];

    NSError *error = NULL;
    NSRegularExpression *regexNewline = [NSRegularExpression regularExpressionWithPattern:REGEX_NEWLINE                                                                                                 options:NSRegularExpressionCaseInsensitive                                                                                  error:&error];

    NSArray* possibleNewLines = [regexNewline matchesInString:text options:0 range:NSMakeRange(range.location, range.length)];
    if (possibleNewLines != nil && possibleNewLines.count > MAX_NEWLINES) {
        return YES;
    }
    else {
        return NO;
    }
}


+ (NSRange)tryToGetFirstPhone:(NSString*)eventText
{
    [CMIUtility Log:@"tryToGetFirstPhone()"];
    [EKEventParser initializeStatics];
    
    NSError *error = NULL;
    
    NSString* regexPattern = [@"" stringByAppendingFormat:@"%@%@%@", REGEX_PHONE_NUMBER_LOOK_BEHIND, regexPhoneNumberPattern, REGEX_PHONE_NUMBER_LOOK_AHEAD];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexPattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:eventText options:0 range:NSMakeRange(0, [eventText  length])];  
    
    return rangeOfFirstMatch;
}

+ (NSRange)tryToGetFirstTollFree:(NSString*)eventText
{
    [CMIUtility Log:@"tryToGetFirstTollFree()"];
    [EKEventParser initializeStatics];
    
    //This regex returns TOLL-FREE numbers...
    NSError *error = NULL;
    NSString* regexPattern = [@"" stringByAppendingFormat:@"%@%@%@", regexTollFreePattern, regexPhoneNumberTollFreePattern, REGEX_PHONE_NUMBER_LOOK_AHEAD];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexPattern                                                                                                                   options:NSRegularExpressionCaseInsensitive                                                                                  error:&error];
    
    NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:eventText options:0 range:NSMakeRange(0, [eventText  length])];
        
    return rangeOfFirstMatch;
}


+ (NSRange)tryToGetCountryTollFreePhone:(NSString*)eventText
{
    [CMIUtility Log:@"tryToGetCountryTollFreePhone()"];
    [EKEventParser initializeStatics];
    
    //This regex returns US and US TOLL-FREE numbers...
    NSError *error = NULL;
    
    NSString* regexPattern = [@"" stringByAppendingFormat:@"%@%@%@", regexCountryTollFreePattern, regexPhoneNumberTollFreePattern, REGEX_PHONE_NUMBER_LOOK_AHEAD];
    NSRegularExpression *regexCountryTollFree = [NSRegularExpression regularExpressionWithPattern:regexPattern                                                                                                                   options:NSRegularExpressionCaseInsensitive                                                                                  error:&error];
        
    NSRange rangeOfPhoneNumber = [regexCountryTollFree rangeOfFirstMatchInString:eventText options:0 range:NSMakeRange(0, [eventText length])];

    
    
    return rangeOfPhoneNumber;
}

+(BOOL) textContainsPhoneNumber:(NSString*)eventText
{
    [CMIUtility Log:@"textContainsPhoneNumber()"];

    NSRange range = [EKEventParser tryToGetFirstPhone:eventText];
    
    if (range.location == NSNotFound) {
        return NO;
    }
    else {
        return YES;
    }
}

+ (NSRange)tryToGetFirstTollFreeImplicit:(NSString*)eventText
{
    [CMIUtility Log:@"tryToGetFirstTollFreeImplicit()"];
    [EKEventParser initializeStatics];
    
    //This regex returns TOLL-FREE numbers...
    NSError *error = NULL;
    NSString* regexPattern = [@"" stringByAppendingFormat:@"%@%@%@", REGEX_PHONE_NUMBER_LOOK_BEHIND,regexPhoneNumberTollFreePattern, REGEX_PHONE_NUMBER_LOOK_AHEAD];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexPattern                                                                                                                   options:NSRegularExpressionCaseInsensitive                                                                                  error:&error];
    
    NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:eventText options:0 range:NSMakeRange(0, [eventText  length])];
    
    return rangeOfFirstMatch;

    
}

+ (NSRange)tryToGetPhone:(NSString*)eventText
{
    [CMIUtility Log:@"tryToGetPhone()"];

    NSRange range;
    if ([EKEventParser textContainsPhoneNumber:eventText] == NO){
        [CMIUtility Log:@"matched no phone #"];
        range.location = NSNotFound;
        return range;    
    }
    
    range = [EKEventParser tryToGetCountryTollFreePhone:eventText];
    if (range.location != NSNotFound) {
        [CMIUtility Log:@"matched Country TollFree"];
        return range;
    }
    // Try to Get the first Toll-Free number
    range = [EKEventParser tryToGetFirstTollFree:eventText];
    if (range.location != NSNotFound) {
        [CMIUtility Log:@"matched TollFree"];
        return range;
    }
    range = [EKEventParser tryToGetFirstTollFreeImplicit:eventText];
    if (range.location != NSNotFound) {
        [CMIUtility Log:@"matched TollFree Implicit"];
        return range;
    }
    
    range = [EKEventParser tryToGetFirstPhone:eventText];
    if (range.location != NSNotFound) {
        [CMIUtility Log:@"matched First Phone#"];
    }
    
    return range;
    
}

+ (NSString*)parseEventText:(NSString*)eventText
{
    [CMIUtility Log:@"parseEventText()"];
    
    NSString* conferenceNumber;
    
    CMIConferenceNumber* cmiConferenceNumber = [EKEventParser eventTextToConferenceNumber:eventText];

    conferenceNumber = cmiConferenceNumber.conferenceNumber == nil ? @"" : cmiConferenceNumber.conferenceNumber;

    return conferenceNumber;
}

+ (CMIConferenceNumber*)eventTextToConferenceNumber:(NSString*)eventText
{
    [CMIUtility Log:@"eventTextToConferenceNumber()"];

    CMIConferenceNumber* cmiConferenceNumber = [[CMIConferenceNumber alloc] init];

    if (eventText.length < 10)   return nil;
    
    NSString* phoneNumber = @"";
    
    // 2-phase pass, first of all find 
    NSRange rangeOfFirstMatch = [EKEventParser tryToGetPhone:eventText];
    if (rangeOfFirstMatch.location != NSNotFound) {
        NSString* firstSubstring = [eventText substringWithRange:rangeOfFirstMatch];
        [CMIUtility Log:firstSubstring];
        NSRange rangeOfSecondMatch = [EKEventParser tryToGetFirstPhone:firstSubstring];
        if (rangeOfSecondMatch.location != NSNotFound) {
            NSString *substringForSecondMatch = [EKEventParser stripRegex:[firstSubstring substringWithRange:rangeOfSecondMatch] regexToStrip:@"[^\\d]"];
            
            cmiConferenceNumber.phoneNumber = [phoneNumber stringByAppendingString:substringForSecondMatch];
            
            // Get PIN / Code. Try a couple of ways...
            NSUInteger afterPhoneNumberPosition = rangeOfFirstMatch.location + rangeOfSecondMatch.location + rangeOfSecondMatch.length;
            NSString* remainderText = [eventText substringFromIndex:afterPhoneNumberPosition];
            cmiConferenceNumber.code = [EKEventParser tryToGetCodeSpecific:eventText];
            if (cmiConferenceNumber.code == nil) {
                cmiConferenceNumber.code = [EKEventParser tryToGetCodeGeneric:remainderText];
            }
            if (cmiConferenceNumber.code != nil) {
                cmiConferenceNumber.codeSeparator = PHONE_CALL_SEPARATOR;
            }        
        }
    }    
    
    return cmiConferenceNumber;
}

+ (NSString*)parseIOSPhoneText:(NSString*)eventText
{
    [CMIUtility Log:@"parseIOSPhoneText()"];
    if (eventText.length < 10)   return nil;

    NSError *error = NULL;
    NSRegularExpression *regexCode = [NSRegularExpression regularExpressionWithPattern:REGEX_CODE_GENERIC 
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSRegularExpression *regexSeparator = [NSRegularExpression regularExpressionWithPattern:REGEX_SEPARATOR 
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:&error];
        
    NSString* phoneNumber = nil;
    NSRange range = [EKEventParser tryToGetFirstPhone:eventText];
    if (range.location != NSNotFound) {
        phoneNumber = [eventText substringWithRange:range];        
        phoneNumber = [EKEventParser stripRegex:phoneNumber regexToStrip:@"[^\\d]"];        
        
        NSRange rangeOfCode = [regexCode rangeOfFirstMatchInString:eventText options:0 range:NSMakeRange(range.location + range.length, [eventText  length]-(range.location + range.length))];
        if (rangeOfCode.location != NSNotFound) {
            phoneNumber = [phoneNumber stringByAppendingString:PHONE_CALL_SEPARATOR];
            phoneNumber = [phoneNumber stringByAppendingString:[eventText substringWithRange:rangeOfCode]];            
            
            NSRange rangeOfSeparator = [regexSeparator rangeOfFirstMatchInString:eventText options:0 range:NSMakeRange(rangeOfCode.location + rangeOfCode.length, [eventText  length] - (rangeOfCode.location + rangeOfCode.length))];
            if (rangeOfSeparator.location != NSNotFound) {
                phoneNumber = [phoneNumber stringByAppendingString:[eventText substringWithRange:rangeOfSeparator]];            

                NSRange rangeOfLeader = [regexCode rangeOfFirstMatchInString:eventText options:0 range:NSMakeRange(rangeOfSeparator.location + rangeOfSeparator.length, [eventText  length] - (rangeOfSeparator.location + rangeOfSeparator.length))];
                if (rangeOfLeader.location != NSNotFound) {
                    phoneNumber = [phoneNumber stringByAppendingString:[eventText substringWithRange:rangeOfLeader]];            
                }

            }
            
        }
    }    
    return phoneNumber;
    
}

@end
