//
//  ContentScrollView.h
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PanelView.h"

#define BAND_HEIGHT_P 64.0
#define BAND_HEIGHT_L 48.0
#define BAND_WIDTH_P 512.0
#define BAND_WIDTH_L 369.0

@interface ContentScrollView : UIScrollView
{
    NSArray *_panelViews;   //all PanelViews managed by the content scroll view
    int _currentPanel;
}

- (void)addPanelWithStacks:(int)stackNum Bands:(int)bandNum;
- (void)removePanel;
- (void)switchToPanel:(int)panelNum;

@end
