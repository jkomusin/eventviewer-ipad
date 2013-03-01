
#import "PrimaryViewController.h"
#import "PanelDrawView.h"
#import "Query.h"
#import "BandLayer.h"
#import "Event.h"
#import "EventPriorityQueue.h"

@interface BandLayer ()
- (void)drawEventsForPanel:(NSInteger)panel fromArray:(NSArray *)eventArray inContext:(CGContextRef)context;
- (NSArray *)createEventFloatsFromEventArrays:(NSArray *)eventArrs;
- (NSInteger)maxNumberOfOverlaps:(NSArray *)floatArr;
- (void)drawOverlaidEventsFromFloats:(NSArray *)floatArr withMaxOverlap:(NSInteger)maxOverlap inContext:(CGContextRef)context;

@end


@implementation BandLayer
{
    id<DataDelegate> dataDelegate;
    id<DrawDelegate> drawDelegate;
}

@synthesize dataDelegate = _dataDelegate;
@synthesize zoomDelegate = _drawDelegate;
@synthesize stackNumber = _stackNumber;
@synthesize bandNumber = _bandNumber;

OBJC_EXPORT BOOL isPortrait;
OBJC_EXPORT enum EVENT_STYLE eventStyle;
OBJC_EXPORT float BAND_HEIGHT;              //
OBJC_EXPORT float BAND_WIDTH;               //  Globals set in ContentViewControlled specifying UI layout parameters
OBJC_EXPORT float BAND_SPACING;             //
OBJC_EXPORT float TIMELINE_HEIGHT;          //

- (void)drawInContext:(CGContextRef)context
{            
    Query *data = [_dataDelegate delegateRequestsQueryData];
    
    CGRect bandDrawF = CGRectMake(0.0f, 0.0f, self.bounds.size.width, self.bounds.size.height);
    bandDrawF = CGRectInset(bandDrawF, 0.5f, 0.5f);
    
    // Draw background
    CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 1.0f);
    CGContextFillRect(context, bandDrawF);
	
	// Retrieve event array copy to draw from to avoid problems during drawing (eventArray has the 'copy' modifier)
	//	(concurrent modifications may result during the return of queries)
	NSArray *eventArray = data.eventArray;
	
    // Draw events for overlaid & current panels
    int currentPanel = [_drawDelegate delegateRequestsCurrentPanel];
	if (eventStyle == UIEventStylePlain)
	{
		BOOL currentPanelIsOverlaid = NO;
		NSArray *overlays = [_dataDelegate delegateRequestsOverlays];
		for (NSNumber *i in overlays)
		{
			[self drawEventsForPanel:[i intValue] fromArray:eventArray inContext:context];
			if ([i intValue] == currentPanel) 
			{
				currentPanelIsOverlaid = YES;
			}
		}
		if (!currentPanelIsOverlaid && currentPanel != -1)
		{
			[self drawEventsForPanel:currentPanel fromArray:eventArray inContext:context];
		}
	}
	else if (eventStyle == UIEventStyleOverlap)
	{
		NSMutableArray *bandArr = [[NSMutableArray alloc] init];
		BOOL currentPanelIsOverlaid = NO;
		NSArray *overlays = [_dataDelegate delegateRequestsOverlays];
		// Retrieve layout of overlaid Events
		for (NSNumber *i in overlays)
		{
			NSMutableArray *eArr = [[[[eventArray objectAtIndex:[i intValue]] objectAtIndex:_stackNumber] objectAtIndex:_bandNumber] mutableCopy];
			[bandArr addObject:eArr];
			if ([i intValue] == currentPanel) 
			{
				currentPanelIsOverlaid = YES;
			}
		}
		if (!currentPanelIsOverlaid && currentPanel != -1)
		{
			NSMutableArray *eArr = [[[[eventArray objectAtIndex:currentPanel] objectAtIndex:_stackNumber] objectAtIndex:_bandNumber] mutableCopy];
			[bandArr addObject:eArr];
		}
		NSArray *floatArr = [self createEventFloatsFromEventArrays:bandArr];
		
		// Find maximum number of overlapping Events for scaling the colors
		int maxOverlap = [self maxNumberOfOverlaps:floatArr];
		NSLog(@"Max overlap: %d", maxOverlap);
		[self drawOverlaidEventsFromFloats:floatArr withMaxOverlap:maxOverlap inContext:context];
	}

    // Draw frame
    CGContextSetRGBStrokeColor(context, 0.0f, 0.0f, 0.0f, 1.0f);
    CGContextStrokeRect(context, bandDrawF);
}

/**
 *  Draw all events for a specific panel.
 *
 *  panelIndex is the 0-based index of the panel whose events are being drawn
 *  eArray is the 4-dimensional array of events stored in the current QueryData object
 *  context is the current drawing context reference
 */
- (void)drawEventsForPanel:(NSInteger)panelIndex fromArray:(NSArray *)eventArray inContext:(CGContextRef)context
{
    NSArray *eArr = [[[[eventArray objectAtIndex:panelIndex] objectAtIndex:_stackNumber] objectAtIndex:_bandNumber] copy];
    float zoomScale = [_drawDelegate delegateRequestsZoomscale];
    CGContextSetFillColorWithColor(context, [_dataDelegate getColorForPanel:panelIndex].CGColor);
	
    for (Event *e in eArr)
    {
        int intX = (int)(e.x * zoomScale);
        if (isPortrait) intX = (int)(intX * (BAND_WIDTH / BAND_WIDTH_P));
        else            intX = (int)(intX * (self.frame.size.width / BAND_WIDTH_P));
        float x = (float)intX + 0.5f;
        
        int intW = (int)(e.width * zoomScale);
        if (isPortrait) intW = (int)(intW * (BAND_WIDTH / BAND_WIDTH_P));
        else            intW = (int)(intW * (self.frame.size.width / BAND_WIDTH_P));
        float width = (float)intW;
        
        CGRect eRect = CGRectMake(x, 
                                  0.0f, 
                                  width, 
                                  self.frame.size.height);
        CGContextFillRect(context, eRect);
    }
}

/**
 *	Creates a 2-dimensional array of floats such that each entry is a 2-tuple of the format:
 *		- float at index 0 specifying the un-zoomed location on the Band
 *		- An enum specifying whether or not the float specifies an Event's START or END location
 *
 *	eventArrs is a mutable array of mutable arrays of Events of all the panels being overlaid (all the arrays being merged to floats).
 */
- (NSArray *)createEventFloatsFromEventArrays:(NSMutableArray *)eventArrs
{
	EventPriorityQueue *queue = [[EventPriorityQueue alloc] init];
	NSMutableArray *results = [[NSMutableArray alloc] init];
	for (NSMutableArray *arr in eventArrs)
	{	// Initialize queue
		if ([arr count] != 0)
			[queue addObject:[arr objectAtIndex:0]];
	}
	// Array to hold Events that are half-processed
	NSMutableArray *eventEnds = [[NSMutableArray alloc] init];
	
	while ([queue count] != 0)
	{
		Event *e = [queue peekObject];
		
		// Check if an end is our best choice
		Event *best = nil;
		for (Event *end in eventEnds)
		{
			if ((!best && end.endX < e.x) ||
				(best && end.endX < best.x))
			{
				best = end;
			}
		}
		if (best)
		{
			[eventEnds removeObject:best];
			[results addObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:best.endX], [NSNumber numberWithInt:EventLocationEnd], nil]];
			continue;
		}

		// Find next Event to insert
		[queue nextObject];
		for (NSMutableArray *arr in eventArrs)
		{
			if ([arr containsObject:e])
			{
				[arr removeObject:e];
				if ([arr count] > 0)
					[queue addObject:(Event *)[arr objectAtIndex:0]];
				break;
			}
		}
		[results addObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:e.x], [NSNumber numberWithInt:EventLocationStart], nil]];
		[eventEnds addObject:e];
	}
	// Clean up any remaining loose ends
	for (int i = 0; i < [eventEnds count]; i++)
	{
		[results addObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:((Event *)[eventEnds objectAtIndex:i]).endX], [NSNumber numberWithInt:EventLocationEnd], nil]];
	}
	
	return (NSArray *)results;
}

/**
 *	Find the maximum number of overlapping Events in the given array of Event floats.
 */
- (NSInteger)maxNumberOfOverlaps:(NSArray *)floatArr
{
	int max = 0;
	int count = 0;
	for (int i = 0; i < [floatArr count]-2; i++)
	{
		NSArray *arr = [floatArr objectAtIndex:i];
		if ([[arr objectAtIndex:1] intValue] == EventLocationStart)
		{
			count++;
			if (count > max)
				max = count;
		}
		else
			count--;
	}
	
	return max;
}

/**
 *	Based on the float array fed in and the maximum number of overlaps that may be encountered, 
 *	draw all event boxes with their respecive overlap amount corresponding to their hue ranging
 *	from green to red.
 */
- (void)drawOverlaidEventsFromFloats:(NSArray *)floatArr withMaxOverlap:(NSInteger)maxOverlap inContext:(CGContextRef)context
{
	int count = 0;
	for (int i = 0; i < [floatArr count]-2; i++)	// Skip last one as we check the next in each iteration
	{
		NSArray *arr = [floatArr objectAtIndex:i];
		NSArray *next = [floatArr objectAtIndex:i+1];
		if ([[arr objectAtIndex:1] intValue] == EventLocationStart)
			count++;	// Beginning of new event, add to overlap
		else
			count--;	// End of event, remove overlap
		
		if ([[arr objectAtIndex:0] floatValue] == [[next objectAtIndex:0] floatValue])
		{	// If the next event starts/ends at the same position, take care of it on the next iteration
			continue;
		}
		else if (count > 0)	// Draw the box
		{
			// Calculate color in green-red spectrum
			float t = (count - 1.0f) / (maxOverlap - 1.0f);
			CGFloat color[] = {t, 1.0f-t, 0.0f, 1.0f};
			CGContextSetFillColor(context, color);
			// Calculate coordinates
			float origX = [[arr objectAtIndex:0] floatValue];
			float origW = [[next objectAtIndex:0] floatValue] - [[arr objectAtIndex:0] floatValue];
			float zoomScale = [_drawDelegate delegateRequestsZoomscale];
			
			int intX = (int)(origX * zoomScale);
			if (isPortrait) intX = (int)(intX * (BAND_WIDTH / BAND_WIDTH_P));
			else            intX = (int)(intX * (self.frame.size.width / BAND_WIDTH_P));
			float x = (float)intX + 0.5f;
			
			int intW = (int)(origW * zoomScale);
			if (isPortrait) intW = (int)(intW * (BAND_WIDTH / BAND_WIDTH_P));
			else            intW = (int)(intW * (self.frame.size.width / BAND_WIDTH_P));
			float width = (float)intW;
			// Calculate box
			CGRect box = CGRectMake(x, 
									0.0f, 
									width, 
									self.frame.size.height);
			CGContextFillRect(context, box);
		}
	}
}

/**
 *  Overridden to modify the duration of the fade-in time of each tile
 */
+ (CFTimeInterval)fadeDuration
{
    return 0.1f;
}

@end
