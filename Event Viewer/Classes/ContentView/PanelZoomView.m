//
//  BandZoomView.m
//  Event Viewer
//
//  Created by admin on 11/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PanelZoomView.h"
#import "PanelDrawView.h"
#import "ContentScrollView.h"

@implementation PanelZoomView
{
    CGRect _originalFrame;  // Frame of the view at zoomScale 1.0
}

@synthesize panelDrawView = _panelDrawView;

OBJC_EXPORT BOOL isPortrait;             // Global variable set in ContentViewController to specify device orientation
OBJC_EXPORT float BAND_HEIGHT;              //
OBJC_EXPORT float BAND_WIDTH;               //  Globals set in ContentViewControlled specifying UI layout parameters
OBJC_EXPORT float BAND_SPACING;             //
OBJC_EXPORT float STACK_SPACING;            //

#pragma mark -
#pragma mark Initialization

/**
 *  Custom initializer to set and intiialize parameters
 *  NOTE: Does NOT establish frame. Sizing must be done by the caller via the approproate method to establish a frame
 *      currenPanel property of drawView must also be set by caller
 *
 *  stackNum is the number of stacks being fit
 *  bandNum is the number of bands being fit
 */
- (id)init
{
    if ((self = [super init]))
    {
        self.backgroundColor = [UIColor blackColor];
        self.opaque = YES;
		self.showsVerticalScrollIndicator = NO;
		self.showsHorizontalScrollIndicator = NO;
		
		self.maximumZoomScale = 2.0f;   // Irrelevant due to our overridden zooming technique that provides infinite zooming
		self.minimumZoomScale = 1.0f;
        self.bouncesZoom = YES;
        
		self.delegate = self;
        
        PanelDrawView *bandView = [[PanelDrawView alloc] init];
        _panelDrawView = bandView;
        [self addSubview:bandView];
    }
    
    return self;
}

/**
 *  Sizes the view to the correct dimensions to fit the specified number of panels, stacks, and bands, typically for a newly submitted query.
 *  NOTE: x,y coordinates must be set by caller prior to sizing
 *
 *  panelNum is the number of panels this must fit alongside with in landscape
 *  stackNum is the number of stacks being fit
 *  bandNum is the number of bands being fit
 */
- (void)sizeForStackNum:(int)stackNum bandNum:(int)bandNum
{
    CGRect frame = self.frame;
    frame.size.width = BAND_WIDTH;
    frame.size.height = (bandNum * (BAND_HEIGHT + BAND_SPACING) + STACK_SPACING) * stackNum;
    self.frame = frame;
    
    _originalFrame = frame;
    
    [_panelDrawView sizeForStackNum:stackNum bandNum:bandNum];
    self.contentSize = _panelDrawView.frame.size;
}

/**
 *  Overridden so that re-drawing only occurs when zooming has completed, to allow for smooth zooming (redrawing is costly if done on ever minute update).
 *  Also informs drawing view that it may set its zoomscale to the current value, as the transformation has ended
 */
- (void)scrollViewDidEndZooming:(PanelZoomView *)scrollView withView:(UIView *)view atScale:(float)scale
{
    [scrollView.panelDrawView doneZooming];
	[scrollView.panelDrawView setNeedsDisplay];
}

/**
 *  Basic override for zooming in UIScrollViews
 */
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView 
{	    
	return _panelDrawView;
}

/**
 *  Zoom self and all subviews
 */
- (void)zoomToScale:(float)zoomScale
{
    CGRect newFrame = _originalFrame;
    newFrame.size.width = _originalFrame.size.width * zoomScale;
    newFrame.size.height = _originalFrame.size.height * zoomScale;
    if (_panelDrawView.currentPanel != 0)
    {
        newFrame.origin.x = _originalFrame.origin.x * zoomScale;
    }
    self.frame = newFrame;
    
    [_panelDrawView zoomToScale:zoomScale];
    self.contentSize = _panelDrawView.frame.size;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
