//
//  CMIMyConferenceNumber.h
//  ConferenceMeIn
//
//  Created by philip penn on 2/18/12.
//  Copyright (c) 2012 Paleon Solutions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CMIUserDefaults.h"

@interface CMIMyConferenceNumber : NSObject

- (id) initWithUserDefaults:(CMIUserDefaults*)cmiUserDefaults;

@property (nonatomic,strong) CMIUserDefaults* cmiUserDefaults;
@property BOOL isValid;
@property (readonly, nonatomic,strong) NSString* conferenceNumberFormatted;

@property (readonly, nonatomic,strong) NSString* conferenceNumber;
@property (readonly, nonatomic,strong) NSString* leaderInfo;
@property (readonly, nonatomic,strong) NSString* fullConferenceNumber;

@end
