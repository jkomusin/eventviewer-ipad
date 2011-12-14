//
//  BandView.m
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ContentViewController.h"
#import "ContentScrollView.h"
#import "BandDrawView.h"
#import "QueryData.h"
#import "Event.h"


@implementation BandDrawView
{
    id<DataDelegate> dataDelegate;
    NSArray *_colorArray;
	
	float _zoomScale;
	float _originalWidth;
    
    NSArray *_layerArray;
}

@synthesize dataDelegate = _dataDelegate;

// Static array containing labels for timeline drawing.
static NSArray *EVMonthLabels = nil;
+ (void)initialize { if(!EVMonthLabels) {EVMonthLabels = [[NSArray alloc] initWithObjects:@"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun", @"Jul", @"Aug", @"Sep", @"Oct", @"Nov", @"Dec", nil]; } }


#pragma mark -
#pragma mark Initialization

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
                              (bandNum * (BAND_HEIGHT_P + BAND_SPACING) + STACK_SPACING) * stackNum);   
    
    if ((self = [super initWithFrame:frame]))
    {
        self.backgroundColor = [UIColor whiteColor];
        self.opaque = YES;
        
        NSArray *newColors = [[NSArray alloc] init];
        _colorArray = newColors;
		
		_originalWidth = frame.size.width;
		_zoomScale = 1.0f;
        
        [self initLayersWithStackNum:stackNum bandNum:bandNum];
    }
    
    return self;
}

- (void)resizeForStackNum:(int)stackNum bandNum:(int)bandNum
{
    CGRect frame = CGRectMake(0.0f, 
                              0.0f, 
                              BAND_WIDTH_P, 
                              (bandNum * (BAND_HEIGHT_P + BAND_SPACING) + STACK_SPACING) * stackNum);
    self.frame = frame;
    
    [self initLayersWithStackNum:stackNum bandNum:bandNum];
}

- (void)initLayersWithStackNum:(int)stackNum bandNum:(int)bandNum
{
    NSMutableArray *newLayers = [[NSMutableArray alloc] initWithCapacity:stackNum];
    for (int i = 0; i < stackNum; i++)
    {
        NSMutableArray *bandLayers = [[NSMutableArray alloc] initWithCapacity:bandNum];
        [newLayers addObject:(NSArray *)bandLayers];
    }
    _layerArray = (NSArray *)newLayers;
}


#pragma mark -
#pragma mark Drawing

/**
 *	Set the size of the frame manually, and notify the BandViews and TimelineView of the change
 */
- (void)setTransform:(CGAffineTransform)newValue;
{                
	_zoomScale = newValue.a;
	if (_zoomScale < 1.0)
		_zoomScale = 1.0;
	NSLog(@"New transform value: %f", _zoomScale);
	
	//modify the innverview's frame
	self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, _originalWidth * _zoomScale, self.frame.size.height);
}

- (void)drawRect:(CGRect)rect 
{
    NSLog(@"DRAW RECT!!!");
    
    QueryData *data = [_dataDelegate delegateRequestsQueryData];
  	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetLineWidth(context, 1.0f);
	
	int wInt = self.frame.size.width/12.0f;
	float monthWidth = (float)wInt;
	
	CGContextSetRGBStrokeColor(context, 0.75f, 0.75f, 0.75f, 1.0f);
	[self drawTimelinesForData:data inContext:context withMonthWidth:monthWidth];
	
	CGContextSetRGBStrokeColor(context, 0.0f, 0.0f, 0.0f, 1.0f);
	CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 1.0f);
    [self drawFramesWithData:data inContext:context withMonthWidth:monthWidth];
	
    int currentPanel = [_dataDelegate delegateRequestsCurrentPanel];
    BOOL currentPanelIsOverlaid = NO;
    // Overlaid panels
    NSArray *overlays = [_dataDelegate delegateRequestsOverlays];
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
- (void)drawFramesWithData:(QueryData *)data inContext:(CGContextRef)context withMonthWidth:(float)width
{    
    float stackHeight = (data.bandNum-1.0f) * (BAND_HEIGHT_P + BAND_SPACING) + BAND_HEIGHT_P + STACK_SPACING;
    for (int i = 0; i < data.stackNum; i++)
    {
        NSArray *stackLayerArray = [_layerArray objectAtIndex:i];
        float stackY = stackHeight * i;
        for (int j = 0; j < data.bandNum; j++)
        {
			float bandY = j * (BAND_HEIGHT_P + BAND_SPACING) + STACK_SPACING + stackY;
            CGRect bandF = CGRectMake(0.0f, bandY, width*12.0f, BAND_HEIGHT_P);
			bandF = CGRectInset(bandF, 0.5f, -0.5f);
			CGContextFillRect(context, bandF);
			CGContextStrokeRect(context, bandF);

            CALayer *bandLayer = [CALayer layer];
            
        }
    }
}

/**
 *	Draw all timelines for each stack.
 *
 *	data is a copy of the current QueryData object
 */
- (void)drawTimelinesForData:(QueryData *)data inContext:(CGContextRef)context withMonthWidth:(float)width
{
	float stackHeight = (data.bandNum-1.0f) * (BAND_HEIGHT_P + BAND_SPACING) + BAND_HEIGHT_P + STACK_SPACING;
	
	if (data.timeScale == 1)
	{
		for (int m = 0; m < 12; m++)
		{
			// Containing rectangles
//			CGRect monthF = CGRectMake(m*((BAND_WIDTH_P-13.0f)/12.0f+1.0f)+1.0f, 0.0f, (BAND_WIDTH_P-13.0f)/12.0f, self.frame.size.height);
//			monthF = CGRectInset(monthF, -0.5f, 0.5f);
//			CGContextStrokeRect(context, monthF);
			int xInt = m * (int)width;
			float x = xInt + 0.5f;
			CGRect monthF = CGRectMake(x, 0.0f, width, self.frame.size.height);
			monthF = CGRectInset(monthF, -0.5f, 0.5f);
			CGContextStrokeRect(context, monthF);
			
			// Labels
			for (int i = 0; i <= data.stackNum; i++)
			{
//				float stackY = stackHeight * i;
//				NSString *blah = [EVMonthLabels objectAtIndex:m];
//				CGRect tFrame = CGRectMake(monthF.origin.x, stackY + 8.0f, (BAND_WIDTH_P-13.0f)/12.0f, 32.0f);
//				[blah drawInRect:tFrame withFont:[UIFont fontWithName:@"Helvetica" size:14.0f] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
				float stackY = stackHeight * i;
				NSString *month = [EVMonthLabels objectAtIndex:m];
				CGRect tFrame = CGRectMake(monthF.origin.x, stackY + 8.0f, width, 32.0f);
				[month drawInRect:tFrame withFont:[UIFont fontWithName:@"Helvetica" size:14.0f] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
			}
		}
	}
	else
	{
		NSLog(@"ERROR: Undefined timescale: %d", data.timeScale);
	}
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
    [eColor setFill];
    int bandNum = [[[eArray lastObject] lastObject] count];
    float stackHeight = (bandNum-1.0f) * (BAND_HEIGHT_P + BAND_SPACING) + BAND_HEIGHT_P + STACK_SPACING;

    int stackCount = 0;
    for (NSArray *stackArr in [eArray objectAtIndex:panel])
    {
        float stackY = stackHeight * stackCount++;
        int bandCount = 0;
        for (NSArray *bandArr in stackArr)
        {
            float bandY = bandCount++ * (BAND_HEIGHT_P + BAND_SPACING) + STACK_SPACING + stackY;
            for (Event *e in bandArr)
            {
                int intX = (int)(e.x * _zoomScale);
				float x = (float)intX + 0.5f;
                int intW = (int)(e.width * _zoomScale);
				float width = (float)intW;
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
