//
//  ContentScrollView.h
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PanelZoomView;
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

/**
 *  ScrollView containing all content in the currently displayed query results. Is the superview to all others, and the ContentViewController's primary view.
 */
@interface ContentScrollView : UIScrollView <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) id<DataDelegate> dataDelegate;
@property (nonatomic, strong) id<DrawDelegate> drawDelegate;
@property (nonatomic, strong) NSArray *panelZoomViews;      // Array of all zooming scrollviews representing the panels in the display
@property (nonatomic, strong) UIView *queryContentView;          // View containing all panels and content within the ContentScrollView (_contentView is reserved by UIScrollView :( )

- (id)initWithPanelNum:(int)panelNum stackNum:(int)stackNum bandNum:(int)bandNum;
- (void)sizeForPanelNum:(int)panelNum stackNum:(int)stackNum bandNum:(int)bandNum;

- (void)switchToPanel:(int)panelIndex;

- (void)startDragging:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void)doDrag:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void)stopDragging:(UILongPressGestureRecognizer *)gestureRecognizer;

@end
