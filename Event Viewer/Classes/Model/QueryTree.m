//
//  QueryTree.m
//  Event Viewer
//
//  Created by Home on 1/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QueryTree.h"
#import "SecondaryViewController.h"
#import "DatabaseHandler.h"
#import "DatabaseConnection.h"
#import "Constraint.h"
#import "JSONKit.h"


@interface QueryTree ()

- (void)initTestArray;
- (void)initTree;
- (void)initTitleArray;

- (void)drillUpOne;
- (void)drillUpToRoot;
- (void)drillDownLocationsThroughIndex:(NSInteger)index;
- (void)drillDownEventsThroughIndex:(NSInteger)index;
- (void)drillDownTimesThroughIndex:(NSInteger)index;

@end


@implementation QueryTree
{
    NSMutableArray *_constraintArray;   // 2-dimensional array of all constraints in the current query tree
                                        // In standard array notation (array[i][j][k][...]):
                                        //  array[x][] represents the level of the tree
                                        //  array[][x] represents the index of the row in the table (i.e. the child of the current node)
    NSMutableArray *_titleArray;        // Array of all titles in the current tree (the last title is the current title, the one before is its parent's)
    NSInteger _currentDepth;                  // Current depth the drill-down constraint tree is at
    enum QUERY_TREE_CATEGORY _currentBranch;   // Current root branch of the tree (events, locations, or times)
    
    DatabaseHandler *_dbHandler;        // Handler for the database, assumed to be logged in
    JSONDecoder *_jsonParser;           // Decoder of returned JSON packets
    NSMutableData *_response;           // The response of the current login query
    
    NSArray *_months;                   // Array to hold names of months
}

@synthesize treeDelegate = _treeDelegate;


/**
 *  Initializes the QueryTree with a new databse handler.
 *
 *  dbHandler is the new (assumed to be logged in) database handler
 */
- (id)initWithHandler:(DatabaseHandler *)dbHandler
{    
    if ((self = [super init]))
    {
        _dbHandler = dbHandler;
        _jsonParser = [[JSONDecoder alloc] init];
        
        _months = [NSArray arrayWithObjects:@"January", @"February", @"March", @"April", @"May", @"June", @"July", @"August", @"September", @"October", @"November", @"December", nil];
        
        [self initTree];
    }
    
    return self;
}

/**
 *  Initializes a dummy test array for old-style UI testing
 */
- (void)initTestArray
{
    NSMutableArray *test = [[NSMutableArray alloc] init];
    for (int i = 0; i < 10; i++)
    {
        NSString *t = @"";
        [test addObject:t];
    }
    [_constraintArray addObject:test];
}

/**
 *  Initialized the tree with the three top-level categories:
 *      Events
 *      Locations
 *      Times
 *
 *  Also resets tree to initial state.
 */
- (void)initTree
{
    NSMutableArray *superRoots = [[NSMutableArray alloc] init];
    
    Constraint *event = [[Constraint alloc] initWithName:@"Events" description:@"Event types and modifiers"];
    [superRoots addObject:event];
    Constraint *loc = [[Constraint alloc] initWithName:@"Locations" description:@"Spatial areas where events take place"];
    [superRoots addObject:loc];
    Constraint *time = [[Constraint alloc] initWithName:@"Times" description:@"Timeframe events occur in"];
    [superRoots addObject:time];
    
    NSMutableArray *constraints = [[NSMutableArray alloc] init];
    [constraints addObject:superRoots];
    _constraintArray = constraints;
    
    _currentDepth = 0;
    _currentBranch = -1;
    [self initTitleArray];
}

/**
 *  Initialized the title array to its starting state.
 */
- (void)initTitleArray
{
    NSMutableArray *titles = [[NSMutableArray alloc] init];
    [titles addObject:@"Categories"]; // Root title
    _titleArray = titles;
}

#pragma mark -
#pragma mark Properties

- (NSString *)getCurrentTitle
{
    return [_titleArray objectAtIndex:_currentDepth];
}

- (Constraint *)getConstraintAtIndex:(NSInteger)index
{
    return (Constraint *)[(NSArray *)[_constraintArray objectAtIndex:_currentDepth] objectAtIndex:index];
}


#pragma mark -
#pragma mark Table View data sourcing

/**
 *  Delegate method that returns the number of rows that are present in the requesting table.
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [(NSArray *)[_constraintArray objectAtIndex:_currentDepth] count];
}

/**
 *  Delegate method that returns a table cell for the specified index in the table.
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Constraint";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) 
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];

        UILongPressGestureRecognizer* dragGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:_treeDelegate action:@selector(handleDragging:)];
        [dragGesture setNumberOfTouchesRequired:1];
        [dragGesture setMinimumPressDuration:0.1f];
        [cell addGestureRecognizer:dragGesture];
    }
    
    Constraint *con = [[_constraintArray objectAtIndex:_currentDepth] objectAtIndex:indexPath.row];
    
    // Configure the cell.
    cell.textLabel.text = con.name;
    cell.detailTextLabel.text = con.description;

    // Store the index f the constraint in the cell's tag
    cell.tag = indexPath.row;
    
    // Add the indicator of a subcategory under this category if not a 'leaf node'
    if (!con.leaf)
    {
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }
    
    return cell;
}


#pragma mark -
#pragma mark Tree navigation


/**
 *  Entry point of tree drill-down navigation.
 *  Advances the tree to the next level, through the given index.
 *  Also advances all accociaed values in tree (current title, depth, branch)
 */
- (void)drillDownToIndex:(NSInteger)index
{
    Constraint *c = [[_constraintArray objectAtIndex:_currentDepth] objectAtIndex:index];
    [_titleArray addObject:c.name];
    
    // Add new array for the new level
    NSMutableArray *newHeight = [[NSMutableArray alloc] init];
    [_constraintArray addObject:newHeight];
    
    _currentDepth++;
    
    // Switch to the specific area
    if (_currentBranch == -1)   // At the root
    {
        if ([c.name isEqualToString:@"Events"])
        {
            _currentBranch = QueryTreeCategoryEvents;
        }
        else if ([c.name isEqualToString:@"Locations"])
        {
            _currentBranch = QueryTreeCategoryLocations;
        }
        else if ([c.name isEqualToString:@"Times"])
        {
            _currentBranch = QueryTreeCategoryTimes;
        }
        else
        {
            NSLog(@"ERROR: Branch '%@' requested from root", c.name);
        }
    }
    
    // Send off to specific handler functions
    if (_currentBranch == QueryTreeCategoryEvents)
    {
        [self drillDownEventsThroughIndex:index];
    }
    else if (_currentBranch == QueryTreeCategoryLocations)
    {
        [self drillDownLocationsThroughIndex:index];
    }
    else if (_currentBranch == QueryTreeCategoryTimes)
    {
        [self drillDownTimesThroughIndex:index];
    }
}

/**
 *  "Drill up" to the previous level.
 */
- (void)drillUpOne
{
    [_constraintArray removeObjectAtIndex:_currentDepth];
    [_titleArray removeObjectAtIndex:_currentDepth];
    
    _currentDepth--;
    if (_currentDepth == 0)
    {
        _currentBranch = -1;
    }
}

/**
 *  "Drill up" all the way to the root of the tree.
 */
- (void)drillUpToRoot
{
    [self initTree];
}

/**
 *  Drill down one level in the tree within the 'Events' branch
 */
- (void)drillDownEventsThroughIndex:(NSInteger)index
{
    if (_currentDepth == 1) // Find relations
    {
        NSString *params = [NSString stringWithFormat:@"method=relation"];
        [_dbHandler queryWithParameters:params fromDelegate:self ofType:DBConnectionTypeRelation];
    }
    else if (_currentDepth == 2) // Find metas for selected index
    {
        Constraint *c = [[_constraintArray objectAtIndex:_currentDepth-1] objectAtIndex:index];
        NSString *params = [NSString stringWithFormat:@"method=meta&relation=%@", c.name];
        [_dbHandler queryWithParameters:params fromDelegate:self ofType:DBConnectionTypeMeta];
    }
    else
    {
        NSLog(@"ERROR: Undefined depth in event branch: %d", _currentDepth);
    }
}

/**
 *  Drill down one level in the tree within the 'Locations' branch
 */
- (void)drillDownLocationsThroughIndex:(NSInteger)index
{
    if (_currentDepth == 1) // Find root categories
    {
        NSString *params = [NSString stringWithFormat:@"method=getRootCategories"];
        [_dbHandler queryWithParameters:params fromDelegate:self ofType:DBConnectionTypeLocation];
    }
    else if (_currentDepth > 1) // Find subcategories
    {
        Constraint *c = [[_constraintArray objectAtIndex:_currentDepth-1] objectAtIndex:index];
        NSString *params = [NSString stringWithFormat:@"method=getSubCategories&category_id=%d", c.identifier];
        [_dbHandler queryWithParameters:params fromDelegate:self ofType:DBConnectionTypeLocation];
    }
    else
    {
        NSLog(@"ERROR: Undefined depth in location branch: %d", _currentDepth);
    }
}

/**
 *  Drill down one level in the tree within the 'Times' branch
 */
- (void)drillDownTimesThroughIndex:(NSInteger)index
{
    NSMutableArray *currentConstraints = [_constraintArray objectAtIndex:_currentDepth];
    
    if (_currentDepth == 1) // Create root categories
    {
        Constraint *years = [[Constraint alloc] initWithName:@"Years" description:@""];
        years.leaf = NO;
        [currentConstraints addObject:years];
        Constraint *months = [[Constraint alloc] initWithName:@"Months" description:@""];
        months.leaf = NO;
        [currentConstraints addObject:months];
        Constraint *days = [[Constraint alloc] initWithName:@"Days" description:@""];
        days.leaf = NO;
        [currentConstraints addObject:days];
        
        [_treeDelegate treeDidUpdateData];
    }
    else if (_currentDepth == 2)
    {
        Constraint *scaleConstraint = [[_constraintArray objectAtIndex:_currentDepth-1] objectAtIndex:index];
        NSString *scale = scaleConstraint.name;
        if ([scale isEqualToString:@"Years"])
        {
            NSString *params = @"method=timerange";
            [_dbHandler queryWithParameters:params fromDelegate:self ofType:DBConnectionTypeTime];
        }
        else if ([scale isEqualToString:@"Months"])
        {
            for (int m = 0; m < [_months count]; m++) //NSString *m in _months)
            {
                NSString *month = [_months objectAtIndex:m];
                Constraint *c = [[Constraint alloc] initWithName:month description:@""];
                c.leaf = YES;
                c.type = @"month";
                c.identifier = m+1;
                [currentConstraints addObject:c];
            }
            
            [_treeDelegate treeDidUpdateData];
        }
        else if ([scale isEqualToString:@"Days"])
        {
            for (int i = 1; i <= 31; i++)
            {
                Constraint *c = [[Constraint alloc] initWithName:[NSString stringWithFormat:@"%d", i] description:@""];
                c.leaf = YES;
                c.type = @"day";
                c.identifier = i;
                [currentConstraints addObject:c];
            }
            
            [_treeDelegate treeDidUpdateData];
        }
        else
        {
            NSLog(@"ERROR: Undefined time scale: %@", scale);
        }
    }
    else
    {
        NSLog(@"ERROR: Undefined depth in time branch: %d", _currentDepth);
    }
}


#pragma mark -
#pragma mark Connection delegation

/**
 *  Called when the connection has begun to be responded to by the URL.
 *  May be called multiple times in the event of a redirect, etc.
 */
- (void)connection:(DatabaseConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if (connection.type != DBConnectionTypeLocation && connection.type != DBConnectionTypeRelation && connection.type != DBConnectionTypeMeta && connection.type != DBConnectionTypeTime)
    {
        NSString *type;
        if (connection.type == DBConnectionTypeLogin)       type = @"LOGIN";
        if (connection.type == DBConnectionTypeEvent)       type = @"EVENT";
        if (connection.type == DBConnectionTypeEventCount) type = @"EVENT_COUNT";
        NSLog(@"ERROR: Connection of type '%@' handled by QueryTree. Expected 'LOCATION', 'RELATION', or 'META'", type);
    }
    _response = [[NSMutableData alloc] init];
}

/**
 *  Called periodically when the connection recieves data.
 */
- (void)connection:(DatabaseConnection *)connection didReceiveData:(NSData *)data
{
    [_response appendData:data];
}

/**
 *  Called when the connection has completed its request.
 */
- (void)connectionDidFinishLoading:(DatabaseConnection *)connection
{
  	NSArray *jsonArr = [_jsonParser objectWithData:_response];
    
    NSLog(@"Retrieved JSON array:");
    NSLog(@"%@", jsonArr);
    
    NSMutableArray *currentConstraints = [_constraintArray objectAtIndex:_currentDepth];
    
    if (connection.type == DBConnectionTypeRelation)
    {
        NSDictionary *dict = (NSDictionary *)jsonArr;
        for (id key in dict)
        {
            NSString *keyString = (NSString *)key;
            if ([keyString isEqualToString:@"location"] || [keyString isEqualToString:@"height"]) 
            {
                continue;
            }
            else
            {
                Constraint *c = [[Constraint alloc] initWithName:keyString description:(NSString *)[dict objectForKey:key]];
                [currentConstraints addObject:c];
            }
        }
    }
    else if (connection.type == DBConnectionTypeMeta)
    {
        for (NSDictionary *dict in jsonArr)
        {
            Constraint *c = [[Constraint alloc] initWithName:(NSString *)[dict objectForKey:@"name"] 
                                                 description:(NSString *)[dict objectForKey:@"description"]];
            
            if (c.name == (NSString *)[NSNull null] || [c.name isEqualToString:@""])
            {
                c.name = @"<null>";
            }
            if (c.description == (NSString *)[NSNull null] || [c.name isEqualToString:@""])
            {
                c.description = @"<null>";
            }
            
            c.type = [_titleArray objectAtIndex:_currentDepth];
            NSString *metaKey = [NSString stringWithFormat:@"%@_id", c.type];
            c.identifier = [(NSString *)[dict objectForKey:metaKey] intValue];
            c.leaf = YES;
            
            [currentConstraints addObject:c];
        }
    }
    else if (connection.type == DBConnectionTypeLocation)
    {
        for (NSDictionary *dict in jsonArr)
        {
            Constraint *c = [[Constraint alloc] initWithName:(NSString *)[dict objectForKey:@"name"]
                                                 description:@""];
            
            if (c.name == (NSString *)[NSNull null] || [c.name isEqualToString:@""])
            {
                c.name = @"<null>";
            }
            
            int location = [(NSString *)[dict objectForKey:@"location_id"] intValue];
            if (location == 1)  // Not a 'leaf' location (has subcategories)
            {
                c.type = @"category";
                c.identifier = [(NSString *)[dict objectForKey:@"category_id"] intValue];
                if (c.identifier == 0) // There was no 'category_id', instead use 'child_id'
                {
                    c.identifier = [(NSString *)[dict objectForKey:@"child_id"] intValue];
                }
                NSLog(@"Constraint with id: %d", c.identifier);
                c.leaf = NO;
            }
            else // 'Leaf' location (no subcategories)
            {
                c.type = @"location";
                c.identifier = location;
                c.leaf = YES;
            }
            
            [currentConstraints addObject:c];
        }
    }
    else if (connection.type == DBConnectionTypeTime)
    {
        NSString *start = (NSString *)[(NSDictionary *)[jsonArr objectAtIndex:0] objectForKey:@"start"];
        NSString *end = (NSString *)[(NSDictionary *)[jsonArr objectAtIndex:1] objectForKey:@"end"];
        
        int startNum = [(NSString *)[start substringWithRange:NSMakeRange(0, 4)] intValue];
        int endNum = [(NSString *)[end substringWithRange:NSMakeRange(0, 4)] intValue];
        
        for (int i = endNum; i >= startNum; i--)
        {
            Constraint *c = [[Constraint alloc] initWithName:[NSString stringWithFormat:@"%d", i] description:@""];
            c.leaf = YES;
            c.type = @"year";
            c.identifier = i;
            [currentConstraints addObject:c];
        }
    }
    
    [_treeDelegate treeDidUpdateData];
}

/**
 *  Called when the connection fails.
 */
- (void)connection:(DatabaseConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Contraint connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}


@end
