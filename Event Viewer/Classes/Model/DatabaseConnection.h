//
//  ServletConnection.h
//  Event Viewer
//
//  Created by Home on 1/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Enumeration for the three categories of query in the system:
 *      - LOGIN is used for all connections that login to the database script
 *      - CONSTRAINT is used for all connections that query for constraints of a certain level
 *          from the database script
 *      - EVENT is used for all connections that query for events from the database script
 *      - EVENT_COUNT is used for all connections querying the number of events in a given query
 */
enum ConnectionType
{
    DBConnectionTypeLogin = 0,
    DBConnectionTypeEvent = 1,
    DBConnectionTypeEventCount = 2,
    DBConnectionTypeLocation = 3,
    DBConnectionTypeRelation = 4,
    DBConnectionTypeMeta = 5,
    DBConnectionTypeTime = 6
};


/**
 *  URLConnection with custom properties to specify the type of connection, along with identifying information.
 */
@interface DatabaseConnection : NSURLConnection
{
    
}

@property (nonatomic, assign) enum ConnectionType type; // Type of data requested by this connection
@property (nonatomic, assign) NSInteger panelIndex;           // Optional index of the panel whose events were requested by this connection
@property (nonatomic, assign) NSInteger stackIndex;           // Optional index of the stack whose events were requested by this connection
@property (nonatomic, assign) NSInteger bandIndex;            // Optional index of the band whose events were requested by this connection

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate ofType:(enum ConnectionType)type withPanelIndex:(NSInteger)panel stackIndex:(NSInteger)stack bandIndex:(NSInteger)band;
- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate ofType:(enum ConnectionType)type;

@end
