
#import "QueryData.h"

@implementation QueryData

@synthesize selectedMetas = _selectedMetas;
@synthesize panelNum = _panelNum;


- (id) init
{
    if ((self = [super init]))
    {        
        //initialize _selectedMetas with empty arrays for specified keys
        NSMutableDictionary *mutableMetas = [_selectedMetas mutableCopy];
        
        NSArray *panelArray = [NSArray arrayWithObjects:nil];
        [mutableMetas setObject:panelArray forKey:@"Panels"];
        NSArray *stackArray = [NSArray arrayWithObjects:nil];
        [mutableMetas setObject:stackArray forKey:@"Stacks"];
        NSArray *bandArray = [NSArray arrayWithObjects:nil];
        [mutableMetas setObject:bandArray forKey:@"Bands"];
        
        _selectedMetas = mutableMetas;        
        _panelNum = 0;
    }
    
    return self;
}

- (id) initTestWithPanels:(int)panels
{    
    if ((self = [self init]))
    {
        NSMutableDictionary *mutableMetas = [_selectedMetas mutableCopy];
        NSMutableArray *mutablePanels = [(NSArray *)[mutableMetas objectForKey:@"Panels"] mutableCopy];
        
        for (char c = 'A'; c < ('A' + panels); c++)
        {
            [mutablePanels addObject:[NSString stringWithFormat:@"%c", c]];
        }
        
        [mutableMetas setObject:mutablePanels forKey:@"Panels"];
        _selectedMetas = mutableMetas;
        _panelNum = panels;

    }

    return self;
}

- (id) copyWithZone:(NSZone *)zone
{
    QueryData *copy = [[QueryData alloc] init];
    copy.selectedMetas = [_selectedMetas copy];
    copy.panelNum = _panelNum;
    return copy;
}


@end
