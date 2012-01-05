//
//  ContentScrollView.h
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PanelZoomView;
@class ContentView;
@class QueryData;
@protocol DataDelegate;
@protocol DrawDelegate;

/**
 *  ScrollView containing all content in the currently displayed query results. Is the superview to all others, and the ContentViewController's primary view.
 */
@interface ContentScrollView : UIScrollView <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) id<DataDelegate> dataDelegate;
@property (nonatomic, strong) id<DrawDelegate> drawDelegate;    // Target for drawing delegation (must be set to the 0-indexed panel)
@property (nonatomic, strong) NSArray *panelZoomViews;          // Array of all zooming scrollviews representing the panels in the display
@property (nonatomic, strong) UIView *queryContentView;         // View containing all panels and content within the ContentScrollView (_contentView is reserved by UIScrollView :( )

- (id)initWithPanelNum:(int)panelNum stackNum:(int)stackNum bandNum:(int)bandNum;
- (void)sizeForPanelNum:(int)panelNum stackNum:(int)stackNum bandNum:(int)bandNum;

- (void)switchToPanel:(int)panelIndex;

- (void)handleDragging:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void)startDragging:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void)doDrag:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void)stopDragging:(UILongPressGestureRecognizer *)gestureRecognizer;

- (BOOL)reorderPanel:(int)panelIndex withNewIndex:(int)index;

@end
