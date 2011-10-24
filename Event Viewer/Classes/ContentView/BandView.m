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

- (id)initWithBandNum:(int)bandNum OfColor:(UIColor *)color
{
    CGRect frame = CGRectMake((768.0 - BAND_WIDTH_P)/4, 
                              16.0 + (BAND_HEIGHT_P + 16.0)*bandNum, 
                              BAND_WIDTH_P, 
                              BAND_HEIGHT_P);
    if ((self = [super initWithFrame:frame]))
    {
        self.backgroundColor = [UIColor whiteColor];
        self.opaque = YES;
        self.hidden = YES;
        _isStatic = NO;
        _color = color;
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

- (void)toggleOverlay
{
    if (!_isStatic)
    {
        _isStatic = YES;
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
    }
    else
    {
        _isStatic = NO;
        self.backgroundColor = [UIColor whiteColor];
        self.opaque = YES;
    }
}

- (void)drawRect:(CGRect)rect {
	//create 1px black border
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetLineWidth(context, 1.0);
	CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0);
	CGContextStrokeRect(context, rect);
    
    //draw test events
    [_color setFill];
    for (int i = 0; i < 3; i++)
    {   //draw 10 events
        float x = arc4random() % (int)BAND_WIDTH_P;
        float width = 25.0;
        CGRect eRect = CGRectMake(x, 0.0, width, BAND_HEIGHT_P);
        CGContextFillRect(context, eRect);
    }
}

@end
