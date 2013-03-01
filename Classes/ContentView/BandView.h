//
//  BandView.h
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class QueryData;
@class ContentScrollView;

@protocol BandViewDelegate

@optional
- (QueryData *) bandsRequestQueryData;
- (int) bandsRequestCurrentPanel;
- (NSArray *) bandsRequestOverlays;

@end


@interface BandView : UIView
{
    id<BandViewDelegate> delegate;
}

@property (nonatomic, strong) id<BandViewDelegate> delegate;

//- (void)setDelegate:(id<BandViewDelegate>)delegate;
- (id)initWithStackNum:(int)stackNum BandNum:(int)bandNum;

@end
