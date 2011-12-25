//
//  BandView.h
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class Event;
@class QueryData;
@class BandLayer;
@class ContentScrollView;
@protocol DataDelegate;

/**
 *  Delegation for all drawing-related information needed by other objects
 */
@protocol DrawDelegate
@required
- (float)delegateRequestsZoomscale;
- (UIColor *)getColorForPanel:(int)panelNum;
- (BandLayer *)getBandLayerForStack:(int)stackNum band:(int)bandNum;
- (CALayer *)getStackLayerForStack:(int)stackNum;
- (BOOL)reorderBandsAroundBand:(int)bandNum inStack:(int)stackNum withNewIndex:(int)index;
- (BOOL)reorderStacks:(int)stackNum withNewIndex:(int)index;

@end


/**
 *  The static View in which all drawing of bands and their events is done.
 *  Contains all BandLayers and is zoomed by the BandZoomView.
 */
@interface BandDrawView : UIView <DrawDelegate, UIPopoverControllerDelegate>

@property (nonatomic, strong) id<DataDelegate> dataDelegate;
@property (nonatomic, strong) UIPopoverController *infoPopup;   // The popover to display the EventInfo pane upon user request for details on a specific Event

- (id)initWithStackNum:(int)stackNum bandNum:(int)bandNum;
- (void)resizeForStackNum:(int)stackNum bandNum:(int)bandNum;
- (void)initLayersWithStackNum:(int)stackNum bandNum:(int)bandNum;

- (void)drawTimelinesForData:(QueryData *)data inContext:(CGContextRef)context withMonthWidth:(float)width;
- (UIColor *)getColorForPanel:(int)panelNum;

- (void)doneZooming;

- (void)startLongPress:(UILongPressGestureRecognizer *)gestureRecognizer;
- (NSArray *)findEventsAtPoint:(CGPoint)location;


@end


