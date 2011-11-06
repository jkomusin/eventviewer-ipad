
#import "QueryData.h"
#import "Event.h"

@implementation QueryData

@synthesize selectedMetas = _selectedMetas;
@synthesize eventArray = _eventArray;

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
        for (char c = 'A'; c < ('A' + panels); c++)
        {
            NSString *new = [[NSString alloc] initWithFormat:@"%c", c];
            [mutablePanels addObject:new];
        }
        NSMutableArray *mutableStacks = [[NSMutableArray alloc] init];
        for (char c = 'A'; c < ('A' + TEST_STACKS); c++)
        {
            NSString *new = [[NSString alloc] initWithFormat:@"%c", c];
            [mutableStacks addObject:new];
        }
        NSMutableArray *mutableBands = [[NSMutableArray alloc] init];
        for (char c = 'A'; c < ('A' + TEST_BANDS); c++)
        {
            NSString *new = [[NSString alloc] initWithFormat:@"%c", c];
            [mutableBands addObject:new];
        }
        NSMutableDictionary *mutableMetas = [[NSMutableDictionary alloc] init];
        NSArray *panelArray = [NSArray arrayWithArray:mutablePanels];
        [mutableMetas setObject:panelArray forKey:@"Panels"];
        NSArray *stackArray = [NSArray arrayWithArray:mutableStacks];
        [mutableMetas setObject:stackArray forKey:@"Stacks"];
        NSArray *bandArray = [NSArray arrayWithArray:mutableBands];
        [mutableMetas setObject:bandArray forKey:@"Bands"];
        
        _selectedMetas = mutableMetas;
        
        //create Events with date arithmetic
        NSDateComponents *components = [[NSDateComponents alloc] init];
        [components setDay:5];  //add 5 days
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSMutableArray *newEvents = [[NSMutableArray alloc] init];
        for (int p = 0; p < panels; p++)
        {
            NSMutableArray *newPanels = [[NSMutableArray alloc] init];
            for (int s = 0; s < TEST_STACKS; s++)
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
                        [newBands addObject:newE];
                    }
                    [newStacks addObject:newBands];
                }
                [newPanels addObject:newStacks];
            }
            [newEvents addObject:newPanels];
        }
        _eventArray = newEvents;
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

/**
 *  Overridden copying protocol for the NSObject 'copy' internals.
 *  Required to store the object in a property with 'copy' descriptor, or to call 'copy' on an object.
 */
- (id) copyWithZone:(NSZone *)zone
{
    QueryData *copy = [[QueryData alloc] init];
    NSDictionary *newMetas = [[NSDictionary alloc] initWithDictionary:_selectedMetas copyItems:YES];
    NSArray *newEvents = [[NSArray alloc] initWithArray:_eventArray copyItems:YES];
    
    copy.selectedMetas = newMetas;
    copy.eventArray = newEvents;
    return copy;
}


@end
