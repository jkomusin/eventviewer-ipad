//
//  Meta.h
//  Event Viewer
//
//  Created by Joshua Komusin on 1/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Object representation of a Meta to encapsulate all associated information
 */
@interface Meta : NSObject

@property (nonatomic, strong) NSString *name;

- (id)initWithName:(NSString *)name;

@end
