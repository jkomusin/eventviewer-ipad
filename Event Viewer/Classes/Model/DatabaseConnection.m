//
//  ServletConnection.m
//  Event Viewer
//
//  Created by Home on 1/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DatabaseConnection.h"

@implementation DatabaseConnection
{
    
}

@synthesize type = _type;
@synthesize panelIndex = _panelIndex;
@synthesize stackIndex = _stackIndex;
@synthesize bandIndex = _bandIndex;

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate ofType:(enum ConnectionType)type
{
    if ((self = [super initWithRequest:request delegate:delegate]))
    {
        self.type = type;
    }
    
    return self;
}

@end
