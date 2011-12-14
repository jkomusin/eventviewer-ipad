//
//  BandView.h
//  Event Viewer
//
//  Created by admin on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class QueryData;
@class ContentScrollView;
@protocol DataDelegate;

@protocol ZoomDelegate

@required
- (float)delegateRequestsZoomscale;
- (UIColor *)getColorForPanel:(int)panelNum;

@end

@interface BandDrawView : UIView <ZoomDelegate>

@property (nonatomic, strong) id<DataDelegate> dataDelegate;

- (id)initWithStackNum:(int)stackNum bandNum:(int)bandNum;
- (void)resizeForStackNum:(int)stackNum bandNum:(int)bandNum;
- (void)initLayersWithStackNum:(int)stackNum bandNum:(int)bandNum;

- (void)drawFramesWithData:(QueryData *)data inContext:(CGContextRef)context withMonthWidth:(float)width;
- (void)drawTimelinesForData:(QueryData *)data inContext:(CGContextRef)context withMonthWidth:(float)width;
- (void)drawEventsForPanel:(int)panel fromArray:(NSArray *)eArray inContext:(CGContextRef)context;
- (UIColor *)getColorForPanel:(int)panelNum;

@end


