//
//  PanelView.h
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PanelView : UIView
{
    NSArray *_stackViews;    // Static array of all StackViews managed by the panel
}

@property (nonatomic, assign) BOOL isStatic;    // YES if panel is currently overlaid, NO otherwise

- (id)initWithStacks:(int)stackNum Bands:(int)bandNum;
- (void)unHide;
- (void)hide;
- (void)toggleOverlay;

@end
