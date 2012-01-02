//
//  BandZoomView.h
//  Event Viewer
//
//  Created by admin on 11/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PanelDrawView;

/**
 *  The ScrollView within the ContentScrollView that contains all of the bands.
 *  Is responsible for zooming the bands, thus should only zoom and scroll left and right.
 */
@interface PanelZoomView : UIScrollView <UIScrollViewDelegate>

@property (nonatomic, strong) PanelDrawView *panelDrawView;      // The static View in which all bands are drawn. Is the view that is zoomed and panned by this ScrollView.

//- (id)initWithFrame:(CGRect)frame forPanelIndex:(int)panelIndex stackNum:(int)stackNum bandNum:(int)bandNum;
- (void)sizeForStackNum:(int)stackNum bandNum:(int)bandNum;

@end
