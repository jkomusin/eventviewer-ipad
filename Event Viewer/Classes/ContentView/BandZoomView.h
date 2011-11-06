//
//  BandZoomView.h
//  Event Viewer
//
//  Created by admin on 11/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BandView;

@interface BandZoomView : UIScrollView

@property (nonatomic, strong) BandView *bandView;

- (id)initWithStackNum:(int)stackNum BandNum:(int)bandNum;

@end
