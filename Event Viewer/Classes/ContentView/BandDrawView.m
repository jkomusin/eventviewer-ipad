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
#import "BandLayer.h"
#import "QueryData.h"
#import "Event.h"


@implementation BandDrawView
{
    id<DataDelegate> dataDelegate;
    NSArray *_colorArray;
	
	float _zoomScale;
	float _originalWidth;
    
    NSArray *_stackLayerArray;  // Array of all stack layers (superlayers to their respective band layers)
    NSArray *_bandLayerArray;   // 2-dimensions array of band layers where for array[i][j], 
                                //  i = 0-based index of stack
                                //  j = 0-based index of band
}

@synthesize dataDelegate = _dataDelegate;

// Static array containing labels for timeline drawing.
static NSArray *EVMonthLabels = nil;
+ (void)initialize { if(!EVMonthLabels) {EVMonthLabels = [[NSArray alloc] initWithObjects:@"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun", @"Jul", @"Aug", @"Sep", @"Oct", @"Nov", @"Dec", nil]; } }


#pragma mark -
#pragma mark Initialization

/**
 *  Initialize the drawing view's size based on the number of stacks and panels in the current query.
 *
 *  stackNum is the number of stacks in the current query (min of 0)
 *  bandNum is the number of bands in the current query (min of 0)
 */
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

/**
 *  Re-initializes the drawing view's size based on the number of stack and panels in the current query.
 *  Should be called whenever the number of stacks or bands change (ex: in the event of a re-query).
 *
 *  stackNum is the number of stacks in the current query (min of 0)
 *  bandNum is the number of bands in the current query (min of 0)
 */
- (void)resizeForStackNum:(int)stackNum bandNum:(int)bandNum
{
    CGRect frame = CGRectMake(0.0f, 
                              0.0f, 
                              BAND_WIDTH_P, 
                              (bandNum * (BAND_HEIGHT_P + BAND_SPACING) + STACK_SPACING) * stackNum);
    self.frame = frame;
    
    [self initLayersWithStackNum:stackNum bandNum:bandNum];
}

/**
 *  Initializes the draw view with the layers where drawing of events will take place.
 *
 *  stackNum is the number of stacks in the current query (min of 0)
 *  bandNum is the number of bands in the current query (min of 0)
 */
- (void)initLayersWithStackNum:(int)stackNum bandNum:(int)bandNum
{    
    // Release old layers
    if (_stackLayerArray)
    {
        for (CALayer *s in [_stackLayerArray mutableCopy])
        {
            for (BandLayer *b in [[s sublayers] mutableCopy])
            {
                [b removeFromSuperlayer];
            }
            [s removeFromSuperlayer];
        }
    }
    
    NSMutableArray *newStackLayers = [[NSMutableArray alloc] init];
    NSMutableArray *newBandLayers = [[NSMutableArray alloc] init];
    float stackHeight = (bandNum-1.0f) * (BAND_HEIGHT_P + BAND_SPACING) + BAND_HEIGHT_P + STACK_SPACING;
    
    // Create new stack layers as superlayers
    for (int i = 0; i < stackNum; i++)
    {
        CALayer *stackLayer = [CALayer layer];
        float stackY = stackHeight * i + STACK_SPACING;
        CGRect stackF = CGRectMake(0.0f, stackY, BAND_WIDTH_P, stackHeight);
        stackLayer.frame = stackF;
        stackLayer.delegate = stackLayer;
        NSMutableArray *currentBandLayers = [[NSMutableArray alloc] init];
        
        // Create new band layers as sublayers of stack layers
        for (int j = 0; j < bandNum; j++)
        {
            BandLayer *bandLayer = [BandLayer layer];
            float bandY = j * (BAND_HEIGHT_P + BAND_SPACING);
            CGRect bandF = CGRectMake(0.0f, bandY, BAND_WIDTH_P, BAND_HEIGHT_P);
            NSLog(@"Creating band with dimensions (%f, %f, %f, %f)", bandF.origin.x, bandF.origin.y, bandF.size.width, bandF.size.height);
            bandLayer.frame = bandF;
            bandLayer.opaque = YES;
            bandLayer.delegate = bandLayer;
			bandLayer.dataDelegate = _dataDelegate;
			bandLayer.zoomDelegate = self;
            bandLayer.stackNumber = i;
            bandLayer.bandNumber = j;
            [stackLayer addSublayer:bandLayer];
            [currentBandLayers addObject:bandLayer];
        }
        
        [self.layer addSublayer:stackLayer];
        [newStackLayers addObject:stackLayer];
        [newBandLayers addObject:(NSArray *)currentBandLayers];
    }
    _stackLayerArray = (NSArray *)newStackLayers;
    _bandLayerArray = (NSArray *)newBandLayers;
}


#pragma mark -
#pragma mark Drawing delegation

/**
 *  Returns the current zoomScale of the display to the requester.
 */
- (float)delegateRequestsZoomscale
{
    return _zoomScale;
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

/**
 *  Returns the specified layer for band drawing.
 *
 *  stacknNum is the 0-based index for the stack containing the band
 *  bandNum is the 0-based index for the stack containing the band
 */
- (BandLayer *)getBandLayerForStack:(int)stackNum band:(int)bandNum
{
    NSLog(@"Finding band layer");
    return [[_bandLayerArray objectAtIndex:stackNum] objectAtIndex:bandNum];
}

/**
 *  Returns the specified layer for containing band layers.
 *
 *  stackNum is the 0-based index for the stack containing the band
 */
- (CALayer *)getStackLayerForStack:(int)stackNum
{
    NSLog(@"Finding stack layer");
    return [_stackLayerArray objectAtIndex:stackNum];
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
	
	self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, _originalWidth * _zoomScale, self.frame.size.height);
    
    for (CALayer *s in _stackLayerArray)
    {
        for (BandLayer *b in [s sublayers])
        {
            CGRect bandF = b.frame;
            bandF.size.width = BAND_WIDTH_P * _zoomScale;
            b.frame = bandF;
        }
    }
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
    
    for (CALayer *s in _stackLayerArray)
    {
        for (BandLayer *b in [s sublayers])
        {
            [b setNeedsDisplay];
        }
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
//        NSArray *stackLayerArray = [_layerArray objectAtIndex:i];
        float stackY = stackHeight * i;
        for (int j = 0; j < data.bandNum; j++)
        {
			float bandY = j * (BAND_HEIGHT_P + BAND_SPACING) + STACK_SPACING + stackY;
            CGRect bandF = CGRectMake(0.0f, bandY, width*12.0f, BAND_HEIGHT_P);
			bandF = CGRectInset(bandF, 0.5f, -0.5f);
			CGContextFillRect(context, bandF);
			CGContextStrokeRect(context, bandF);

//            CALayer *bandLayer = [CALayer layer];
            
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


@end
