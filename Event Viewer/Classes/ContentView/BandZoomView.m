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

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) 
    {

    }
    
    return self;
}

- (id)initWithStackNum:(int)stackNum bandNum:(int)bandNum
{
    CGRect frame = CGRectMake(192.0f,//(768.0 - BAND_WIDTH_P)*3/4,
                              0.0f,
                              BAND_WIDTH_P,
                              (bandNum * (BAND_HEIGHT_P + BAND_SPACING) + STACK_SPACING) * stackNum);
    if ((self = [super initWithFrame:frame]))
    {
        self.backgroundColor = [UIColor whiteColor];
        self.opaque = YES;
		self.showsVerticalScrollIndicator = NO;
		self.showsHorizontalScrollIndicator = NO;
		
		self.maximumZoomScale = 10.0f;
		self.minimumZoomScale = 1.0f;
		self.delegate = self;
        
        BandDrawView *bandView = [[BandDrawView alloc] initWithStackNum:stackNum bandNum:bandNum];
        _bandDrawView = bandView;
        [self addSubview:bandView];
        self.contentSize = bandView.frame.size;
        
        [_bandDrawView setNeedsDisplay];
    }
    
    return self;
}

- (void)resizeForStackNum:(int)stackNum bandNum:(int)bandNum
{
    CGRect frame = CGRectMake(192.0f,//(768.0 - BAND_WIDTH_P)*3/4,
                              0.0f,
                              BAND_WIDTH_P,
                              (bandNum * (BAND_HEIGHT_P + BAND_SPACING) + STACK_SPACING) * stackNum);
    self.frame = frame;
    [_bandDrawView resizeForStackNum:stackNum bandNum:bandNum];
    self.contentSize = _bandDrawView.frame.size;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView 
{	
	return _bandDrawView;
}

- (void)scrollViewDidEndZooming:(BandZoomView *)scrollView withView:(UIView *)view atScale:(float)scale
{
	[scrollView.bandDrawView setNeedsDisplay];
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
