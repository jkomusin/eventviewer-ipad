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
    CGRect frame = CGRectMake((768.0 - BAND_WIDTH_P)*3/4,
                              0.0,
                              BAND_WIDTH_P,
                              (bandNum * (BAND_HEIGHT_P + 16.0) + 16.0) * stackNum);
    if ((self = [super initWithFrame:frame]))
    {
        self.backgroundColor = [UIColor whiteColor];
        self.opaque = YES;
        
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
    CGRect frame = CGRectMake((768.0 - BAND_WIDTH_P)*3/4,
                              0.0,
                              BAND_WIDTH_P,
                              (bandNum * (BAND_HEIGHT_P + 16.0) + 16.0) * stackNum);
    self.frame = frame;
    self.contentSize = _bandDrawView.frame.size;
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
