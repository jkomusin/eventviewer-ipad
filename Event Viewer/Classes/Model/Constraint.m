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

- (id)initWithName:(NSString *)name
{
    if ((self = [super init]))
    { 
        _name = name;
    }
    
    return self;
}

@end
