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
    LOGIN = 0,
    CONSTRAINT = 1,
    EVENT = 2,
    EVENT_COUNT = 3
};


/**
 *  URLConnection with custom properties to specify the type of connection, along with identifying information.
 */
@interface DatabaseConnection : NSURLConnection

@property (nonatomic, assign) enum ConnectionType type; // Type of data requested by this connection
@property (nonatomic, assign) int panelIndex;           // Optional index of the panel whose events were requested by this connection
@property (nonatomic, assign) int stackIndex;           // Optional index of the stack whose events were requested by this connection
@property (nonatomic, assign) int bandIndex;            // Optional index of the band whose events were requested by this connection

@end
