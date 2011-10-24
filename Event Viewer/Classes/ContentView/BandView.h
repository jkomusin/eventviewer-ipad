//
//  BandView.h
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContentScrollView.h"

@interface BandView : UIView
{
    BOOL _isStatic;     //whether or not band is overlayed
    UIColor *_color;    //color of events
}

- (id)initWithBandNum:(int)bandNum OfColor:(UIColor *)color;
- (void)unHide;
- (void)hide;
- (void)toggleOverlay;

@end
