//
//  BandView.m
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ContentViewController.h"
#import "ContentScrollView.h"
#import "PanelDrawView.h"
#import "PanelZoomView.h"
#import "BandLayer.h"
#import "QueryData.h"
#import "EventInfo.h"
#import "Event.h"


@implementation PanelDrawView
{
    id<DataDelegate> dataDelegate;
    NSArray *_colorArray;
	
	float _zoomScale;           // Current scale of the events and bands specified by the BandZoomView, for use in re-drawing at appropriate sizes
    float _newZoomScale;        // Zoom scale to be used during band zooming, due to the manual management of transforms
    CGRect _originalFrame;      // Frame of view at (external) zoomScale 1.0
    float _globalZoomScale;     // Zoom scale of the global content display
    
    NSArray *_stackLayerArray;  // Array of all stack layers (superlayers to their respective band layers)
    NSArray *_bandLayerArray;   // 2-dimensions array of band layers where for array[i][j], 
                                //  i = 0-based index of stack
                                //  j = 0-based index of band
}

@synthesize dataDelegate = _dataDelegate;
@synthesize infoPopup = _infoPopup;
@synthesize currentPanel = _currentPanel;

OBJC_EXPORT BOOL isPortrait;             // Global variable set in ContentViewController to specify device orientation
OBJC_EXPORT float BAND_HEIGHT;              //
OBJC_EXPORT float BAND_WIDTH;               //  Globals set in ContentViewControlled specifying UI layout parameters
OBJC_EXPORT float BAND_SPACING;             //
OBJC_EXPORT float TIMELINE_HEIGHT;            //


#pragma mark -
#pragma mark Initialization

/**
 *  Initialize the drawing view's parameters
 *  NOTE: Does NOT establish frame. Sizing must be done by the caller via the approproate method to establish a frame
 *
 *  stackNum is the number of stacks in the current query (min of 0)
 *  bandNum is the number of bands in the current query (min of 0)
 */
- (id)init
{        
    if ((self = [super init]))
    {
        self.backgroundColor = [UIColor blackColor];
        self.opaque = YES;
        
        NSArray *newColors = [[NSArray alloc] init];
        _colorArray = newColors;
		
		_zoomScale = 1.0f;
        _newZoomScale = 1.0f;
        _globalZoomScale = 1.0f;
        
        // Handler for event details
        UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [self addGestureRecognizer:longPressRecognizer]; 
    }
    
    return self;
}

/**
 *  Sizes the drawing view based on the number of panels, stacks, and bands in the current query.
 *  Should be called whenever the number of panels, stacks, or bands change (ex: in the event of a re-query).
 *
 *  stackNum is the number of stacks in the current query (min of 0)
 *  bandNum is the number of bands in the current query (min of 0)
 *  landScale is the scale the panel should be sized to
 */
- (void)sizeForStackNum:(int)stackNum bandNum:(int)bandNum
{
    CGRect frame = CGRectMake(0.0f,
                              0.0f, 
                              BAND_WIDTH, 
                              (bandNum * (BAND_HEIGHT + BAND_SPACING) + TIMELINE_HEIGHT) * stackNum + TIMELINE_HEIGHT);
    self.frame = frame;
    
    _originalFrame = frame;
    _zoomScale = 1.0f;
    _newZoomScale = 1.0f;
    _globalZoomScale = 1.0f;
    
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
    float stackHeight = (bandNum-1.0f) * (BAND_HEIGHT + BAND_SPACING) + BAND_HEIGHT + TIMELINE_HEIGHT;
    
    // Create new stack layers as superlayers
    for (int i = 0; i < stackNum; i++)
    {
        CATiledLayer *stackLayer = [CATiledLayer layer];
        float stackY = stackHeight * i + TIMELINE_HEIGHT;
        CGRect stackF = CGRectMake(0.0f, stackY, BAND_WIDTH, stackHeight);
        stackLayer.frame = stackF;
        stackLayer.delegate = stackLayer;
        NSMutableArray *currentBandLayers = [[NSMutableArray alloc] init];
        
        // Create new band layers as sublayers of stack layers
        for (int j = 0; j < bandNum; j++)
        {
            BandLayer *bandLayer = [BandLayer layer];
            float bandY = j * (BAND_HEIGHT + BAND_SPACING);
            CGRect bandF = CGRectMake(0.0f, bandY, BAND_WIDTH, BAND_HEIGHT);  
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

- (int)delegateRequestsCurrentPanel
{
    return _currentPanel;
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
 *  Reorder stacks specified
 *
 *  stackNum is the 0-based index of the currently dragged stack
 *  index is the new 0-based index of the stack being dragged
 */
- (BOOL)reorderStack:(int)stackNum withNewIndex:(int)index
{
    // Check to make sure we need to reorder (we may be outside the bounds of the stack)
    if (index >= [_stackLayerArray count]) return NO;
    if (stackNum >= [_stackLayerArray count]) return NO;
    
    QueryData *data = [_dataDelegate delegateRequestsQueryData];
    float stackHeight = (data.bandNum-1.0f) * (BAND_HEIGHT + BAND_SPACING) + BAND_HEIGHT + TIMELINE_HEIGHT;
    
    NSMutableArray *mutaStackLayerArr = [_stackLayerArray mutableCopy];
    
    // Shift old stack
    CALayer *oldStack = [mutaStackLayerArr objectAtIndex:index];
    if (stackNum < index)    // Move old band up
    {
        CGPoint pos = oldStack.position;
        pos.y = pos.y - stackHeight;
        oldStack.position = pos;
    }
    else if (stackNum > index)   // Move old band down
    {
        CGPoint pos = oldStack.position;
        pos.y = pos.y + stackHeight;
        oldStack.position = pos;
    }
    else
        NSLog(@"ERROR! -- stackNum (%d), index (%d) conflict", stackNum, index);
    
    // Shift new stack
    CALayer *draggingStack = [mutaStackLayerArr objectAtIndex:stackNum];
    if (stackNum < index)    // Move new band down
    {
        CGPoint pos = draggingStack.position;
        pos.y = pos.y + stackHeight;
        draggingStack.position = pos;
    }
    else if (stackNum > index)   // Move new band up
    {
        CGPoint pos = draggingStack.position;
        pos.y = pos.y - stackHeight;
        draggingStack.position = pos;
    }
    else
        NSLog(@"ERROR! -- stackNum (%d), index (%d) conflict", stackNum, index);
    
    // Reposition layers within array
    [mutaStackLayerArr replaceObjectAtIndex:index withObject:draggingStack];
    [mutaStackLayerArr replaceObjectAtIndex:stackNum withObject:oldStack];
    
    _stackLayerArray = (NSArray *)mutaStackLayerArr;
    
    // Inform data delegate that reordering is needed
    [_dataDelegate swapStack:stackNum withStack:index];
    
    return YES;
}

/**
 *  Reorders all bands in a stack around the band currently being dragged.
 *
 *  bandNum is the original 0-based index of the band being dragged
 *  stackNum is the 0-based index of the stack the bands are in
 *  index is the new 0-based index of the band being dragged
 *
 *  Returns YES if the reordering occured, else NO
 */
- (BOOL)reorderBandsAroundBand:(int)bandNum inStack:(int)stackNum withNewIndex:(int)index
{
    // Check to make sure we need to reorder (we may be outside the bounds of the stack)
    if (index >= [[_bandLayerArray objectAtIndex:stackNum] count]) return NO;
    if (bandNum >= [[_bandLayerArray objectAtIndex:stackNum] count]) return NO;
    
    NSMutableArray *bandLayerMutable = [_bandLayerArray mutableCopy];
    for (int i = 0; i < [bandLayerMutable count]; i++)
    {
        NSMutableArray *bandArray = [[bandLayerMutable objectAtIndex:i] mutableCopy];
        
        BandLayer *oldBand = [bandArray objectAtIndex:index];
        if (bandNum < index)    // Move old band up
        {
            CGPoint pos = oldBand.position;
            pos.y = pos.y - (BAND_HEIGHT + BAND_SPACING);
            oldBand.position = pos;
        }
        else if (bandNum > index)   // Move old band down
        {
            CGPoint pos = oldBand.position;
            pos.y = pos.y + (BAND_HEIGHT + BAND_SPACING);
            oldBand.position = pos;
        }
        else
            NSLog(@"ERROR! -- bandNum (%d), index (%d) conflict", bandNum, index);
            
        BandLayer *draggingBand = [bandArray objectAtIndex:bandNum];
        if (bandNum < index)    // Move new band down
        {
            CGPoint pos = draggingBand.position;
            pos.y = pos.y + (BAND_HEIGHT + BAND_SPACING);
            draggingBand.position = pos;
        }
        else if (bandNum > index)   // Move new band up
        {
            CGPoint pos = draggingBand.position;
            pos.y = pos.y - (BAND_HEIGHT + BAND_SPACING);
            draggingBand.position = pos;
        }
        else
            NSLog(@"ERROR! -- bandNum (%d), index (%d) conflict", bandNum, index);
        
        // Inform band layers of their new positions
        draggingBand.bandNumber = index;
        oldBand.bandNumber = bandNum;
        
        // Reposition layers within array
        [bandArray replaceObjectAtIndex:index withObject:draggingBand];
        [bandArray replaceObjectAtIndex:bandNum withObject:oldBand];
                
        [bandLayerMutable replaceObjectAtIndex:i withObject:(NSArray *)bandArray];        
    }
    
    _bandLayerArray = (NSArray *)bandLayerMutable;
    
    // Inform data delegate that reordering is needed
    [_dataDelegate swapBand:bandNum withBand:index];
        
    return YES;
}


#pragma mark -
#pragma mark Long-press handling

/**
 *  Handling of long-press gestures in regards to displaying specifics on the event that has been pressed.
 *  NOTE: We do not care about any other events related to the long-press other than it's initial recognization,
 *  as dismissal of the popover is handled by the popover's delegate (us in popoverControllerShouldDismissPopover).
 */
-(void)handleLongPress:(UILongPressGestureRecognizer *)longPressRecognizer 
{    
    switch ([longPressRecognizer state]) 
    {
        case UIGestureRecognizerStateBegan:
            [self startLongPress:longPressRecognizer];
            break;
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            break;
        default:
            break;
    }
}

/**
 *  Initiate the popup of the event details pane, as the long-press gesture has been recognized
 */
- (void)startLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    [self becomeFirstResponder];
    CGPoint location = [gestureRecognizer locationInView:self];
    NSArray *pressedEvents = [self findEventsAtPoint:location];
    
    if ([pressedEvents count] == 0) return;
    
    EventInfo *eInfo = [[EventInfo alloc] initWithEventArray:pressedEvents];
    _infoPopup = [[UIPopoverController alloc] initWithContentViewController:eInfo];
    CGRect eRect = CGRectMake(location.x, location.y, 1.0f, 1.0f);
    [_infoPopup presentPopoverFromRect:eRect inView:self permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

/**
 *  Find and return an array of all events underneath the specified point.
 *  Includes events in all currently printed panels.
 *
 *  location is the point under which we are looking for events
 */
- (NSArray *)findEventsAtPoint:(CGPoint)location
{
    NSMutableArray *results = [[NSMutableArray alloc] init];
    for (int i = 0; i < [_bandLayerArray count]; i++)
    {
        NSArray *layersInStack = [_bandLayerArray objectAtIndex:i];
        for (int j = 0; j < [layersInStack count]; j++)
        {
            BandLayer *b = [layersInStack objectAtIndex:j];
            // Bands' frame are relative to their superlayers (the stack layers), so normalize accordingly
            CGRect bFrame = b.frame;
            bFrame.origin.y = bFrame.origin.y + [b superlayer].frame.origin.y;
            
            if (CGRectContainsPoint(bFrame, location))
            {                
                // We've found the layer, now find the Event(s) in the current panel and each overlay
                QueryData *data = [_dataDelegate delegateRequestsQueryData];
                NSMutableArray *overlays = [[_dataDelegate delegateRequestsOverlays] mutableCopy];
                [overlays addObject:[NSNumber numberWithInt:_currentPanel]];
                BOOL currentOverlaid = NO;
                for (NSNumber *o in overlays)
                {
                    if ([o intValue] == _currentPanel && currentOverlaid) continue;   // Need to skip the current panel we added if it was returned as an overlay
                    
                    NSArray *eArr = [[[data.eventArray objectAtIndex:[o intValue]] objectAtIndex:i] objectAtIndex:j];
                    for (Event *e in eArr)
                    {
                        if ((e.x * _zoomScale * (b.frame.size.width / BAND_WIDTH_P)) <= location.x && (e.x + e.width) * _zoomScale  * (b.frame.size.width / BAND_WIDTH_P) >= location.x)
                        {
                            [results addObject:e];
                        }
                    }
                    
                    if ([o intValue] == _currentPanel) currentOverlaid = YES; // Again, skipping current panel if overlaid
                }
                
            }
        }
    }
    
    return results;
}

/**
 *  De-reference (release) the popover when asked due to the user touching outside it.
 */
- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    _infoPopup = nil;
    return YES;
}


#pragma mark -
#pragma mark Drawing

/**
 *	Set the size of the frame manually during all transformations (which occur when zooming).
 *  This is what enables the View to zoom ONLY horizontally, and not verically
 */
- (void)setTransform:(CGAffineTransform)newValue;
{   
    if (!isPortrait) return;
    
    // The 'a' value of the transform is the transform's new scale of the view, which is reset after the zooming action completes
    //  newZoomScale should therefore be kept while zooming, and then zoomScale should be updated upon completion
	_newZoomScale = _zoomScale * newValue.a;

	if (_newZoomScale < 1.0)
		_newZoomScale = 1.0;
	
    // Resize self
	self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, _originalFrame.size.width * _newZoomScale, self.frame.size.height);
    
    // Resize all BandLayers
    [CATransaction begin];
    [CATransaction setDisableActions: YES];
    for (CATiledLayer *s in _stackLayerArray)
    {
        for (BandLayer *b in [s sublayers])
        {
            CGRect bandF = b.frame;
            bandF.size.width = BAND_WIDTH * _newZoomScale;
            
            b.frame = bandF;
            
        }
    }
    [CATransaction commit];
}

/**
 *  Inform the view that zooming has ceased, and therefore the next transforms will have their own reset frame of reference
 *  (i.e. they will begin at 1.0 again, rather than resuming where they left off at the end of zooming)
 *  To do so, simply set the current zoomScale to the previously modified newZoomScale
 */
- (void)doneZooming
{
    _zoomScale = _newZoomScale;
}

/**
 *  Zoom self and all subviews/layers
 */
- (void)zoomToScale:(float)zoomScale
{    
    _globalZoomScale = zoomScale;
    
    CGRect newDrawF = _originalFrame;
    newDrawF.size.width = _originalFrame.size.width * zoomScale;
    newDrawF.size.height = _originalFrame.size.height * zoomScale;
    self.frame = newDrawF;
    
    float temp_BAND_WIDTH = BAND_WIDTH * _globalZoomScale;
    float temp_BAND_HEIGHT = BAND_HEIGHT * _globalZoomScale;
    float temp_BAND_SPACING = BAND_SPACING * _globalZoomScale;
    float temp_TIMELINE_HEIGHT = TIMELINE_HEIGHT * _globalZoomScale;
    
    QueryData *data = [_dataDelegate delegateRequestsQueryData];
    float stackHeight = (data.bandNum-1.0f) * (temp_BAND_HEIGHT + temp_BAND_SPACING) + temp_BAND_HEIGHT + temp_TIMELINE_HEIGHT;
    
//    CGSize stackTiles = ((CATiledLayer *)[_stackLayerArray lastObject]).tileSize;
//    stackTiles.width = stackTiles.width * zoomScale;
//    stackTiles.height = stackTiles.height * zoomScale;
//    
//    CGSize bandTiles = ((BandLayer *)[[_bandLayerArray lastObject] lastObject]).tileSize;
//    stackTiles.width = stackTiles.width * zoomScale;
//    stackTiles.height = stackTiles.height * zoomScale;
    
    [CATransaction begin];
    [CATransaction setDisableActions: YES];
    // Resize stack layers
    for (int i = 0; i < data.stackNum; i++)
    {
        CATiledLayer *stackLayer = [_stackLayerArray objectAtIndex:i];
        float stackY = stackHeight * i + temp_TIMELINE_HEIGHT;
        CGRect stackF = CGRectMake(0.0f, stackY, temp_BAND_WIDTH, stackHeight);
        stackLayer.frame = stackF;
//        stackLayer.tileSize = stackTiles;
        
        // Create new band layers as sublayers of stack layers
        NSArray *bandArray = [_bandLayerArray objectAtIndex:i];
        for (int j = 0; j < data.bandNum; j++)
        {
            BandLayer *bandLayer = [bandArray objectAtIndex:j];
            float bandY = j * (temp_BAND_HEIGHT + temp_BAND_SPACING);
            CGRect bandF = CGRectMake(0.0f, bandY, temp_BAND_WIDTH, temp_BAND_HEIGHT);  
            bandLayer.frame = bandF;
//            bandLayer.tileSize = bandTiles;
        }
    }
    [CATransaction commit]; 
}

+ layerClass
{
    return [CATiledLayer class];
}

/**
 *  Typical override of drawing code to initiate redrawing of results
 */
- (void)drawRect:(CGRect)rect 
{    
    QueryData *data = [_dataDelegate delegateRequestsQueryData];
  	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetLineWidth(context, 1.0f);
	
	int wInt = self.frame.size.width/12.0f;
	float monthWidth = (float)wInt;
	
	CGContextSetRGBStrokeColor(context, 0.75f, 0.75f, 0.75f, 1.0f);
    CGContextSetRGBFillColor(context, 0.75f, 0.75f, 0.75f, 1.0f);
	[self drawTimelinesForData:data inContext:context withMonthWidth:monthWidth];
    
    for (CATiledLayer *s in _stackLayerArray)
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
    float temp_BAND_HEIGHT = BAND_HEIGHT * _globalZoomScale;
    float temp_BAND_SPACING = BAND_SPACING * _globalZoomScale;
    float temp_TIMELINE_HEIGHT = TIMELINE_HEIGHT * _globalZoomScale;
	float stackHeight = (data.bandNum-1.0f) * (temp_BAND_HEIGHT + temp_BAND_SPACING) + temp_BAND_HEIGHT + temp_TIMELINE_HEIGHT;
	
	if (data.timeScale == 1)
	{
        NSArray *months = [[NSArray alloc] initWithObjects:@"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun", @"Jul", @"Aug", @"Sep", @"Oct", @"Nov", @"Dec", nil];
        
		for (int m = 0; m < 12; m++)
		{
			int xInt = m * (int)width;
			float x = xInt + 0.5f;
			CGRect monthF = CGRectMake(x, 0.0f, width, self.frame.size.height);
			monthF = CGRectInset(monthF, -0.5f, 0.5f);
			CGContextStrokeRect(context, monthF);
			
			// Labels
			for (int i = 0; i <= data.stackNum; i++)
			{
				float stackY = stackHeight * i;
				NSString *month = [months objectAtIndex:m];
				CGRect tFrame = CGRectMake(monthF.origin.x, stackY + 8.0f, width, 16.0f);
                float fontSize = (temp_TIMELINE_HEIGHT / 3.0f) + 1.0f;
				[month drawInRect:tFrame withFont:[UIFont fontWithName:@"Helvetica" size:fontSize] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
			}
		}
	}
	else
	{
		NSLog(@"ERROR: Undefined timescale: %d", data.timeScale);
	}
}



@end
