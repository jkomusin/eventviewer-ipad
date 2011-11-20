//
//  Event.h
//  Event Viewer
//
//  Created by admin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Event : NSObject

@property (nonatomic, strong) NSDate *start;
@property (nonatomic, strong) NSDate *end;
@property (nonatomic, assign) float x;
@property (nonatomic, assign) float width;

- (id) initWithStartTime:(NSDate *)start endTime:(NSDate *)end;

@end
