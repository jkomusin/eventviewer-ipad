//
//  QueryTree.m
//  Event Viewer
//
//  Created by Home on 1/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QueryTree.h"

@implementation QueryTree
{
    NSMutableArray *constraintArray;    // Array of all constraints in the current query tree
    int currentDepth;                   // Current depth the drill-down constraint tree is at
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[UITableViewCell alloc] init];
}

@end
