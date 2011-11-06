//
//  BandView.m
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "BandDrawView.h"
#import "ContentScrollView.h"
#import "QueryData.h"
#import "Event.h"

@implementation BandDrawView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        // Initialization code
    }
    
    return self;
}

- (id)initWithStackNum:(int)stackNum bandNum:(int)bandNum
{
    CGRect frame = CGRectMake(0.0f, 
                              0.0f, 
                              BAND_WIDTH_P, 
                              (bandNum * (BAND_HEIGHT_P + 16.0f) + 16.0f) * stackNum);   
    
    if ((self = [super initWithFrame:frame]))
    {
        self.backgroundColor = [UIColor whiteColor];
        self.opaque = YES;
        
        NSArray *newColors = [[NSArray alloc] init];
        _colorArray = newColors;
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect 
{
    NSLog(@"DRAW RECT!!!");
    
    QueryData *data = [self.delegate bandsRequestQueryData];
  	CGContextRef context = UIGraphicsGetCurrentContext();
    
    //resize view
    CGRect frame = CGRectMake(0.0f, 
                              0.0f, 
                              BAND_WIDTH_P, 
                              (data.bandNum * (BAND_HEIGHT_P + 16.0) + 16.0) * data.stackNum);
    self.frame = frame;
    
    [self drawFramesWithData:data inContext:context];
    [self drawEventsWithArray:data.eventArray inContext:context];
}

/**
 *  Draw all outlines around stacks and bands.
 */
- (void)drawFramesWithData:(QueryData *)data inContext:(CGContextRef)context
{
	CGContextSetLineWidth(context, 2.0f);
	CGContextSetRGBStrokeColor(context, 0.0f, 0.0f, 0.0f, 1.0f);
    
    float stackHeight = (data.bandNum * (BAND_HEIGHT_P + 16.0f) + 16.0f);
    for (int i = 0; i < data.stackNum; i++)
    {
        float stackY = stackHeight * i;
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, 0.0f, stackY);
        CGContextAddLineToPoint(context, BAND_WIDTH_P, stackY);
        CGContextStrokePath(context);
        for (int j = 0; j < data.bandNum; j++)
        {
            float bandY = (j * (BAND_HEIGHT_P + 16.0f) + 16.0f) + stackY;
            CGRect bandF = CGRectMake(0.0f, bandY, BAND_WIDTH_P, BAND_HEIGHT_P);
            CGContextStrokeRect(context, bandF);
        }
    }
    //draw end stack line
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0.0f, self.frame.size.height);
    CGContextAddLineToPoint(context, BAND_WIDTH_P, self.frame.size.height);
    CGContextStrokePath(context);
}

/**
 *  Draw all events in the given array
 */
- (void)drawEventsWithArray:(NSArray *)eArray inContext:(CGContextRef)context
{
    int currentPanel = [self.delegate bandsRequestCurrentPanel];
    UIColor *eColor = [self getColorForPanel:currentPanel];
    int stackNum = [[eArray lastObject] count];
    int bandNum = [[[eArray lastObject] lastObject] count];
    float stackHeight = (bandNum * (BAND_HEIGHT_P + 16.0f) + 16.0f);

    for (int i = 0; i < stackNum; i++)
    {
        float stackY = stackHeight * i;
        for (int j = 0; j < bandNum; j++)
        {
            float bandY = (j * (BAND_HEIGHT_P + 16.0f) + 16.0f) + stackY;
            [eColor setFill];
            NSArray *bandEArray = [[[eArray objectAtIndex:currentPanel] objectAtIndex:i] objectAtIndex:j];
            for (Event *e in bandEArray)
            {
                NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:e.start];
                NSInteger day = [components day];    
                NSInteger month = [components month];
                float x = (month - 1.0f)*(BAND_WIDTH_P / 12.0f) + (day - 1.0f)*(BAND_WIDTH_P / 356.0f);
                float width = 25.0f;
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
}

/**
 *  Retrieve color for events of a specified panel.
 *  If no color has been created for the panel, create one and add it to the array.
 */
- (UIColor *)getColorForPanel:(int)panelNum
{
    UIColor *eColor;

    if ([_colorArray count] < panelNum+1)
    {
        CGFloat red =  (CGFloat)random()/(CGFloat)RAND_MAX;
        CGFloat blue = (CGFloat)random()/(CGFloat)RAND_MAX;
        CGFloat green = (CGFloat)random()/(CGFloat)RAND_MAX;
        eColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0f];
        NSMutableArray *mutableColors = [_colorArray mutableCopy];
        [mutableColors addObject:eColor];
        _colorArray = mutableColors;
    }
    else
    {
        eColor = [_colorArray objectAtIndex:panelNum];
    }
    
    return eColor;
}

@end
