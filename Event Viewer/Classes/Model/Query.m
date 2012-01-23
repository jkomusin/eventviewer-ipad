
#import "PrimaryViewController.h"
#import "ContentScrollView.h"
#import "Query.h"
#import "Event.h"
#import "Meta.h"

#define MY_MALLOC(x)    my_malloc( #x, x )
#define MY_FREE(x)      my_free(x)

@implementation Query

@synthesize selectedMetas = _selectedMetas;
@synthesize eventArray = _eventArray;
//@synthesize eventFloats = _eventFloats;
@synthesize timeScale = _timeScale;

OBJC_EXPORT float BAND_HEIGHT;              //
OBJC_EXPORT float BAND_WIDTH;               //  Globals set in ContentViewControlled specifying UI layout parameters
OBJC_EXPORT float BAND_SPACING;             //
OBJC_EXPORT float TIMELINE_HEIGHT;            //

- (id) init
{
    if ((self = [super init]))
    {        
        //initialize _selectedMetas with empty arrays for specified keys
        NSMutableDictionary *mutableMetas = [[NSMutableDictionary alloc] init];
        
        NSArray *panelArray = [NSArray arrayWithObjects:nil];
        [mutableMetas setObject:panelArray forKey:@"Panels"];
        NSArray *stackArray = [NSArray arrayWithObjects:nil];
        [mutableMetas setObject:stackArray forKey:@"Stacks"];
        NSArray *bandArray = [NSArray arrayWithObjects:nil];
        [mutableMetas setObject:bandArray forKey:@"Bands"];
        
        _selectedMetas = mutableMetas;
        
        NSArray *emptyEvents = [[NSArray alloc] init];
        _eventArray = emptyEvents;
        
        //_eventFloats = create4D(2, 2, 2, 2);
		
		_timeScale = -1;
    }
    
    return self;
}

/**
 *  Initializes the data model with a specified number of panels for stress-testing purposes.
 *  
 *  panels is the number of panels to create
 */
- (id) initTestWithPanels:(int)panels
{    
    if ((self = [self init]))
    {
        NSMutableArray *mutablePanels = [[NSMutableArray alloc] init];
        for (char p = 'A'; p < ('A' + panels); p++)
        {
            NSString *new = [[NSString alloc] initWithFormat:@"Panel %c", p];
            Meta *newM = [[Meta alloc] initWithName:new];
            [mutablePanels addObject:newM];
        }
        
        NSMutableArray *mutableStacks = [[NSMutableArray alloc] init];
        for (char s = 'A'; s < ('A' + TEST_STACKS); s++)
        {
            NSString *new = [[NSString alloc] initWithFormat:@"Stack %c", s];
            Meta *newM = [[Meta alloc] initWithName:new];
            [mutableStacks addObject:newM];
        }
        
        NSMutableArray *mutableBands = [[NSMutableArray alloc] init];
        for (char b = 'A'; b < ('A' + TEST_BANDS); b++)
        {
            NSString *new = [[NSString alloc] initWithFormat:@"Band %c", b];
            Meta *newM = [[Meta alloc] initWithName:new];
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
    
		_timeScale = 1;
    
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
 */
- (int)panelNum
{
    return [(NSArray *)[_selectedMetas objectForKey:@"Panels"] count];
}
- (int)stackNum
{
    return [(NSArray *)[_selectedMetas objectForKey:@"Stacks"] count];
}
- (int)bandNum
{
    return [(NSArray *)[_selectedMetas objectForKey:@"Bands"] count];
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
    NSArray *newEvents = [[NSArray alloc] initWithArray:_eventArray copyItems:YES];
    
    copy.selectedMetas = newMetas;
    copy.eventArray = newEvents;
//    copy.eventFloats = _eventFloats;
	copy.timeScale = _timeScale;
    return copy;
}



@end
