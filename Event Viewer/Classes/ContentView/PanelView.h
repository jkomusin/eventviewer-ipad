//
//  PanelView.h
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContentScrollView.h"
#import "StackView.h"

@interface PanelView : UIView
{
    NSArray *_stackViews;    //all StackViews managed by the panel
}

- (id)initWithStacks:(int)stackNum Bands:(int)bandNum;
- (void)unHide;
- (void)hide;

@end
