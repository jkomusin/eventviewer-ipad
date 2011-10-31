//
//  StackView.h
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContentScrollView.h"
#import "BandView.h"

@interface StackView : UIView
{
    NSArray *_bandViews;    // Static array of all BandViews managed by the stack
    int _bandNum;           // Number of bands managed by the stack
    UIColor *_eventColor;   // Color of events
    BOOL _isStatic;         // YES if this stack is overlayed, NO otherwise
}

- (id)initWithStackNum:(int)stackNum OutOf:(int)stacks WithBands:(int)bandNum OfColor:(UIColor *)color;
- (void)unHide;
- (void)hide;
- (void)toggleOverlay;

@end
