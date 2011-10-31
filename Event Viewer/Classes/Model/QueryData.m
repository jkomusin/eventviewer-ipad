
#import "QueryData.h"

@implementation QueryData

@synthesize selectedMetas = _selectedMetas;


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
    }
    
    return self;
}

/**
 *  Initializes the data model with a specified number of panels for stress-testing purposes
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
        
        NSMutableDictionary *mutableMetas = [[NSMutableDictionary alloc] init];
        NSArray *panelArray = [NSArray arrayWithArray:mutablePanels];
        [mutableMetas setObject:panelArray forKey:@"Panels"];
        NSArray *stackArray = [NSArray arrayWithObjects:nil];
        [mutableMetas setObject:stackArray forKey:@"Stacks"];
        NSArray *bandArray = [NSArray arrayWithObjects:nil];
        [mutableMetas setObject:bandArray forKey:@"Bands"];
        
        _selectedMetas = mutableMetas;
    }

    return self;
}

/**
 *  Overrriden copying protocol for the NSObject 'copy' internals.
 *  Required to store the object in a property with 'copy' descriptor, or to call 'copy' on an object.
 */
- (id) copyWithZone:(NSZone *)zone
{
    QueryData *copy = [[QueryData alloc] init];
    NSDictionary *newMetas = [[NSDictionary alloc] initWithDictionary:_selectedMetas copyItems:YES];
    
    copy.selectedMetas = newMetas;
    return copy;
}


@end
