//
//  BandView.m
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "BandView.h"

@implementation BandView

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        // Initialization code
    }
    return self;
}

- (id)initWithBandNum:(int)bandNum
{
    CGRect frame = CGRectMake((768.0 - BAND_WIDTH_P)/4, 
                              16.0 + (BAND_HEIGHT_P + 16.0)*bandNum, 
                              BAND_WIDTH_P, 
                              BAND_HEIGHT_P);
    if ((self = [super initWithFrame:frame]))
    {
        self.backgroundColor = [UIColor blueColor];
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
}

- (void)hide
{
    if (self.hidden)
        return;
    self.hidden = YES;
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
