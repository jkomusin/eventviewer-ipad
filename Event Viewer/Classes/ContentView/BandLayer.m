//
//  BandLayer.m
//  Event Viewer
//
//  Created by monet on 12/13/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ContentViewController.h"
#import "BandDrawView.h"
#import "QueryData.h"
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


- (void)drawInContext:(CGContextRef)context
{	
    QueryData *data = [_dataDelegate delegateRequestsQueryData];
    
    CGRect bandDrawF = CGRectMake(0.0f, 0.0f, self.bounds.size.width, self.bounds.size.height);
    bandDrawF = CGRectInset(bandDrawF, 0.5f, 0.5f);
    
    // Draw background
    CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 1.0f);
    CGContextFillRect(context, bandDrawF);
    
    // Draw events for overlaid & current panels
    int currentPanel = [_dataDelegate delegateRequestsCurrentPanel];
    BOOL currentPanelIsOverlaid = NO;
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

    // Draw frame
    CGContextSetRGBStrokeColor(context, 0.0f, 0.0f, 0.0f, 1.0f);
    CGContextStrokeRect(context, bandDrawF);
}

- (void)drawEventsForPanel:(int)panel fromArray:(NSArray *)eventArray inContext:(CGContextRef)context
{
    NSArray *eArr = [[[eventArray objectAtIndex:panel] objectAtIndex:_stackNumber] objectAtIndex:_bandNumber];
    float zoomScale = [_drawDelegate delegateRequestsZoomscale];
    CGContextSetFillColorWithColor(context, [_drawDelegate getColorForPanel:panel].CGColor);
    
    for (Event *e in eArr)
    {
        int intX = (int)(e.x * zoomScale);
        float x = (float)intX + 0.5f;
        int intW = (int)(e.width * zoomScale);
        float width = (float)intW;
        CGRect eRect = CGRectMake(x, 
                                  0.0f, 
                                  width, 
                                  BAND_HEIGHT_P);
        CGContextFillRect(context, eRect);
    }
}

@end
