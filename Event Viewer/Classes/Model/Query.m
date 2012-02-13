
#import "PrimaryViewController.h"
#import "ContentScrollView.h"
#import "DatabaseHandler.h"
#import "DatabaseConnection.h"
#import "JSONKit.h"
#import "Query.h"
#import "Event.h"
#import "Constraint.h"

#define MY_MALLOC(x)    my_malloc( #x, x )
#define MY_FREE(x)      my_free(x)

@implementation Query
{
    DatabaseHandler *_dbHandler;        // Handler for the database, assumed to be logged in
    JSONDecoder *_jsonParser;           // Decoder of returned JSON packets
    NSMutableArray *_responseArray;     // 3-dimensional array of response data for current event queries with the format:
                                        //  [x][][] - The panel for the response's events
                                        //  [][x][] - The stack for the response's events
                                        //  [][][x] - The band for the response's events (this is the MutableData object)
}

@synthesize selectedMetas = _selectedMetas;
@synthesize eventArray = _eventArray;
//@synthesize eventFloats = _eventFloats;
@synthesize timeScale = _timeScale;

OBJC_EXPORT float BAND_HEIGHT;              //
OBJC_EXPORT float BAND_WIDTH;               //  Globals set in ContentViewControlled specifying UI layout parameters
OBJC_EXPORT float BAND_SPACING;             //
OBJC_EXPORT float TIMELINE_HEIGHT;            //

/**
 *  Full initialization of data model object
 */
- (id) init
{
    if ((self = [super init]))
    {        
        // Initialize _selectedMetas with empty arrays for specified keys
        NSMutableDictionary *mutableMetas = [[NSMutableDictionary alloc] init];
        NSMutableArray *panelArray = [NSMutableArray arrayWithObjects:nil];
        [mutableMetas setObject:panelArray forKey:@"Panels"];
        NSMutableArray *stackArray = [NSMutableArray arrayWithObjects:nil];
        [mutableMetas setObject:stackArray forKey:@"Stacks"];
        NSMutableArray *bandArray = [NSMutableArray arrayWithObjects:nil];
        [mutableMetas setObject:bandArray forKey:@"Bands"];
        _selectedMetas = mutableMetas;
        
        // Initialize _eventArray with empty arrays
        NSMutableArray *emptyEvents = [[NSMutableArray alloc] init];
        NSMutableArray *emptyStacks = [[NSMutableArray alloc] init];
        NSMutableArray *emptyBands = [[NSMutableArray alloc] init];
        NSMutableArray *emptyBandEvents = [[NSMutableArray alloc] init];
        [emptyEvents addObject:emptyStacks];
        [emptyStacks addObject:emptyBands];
        [emptyBands addObject:emptyBandEvents];
        _eventArray = emptyEvents;
        
        // Initialize _responseArray with empty arrays
        NSMutableArray *emptyResponses = [[NSMutableArray alloc] init];
        _responseArray = emptyResponses;
        
        // Initialize _jsonParser
        _jsonParser = [[JSONDecoder alloc] init];
        
        //_eventFloats = create4D(2, 2, 2, 2);
		
		_timeScale = QueryTimescaleInfinite;
    }
    
    return self;
}

/**
 *  Initializes data model with new database handler
 *
 *  dbHandler is the new database handler object, assumed to be logged in
 */
- (id) initWithHandler:(DatabaseHandler *)dbHandler
{
    if ((self = [self init]))
    {
        _dbHandler = dbHandler;
    }
    
    return self;
}

/**
 *  Initializes the data model with a specified number of panels for stress-testing purposes.
 *  
 *  panels is the number of panels to create
 */
- (id) initTestWithPanels:(NSInteger)panels
{    
    if ((self = [self init]))
    {
        NSMutableArray *mutablePanels = [[NSMutableArray alloc] init];
        for (char p = 'A'; p < ('A' + panels); p++)
        {
            NSString *new = [[NSString alloc] initWithFormat:@"Panel %c", p];
            Constraint *newM = [[Constraint alloc] initWithName:new description:@""];
            [mutablePanels addObject:newM];
        }
        
        NSMutableArray *mutableStacks = [[NSMutableArray alloc] init];
        for (char s = 'A'; s < ('A' + TEST_STACKS); s++)
        {
            NSString *new = [[NSString alloc] initWithFormat:@"Stack %c", s];
            Constraint *newM = [[Constraint alloc] initWithName:new description:@""];
            [mutableStacks addObject:newM];
        }
        
        NSMutableArray *mutableBands = [[NSMutableArray alloc] init];
        for (char b = 'A'; b < ('A' + TEST_BANDS); b++)
        {
            NSString *new = [[NSString alloc] initWithFormat:@"Band %c", b];
            Constraint *newM = [[Constraint alloc] initWithName:new description:@""];
            [mutableBands addObject:newM];
        }
        NSMutableDictionary *mutableMetas = [[NSMutableDictionary alloc] init];
        [mutableMetas setObject:(NSArray *)mutablePanels forKey:@"Panels"];
        [mutableMetas setObject:(NSArray *)mutableStacks forKey:@"Stacks"];
        [mutableMetas setObject:(NSArray *)mutableBands forKey:@"Bands"];
        
        _selectedMetas = (NSDictionary *)mutableMetas;
        
        // Handle tests for 0 panels or stacks
        if (panels == 0) panels = 1;
        int stackNumber = TEST_STACKS;
        if (stackNumber == 0) stackNumber = 1;
        
        //create Events with date arithmetic
        NSDateComponents *components = [[NSDateComponents alloc] init];
        [components setDay:5];  //add 5 days
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSMutableArray *newEvents = [[NSMutableArray alloc] init];
        for (int p = 0; p < panels; p++)
        {
            NSMutableArray *newPanels = [[NSMutableArray alloc] init];
            for (int s = 0; s < stackNumber; s++)
            {
                NSMutableArray *newStacks = [[NSMutableArray alloc] init];
                for (int b = 0; b < TEST_BANDS; b++)
                {
                    NSMutableArray *newBands = [[NSMutableArray alloc] init];
                    for (int i = 0; i < 3; i++)
                    {
                        int day = abs(arc4random() % 27) +1;
                        int month = abs(arc4random() % 11) +1;
                        NSString *startS = [NSString stringWithFormat:@"2000 %02d %02d", month, day];
                        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                        [dateFormatter setDateFormat:@"yyyy MM dd"];
                        NSDate *startDate = [dateFormatter dateFromString:startS];
                        NSDate *endDate = [cal dateByAddingComponents:components toDate:startDate options:0];
                        
                        //(Legacy) Previously used conversion from dates to numeric representations. Proved to be incredibly slow.
                        //                NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:e.start];
                        //                NSInteger day = [components day];    
                        //                NSInteger month = [components month];
                        
                        Event *newE = [[Event alloc] initWithStartTime:startDate endTime:endDate];
                        //calcualte normalized posisitions
                        float x = (month - 1.0f)*(BAND_WIDTH_P / 12.0f) + (day - 1.0f)*(BAND_WIDTH_P / 356.0f);
						//round to nearest 0.5 for sharpness of drawing
						int xInt = (int)x;
						x = xInt + 0.5f;
                        float width = 25.0f;
                        //fix erroneous widths
                        if (x + width > BAND_WIDTH_P) width = width - ((x + width) - BAND_WIDTH_P);
                        newE.x = x;
                        newE.width = width;
                        
                        [newBands addObject:newE];
                    }
                    [newStacks addObject:newBands];
                }
                [newPanels addObject:newStacks];
            }
            [newEvents addObject:newPanels];
        }
        _eventArray = newEvents;
    
		_timeScale = QueryTimescaleYear;
    
        //(Experimental) Pure C float stlye storage for the pure-C 4-dimensional array
        //create array of floats for each band's events
/*        float ****floats = create4D(panels, TEST_STACKS, TEST_BANDS, 6);
        for (int i = 0; i < panels; i++)
        {
            for (int j = 0; j < TEST_STACKS; j++)
            {
                for (int k = 0; k < TEST_BANDS; k++)
                {
                    NSArray *bandEArray = [[[_eventArray objectAtIndex:i] objectAtIndex:j] objectAtIndex:k];
                    for (int l = 0; l < [bandEArray count]; l++)
                    {
                        Event *e = [bandEArray objectAtIndex:l];
                        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:e.start];
                        NSInteger day = [components day];    
                        NSInteger month = [components month];
                        float x = (month - 1.0f)*(BAND_WIDTH_P / 12.0f) + (day - 1.0f)*(BAND_WIDTH_P / 356.0f);
                        float width = 25.0f;
                        //fix erroneous widths
                        if (x + width > BAND_WIDTH_P) width = width - ((x + width) - BAND_WIDTH_P);
                        
                        //add to float array
                        floats[i][j][k][l*2] = x;
                        floats[i][j][k][(l*2)+1] = width;
                    }            
                }
            }
        }
        NSLog(@"Test float[0][0][0][0]: %f", floats[0][0][0][0]);
*/
    }

    return self;
}

/**
 *  Count accessors
 *
 *  NOTE: Should not be used as the basis for indices into the event array, as there are initially one array per category in the event array.
 */
- (NSInteger)panelNum
{
    return [(NSArray *)[_selectedMetas objectForKey:@"Panels"] count];
}
- (NSInteger)stackNum
{
    return [(NSArray *)[_selectedMetas objectForKey:@"Stacks"] count];
}
- (NSInteger)bandNum
{
    return [(NSArray *)[_selectedMetas objectForKey:@"Bands"] count];
}


#pragma mark -
#pragma mark Constraint management

/**
 *  Add a Constraint to a specified UI element category.
 *  Also update all other data structures related to constraints.
 *
 *  constraint is the Constraint object being appended to the arrays of Constraints.
 *  category references whether the Constraint is being added to the Bands, Stacks, or Panels categories.
 */
- (void)addConstraint:(Constraint *)constraint toArray:(enum UI_OBJECT)category
{
    // Get panel numbers from the number of arrays rather than the selected constraint numbers
    int panelNum = [_eventArray count];
    int stackNum = [[_eventArray objectAtIndex:0] count];
    int bandNum = [[[_eventArray objectAtIndex:0] objectAtIndex:0] count];
    
    // Add constraint to appropriate array, and allocate event arrays, skipping adding event arrays 
    //  if we are adding the first of a type of constraint, as the event array has been initialized
    //  with one array per category.
    if (category == UIObjectBand)
    {
        // Add constraint to selected constraint array
        NSMutableArray *arr = [_selectedMetas objectForKey:@"Bands"];
        [arr addObject:constraint];
        
        // Allocate room for event arrays associated with new constraint if this is not the first
        if (self.bandNum != 0)
        {
            for (int i = 0; i < panelNum; i++)
            {
                for (int j = 0; j < stackNum; j++)
                {
                    NSMutableArray *newBand = [[NSMutableArray alloc] init];
                    [[[_eventArray objectAtIndex:i] objectAtIndex:j] addObject:newBand];
                }
            }
        }
    }
    else if (category == UIObjectStack)
    {
        // Add constraint to selected constraint array
        NSMutableArray *arr = [_selectedMetas objectForKey:@"Stacks"];
        [arr addObject:constraint];
        
        // Allocate room for event arrays associated with new constraint if this is not the first
        if (self.stackNum != 0)
        {
            for (int i = 0; i < panelNum; i++)
            {
                NSMutableArray *newStack = [[NSMutableArray alloc] init];
                for (int k = 0; k < bandNum; k++)
                {
                    NSMutableArray *newBand = [[NSMutableArray alloc] init];
                    [newStack addObject:newBand];
                }
                
                [[_eventArray objectAtIndex:i] addObject:newStack];
            }
        }
    }
    else if (category == UIObjectPanel)
    {
        // Add constraint to selected constraint array
        NSMutableArray *arr = [_selectedMetas objectForKey:@"Panels"];
        [arr addObject:constraint];
        
        // Allocate room for event arrays associated with new constraint if this is not the first
        if (self.panelNum != 0)
        {
            NSMutableArray *newPanel = [[NSMutableArray alloc] init];
            for (int j = 0; j < stackNum; j++)
            {
                NSMutableArray *newStack = [[NSMutableArray alloc] init];
                for (int k = 0; k < bandNum; k++)
                {
                    NSMutableArray *newBand = [[NSMutableArray alloc] init];
                    [newStack addObject:newBand];
                }
                
                [newPanel addObject:newStack];
            }
            
            [_eventArray addObject:newPanel];
        }
    }
    else
    {
        NSLog(@"ERROR: Invalid UI category index: %d", category);
    }
    
    // Set new timescale if necessary
    if ([constraint.type isEqualToString:@"year"] && _timeScale > QueryTimescaleYear)
        _timeScale = QueryTimescaleYear;
    if ([constraint.type isEqualToString:@"month"] && _timeScale > QueryTimescaleMonth)
        _timeScale = QueryTimescaleMonth;
    if ([constraint.type isEqualToString:@"day"] && _timeScale > QueryTimescaleDay)
        _timeScale = QueryTimescaleDay;
    
    NSLog(@"\nNumber of bands: %d \nNumber of stacks: %d \nNumber of panels: %d", 
          [[[_eventArray objectAtIndex:0] objectAtIndex:0] count],
          [[_eventArray objectAtIndex:0] count],
          [_eventArray count]);
}


#pragma mark -
#pragma mark Querying for data

- (void)queryForEventsWithCurrentConstraints
{
    NSArray *panelConstraints = [_selectedMetas objectForKey:@"Panels"];
    NSArray *stackConstraints = [_selectedMetas objectForKey:@"Stacks"];
    NSArray *bandConstraints = [_selectedMetas objectForKey:@"Bands"];
    
    NSMutableArray *newResponses = [[NSMutableArray alloc] init];
    // Initialize the query response array to the size of the query
    for (int i = 0; i < [panelConstraints count]; i++)
    {
        NSMutableArray *panels = [[NSMutableArray alloc] init];
        for (int j = 0; j < [stackConstraints count]; j++)
        {
            NSMutableArray *stacks = [[NSMutableArray alloc] init];
            [panels addObject:stacks];
        }
        [newResponses addObject:panels];
    }
    _responseArray = newResponses;
    
    for (int p = 0; p < [panelConstraints count]; p++) //Constraint *panel in panelConstraints)
    {
        Constraint *panel = [panelConstraints objectAtIndex:p];
        for (int s = 0; s < [stackConstraints count]; s++) //Constraint *stack in stackConstraints)
        {
            Constraint *stack = [stackConstraints objectAtIndex:s];
            for (int b = 0; b < [bandConstraints count]; b++) //Constraint *band in bandConstraints)
            {
                Constraint *band = [bandConstraints objectAtIndex:b];
                
                NSString *panelQuery = [NSString stringWithFormat:@"%@=%d", panel.type, panel.identifier];
                NSString *stackQuery = [NSString stringWithFormat:@"%@=%d", stack.type, stack.identifier];
                NSString *bandQuery = [NSString stringWithFormat:@"%@=%d", band.type, band.identifier];
                NSString *params = [NSString stringWithFormat:@"method=data&%@&%@&%@", panelQuery, stackQuery, bandQuery];
                
                [_dbHandler queryWithParameters:params fromDelegate:self ofType:DBConnectionTypeEvent withPanelIndex:p stackIndex:s bandIndex:b];
            }
        }
    }
}


#pragma mark -
#pragma mark Query builder data source
/**
 *  We assume that the only table views accessing these methods are the tables within the query builder.
 *  We also assume that each table has its 'tag' property set to an identifying number to specify if it is either the band, stack, or panel table.
 */

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *dataArr;
    if (tableView.tag == UIObjectBand)
    {
        dataArr = [_selectedMetas objectForKey:@"Bands"];
    }
    else if (tableView.tag == UIObjectStack)
    {
        dataArr = [_selectedMetas objectForKey:@"Stacks"];
    }
    else if (tableView.tag == UIObjectPanel)
    {
        dataArr = [_selectedMetas objectForKey:@"Panels"];
    }
    
    return [dataArr count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"BuilderConstraint";
    
    NSArray *dataArr;
    if (tableView.tag == UIObjectBand)
    {
        dataArr = [_selectedMetas objectForKey:@"Bands"];
    }
    else if (tableView.tag == UIObjectStack)
    {
        dataArr = [_selectedMetas objectForKey:@"Stacks"];
    }
    else if (tableView.tag == UIObjectPanel)
    {
        dataArr = [_selectedMetas objectForKey:@"Panels"];
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) 
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    Constraint *con = [dataArr objectAtIndex:indexPath.row];
    
    // Configure the cell.
    cell.textLabel.text = con.name;
    cell.detailTextLabel.text = con.description;
    
    return cell;
}


#pragma mark -
#pragma mark Connection delegation

/**
 *  Called when the connection has begun to be responded to by the URL.
 *  May be called multiple times in the event of a redirect, etc.
 */
- (void)connection:(DatabaseConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if (connection.type != DBConnectionTypeEvent && connection.type != DBConnectionTypeEventCount)
    {
        NSString *type;
        if (connection.type == DBConnectionTypeLogin)       type = @"LOGIN";
        if (connection.type == DBConnectionTypeLocation)    type = @"LOCATION";
        if (connection.type == DBConnectionTypeRelation)    type = @"RELATION";
        if (connection.type == DBConnectionTypeMeta)        type = @"META";
        if (connection.type == DBConnectionTypeTime)        type = @"TIME";
        NSLog(@"ERROR: Connection of type '%@' handled by Query. Expected 'EVENT', or 'EVENT_COUNT'", type);
    }
    
    NSMutableData *responseData = [[NSMutableData alloc] init];
    NSMutableArray *stackArray = [[_responseArray objectAtIndex:connection.panelIndex] objectAtIndex:connection.stackIndex];
    
    NSLog(@"Stack array count: %d", [stackArray count]);
    
    if ([stackArray count] <= connection.bandIndex)
    {
        for (int i = [stackArray count]; i <= connection.bandIndex; i++)
        {
            NSMutableData *newData = [[NSMutableData alloc] init];  // placeholder
            [stackArray addObject:newData];
        }
    }
    
    NSLog(@"Stack array count: %d", [stackArray count]);
    
    [stackArray replaceObjectAtIndex:connection.bandIndex withObject:responseData];
}

/**
 *  Called periodically when the connection recieves data.
 */
- (void)connection:(DatabaseConnection *)connection didReceiveData:(NSData *)data
{
    NSMutableData *response = [[[_responseArray objectAtIndex:connection.panelIndex] objectAtIndex:connection.stackIndex] objectAtIndex:connection.bandIndex];
    [response appendData:data];
}

/**
 *  Called when the connection has completed its request.
 */
- (void)connectionDidFinishLoading:(DatabaseConnection *)connection
{
    NSMutableData *response = [[[_responseArray objectAtIndex:connection.panelIndex] objectAtIndex:connection.stackIndex] objectAtIndex:connection.bandIndex];
  	NSArray *jsonArr = [_jsonParser objectWithData:response];
    
    NSLog(@"Retrieved JSON array:");
    NSLog(@"%@", jsonArr);
    
    
    
//    NSMutableArray *currentConstraints = [_constraintArray objectAtIndex:_currentDepth];
//    
//    if (connection.type == RELATION)
//    {
//        NSDictionary *dict = (NSDictionary *)jsonArr;
//        for (id key in dict)
//        {
//            NSString *keyString = (NSString *)key;
//            if ([keyString isEqualToString:@"location"] || [keyString isEqualToString:@"height"]) 
//            {
//                continue;
//            }
//            else
//            {
//                Constraint *c = [[Constraint alloc] initWithName:keyString description:(NSString *)[dict objectForKey:key]];
//                [currentConstraints addObject:c];
//            }
//        }
//    }
//    else if (connection.type == META)
//    {
//        for (NSDictionary *dict in jsonArr)
//        {
//            Constraint *c = [[Constraint alloc] initWithName:(NSString *)[dict objectForKey:@"name"] 
//                                                 description:(NSString *)[dict objectForKey:@"description"]];
//            
//            if (c.name == (NSString *)[NSNull null] || [c.name isEqualToString:@""])
//            {
//                c.name = @"<null>";
//            }
//            if (c.description == (NSString *)[NSNull null] || [c.name isEqualToString:@""])
//            {
//                c.description = @"<null>";
//            }
//            
//            c.type = [_titleArray objectAtIndex:(_currentDepth - 1)];
//            NSString *metaKey = [NSString stringWithFormat:@"%@_id", c.type];
//            c.identifier = [(NSString *)[dict objectForKey:metaKey] intValue];
//            c.leaf = YES;
//            
//            [currentConstraints addObject:c];
//        }
//    }
//    else if (connection.type == LOCATION)
//    {
//        for (NSDictionary *dict in jsonArr)
//        {
//            Constraint *c = [[Constraint alloc] initWithName:(NSString *)[dict objectForKey:@"name"]
//                                                 description:@""];
//            
//            if (c.name == (NSString *)[NSNull null] || [c.name isEqualToString:@""])
//            {
//                c.name = @"<null>";
//            }
//            
//            int location = [(NSString *)[dict objectForKey:@"location_id"] intValue];
//            if (location == 1)  // Not a 'leaf' location (has subcategories)
//            {
//                c.type = @"category";
//                c.identifier = [(NSString *)[dict objectForKey:@"category_id"] intValue];
//                if (c.identifier == 0) // There was no 'category_id', instead use 'child_id'
//                {
//                    c.identifier = [(NSString *)[dict objectForKey:@"child_id"] intValue];
//                }
//                NSLog(@"Constraint with id: %d", c.identifier);
//                c.leaf = NO;
//            }
//            else // 'Leaf' location (no subcategories)
//            {
//                c.type = @"location";
//                c.identifier = location;
//                c.leaf = YES;
//            }
//            
//            [currentConstraints addObject:c];
//        }
//    }
//    else if (connection.type == TIME)
//    {
//        NSString *start = (NSString *)[(NSDictionary *)[jsonArr objectAtIndex:0] objectForKey:@"start"];
//        NSString *end = (NSString *)[(NSDictionary *)[jsonArr objectAtIndex:1] objectForKey:@"end"];
//        
//        int startNum = [(NSString *)[start substringWithRange:NSMakeRange(0, 4)] intValue];
//        int endNum = [(NSString *)[end substringWithRange:NSMakeRange(0, 4)] intValue];
//        
//        for (int i = endNum; i >= startNum; i--)
//        {
//            Constraint *c = [[Constraint alloc] initWithName:[NSString stringWithFormat:@"%d", i] description:@""];
//            c.leaf = YES;
//            [currentConstraints addObject:c];
//        }
//    }
//    
//    [_treeDelegate treeDidUpdateData];
}

/**
 *  Called when the connection fails.
 */
- (void)connection:(DatabaseConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Event data connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}


#pragma mark -
#pragma mark (Experimental) C-style Arrays

// Cusom malloc
void *my_malloc ( char *expr, size_t size )
{
    void *result = malloc( size );
    printf( "Malloc(%s) is size %lu, returning %p\n", expr, (unsigned long)size, result );
    return result;
}
// Custom free
void my_free( void *ptr )
{
    printf( "Free(%p)\n", ptr );
    free( ptr );
}
/**
 *  Create 4-dimensional arrat of floats [x][y][r][c]
 */
float ****create4D ( int max_x, int max_y, int max_r, int max_c )
{
    float ****all_x = MY_MALLOC( max_x * sizeof *all_x );
    float  ***all_y = MY_MALLOC( max_x * max_y * sizeof *all_y );
    float   **all_r = MY_MALLOC( max_x * max_y * max_r * sizeof *all_r );
    float    *all_c = MY_MALLOC( max_x * max_y * max_r * max_c * sizeof *all_c );
    float ****result = all_x;
    int x, y, r;
    
    for ( x = 0 ; x < max_x ; x++, all_y += max_y ) {
        result[x] = all_y;
        for ( y = 0 ; y < max_y ; y++, all_r += max_r ) {
            result[x][y] = all_r;
            for ( r = 0 ; r < max_r ; r++, all_c += max_c ) {
                result[x][y][r] = all_c;
            }
        }
    }
    
    return result;
}

/*- (void)dealloc
 {
 MY_FREE( _eventFloats[0][0][0] );
 MY_FREE( _eventFloats[0][0] );
 MY_FREE( _eventFloats[0] );
 MY_FREE( _eventFloats );
 }*/


#pragma mark -
#pragma mark Copy protocol

/**
 *  Overridden copying protocol for the NSObject 'copy' internals.
 *  Required to store the object in a property with 'copy' descriptor, or to call 'copy' on an object.
 */
- (id) copyWithZone:(NSZone *)zone
{
    Query *copy = [[Query alloc] init];
    NSDictionary *newMetas = [[NSDictionary alloc] initWithDictionary:_selectedMetas copyItems:YES];
    NSMutableArray *newEvents = [[NSMutableArray alloc] initWithArray:_eventArray copyItems:YES];
    
    copy.selectedMetas = newMetas;
    copy.eventArray = newEvents;
//    copy.eventFloats = _eventFloats;
	copy.timeScale = _timeScale;
    return copy;
}



@end
