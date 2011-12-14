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
    id<ZoomDelegate> zoomDelegate;
}

@synthesize dataDelegate = _dataDelegate;
@synthesize zoomDelegate = _zoomDelegate;
@synthesize stackNumber = _stackNumber;
@synthesize bandNumber = _bandNumber;


- (void)drawInContext:(CGContextRef)context
{
    NSLog(@"BandLayer is drawing on frame (%f, %f, %f, %f)", self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
//      
//    CGFloat components[4] = {1.0f,0.0f,0.0f,1.0f};
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//    CGColorRef color = CGColorCreate(colorSpace, components);
//    CGColorSpaceRelease(colorSpace);
//	self.backgroundColor = [UIColor redColor].CGColor;
//	CGColorRelease(color);
	self.opaque = YES;
	
    QueryData *data = [dataDelegate delegateRequestsQueryData];
    float zoomScale = [zoomDelegate delegateRequestsZoomscale];
	NSLog(@"Zoomscale: %f", zoomScale);
//	zoomScale = 1.0f;
    
    // Draw frame
    CGContextSetRGBStrokeColor(context, 0.0f, 0.0f, 0.0f, 1.0f);
    CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 1.0f);
    CGRect bandF = CGRectMake(0.0f, 0.0f, self.bounds.size.width * zoomScale, self.bounds.size.height * zoomScale);
    bandF = CGRectInset(bandF, 0.5f, 0.5f);
    CGContextFillRect(context, bandF);
    CGContextStrokeRect(context, bandF);
    
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

- (void)drawEventsForPanel:(int)panel fromArray:(NSArray *)eventArray inContext:(CGContextRef)context
{
    NSArray *eArr = [[[eventArray objectAtIndex:panel] objectAtIndex:_stackNumber] objectAtIndex:_bandNumber];
    float zoomScale = [zoomDelegate delegateRequestsZoomscale];
    [[zoomDelegate getColorForPanel:panel] setFill];
    
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
