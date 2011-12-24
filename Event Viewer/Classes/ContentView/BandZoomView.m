//
//  BandZoomView.m
//  Event Viewer
//
//  Created by admin on 11/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "BandZoomView.h"
#import "BandDrawView.h"
#import "ContentScrollView.h"

@implementation BandZoomView

@synthesize bandDrawView = _bandDrawView;


#pragma mark -
#pragma mark Initialization

/**
 *  Custom initializer to resize the view to fit the required number of stacks and bands.
 *
 *  stackNum is the number of stacks being fit
 *  bandNum is the number of bands being fit
 */
- (id)initWithStackNum:(int)stackNum bandNum:(int)bandNum
{
    CGRect frame = CGRectMake((int)(768.0 - BAND_WIDTH_P)*3/4,  // Has to be rounded to an integer to truncate the trailing floating-point errors that reuslt for the calculation, otherwise drawing will not be exact in iOS's drawing coordinates (in order to offset them by precisely 0.5 units)
                              0.0f,
                              BAND_WIDTH_P,
                              (bandNum * (BAND_HEIGHT_P + BAND_SPACING) + STACK_SPACING) * stackNum);
    if ((self = [super initWithFrame:frame]))
    {
        self.backgroundColor = [UIColor blackColor];
        self.opaque = YES;
		self.showsVerticalScrollIndicator = NO;
		self.showsHorizontalScrollIndicator = NO;
		
		self.maximumZoomScale = 2.0f;   // Irrelevant due to our overridden zooming technique that provides infinite zooming
		self.minimumZoomScale = 1.0f;
        self.bouncesZoom = YES;
        
		self.delegate = self;
        
        BandDrawView *bandView = [[BandDrawView alloc] initWithStackNum:stackNum bandNum:bandNum];
        _bandDrawView = bandView;
        [self addSubview:bandView];
        self.contentSize = bandView.frame.size;
        
        [_bandDrawView setNeedsDisplay];
    }
    
    return self;
}

/**
 *  Resizes the view to the correct dimensions to fit the specified number of stacks and bands, typically for a newly submitted query.
 *
 *  stackNum is the number of stacks being fit
 *  bandNum is the number of bands being fit
 */
- (void)resizeForStackNum:(int)stackNum bandNum:(int)bandNum
{
    CGRect frame = CGRectMake((int)(768.0 - BAND_WIDTH_P)*3/4,  // See above explanation on integer cast
                              0.0f,
                              BAND_WIDTH_P,
                              (bandNum * (BAND_HEIGHT_P + BAND_SPACING) + STACK_SPACING) * stackNum);
    self.frame = frame;
    [_bandDrawView resizeForStackNum:stackNum bandNum:bandNum];
    self.contentSize = _bandDrawView.frame.size;
}

/**
 *  Overridden to manually zoom drawing view
 */
//- (void)scrollViewDidZoom:(BandZoomView *)scrollView
//{
//    [scrollView.bandDrawView setNewZoomScale:[scrollView zoomScale]];
//}

/**
 *  Overridden so that re-drawing only occurs when zooming has completed, to allow for smooth zooming (redrawing is costly if done on ever minute update).
 */
- (void)scrollViewDidEndZooming:(BandZoomView *)scrollView withView:(UIView *)view atScale:(float)scale
{
    [scrollView.bandDrawView doneZooming];
	[scrollView.bandDrawView setNeedsDisplay];
}

/**
 *  Overrridden so that re-drawing will occur when scrolling has completed, effectively erasing all cached tiles
 */
//- (void)scrollViewDidEndDecelerating:(BandZoomView *)scrollView
//{
//    [scrollView.bandDrawView setNeedsDisplay];
//}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView 
{	
	return _bandDrawView;
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
