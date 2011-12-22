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
	
	float _zoomScale;           // Current scale of the events and bands specified by the BandZoomView, for use in re-drawing at appropriate sizes
	float _originalWidth;       // Original width of the view (a little superficial given that this width is specified by BAND_WIDTH_P/L, but included for added robustness)
    
    NSArray *_stackLayerArray;  // Array of all stack layers (superlayers to their respective band layers)
    NSArray *_bandLayerArray;   // 2-dimensions array of band layers where for array[i][j], 
                                //  i = 0-based index of stack
                                //  j = 0-based index of band
}

@synthesize dataDelegate = _dataDelegate;

// Static array containing labels for timeline drawing.
static NSArray *EVMonthLabels = nil;
+ (void)initialize { if(!EVMonthLabels) {EVMonthLabels = [[NSArray alloc] initWithObjects:@"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun", @"Jul", @"Aug", @"Sep", @"Oct", @"Nov", @"Dec", nil]; } }
///////


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
    BandLayer *result = [[_bandLayerArray objectAtIndex:stackNum] objectAtIndex:bandNum];
    return result;
}

/**
 *  Returns the specified layer for containing band layers.
 *
 *  stackNum is the 0-based index for the stack containing the band
 */
- (CALayer *)getStackLayerForStack:(int)stackNum
{
    NSLog(@"Finding stack layer");
    CALayer *result = [_stackLayerArray objectAtIndex:stackNum];
    return result;
}

/**
 *  Reorders all bands in a stack around the band currently being dragged.
 *
 *  bandNum is the original 0-based index of the band being dragged
 *  stackNum is the 0-based index of the stack the bands are in
 *  index is the new 0-based index of the band being dragged
 *
 *  Returns the new index of the band being dragged
 */
- (int)reorderBandsAroundBand:(int)bandNum inStack:(int)stackNum withNewIndex:(int)index
{
    if (index >= [[_bandLayerArray objectAtIndex:stackNum] count]) return bandNum;
    if (bandNum >= [[_bandLayerArray objectAtIndex:stackNum] count]) return bandNum-1;
    
    NSMutableArray *bandLayerMutable = [_bandLayerArray mutableCopy];
    for (int i = 0; i < [bandLayerMutable count]; i++)
    {
        NSMutableArray *bandArray = [[bandLayerMutable objectAtIndex:i] mutableCopy];
        
        BandLayer *oldBand = [bandArray objectAtIndex:index];
        if (bandNum < index)    // Move old band up
        {
            CGPoint pos = oldBand.position;
            pos.y = pos.y - (BAND_HEIGHT_P + BAND_SPACING);
            oldBand.position = pos;
        }
        else if (bandNum > index)   // Move old band down
        {
            CGPoint pos = oldBand.position;
            pos.y = pos.y + (BAND_HEIGHT_P + BAND_SPACING);
            oldBand.position = pos;
        }
        else
            NSLog(@"ERROR! -- bandNum (%d), index (%d) conflict", bandNum, index);
        
        BandLayer *draggingBand = [bandArray objectAtIndex:bandNum];
        if (i != stackNum)
        {
            if (bandNum < index)    // Move new band down
            {
                CGPoint pos = draggingBand.position;
                pos.y = pos.y + (BAND_HEIGHT_P + BAND_SPACING);
                draggingBand.position = pos;
            }
            else if (bandNum > index)   // Move new band up
            {
                CGPoint pos = draggingBand.position;
                pos.y = pos.y - (BAND_HEIGHT_P + BAND_SPACING);
                draggingBand.position = pos;
            }
            else
                NSLog(@"ERROR! -- bandNum (%d), index (%d) conflict", bandNum, index);
        }
        
        // Reposition layers within array
        [bandArray replaceObjectAtIndex:index withObject:draggingBand];
        [bandArray replaceObjectAtIndex:bandNum withObject:oldBand];
                
        [bandLayerMutable replaceObjectAtIndex:i withObject:(NSArray *)bandArray];        
    }
    
    _bandLayerArray = (NSArray *)bandLayerMutable;
        
    return index;
}

/**
 *  Reset specified band to it's proper position.
 *
 *  bandNum is the 0-based index of the band
 */
- (void)moveBandToRestWithIndex:(int)bandNum inStack:(int)stackNum
{
    BandLayer *b = [[_bandLayerArray objectAtIndex:stackNum] objectAtIndex:bandNum];
    
    CGPoint pos = b.position;
    pos.y = bandNum * (BAND_HEIGHT_P + BAND_SPACING) + STACK_SPACING;
    b.position = pos;
}


#pragma mark -
#pragma mark Drawing

/**
 *	Set the size of the frame manually during all transformations (which occur when zooming).
 *  This is what enables the View to zoom ONLY horizontally, and not verically
 */
- (void)setTransform:(CGAffineTransform)newValue;
{                
	_zoomScale = newValue.a;
	if (_zoomScale < 1.0)
		_zoomScale = 1.0;
	
    // Resize self
	self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, _originalWidth * _zoomScale, self.frame.size.height);
    
    // Resize all BandLayers
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
 *	Draw all timelines behind all stacks on the BandDrawView itself.
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



@end
