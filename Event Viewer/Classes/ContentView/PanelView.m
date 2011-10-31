//
//  PanelView.m
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PanelView.h"

@implementation PanelView

@synthesize isStatic = _isStatic;

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) 
    {
        // Initialization code
    }
    return self;
}

/**
 *  Overridden initialization to create the panel with a specified number of stacks and bands.
 *  Does not take a frame parameter, as the frame of a panel is always a size derived from the number of stacks and bands.
 *
 *  stackNum is the number of stacks in the panel
 *  bandNum is the number of bands in each stack
 */
- (id)initWithStacks:(int)stackNum Bands:(int)bandNum
{
    CGRect frame = CGRectMake(0.0, 
                              0.0, 
                              768.0, 
                              (bandNum * (BAND_HEIGHT_P + 16.0) + 16.0) * stackNum);
    if ((self = [super initWithFrame:frame]))
    {
        NSMutableArray *mutableStacks = [[NSMutableArray alloc] init];
        
        //determine color of bands
        CGFloat red =  (CGFloat)random()/(CGFloat)RAND_MAX;
        CGFloat blue = (CGFloat)random()/(CGFloat)RAND_MAX;
        CGFloat green = (CGFloat)random()/(CGFloat)RAND_MAX;
        UIColor *bandColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
        for (int i = 0; i < stackNum; i++)
        {
            StackView *newStack = [[StackView alloc] initWithStackNum:i OutOf:stackNum WithBands:bandNum OfColor:bandColor];
            [self addSubview:newStack];
            [mutableStacks addObject:newStack];
        }
        
        _stackViews = mutableStacks;
        
        self.backgroundColor = [UIColor whiteColor];
        self.opaque = YES;
        self.hidden = YES;
        self.isStatic = NO;
    }
    
    return self;
}

/**
 *  Unhides the panel and all of its related components, unless the panel is currently statically overlaid.
 */
- (void)unHide
{
    if (_isStatic || !self.hidden)
        return;
    NSLog(@"Showing panel");
    self.hidden = NO;
    for (StackView *s in _stackViews) 
    {
        [s unHide];
    }
}

/**
 *  Hides the panel and all of its related components, unless the panel is currently statically overlaid.
 */
- (void)hide
{
    if (_isStatic || self.hidden)
        return;
    NSLog(@"Hiding panel");
    self.hidden = YES;
    for (StackView *s in _stackViews) 
    {
        [s hide];
    }
}

/**
 *  Toggles the panel and all of its related components to become transparent and overlay on top of all other currently displayed panels.
 */
- (void)toggleOverlay
{
    if (!_isStatic)
    {
        NSLog(@"Making panel overlay");
        _isStatic = YES;
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        for (StackView *s in _stackViews)
        {
            [s toggleOverlay];
        }
    }
    else
    {
        NSLog(@"Unoverlaying panel");
        _isStatic = NO;
        self.backgroundColor = [UIColor whiteColor];
        self.opaque = YES;
        for (StackView *s in _stackViews)
        {
            [s toggleOverlay];
        }
    }
}

- (void)drawRect:(CGRect)rect 
{
	//create 1px black border
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetLineWidth(context, 1.0);
    [[UIColor blackColor] set];
	CGContextStrokeRect(context, rect);
}

@end
