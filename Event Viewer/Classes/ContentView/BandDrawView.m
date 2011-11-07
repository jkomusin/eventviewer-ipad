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
    
    QueryData *data = [delegate bandsRequestQueryData];
  	CGContextRef context = UIGraphicsGetCurrentContext();
    
    //resize view if necessary and notify controller of resizing
    CGRect frame = CGRectMake(0.0f, 
                              0.0f, 
                              BAND_WIDTH_P, 
                              (data.bandNum * (BAND_HEIGHT_P + 16.0) + 16.0) * data.stackNum);
    if (self.frame.size.width != frame.size.width || self.frame.size.height != frame.size.height)
    {
        self.frame = frame;
        //[self.delegate bandsHaveResized];
    }
    
    [self drawFramesWithData:data inContext:context];
    
    int currentPanel = [delegate bandsRequestCurrentPanel];
    BOOL currentPanelIsOverlaid = NO;
    //draw all overlaid panels
    NSArray *overlays = [delegate bandsRequestOverlays];
    for (NSNumber *i in overlays)
    {
        [self drawEventsForPanel:[i intValue] fromArray:data.eventArray inContext:context];
        if ([i intValue] == currentPanel) 
        {
            currentPanelIsOverlaid = YES;
        }
    }
    if (!currentPanelIsOverlaid && currentPanel != -1)
    {
        [self drawEventsForPanel:currentPanel fromArray:data.eventArray inContext:context];
    }
    
}

/**
 *  Draw all outlines around stacks and bands.
 *
 *  data is a copy of the current QueryData object
 *  context is the current drawing context reference
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
 *  Draw all events for a specific panel.
 *
 *  panel is the index of the panel whose events are being drawn (0-indexed)
 *  eArray is the 4-dimensional array of events stored in the current QueryData object
 *  context is the current drawing context reference
 */
- (void)drawEventsForPanel:(int)panel fromArray:(NSArray *)eArray inContext:(CGContextRef)context
{
    UIColor *eColor = [self getColorForPanel:panel];
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
            NSArray *bandEArray = [[[eArray objectAtIndex:panel] objectAtIndex:i] objectAtIndex:j];
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
