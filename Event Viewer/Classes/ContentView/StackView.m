//
//  StackView.m
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "StackView.h"

@implementation StackView

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        // Initialization code
    }
    return self;
}

- (id)initWithStackNum:(int)stackNum OutOf:(int)stacks WithBands:(int)bandNum
{
    float height = (bandNum * (BAND_HEIGHT_P + 16.0) + 16.0);
    CGRect frame = CGRectMake((768.0 - BAND_WIDTH_P)/4, 
                              height * stackNum, 
                              512.0+128.0,//BAND_WIDTH_P + (BAND_WIDTH_P - 768.0)/2, 
                              height);
    if ((self = [super initWithFrame:frame]))
    {
        NSMutableArray *mutableBands = [[NSMutableArray alloc] init];
        
        for (int i = 0; i < bandNum; i++)
        {
            BandView *newBand = [[BandView alloc] initWithBandNum:i];
            [self addSubview:newBand];
            [mutableBands addObject:newBand];
        }
        
        _bandViews = mutableBands;
        
        self.backgroundColor = [UIColor greenColor];
        self.opaque = YES;
        self.hidden = YES;
    }
    
    return self;
}

- (void)unHide
{
    if (!self.hidden)
        return;
    self.hidden = NO;
    for (BandView *b in _bandViews) 
    {
        [b unHide];
    }
}

- (void)hide
{
    if (self.hidden)
        return;
    self.hidden = YES;
    for (BandView *b in _bandViews)
    {
        [b hide];
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
