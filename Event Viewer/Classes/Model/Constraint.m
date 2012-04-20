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
@synthesize leaf = _leaf;


- (id)initWithName:(NSString *)name description:(NSString *)desc
{
    if ((self = [super init]))
    { 
        _name = name;
        _description = desc;
    }
    
    return self;
}

- (BOOL)isEqual:(id)object
{
	if ([object isKindOfClass:[Constraint class]])
	{
		Constraint *c = (Constraint *)object;
		if (self.type != c.type || self.identifier != c.identifier)
		{
			return NO;
		}
		return YES;
	}
	return NO;
}

- (NSUInteger)hash
{
	return [_name hash] ^ [_description hash] ^ _identifier ^ [_type hash];
}

@end
