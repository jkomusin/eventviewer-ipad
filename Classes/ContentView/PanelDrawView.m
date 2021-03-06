
#import <QuartzCore/QuartzCore.h>

#import "PrimaryViewController.h"
#import "ContentScrollView.h"
#import "PanelDrawView.h"
#import "PanelZoomView.h"
#import "BandLayer.h"
#import "Query.h"
#import "EventInfo.h"
#import "Event.h"


@implementation PanelDrawView
{
    id<DataDelegate> dataDelegate;
	
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
		
		_zoomScale = 1.0f;
        _newZoomScale = 1.0f;
        _globalZoomScale = 1.0f;
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
- (void)sizeForStackNum:(NSInteger)stackNum bandNum:(NSInteger)bandNum
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
- (void)initLayersWithStackNum:(NSInteger)stackNum bandNum:(NSInteger)bandNum
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
#pragma mark Class variable for month storage
+ (NSArray *)monthArray
{
	static NSArray* mArray = nil;
    if (mArray == nil)
    {
        mArray = [[NSArray alloc] initWithObjects:@"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun", @"Jul", @"Aug", @"Sep", @"Oct", @"Nov", @"Dec", nil];
    }
	
    return mArray;
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

- (NSInteger)delegateRequestsCurrentPanel
{
    return _currentPanel;
}

/**
 *  Returns the specified layer for band drawing.
 *
 *  stacknNum is the 0-based index for the stack containing the band
 *  bandNum is the 0-based index for the stack containing the band
 */
- (BandLayer *)getBandLayerForStack:(NSInteger)stackNum band:(NSInteger)bandNum
{
    BandLayer *result = [[_bandLayerArray objectAtIndex:stackNum] objectAtIndex:bandNum];
    return result;
}

/**
 *  Returns the specified layer for containing band layers.
 *
 *  stackNum is the 0-based index for the stack containing the band
 */
- (CALayer *)getStackLayerForStack:(NSInteger)stackNum
{
    CALayer *result = [_stackLayerArray objectAtIndex:stackNum];
    return result;
}

/**
 *  Reorder stacks specified
 *
 *  stackNum is the 0-based index of the currently dragged stack
 *  index is the new 0-based index of the stack being dragged
 */
- (void)reorderStack:(NSInteger)stackIndex withNewIndex:(NSInteger)index
{    
    float temp_BAND_HEIGHT = BAND_HEIGHT * _globalZoomScale;
    float temp_BAND_SPACING = BAND_SPACING * _globalZoomScale;
    float temp_TIMELINE_HEIGHT = TIMELINE_HEIGHT * _globalZoomScale;
    
    Query *data = [_dataDelegate delegateRequestsQueryData];
    float stackHeight = (data.bandNum-1.0f) * (temp_BAND_HEIGHT + temp_BAND_SPACING) + temp_BAND_HEIGHT + temp_TIMELINE_HEIGHT;
    
    NSMutableArray *mutaStackLayerArr = [_stackLayerArray mutableCopy];
    
    // Shift old stack
    CALayer *oldStack = [mutaStackLayerArr objectAtIndex:index];
    if (stackIndex < index)    // Move old band up
    {
        CGPoint pos = oldStack.position;
        pos.y = pos.y - stackHeight * (index - stackIndex);
        oldStack.position = pos;
    }
    else if (stackIndex > index)   // Move old band down
    {
        CGPoint pos = oldStack.position;
        pos.y = pos.y + stackHeight * (stackIndex - index);
        oldStack.position = pos;
    }
    else
        NSLog(@"ERROR! -- stackNum (%d), index (%d) conflict", stackIndex, index);
    
    // Shift new stack
    CALayer *draggingStack = [mutaStackLayerArr objectAtIndex:stackIndex];
    if (stackIndex < index)    // Move new band down
    {
        CGPoint pos = draggingStack.position;
        pos.y = pos.y + stackHeight * (index - stackIndex);
        draggingStack.position = pos;
    }
    else if (stackIndex > index)   // Move new band up
    {
        CGPoint pos = draggingStack.position;
        pos.y = pos.y - stackHeight * (stackIndex - index);
        draggingStack.position = pos;
    }
    else
        NSLog(@"ERROR! -- stackNum (%d), index (%d) conflict", stackIndex, index);
    
    // Reposition layers within stack array
    [mutaStackLayerArr replaceObjectAtIndex:index withObject:draggingStack];
    [mutaStackLayerArr replaceObjectAtIndex:stackIndex withObject:oldStack];
    _stackLayerArray = (NSArray *)mutaStackLayerArr;
    
    // Reposition layers within band array
    NSMutableArray *mutaBandLayerArr = [_bandLayerArray mutableCopy];
    NSArray *temp = [mutaBandLayerArr objectAtIndex:index];
    [mutaBandLayerArr replaceObjectAtIndex:index withObject:[mutaBandLayerArr objectAtIndex:stackIndex]];
    [mutaBandLayerArr replaceObjectAtIndex:stackIndex withObject:temp];
    _bandLayerArray = (NSArray *)mutaBandLayerArr;
    
    // Inform band layers of their new stack indices
    for (BandLayer *b in oldStack.sublayers)
    {
        b.stackNumber = stackIndex;
    }
    for (BandLayer *b in draggingStack.sublayers)
    {
        b.stackNumber = index;
    }
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
- (void)reorderBandsAroundBand:(NSInteger)bandIndex inStack:(NSInteger)stackIndex withNewIndex:(NSInteger)index
{    
    float temp_BAND_HEIGHT = BAND_HEIGHT * _globalZoomScale;
    float temp_BAND_SPACING = BAND_SPACING * _globalZoomScale;
    
    NSMutableArray *bandLayerMutable = [_bandLayerArray mutableCopy];
    for (NSInteger i = 0; i < [bandLayerMutable count]; i++)	// For each stack in the panel
    {
        NSMutableArray *bandArray = [[bandLayerMutable objectAtIndex:i] mutableCopy];
        
        BandLayer *oldBand = [bandArray objectAtIndex:index];
        if (bandIndex < index)    // Move old band up
        {
            CGPoint pos = oldBand.position;
            pos.y = pos.y - (temp_BAND_HEIGHT + temp_BAND_SPACING) * (index - bandIndex);
            oldBand.position = pos;
        }
        else if (bandIndex > index)   // Move old band down
        {
            CGPoint pos = oldBand.position;
            pos.y = pos.y + (temp_BAND_HEIGHT + temp_BAND_SPACING) * (bandIndex - index);
            oldBand.position = pos;
        }
        else
            NSLog(@"ERROR! -- bandNum (%d), index (%d) conflict", bandIndex, index);
            
        BandLayer *draggingBand = [bandArray objectAtIndex:bandIndex];
        if (bandIndex < index)    // Move new band down
        {
            CGPoint pos = draggingBand.position;
            pos.y = pos.y + (temp_BAND_HEIGHT + temp_BAND_SPACING) * (index - bandIndex);
            draggingBand.position = pos;
        }
        else if (bandIndex > index)   // Move new band up
        {
            CGPoint pos = draggingBand.position;
            pos.y = pos.y - (temp_BAND_HEIGHT + temp_BAND_SPACING) * (bandIndex - index);
            draggingBand.position = pos;
        }
        else
            NSLog(@"ERROR! -- bandNum (%d), index (%d) conflict", bandIndex, index);
        
        // Inform band layers of their new positions
        draggingBand.bandNumber = index;
        oldBand.bandNumber = bandIndex;
        
        // Reposition layers within array
        [bandArray replaceObjectAtIndex:index withObject:draggingBand];
        [bandArray replaceObjectAtIndex:bandIndex withObject:oldBand];
                
        [bandLayerMutable replaceObjectAtIndex:i withObject:(NSArray *)bandArray];        
    }
    
    _bandLayerArray = (NSArray *)bandLayerMutable;
}


#pragma mark -
#pragma mark Event-press handling


/**
 *  Find and return an array of all events underneath the specified point.
 *  Includes events in all currently printed panels.
 *
 *  location is the point under which we are looking for events
 */
- (NSArray *)findEventsAtPoint:(CGPoint)location
{
    Query *data = [_dataDelegate delegateRequestsQueryData];
    
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
                NSMutableArray *overlays = [[_dataDelegate delegateRequestsOverlays] mutableCopy];
                [overlays addObject:[NSNumber numberWithInt:_currentPanel]];
                BOOL currentOverlaid = NO;
                for (NSNumber *o in overlays)
                {
                    if ([o intValue] == _currentPanel && currentOverlaid) continue;   // Need to skip the current panel we added if it was returned as an overlay
                    
                    NSArray *eArr = [[[data.eventArray objectAtIndex:[o intValue]] objectAtIndex:i] objectAtIndex:j];
                    for (Event *e in eArr)
                    {
                        if ((e.x * (b.frame.size.width / BAND_WIDTH_P)) <= location.x && (e.x + e.width) * (b.frame.size.width / BAND_WIDTH_P) >= location.x)
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
    
    Query *data = [_dataDelegate delegateRequestsQueryData];
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
    for (int i = 0; i < [_stackLayerArray count]; i++)
    {
        CATiledLayer *stackLayer = [_stackLayerArray objectAtIndex:i];
        float stackY = stackHeight * i + temp_TIMELINE_HEIGHT;
        CGRect stackF = CGRectMake(0.0f, stackY, temp_BAND_WIDTH, stackHeight);
        stackLayer.frame = stackF;
//        stackLayer.tileSize = stackTiles;
        
        // Resize band layers
        NSArray *bandArray = [_bandLayerArray objectAtIndex:i];
        for (int j = 0; j < [[stackLayer sublayers] count]; j++)
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
    Query *data = [_dataDelegate delegateRequestsQueryData];
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
- (void)drawTimelinesForData:(Query *)data inContext:(CGContextRef)context withMonthWidth:(float)width
{    
    float temp_BAND_HEIGHT = BAND_HEIGHT * _globalZoomScale;
    float temp_BAND_SPACING = BAND_SPACING * _globalZoomScale;
    float temp_TIMELINE_HEIGHT = TIMELINE_HEIGHT * _globalZoomScale;
	float stackHeight = (data.bandNum-1.0f) * (temp_BAND_HEIGHT + temp_BAND_SPACING) + temp_BAND_HEIGHT + temp_TIMELINE_HEIGHT;
	
	if (data.timeScale == QueryTimescaleYear)
	{        
		for (int m = 0; m < 12; m++)
		{
			int xInt = m * (int)width;
			float x = xInt + 0.5f;
			CGRect monthF = CGRectMake(x, 0.0f, width, self.frame.size.height);
			monthF = CGRectInset(monthF, -0.5f, 0.5f);
			CGContextStrokeRect(context, monthF);
			NSString *month = [[PanelDrawView monthArray] objectAtIndex:m];
			
			// Labels
			for (int i = 0; i <= [_stackLayerArray count]; i++)
			{
				float stackY = stackHeight * i;
				CGRect tFrame = CGRectMake(monthF.origin.x, stackY + 8.0f, width, 16.0f);
                int fontSize = (int)((temp_TIMELINE_HEIGHT / 3.0f) + 1.0f);
				UIFont *font = [UIFont fontWithName:@"Helvetica" size:fontSize];
				[month drawInRect:tFrame withFont:font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
			}
		}
	}
	else
	{
		NSLog(@"ERROR: Undefined timescale: %d", data.timeScale);
	}
}



@end
