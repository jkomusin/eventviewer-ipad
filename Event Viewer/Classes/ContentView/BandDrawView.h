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

@protocol BandDrawViewDelegate

@optional
- (QueryData *)bandsRequestQueryData;
- (int)bandsRequestCurrentPanel;
- (NSArray *)bandsRequestOverlays;

@end


@interface BandDrawView : UIView
{
    id<BandDrawViewDelegate> delegate;
    NSArray *_colorArray;
}

@property (nonatomic, strong) id<BandDrawViewDelegate> delegate;

- (id)initWithStackNum:(int)stackNum bandNum:(int)bandNum;
- (void)resizeForStackNum:(int)stackNum bandNum:(int)bandNum;

- (void)drawFramesWithData:(QueryData *)data inContext:(CGContextRef)context;
- (void)drawEventsForPanel:(int)panel fromArray:(NSArray *)eArray inContext:(CGContextRef)context;
- (void)drawEventsForPanel:(int)panel fromData:(QueryData *)data inContext:(CGContextRef)context;
- (UIColor *)getColorForPanel:(int)panelNum;

@end
