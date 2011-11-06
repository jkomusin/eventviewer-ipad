//
//  BandView.m
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "BandView.h"
#import "ContentScrollView.h"
#import "QueryData.h"

@implementation BandView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        // Initialization code
    }
    return self;
}

- (id)initWithStackNum:(int)stackNum BandNum:(int)bandNum
{
    CGRect frame = CGRectMake(0.0f, 
                              0.0f, 
                              BAND_WIDTH_P, 
                              (bandNum * (BAND_HEIGHT_P + 16.0) + 16.0) * stackNum);    
    if ((self = [super initWithFrame:frame]))
    {
        self.backgroundColor = [UIColor whiteColor];
        self.opaque = YES;
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect 
{
    NSLog(@"Drawing RECT!!!");
    
    QueryData *data = [self.delegate bandsRequestQueryData];

    //resize view
    CGRect frame = CGRectMake((768.0 - BAND_WIDTH_P)*3/4, 
                              0.0, 
                              BAND_WIDTH_P, 
                              (data.bandNum * (BAND_HEIGHT_P + 16.0) + 16.0) * data.stackNum);
    self.frame = frame;
    
	//create 1px black border around bands and stacks
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetLineWidth(context, 1.0);
	CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0);
    float stackHeight = (data.bandNum * (BAND_HEIGHT_P + 16.0) + 16.0);
    for (int i = 0; i < data.stackNum; i++)
    {
        float stackY = stackHeight * i;
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, 0.0f, stackY);
        CGContextAddLineToPoint(context, BAND_WIDTH_P, stackY);
        CGContextStrokePath(context);
        for (int j = 0; j < data.bandNum; j++)
        {
            float bandY = (j * (BAND_HEIGHT_P + 16.0) + 16.0);
            CGRect bandF = CGRectMake(0.0f, bandY, BAND_WIDTH_P, BAND_HEIGHT_P);
            CGContextStrokeRect(context, bandF);
            
            //generate random event color
            CGFloat red =  (CGFloat)random()/(CGFloat)RAND_MAX;
            CGFloat blue = (CGFloat)random()/(CGFloat)RAND_MAX;
            CGFloat green = (CGFloat)random()/(CGFloat)RAND_MAX;
            UIColor *bandColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
            [bandColor setFill];
            //draw test events
            for (int k = 0; k < 3; k++)
            {
                float x = arc4random() % (int)BAND_WIDTH_P;
                float width = 25.0;
                //fix erroneous widths
                if (x + width > BAND_WIDTH_P) width = width - ((x + width) - BAND_WIDTH_P);
                CGRect eRect = CGRectMake(x, 
                                          bandY, 
                                          width, 
                                          BAND_HEIGHT_P);
                CGContextFillRect(context, eRect);
            }

        }
    }
    //draw end stack line
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0.0f, self.frame.size.height);
    CGContextAddLineToPoint(context, BAND_WIDTH_P, self.frame.size.height);
    CGContextStrokePath(context);
}

@end
