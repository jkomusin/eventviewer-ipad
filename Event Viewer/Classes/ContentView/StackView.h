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
}

- (id)initWithStackNum:(int)stackNum OutOf:(int)stacks WithBands:(int)bandNum;
- (void)unHide;
- (void)hide;

@end
