//
//  Meta.h
//  Event Viewer
//
//  Created by Joshua Komusin on 1/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Object representation of a constraint to encapsulate all associated information
 */
@interface Constraint : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, assign) int identifier;
@property (nonatomic, strong) NSString *type;
//@property (nonatomic, strong) NSDictionary *ids;

- (id)initWithName:(NSString *)name description:(NSString *)desc;

@end
