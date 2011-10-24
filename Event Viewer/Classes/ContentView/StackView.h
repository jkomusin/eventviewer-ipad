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
    NSArray *_bandViews;    //all BandViews managed by the stack
    int _bandNum;           //number of bands managed by the stack
    UIColor *_eventColor;   //color of events
    BOOL _isStatic;         //whether or not this stack is overlayed
}

- (id)initWithStackNum:(int)stackNum OutOf:(int)stacks WithBands:(int)bandNum OfColor:(UIColor *)color;
- (void)unHide;
- (void)hide;
- (void)toggleOverlay;

@end
