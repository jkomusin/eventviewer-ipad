//
//  ContentScrollView.m
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ContentScrollView.h"
#import "BandZoomView.h"
#import "BandDrawView.h"

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
        BandZoomView *zoomView = [[BandZoomView alloc] initWithStackNum:0 bandNum:0];
        [self addSubview:zoomView];
        _bandZoomView = zoomView;
        self.opaque = YES;
    }
    
    return self;
}

- (void)resizeForStackNum:(int)stackNum bandNum:(int)bandNum
{
    [_bandZoomView resizeForStackNum:stackNum bandNum:bandNum];
    if (self.contentSize.height != _bandZoomView.frame.size.height || self.contentSize.width != _bandZoomView.frame.size.width)
    {
        NSLog(@"Resizing CSV");
        self.contentSize = _bandZoomView.frame.size;
    }
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
    //reset current panel, especially if removing all panels/last panel
}

/**
 *  Display a specific panel in the array of panels, hiding the previously displayed panel.
 *  (assuming the previous panel is not statically visable)
 *
 *  panelNum is the array index of the panel to switch the view to (0-indexed)
 */
- (void)switchToPanel:(int)panelNum
{
    if (panelNum == _currentPanel)
        return;

    _currentPanel = panelNum;
    [_bandZoomView.bandDrawView setNeedsDisplay];
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
