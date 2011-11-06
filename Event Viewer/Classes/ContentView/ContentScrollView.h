//
//  ContentScrollView.h
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BandZoomView;

// Constants containing dimensions of bands in each device orientation.
//  All other measurements of UI elements are based off of these dimensions.
#define BAND_HEIGHT_P 64.0
#define BAND_HEIGHT_L 48.0
#define BAND_WIDTH_P 512.0
#define BAND_WIDTH_L 369.0

@interface ContentScrollView : UIScrollView
{
    NSArray *_panelViews;   // Static array of all PanelViews
}

@property (nonatomic, assign) int currentPanel;      // Index in the panelViews array of the panel currently selected by the scrubber's movable selector (0-indexed, -1 indicates no panes exist)
@property (nonatomic, strong) BandZoomView *bandZoomView;   // Zooming scrollview containing all drawings of bands, stacks, and events

- (void)addPanelWithStacks:(int)stackNum bands:(int)bandNum;
- (void)removePanel;
- (void)switchToPanel:(int)panelNum;
- (void)toggleOverlayPanel:(int)panelNum;

@end
