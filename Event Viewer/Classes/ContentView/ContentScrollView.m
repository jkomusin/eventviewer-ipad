//
//  ContentScrollView.m
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ContentScrollView.h"
#import "PanelView.h"
#import "BandZoomView.h"

@implementation ContentScrollView

@synthesize currentPanel = _currentPanel;
@synthesize bandZoomView = _bandZoomView;

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) 
    {
        NSArray *newArr = [[NSArray alloc] init];
        _panelViews = newArr;
        _currentPanel = -1;     // No panels exist yet
    }
    
    self.opaque = YES;
    return self;
}

/**
 *  Add a single panel to the current display
 *
 *  stackNum contains the number of stacks in the panel (>0)
 *  bandNum contains the number of bands in each stack in the panel (>0)
 */
- (void)addPanelWithStacks:(int)stackNum Bands:(int)bandNum
{
    NSLog(@"Adding panel!");
    
    BandZoomView *zoomView = [[BandZoomView alloc] initWithStackNum:stackNum BandNum:bandNum];
    if (self.contentSize.width != zoomView.frame.size.width || self.contentSize.height != zoomView.frame.size.height)
        self.contentSize = zoomView.frame.size;
    
/*    NSMutableArray *mutablePanels = [_panelViews mutableCopy];
    PanelView *newPanel = [[PanelView alloc] initWithStacks:(int)stackNum Bands:(int)bandNum];
    [mutablePanels addObject:newPanel];
    _panelViews = mutablePanels;
    
    if (self.contentSize.width != newPanel.frame.size.width || self.contentSize.height != newPanel.frame.size.height)
        self.contentSize = newPanel.frame.size;
    [self addSubview:newPanel];
*/
}

/**
 *  Remove and destroy the last panel in the array of panels from the display
 */
- (void)removePanel
{
    NSLog(@"Removing panel!");
    
/*    NSMutableArray *mutablePanels = [_panelViews mutableCopy];
    [[mutablePanels lastObject] removeFromSuperview];
    [mutablePanels removeLastObject];
    _panelViews = mutablePanels; 
*/
}

/**
 *  Display a specific panel in the array of panels, hiding the previously displayed panel.
 *  (assuming the previous panel is not statically visable)
 *
 *  panelNum is the array index of the panel to switch the view to (0-indexed)
 */
- (void)switchToPanel:(int)panelNum
{
/*    if (panelNum == _currentPanel || _panelViews.count < 1)
        return;
    
    if (_currentPanel >= 0)
    {
        PanelView *oldPan = [_panelViews objectAtIndex:_currentPanel];
        if (!oldPan.isStatic)
            [oldPan hide];
    }
    
    PanelView *newPan = [_panelViews objectAtIndex:panelNum];
    [newPan unHide];
*/
    _currentPanel = panelNum;

}

/**
 *  Toggles whether the specified panel is statically overlayed on the display.
 *
 *  panelNm is the index of the panel being toggled (0-indexed)
 *  isVisible is YES if the panel is the currently selected panel, and NO if it is not
 */
- (void)toggleOverlayPanel:(int)panelNum
{
    PanelView *p = [_panelViews objectAtIndex:panelNum];
    if (!p.isStatic)
    {    
        if (panelNum != _currentPanel)
            [p unHide];
        [self bringSubviewToFront:p];
        [p toggleOverlay];
    }
    else
    {
        [p toggleOverlay];
        if (panelNum != _currentPanel)
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
