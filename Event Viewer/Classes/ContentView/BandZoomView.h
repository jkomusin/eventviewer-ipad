//
//  BandZoomView.h
//  Event Viewer
//
//  Created by admin on 11/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BandDrawView;

@interface BandZoomView : UIScrollView

@property (nonatomic, strong) BandDrawView *bandDrawView;

- (id)initWithStackNum:(int)stackNum bandNum:(int)bandNum;
- (void)resizeForStackNum:(int)stackNum bandNum:(int)bandNum;

@end
