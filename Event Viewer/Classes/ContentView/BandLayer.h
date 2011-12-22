//
//  BandLayer.h
//  Event Viewer
//
//  Created by monet on 12/13/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@protocol DataDelegate;
@protocol DrawDelegate;


/**
 *  Layers that contain all events and are resized along with the BandDrawView.
 *  Are all sublayers of the BandDrawView.
 */
@interface BandLayer : CALayer

@property (nonatomic, strong) id<DataDelegate> dataDelegate;
@property (nonatomic, strong) id<DrawDelegate> zoomDelegate;

/**
 *  0-based indices specifying the location of the band in the data model
 */
@property (nonatomic, assign) int stackNumber;
@property (nonatomic, assign) int bandNumber;


- (void)drawEventsForPanel:(int)panel fromArray:(NSArray *)eventArray inContext:(CGContextRef)context;

@end
