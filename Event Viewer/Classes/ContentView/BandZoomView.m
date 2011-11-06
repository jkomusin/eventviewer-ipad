//
//  BandZoomView.m
//  Event Viewer
//
//  Created by admin on 11/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "BandZoomView.h"
#import "BandView.h"
#import "ContentScrollView.h"

@implementation BandZoomView

@synthesize bandView = _bandView;

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) 
    {

    }
    
    return self;
}

- (id)initWithStackNum:(int)stackNum BandNum:(int)bandNum
{
    CGRect frame = CGRectMake((768.0 - BAND_WIDTH_P)*3/4, 
                              0.0, 
                              BAND_WIDTH_P, 
                              (bandNum * (BAND_HEIGHT_P + 16.0) + 16.0) * stackNum);    
    if ((self = [super initWithFrame:frame]))
    {
        self.backgroundColor = [UIColor whiteColor];
        self.opaque = YES;
        
        BandView *bandView = [[BandView alloc] initWithStackNum:stackNum BandNum:bandNum];
        _bandView = bandView;
        [self addSubview:bandView];
        self.contentSize = bandView.frame.size;
        
        [_bandView setNeedsDisplay];
    }
    
    return self;
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
