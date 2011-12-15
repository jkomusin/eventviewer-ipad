//
//  ContentScrollView.h
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BandZoomView;
@class QueryData;
@protocol DataDelegate;
@protocol DrawDelegate;

// Constants containing dimensions of bands in each device orientation.
//  All other measurements of UI elements are based off of these dimensions.
#define BAND_HEIGHT_P 64.0f
#define BAND_HEIGHT_L 48.0f
#define BAND_WIDTH_P 529.0f
#define BAND_WIDTH_L 369.0f
#define BAND_SPACING 8.0f
#define STACK_SPACING 32.0f


@interface ContentScrollView : UIScrollView

@property (nonatomic, strong) id<DataDelegate> dataDelegate;
@property (nonatomic, strong) id<DrawDelegate> drawDelegate;
@property (nonatomic, assign) int currentPanel;      // Index in the panelViews array of the panel currently selected by the scrubber's movable selector (0-indexed, -1 indicates no panes exist)
@property (nonatomic, strong) BandZoomView *bandZoomView;   // Zooming scrollview containing all drawings of bands, stacks, and events

- (void)resizeForStackNum:(int)stackNum bandNum:(int)bandNum;

- (void)createLabels;
- (void)swapAllBandLabels:(int)draggingIndex and:(int)otherIndex;

- (void)switchToPanel:(int)panelNum;

- (void)startDragging:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void)doDrag:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void)stopDragging:(UILongPressGestureRecognizer *)gestureRecognizer;

@end
