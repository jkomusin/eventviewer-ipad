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

@property (nonatomic, strong) NSString *name;           // Name of the constraint
@property (nonatomic, strong) NSString *description;    // Description of the constraint
@property (nonatomic, assign) int identifier;           // id number of the constraint for use in queries
@property (nonatomic, strong) NSString *type;           // Type of constraint, affixed with '_id' in results, possibilities include:
                                                        //  category, location, type, condition

@property (nonatomic, assign) BOOL leaf;                // Whether or not this constraint has subconstraints under it (if it is a leaf in the tree)


- (id)initWithName:(NSString *)name description:(NSString *)desc;

@end
