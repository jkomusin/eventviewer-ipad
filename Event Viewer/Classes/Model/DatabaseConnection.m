
#import "DatabaseConnection.h"

@implementation DatabaseConnection
{
}

@synthesize type = _type;

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate ofType:(enum ConnectionType)type
{
    if ((self = [super initWithRequest:request delegate:delegate]))
    {
        self.type = type;
    }
    
    return self;
}


@end
