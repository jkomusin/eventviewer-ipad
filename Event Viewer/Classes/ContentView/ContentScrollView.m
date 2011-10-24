//
//  ContentScrollView.m
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ContentScrollView.h"

@implementation ContentScrollView

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) 
    {
        NSArray *newArr = [[NSArray alloc] init];
        _panelViews = newArr;
        _currentPanel = -1;
    }
    
    self.opaque = YES;
    return self;
}

- (void)addPanelWithStacks:(int)stackNum Bands:(int)bandNum
{
    NSLog(@"Adding panel!");
    
    NSMutableArray *mutablePanels = [_panelViews mutableCopy];
    PanelView *newPanel = [[PanelView alloc] initWithStacks:(int)stackNum Bands:(int)bandNum];
    [mutablePanels addObject:newPanel];
    _panelViews = mutablePanels;
    
    self.contentSize = newPanel.frame.size;
    [self addSubview:newPanel];
}

- (void)removePanel
{
    NSLog(@"Removing panel!");
    
    NSMutableArray *mutablePanels = [_panelViews mutableCopy];
    [[mutablePanels lastObject] removeFromSuperview];
    [mutablePanels removeLastObject];
    _panelViews = mutablePanels; 
}

- (void)switchToPanel:(int)panelNum
{
    if (panelNum == _currentPanel || _panelViews.count < 1)
        return;
    
    if (_currentPanel >= 0)
    {
        PanelView *oldPan = [_panelViews objectAtIndex:_currentPanel];
        if (!oldPan.isStatic)
            [oldPan hide];
    }
    
    PanelView *newPan = [_panelViews objectAtIndex:panelNum];
    [newPan unHide];
    _currentPanel = panelNum;
}

- (void)toggleOverlayPanel:(int)panelNum isVisible:(BOOL)isVisible
{
    PanelView *p = [_panelViews objectAtIndex:panelNum];
    if (!p.isStatic)
    {    
        if (!isVisible)
            [p unHide];
        [self bringSubviewToFront:p];
        [p toggleOverlay];
    }
    else
    {
        [p toggleOverlay];
        if (!isVisible)
            [p hide];
    }
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
