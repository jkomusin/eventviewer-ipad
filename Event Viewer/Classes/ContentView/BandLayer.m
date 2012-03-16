//
//  BandLayer.m
//  Event Viewer
//
//  Created by monet on 12/13/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PrimaryViewController.h"
#import "PanelDrawView.h"
#import "Query.h"
#import "BandLayer.h"
#import "Event.h"

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
 *  Overridden to modify the duration of the fade-in time of each tile
 */
+ (CFTimeInterval)fadeDuration
{
    return 0.1f;
}

@end
