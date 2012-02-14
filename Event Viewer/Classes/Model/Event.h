//
//  Event.h
//  Event Viewer
//
//  Created by admin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Object representation of an Event to encapsulate all associated information
 */
@interface Event : NSObject

@property (nonatomic, strong) NSDate *start;    // Date timestamp when the event began
@property (nonatomic, strong) NSDate *end;      // Date timestamp when the event ended
@property (nonatomic, assign) float x;          // Raw float of the beginning point of the event on a Band, used to speed up later drawing and re-drawing at the cost of a longer initialization time
@property (nonatomic, assign) float width;      // Raw float representing the width or duration of the event on a Band, for the same reason as above
@property (nonatomic, assign) NSInteger year;
@property (nonatomic, assign) NSInteger month;
@property (nonatomic, assign) NSInteger day;
@property (nonatomic, assign) float magnitude;

- (id)initWithStartTime:(NSDate *)start endTime:(NSDate *)end;

@end
