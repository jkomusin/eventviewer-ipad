
#import "PrimaryViewController.h"
#import "ContentScrollView.h"
#import "DatabaseHandler.h"
#import "DatabaseConnection.h"
#import "JSONKit.h"
#import "Query.h"
#import "Event.h"
#import "Constraint.h"
#import "QueryBuilderView.h"


@implementation Query
{
    DatabaseHandler *_dbHandler;        // Handler for the database, assumed to be logged in
    JSONDecoder *_jsonParser;           // Decoder of returned JSON packets
    NSMutableData *_response;			// Response for current query
	DatabaseConnection *_queryConnect;	// Connection to current query
}

@synthesize contentDelegate = _contentDelegate;
@synthesize queryDelegate = _queryDelegate;
@synthesize selectedMetas = _selectedMetas;
@synthesize eventArray = _eventArray;
@synthesize timeScale = _timeScale;
@synthesize isQuerying = _isQuerying;
@synthesize hidingSelectedBands = _hidingSelectedBands;
@synthesize hidingSelectedStacks = _hidingSelectedStacks;
@synthesize hidingSelectedPanels = _hidingSelectedPanels;

OBJC_EXPORT float BAND_HEIGHT;              //
OBJC_EXPORT float BAND_WIDTH;               //  Globals set in ContentViewControlled specifying UI layout parameters
OBJC_EXPORT float BAND_SPACING;             //
OBJC_EXPORT float TIMELINE_HEIGHT;          //

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
		
		_hidingSelectedBands = NO;
		_hidingSelectedStacks = NO;
		_hidingSelectedPanels = NO;
        
        // Initialize _eventArray with empty arrays
        NSMutableArray *emptyEvents = [[NSMutableArray alloc] init];
        NSMutableArray *emptyStacks = [[NSMutableArray alloc] init];
        NSMutableArray *emptyBands = [[NSMutableArray alloc] init];
        NSArray *emptyBandEvents = [[NSMutableArray alloc] init];
        [emptyEvents addObject:emptyStacks];
        [emptyStacks addObject:emptyBands];
        [emptyBands addObject:emptyBandEvents];
        _eventArray = emptyEvents;
        
        // Initialize _jsonParser
        _jsonParser = [[JSONDecoder alloc] init];
		
		_isQuerying = NO;
		
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
    return [(NSArray *)[self.selectedMetas objectForKey:@"Panels"] count];
}
- (NSInteger)stackNum
{
    return [(NSArray *)[self.selectedMetas objectForKey:@"Stacks"] count];
}
- (NSInteger)bandNum
{
    return [(NSArray *)[self.selectedMetas objectForKey:@"Bands"] count];
}

/**
 *	SelectedMeta accessor
 *	Takes into account whether certain metas should be hidden or not
 */
- (NSDictionary *)selectedMetas
{
	NSMutableDictionary *dict;
	@synchronized(self)
	{	
		dict = [_selectedMetas mutableCopy];
		if (_hidingSelectedPanels)
		{
			[dict setObject:[NSArray arrayWithObjects:nil] forKey:@"Panels"];
		}
		if (_hidingSelectedStacks)
		{
			[dict setObject:[NSArray arrayWithObjects:nil] forKey:@"Stacks"];
		}
		if (_hidingSelectedBands)
		{
			[dict setObject:[NSArray arrayWithObjects:nil] forKey:@"Bands"];
		}
	}
	return (NSDictionary *)dict;
}
// Need to implement the atomic setter manually
- (void)setSelectedMetas:(NSDictionary *)selectedMetas
{
	@synchronized(self)
	{
		if (_selectedMetas != selectedMetas)
		{
			_selectedMetas = selectedMetas;
		}
	}
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
}


#pragma mark -
#pragma mark Querying for data

- (void)queryForEventsWithCurrentConstraints
{
	NSDictionary *metas = self.selectedMetas;
	
    NSArray *panelConstraints = [metas objectForKey:@"Panels"];
    NSArray *stackConstraints = [metas objectForKey:@"Stacks"];
    NSArray *bandConstraints = [metas objectForKey:@"Bands"];
    
    // Initialize the event arrays to the size of the query
    NSMutableArray *newEvents = [[NSMutableArray alloc] init];
    for (int p = 0; p < [panelConstraints count]; p++)
    {
        NSMutableArray *panelEvents = [[NSMutableArray alloc] init];
        for (int s = 0; s < [stackConstraints count]; s++)
        {
            NSMutableArray *stackEvents = [[NSMutableArray alloc] init];
            for (int b = 0; b < [bandConstraints count]; b++)
            {
                NSMutableArray *bandEvents = [[NSMutableArray alloc] init];
                [stackEvents addObject:bandEvents];
            }
            
            [panelEvents addObject:stackEvents];
        }
        
        [newEvents addObject:panelEvents];
    }
    _eventArray = newEvents;
    
    // Query for events
	NSMutableString *parameters = [[NSMutableString alloc] init];
	if ([panelConstraints count] > 0)
	{
		[parameters appendString:@"panels="];
		for (int p = 0; p < [panelConstraints count]; p++)
		{
			Constraint *panel = [panelConstraints objectAtIndex:p];
			[parameters appendFormat:@"%@=%d,", panel.type, panel.identifier];
		}
		parameters = [[parameters substringToIndex:[parameters length]-1] mutableCopy]; // Remove trailing comma
		[parameters appendString:@"&"];	// Add delimiter
	}
	if ([stackConstraints count] > 0)
	{
		[parameters appendString:@"stacks="];
        for (int s = 0; s < [stackConstraints count]; s++)
        {
            Constraint *stack = [stackConstraints objectAtIndex:s];
			[parameters appendFormat:@"%@=%d,", stack.type, stack.identifier];			
		}
		parameters = [[parameters substringToIndex:[parameters length]-1] mutableCopy];
		[parameters appendString:@"&"];
	}
	if ([bandConstraints count] > 0)
	{
		[parameters appendString:@"bands="];
		for (int b = 0; b < [bandConstraints count]; b++)
		{
			Constraint *band = [bandConstraints objectAtIndex:b];
			[parameters appendFormat:@"%@=%d,", band.type, band.identifier];
		}
		parameters = [[parameters substringToIndex:[parameters length]-1] mutableCopy];
    }
	
	_isQuerying = YES;
	[_dbHandler queryDataWithParameters:parameters fromDelegate:self ofType:DBConnectionTypeEvent];
}

- (void)cancelCurrentQuery
{
	if (_isQuerying)
	{
		[_dbHandler cancelCurrentQuery];
	}
}


#pragma mark -
#pragma mark Data management

- (void)swapBandData:(NSInteger)i withBand:(NSInteger)j
{
    // Handle possibility of 0 panel or stack-query
    int panelNum = self.panelNum;
    if (panelNum == 0) panelNum = 1;
    int stackNum = self.stackNum;
    if (stackNum == 0) stackNum = 1;
    
    // Reorder events
    for (int p = 0; p < panelNum; p++)
    {
        for (int s = 0; s < stackNum; s++)
        {
            NSMutableArray *mutableBands = [[[_eventArray objectAtIndex:p] objectAtIndex:s] mutableCopy];
            NSArray *tempBand = [mutableBands objectAtIndex:i];
            [mutableBands replaceObjectAtIndex:i withObject:[mutableBands objectAtIndex:j]];
            [mutableBands replaceObjectAtIndex:j withObject:tempBand];
            [[_eventArray objectAtIndex:p] replaceObjectAtIndex:s withObject:(NSArray *)mutableBands];
        }
    }
    
    // Reorder meta array
    NSMutableArray *mutableBandMetas = [[_selectedMetas objectForKey:@"Bands"] mutableCopy];
    Constraint *tempMeta = [mutableBandMetas objectAtIndex:i];
    [mutableBandMetas replaceObjectAtIndex:i withObject:[mutableBandMetas objectAtIndex:j]];
    [mutableBandMetas replaceObjectAtIndex:j withObject:tempMeta];
    NSMutableDictionary *mutableMetas = [_selectedMetas mutableCopy];
    [mutableMetas setObject:(NSArray *)mutableBandMetas forKey:@"Bands"];
    _selectedMetas = (NSDictionary *)mutableMetas;
}

- (void)swapStackData:(NSInteger)i withStack:(NSInteger)j
{
	// Reorder events
    NSMutableArray *mutableEvents = [_eventArray mutableCopy];
    
    // Handle possibility fo 0 panel-query
    int panelNum = self.panelNum;
    if (panelNum == 0) panelNum = 1;
	
    for (int p = 0; p < panelNum; p++)
    {
        NSMutableArray *mutableStacks = [[_eventArray objectAtIndex:p] mutableCopy];
        NSArray *tempStack = [mutableStacks objectAtIndex:i];
        [mutableStacks replaceObjectAtIndex:i withObject:[mutableStacks objectAtIndex:j]];
        [mutableStacks replaceObjectAtIndex:j withObject:tempStack];
        
        [mutableEvents replaceObjectAtIndex:p withObject:(NSArray *)mutableStacks];
    }
    _eventArray = mutableEvents;
    
    // Reorder meta array
    NSMutableArray *mutableStackMetas = [[_selectedMetas objectForKey:@"Stacks"] mutableCopy];
    Constraint *tempMeta = [mutableStackMetas objectAtIndex:i];
    [mutableStackMetas replaceObjectAtIndex:i withObject:[mutableStackMetas objectAtIndex:j]];
    [mutableStackMetas replaceObjectAtIndex:j withObject:tempMeta];
    NSMutableDictionary *mutableMetas = [_selectedMetas mutableCopy];
    [mutableMetas setObject:(NSArray *)mutableStackMetas forKey:@"Stacks"];
    _selectedMetas = (NSDictionary *)mutableMetas;

}

- (void)swapPanelData:(NSInteger)i withPanel:(NSInteger)j
{
	// Reorder events
    NSMutableArray *mutableEvents = [_eventArray mutableCopy];
    
    NSArray *tempPanel = [mutableEvents objectAtIndex:i];
    [mutableEvents replaceObjectAtIndex:i withObject:[mutableEvents objectAtIndex:j]];
    [mutableEvents replaceObjectAtIndex:j withObject:tempPanel];
	
    _eventArray = mutableEvents;
    
    // Reorder meta array
    NSMutableArray *mutablePanelMetas = [[_selectedMetas objectForKey:@"Panels"] mutableCopy];
    Constraint *tempMeta = [mutablePanelMetas objectAtIndex:i];
    [mutablePanelMetas replaceObjectAtIndex:i withObject:[mutablePanelMetas objectAtIndex:j]];
    [mutablePanelMetas replaceObjectAtIndex:j withObject:tempMeta];
    NSMutableDictionary *mutableMetas = [_selectedMetas mutableCopy];
    [mutableMetas setObject:(NSArray *)mutablePanelMetas forKey:@"Panels"];
    _selectedMetas = (NSDictionary *)mutableMetas;
}

- (void)swapBinData:(enum UI_OBJECT)i withBin:(enum UI_OBJECT)j
{
	// Reorder event array
	int newPanels = -1;
	int newStacks = -1;
	int newBands = -1;
	NSString *iKey = @"";
	NSString *jKey = @"";
	// Check all 6 possible permuations of swaps between bins, and determine new number of indices
	if ((i == UIObjectPanel && j == UIObjectStack) || (j == UIObjectPanel && i == UIObjectStack))
	{
		// Swap panels and stacks 
		newPanels = [[_eventArray objectAtIndex:0] count];
		newStacks = [_eventArray count];
		newBands = [[[_eventArray objectAtIndex:0] objectAtIndex:0] count];
		iKey = @"Panels";
		jKey = @"Stacks";
	}
	else if ((i == UIObjectPanel && j == UIObjectBand) || (j == UIObjectPanel && i == UIObjectBand))
	{
		// Swap panels and bands
		newPanels = [[[_eventArray objectAtIndex:0] objectAtIndex:0] count];
		newStacks = [[_eventArray objectAtIndex:0] count];
		newBands = [_eventArray count];
		iKey = @"Panels";
		jKey = @"Bands";
	}
	else if ((i == UIObjectStack && j == UIObjectBand) || (j == UIObjectStack && i == UIObjectBand))
	{
		// Swap stacks and bands
		newPanels = [_eventArray count];
		newStacks = [[[_eventArray objectAtIndex:0] objectAtIndex:0] count];
		newBands = [[_eventArray objectAtIndex:0] count];
		iKey = @"Stacks";
		jKey = @"Bands";
	}
	else
	{
		NSLog(@"ERROR: Illegal arrangement of bins to swap: %d and %d", i, j);
	}
	// Reorder meta dictionary
	NSMutableDictionary *newMetas = [_selectedMetas mutableCopy];
	NSMutableArray *temp = [_selectedMetas objectForKey:iKey];
	[newMetas setObject:[_selectedMetas objectForKey:jKey] forKey:iKey];
	[newMetas setObject:temp forKey:jKey];
	_selectedMetas = (NSDictionary *)newMetas;
	
	// Create new array
	NSMutableArray *newEventArr = [[NSMutableArray alloc] init];
	for (int p = 0; p < newPanels; p++)
	{
		NSMutableArray *newPanelArr = [[NSMutableArray alloc] init];
		for (int s = 0; s < newStacks; s++)
		{
			NSMutableArray *newStackArr = [[NSMutableArray alloc] init];
			for (int b = 0; b < newBands; b++)
			{
				// Grab band from old index, insert into new index
				NSArray *band;
				if ((i == UIObjectPanel && j == UIObjectStack) || (j == UIObjectPanel && i == UIObjectStack))
				{
					band = [[[[_eventArray objectAtIndex:s] objectAtIndex:p] objectAtIndex:b] copy];
				}
				else if ((i == UIObjectPanel && j == UIObjectBand) || (j == UIObjectPanel && i == UIObjectBand))
				{
					band = [[[[_eventArray objectAtIndex:b] objectAtIndex:s] objectAtIndex:p] copy];
				}
				else if ((i == UIObjectStack && j == UIObjectBand) || (j == UIObjectStack && i == UIObjectBand))
				{
					band = [[[[_eventArray objectAtIndex:p] objectAtIndex:b] objectAtIndex:s] copy];
				}
				[newStackArr addObject:band];
			}
			[newPanelArr addObject:newStackArr];
		}
		[newEventArr addObject:newPanelArr];
	}
	_eventArray = newEventArr;
}



#pragma mark -
#pragma mark Query builder data source
/**
 *  We assume that the only table views accessing these methods are the tables within the query builder specifying selected constraints.
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
    if (tableView.editing)
	{
		cell.showsReorderControl = YES;
	}
	else
	{
		cell.showsReorderControl = NO;
	}
	
	
    Constraint *con = [dataArr objectAtIndex:indexPath.row];
    
    // Configure the cell.
    cell.textLabel.text = con.name;
    cell.detailTextLabel.text = con.description;
    
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{		
	NSMutableArray *consArr;
    if (tableView.tag == UIObjectBand)
    {
        consArr = [_selectedMetas objectForKey:@"Bands"];
		[self swapBandData:fromIndexPath.row withBand:toIndexPath.row];
    }
    else if (tableView.tag == UIObjectStack)
    {
        consArr = [_selectedMetas objectForKey:@"Stacks"];
		[self swapStackData:fromIndexPath.row withStack:toIndexPath.row];
    }
    else if (tableView.tag == UIObjectPanel)
    {
        consArr = [_selectedMetas objectForKey:@"Panels"];
		[self swapPanelData:fromIndexPath.row withPanel:toIndexPath.row];
    }
	
	Constraint *cTemp = [consArr objectAtIndex:toIndexPath.row];
	[consArr replaceObjectAtIndex:toIndexPath.row withObject:[consArr objectAtIndex:fromIndexPath.row]];
	[consArr replaceObjectAtIndex:fromIndexPath.row withObject:cTemp];
	
	if (tableView.tag == UIObjectBand)
	{
		[_contentDelegate swapBandLayer:fromIndexPath.row withBand:toIndexPath.row];
	}
	else if (tableView.tag == UIObjectStack)
	{
		[_contentDelegate swapStackLayer:fromIndexPath.row withStack:toIndexPath.row];
	}
	else if (tableView.tag == UIObjectPanel)
	{
		[_contentDelegate swapPanelLayer:fromIndexPath.row withPanel:toIndexPath.row];
	}
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{	
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		NSMutableArray *dataArr;
		if (tableView.tag == UIObjectBand)
		{
			dataArr = [_selectedMetas objectForKey:@"Bands"];
			if ([dataArr count] > 1)
			{
				// Remove allocated space for events
				for (NSMutableArray *panelArr in _eventArray)
				{
					for (NSMutableArray *stackArr in panelArr)
					{
						[stackArr removeObjectAtIndex:indexPath.row];
					}
				}
			}
		}
		else if (tableView.tag == UIObjectStack)
		{
			dataArr = [_selectedMetas objectForKey:@"Stacks"];
			if ([dataArr count] > 1)
			{
				// Remove allocated space for events
				for (NSMutableArray *panelArr in _eventArray)
				{
					[panelArr removeObjectAtIndex:indexPath.row];
				}
			}
		}
		else if (tableView.tag == UIObjectPanel)
		{
			dataArr = [_selectedMetas objectForKey:@"Panels"];
			if ([dataArr count] > 1)
			{
				// Remove allocated space for events
				[_eventArray removeObjectAtIndex:indexPath.row];
			}
		}
		
		Constraint *c = [dataArr objectAtIndex:indexPath.row];
		[dataArr removeObjectAtIndex:indexPath.row];
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
		[_queryDelegate queryDeletedRowWithConstraint:c fromTableWithTag:tableView.tag];
	}
	
	[_queryDelegate queryDidChange];
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
	_isQuerying = NO;
	
  	NSArray *jsonArr = [_jsonParser objectWithData:_response];
    
    if (connection.type == DBConnectionTypeEvent)
    {
		// Returned event JSON array should have the format:
		//	3-dimensional array with arrays indexed as follows:
		//		[x][][] specifies the panel
		//		[][x][] specifies the stack
		//		[][][x] specifies the return value of the get.php script's 'data' method
		//
		//	Each return value of the original get.php 'data' methd is formatted as follows:
		//
		//	Array with elements that are dictionaries with two keys: "header" and "occurrence"
		//	"header" containts a dictionary of the specific constraints on the events in the dictionary
		//	"occurrence" contains an array of dictionaries which are each an event under the header
		//		Each event dictionary has the format similar to the following example:
		//		day = 11;
		//		end = "2004-10-12 18:00:00-04";
		//		instance_id = "2004-10-11 03:00:00-04";
		//		magnitude = "15.23999023";
		//		month = 10;
		//		start = "2004-10-11 03:00:00-04";
		//		year = 2004;
		
		NSDateFormatter *dateMaker = [[NSDateFormatter alloc] init];
		[dateMaker setDateFormat:@"yyyy-MM-dd HH:mm"];
		
		for (int p = 0; p < [jsonArr count]; p++)
		{
			NSArray *panelArr = [jsonArr objectAtIndex:p];
			if ([panelArr isKindOfClass:[NSNull class]])
				continue;
			for (int s = 0; s < [panelArr count]; s++)
			{
				NSArray *stackArr = [panelArr objectAtIndex:s];
				if ([stackArr isKindOfClass:[NSNull class]])	
					continue;
				for (int b = 0; b < [stackArr count]; b++)
				{
					NSArray *bandArr = [stackArr objectAtIndex:b];
					if ([bandArr isKindOfClass:[NSNull class]])
						continue;
					NSMutableArray *eventArr = [[NSMutableArray alloc] init];
					for (NSDictionary *dict in bandArr)
					{
						if ([dict isKindOfClass:[NSNull class]])	
							continue;
						for (NSDictionary *eventDict in [dict objectForKey:@"occurrence"])
						{
							if ([eventDict isKindOfClass:[NSNull class]])	
								continue;
							NSString *startString = [eventDict objectForKey:@"start"];
							NSString *endString = [eventDict objectForKey:@"end"];
							NSDate *start = [dateMaker dateFromString:[startString substringWithRange:NSMakeRange(0, 16)]];
							NSDate *end = [dateMaker dateFromString:[endString substringWithRange:NSMakeRange(0, 16)]];
							Event *e = [[Event alloc] initWithStartTime:start endTime:end];
							e.year = [[eventDict objectForKey:@"year"] intValue];
							e.month = [[eventDict objectForKey:@"month"] intValue];
							e.day = [[eventDict objectForKey:@"day"] intValue];
							
							// Determine coordinates based on timescale
							if (_timeScale == QueryTimescaleYear)
							{
								float x = (e.month - 1.0f)*(BAND_WIDTH_P / 12.0f) + (e.day - 1.0f)*(BAND_WIDTH_P / 356.0f);
								//round to nearest 0.5 for sharpness of drawing
								int xInt = (int)x;
								x = xInt + 0.5f;
								// length of event in minutes
								int length = (int)([end timeIntervalSinceDate:start] / 60.0f);
								float width = length * (BAND_WIDTH_P / 365.0f / 24.0f / 60.0f);
								//fix erroneous widths
								if (x + width > BAND_WIDTH_P) width = width - ((x + width) - BAND_WIDTH_P);
								e.x = x;
								e.width = width;
							}
							else
							{
								NSLog(@"ERROR: Query timescale of %d undefined", _timeScale);
							}
							
							[eventArr addObject:e];
						}
					}
					
					// Store new events
					[[[_eventArray objectAtIndex:p] objectAtIndex:s] replaceObjectAtIndex:b withObject:eventArr];
				}
			}
		}		
    }
    else
    {
        NSLog(@"ERROR: Connection of type %d handled by Query data object.", connection.type);
    }

	[_contentDelegate queryHasRecievedData];
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
	copy.timeScale = _timeScale;
    return copy;
}



@end
