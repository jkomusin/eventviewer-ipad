//
//  QueryTree.h
//  Event Viewer
//
//  Created by Home on 1/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Data model for the tree of queriable constraints pulled from the database
 *  that can form a query.
 *  This object supplies the backing data for the SecondaryViewController's table.
 *  Represents a tree structure due to the drill-down nature of the table.
 */
@interface QueryTree : NSObject <UITableViewDataSource>

@end
