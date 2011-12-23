//
//  EventInfo.m
//  Event Viewer
//
//  Created by Joshua Komusin on 12/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "EventInfo.h"
#import "Event.h"

@implementation EventInfo


- (id)initWithEventArray:(NSArray *)eventArr
{
    if ((self = [super init]))
    {
        CGRect frame = CGRectMake(0.0f, 0.0f, 200.0f, [eventArr count] * 50.0f);
        self.contentSizeForViewInPopover = CGSizeMake(200.0f, [eventArr count] * 50.0f);
        UIView *v = [[UIView alloc] initWithFrame:frame];
        v.backgroundColor = [UIColor whiteColor];
        for (int i = 0; i < [eventArr count]; i++)
        {
            Event *e = [eventArr objectAtIndex:i];
            CGRect xFrame = CGRectMake(0.0f, i * 50.0f, 200.0f, 25.0f);
            UILabel *x = [[UILabel alloc] initWithFrame:xFrame];
            x.text = [NSString stringWithFormat:@"X: %f", e.x];
            [v addSubview:x];
            
            CGRect wiFrame = CGRectMake(0.0f, i * 50.0f + 25.0f, 200.0f, 25.0f);
            UILabel *wi = [[UILabel alloc] initWithFrame:wiFrame];
            wi.text = [NSString stringWithFormat:@"Width: %f", e.width];
            [v addSubview:wi];
        }
        
        self.view = v;
    }
    
    return self;
}

@end
