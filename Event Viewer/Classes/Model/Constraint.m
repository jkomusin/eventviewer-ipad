//
//  Meta.m
//  Event Viewer
//
//  Created by Joshua Komusin on 1/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Constraint.h"

@implementation Constraint

@synthesize name = _name;
@synthesize description = _description;
@synthesize identifier = _identifier;
@synthesize type = _type;
//@synthesize ids = _ids;

- (id)initWithName:(NSString *)name description:(NSString *)desc
{
    if ((self = [super init]))
    { 
        _name = name;
        _description = desc;
//        _ids = [[NSDictionary alloc] init];
    }
    
    return self;
}

@end
