//
//  BandView.h
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Event;
@class Query;
@class BandLayer;
@class ContentScrollView;
@protocol DataDelegate;

/**
 *  Delegation for all drawing-related information needed by other objects
 */
@protocol DrawDelegate
@required
- (float)delegateRequestsZoomscale;
- (NSInteger)delegateRequestsCurrentPanel;
- (BandLayer *)getBandLayerForStack:(NSInteger)stackNum band:(NSInteger)bandNum;
- (CALayer *)getStackLayerForStack:(NSInteger)stackNum;
- (void)reorderBandsAroundBand:(NSInteger)bandIndex inStack:(NSInteger)stackIndex withNewIndex:(NSInteger)index;
- (void)reorderStack:(NSInteger)stackIndex withNewIndex:(NSInteger)index;

@end


/**
 *  The static View in which all drawing of bands and their events is done.
 *  Contains all BandLayers and is zoomed by the BandZoomView.
 */
@interface PanelDrawView : UIView <DrawDelegate, UIPopoverControllerDelegate>

@property (nonatomic, strong) id<DataDelegate> dataDelegate;
@property (nonatomic, strong) UIPopoverController *infoPopup;   // The popover to display the EventInfo pane upon user request for details on a specific Event
@property (nonatomic, assign) NSInteger currentPanel; // Index of the panel this zoom view displays content for

- (void)sizeForStackNum:(NSInteger)stackNum bandNum:(NSInteger)bandNum;
- (void)initLayersWithStackNum:(NSInteger)stackNum bandNum:(NSInteger)bandNum;

- (void)drawTimelinesForData:(Query *)data inContext:(CGContextRef)context withMonthWidth:(float)width;

- (void)doneZooming;
- (void)zoomToScale:(float)zoomScale;

- (NSArray *)findEventsAtPoint:(CGPoint)location;


@end


