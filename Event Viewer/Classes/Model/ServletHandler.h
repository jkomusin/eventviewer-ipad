//
//  DatabaseHandler.h
//  Event Viewer
//
//  Created by Home on 1/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Object that handles all interfacing with the get.php script and parsing of the results.
 *  Must be instantiated with a script URL and a unsername/password.
 *
 *  The key to submitting recieving requests asynchronously is the assignment of the correct delegate:
 *      - The DatabaseHandler should be the delegate only for the return of login requests
 *      - The QueryTree should be the delegate only for the return of queries for an array of metas
 *      - The Query should be the delegate only for the return of queries for events
 */
@interface ServletHandler : NSObject </*NSURLConnectionDelegate,*/ NSURLConnectionDataDelegate>

- (NSDictionary *) queryWithParameters:(NSString *)params;
- (void) getEventCountForCurrentQuery;

@end
