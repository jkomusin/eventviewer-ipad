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

- (id)initWithBandNum:(int)bandNum;
- (void)unHide;
- (void)hide;

@end
