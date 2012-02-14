//
//  Event.m
//  Event Viewer
//
//  Created by admin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Event.h"

@implementation Event

@synthesize start = _start;
@synthesize end = _end;
@synthesize x = _x;
@synthesize width = _width;
@synthesize year = _year;
@synthesize month = _month;
@synthesize day = _day;
@synthesize magnitude = _magnitude;


- (id)initWithStartTime:(NSDate *)start endTime:(NSDate *)end
{
    if ((self = [super init]))
    { 
        _start = start;
        _end = end;
    }
    
    return self;
}

@end
