//
//  PanelView.m
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PanelView.h"

@implementation PanelView

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) 
    {
        // Initialization code
    }
    return self;
}

- (id)initWithStacks:(int)stackNum Bands:(int)bandNum
{
    CGRect frame = CGRectMake(0.0, 
                              0.0, 
                              768.0, 
                              (bandNum * (BAND_HEIGHT_P + 16.0) + 16.0) * stackNum);
    if ((self = [super initWithFrame:frame]))
    {
        NSMutableArray *mutableStacks = [[NSMutableArray alloc] init];
        
        for (int i = 0; i < stackNum; i++)
        {
            StackView *newStack = [[StackView alloc] initWithStackNum:i OutOf:stackNum WithBands:bandNum];
            [self addSubview:newStack];
            [mutableStacks addObject:newStack];
        }
        
        _stackViews = mutableStacks;
        
        CGFloat red =  (CGFloat)random()/(CGFloat)RAND_MAX;
        CGFloat blue = (CGFloat)random()/(CGFloat)RAND_MAX;
        CGFloat green = (CGFloat)random()/(CGFloat)RAND_MAX;
        self.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
        self.opaque = YES;
        self.hidden = YES;
    }
    
    return self;
}

- (void)unHide
{
    NSLog(@"Showing panel");
    if (!self.hidden)
        return;
    self.hidden = NO;
    for (StackView *s in _stackViews) 
    {
        [s unHide];
    }
}

- (void)hide
{
    NSLog(@"Hiding panel");
    if (self.hidden)
        return;
    self.hidden = YES;
    for (StackView *s in _stackViews) 
    {
        [s hide];
    }
}

- (void)drawRect:(CGRect)rect {
	/* Set UIView Border */
	// Get the contextRef
	CGContextRef contextRef = UIGraphicsGetCurrentContext();
    
	// Set the border width
	CGContextSetLineWidth(contextRef, 1.0);
    
	// Set the border color to RED
	CGContextSetRGBStrokeColor(contextRef, 0.0, 0.0, 0.0, 1.0);
    
	// Draw the border along the view edge
	CGContextStrokeRect(contextRef, rect);
}

@end
