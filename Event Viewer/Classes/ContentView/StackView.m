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

- (id)initWithStackNum:(int)stackNum OutOf:(int)stacks WithBands:(int)bandNum OfColor:(UIColor *)color
{
    float height = (bandNum * (BAND_HEIGHT_P + 16.0) + 16.0);
    CGRect frame = CGRectMake((768.0 - BAND_WIDTH_P)/4, 
                              height * stackNum, 
                              512.0+128.0,//BAND_WIDTH_P + (BAND_WIDTH_P - 768.0)/2, 
                              height);
    if ((self = [super initWithFrame:frame]))
    {
//        NSMutableArray *mutableBands = [[NSMutableArray alloc] init];
//        
//        for (int i = 0; i < bandNum; i++)
//        {
//            BandView *newBand = [[BandView alloc] initWithBandNum:i OfColor:color];
//            [self addSubview:newBand];
//            [mutableBands addObject:newBand];
//        }
//        
//        _bandViews = mutableBands;
        
        self.backgroundColor = [UIColor whiteColor];
        self.opaque = YES;
        self.hidden = YES;
        _isStatic = NO;
        _bandNum = bandNum;
        _eventColor = color;
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

- (void)toggleOverlay
{
    if (!_isStatic)
    {
        _isStatic = YES;
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        for (BandView *b in _bandViews)
        {
            [b toggleOverlay];
        }
    }
    else
    {
        _isStatic = NO;
        self.backgroundColor = [UIColor whiteColor];
        self.opaque = YES;
        for (BandView *b in _bandViews)
        {
            [b toggleOverlay];
        }
    }
}

- (void)drawRect:(CGRect)rect 
{
	//create 1px black border
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetLineWidth(context, 1.0);
    [[UIColor blackColor] set];
	CGContextStrokeRect(context, rect);
    
    float bandX = (768.0 - BAND_WIDTH_P)/4;
    //draw bands
    for (int i = 0; i < _bandNum; i++)
    {
        CGRect frame = CGRectMake(bandX, 
                                  16.0 + (BAND_HEIGHT_P + 16.0)*i, 
                                  BAND_WIDTH_P, 
                                  BAND_HEIGHT_P);
        CGContextStrokeRect(context, frame);
    }
    
    //draw events
    [_eventColor set];
    for (int j = 0; j < _bandNum; j++)
    {
        for (int i = 0; i < 3; i++)
        {
            float x = arc4random() % (int)BAND_WIDTH_P;
            float width = 25.0;
            //fix erroneous widths
            if (x + width > BAND_WIDTH_P) width = width - ((x + width) - BAND_WIDTH_P);
            CGRect eRect = CGRectMake(bandX + x, 
                                      16.0 + (BAND_HEIGHT_P + 16.0)*j, 
                                      width, 
                                      BAND_HEIGHT_P);
            CGContextFillRect(context, eRect);
        }
    }
}

@end
