
#import "DatabaseConnection.h"


@class Query;
@class DatabaseConnection;
@protocol LoginDelegate;

/**
 *  Object that handles all interfacing with the get.php script and parsing of the results.
 *  Must be instantiated with a script URL and a username/password.
 *
 *  The key to submitting recieving requests asynchronously is the assignment of the correct delegate:
 *      - The DatabaseHandler should be the delegate only for the return of login requests
 *      - The QueryTree should be the delegate only for the return of queries for an array of metas
 *      - The Query should be the delegate only for the return of queries for events
 */
@interface DatabaseHandler : NSObject <NSURLConnectionDataDelegate>
{
    
}

@property (nonatomic, strong) id<LoginDelegate> loginDelegate;

- (id)initWithURL:(NSString *)url dataURL:(NSString *)dURL username:(NSString *)user password:(NSString *)pass delegate:(id<LoginDelegate>)delegate;

- (DatabaseConnection *) queryWithParameters:(NSString *)params fromDelegate:(id)delegate ofType:(enum ConnectionType)type;
- (DatabaseConnection *) queryDataWithParameters:(NSString *)params fromDelegate:(id)delegate ofType:(enum ConnectionType)type;
- (void) getEventCountForQuery:(Query *)query;
- (void) cancelCurrentQuery;

@end
