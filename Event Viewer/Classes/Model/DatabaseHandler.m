//
//  DatabaseHandler.m
//  Event Viewer
//
//  Created by Home on 1/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DatabaseHandler.h"
#import "DatabaseConnection.h"
#import "PrimaryViewController.h"
#import "Query.h"

@interface DatabaseHandler ()

- (void)loginWithUsername:(NSString *)user password:(NSString *)pass;

@end


@implementation DatabaseHandler
{
    NSString *_servletURL;       // URL of the servlet, or 'get.php' script
    NSString *_dataServletURL;	 // URL of the servlet pertaining to data, or 'get_data.php' script
    NSMutableData *_response;    // The response of the current login query
}

@synthesize loginDelegate = _loginDelegate;


#pragma mark -
#pragma mark Initialization

- (id)initWithURL:(NSString *)url dataURL:(NSString *)dURL username:(NSString *)user password:(NSString *)pass delegate:(id<LoginDelegate>)delegate
{
    if ((self = [super init]))
    { 
        _loginDelegate = delegate;
        _servletURL = url;
		_dataServletURL = dURL;
        [self loginWithUsername:user password:pass];
    }
    
    return self;
}


- (void)loginWithUsername:(NSString *)user password:(NSString *)pass
{
    NSString *loginURL = [NSString stringWithFormat:@"%@?method=login&user=%@&pass=%@", _servletURL, user, pass];
    NSURLRequest *loginRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:loginURL]
                                                cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                            timeoutInterval:60.0];
    
    (void) [[DatabaseConnection alloc] initWithRequest:loginRequest delegate:self ofType:DBConnectionTypeLogin];
}


#pragma mark -
#pragma mark Public Querying

/**
 *  Querys the curent get.php script with the parameters specified.
 *  Parameters must be specified as they appear after the '?' at the end of the address
 *  of the current script.
 *
 *  Data will be returned to the delegate by the delegate methods:
 *  connection:didReceiveResponse:, connection:didReceiveData:, connection:didFailWithError: and connectionDidFinishLoading:
 */
- (DatabaseConnection *) queryWithParameters:(NSString *)params fromDelegate:(id)delegate ofType:(enum ConnectionType)type
{
    NSLog(@"Querying with parameters: %@ and type: %d", params, type);
    
    NSString *queryURL = [NSString stringWithFormat:@"%@?%@", _servletURL, params];
    NSURLRequest *dbRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:queryURL]
                                             cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                         timeoutInterval:60.0];
    
    return [[DatabaseConnection alloc] initWithRequest:dbRequest delegate:delegate ofType:type];
}
- (DatabaseConnection *) queryDataWithParameters:(NSString *)params fromDelegate:(id)delegate ofType:(enum ConnectionType)type
{
    NSLog(@"Querying with parameters: %@ and type: %d", params, type);
    
    NSString *queryURL = [NSString stringWithFormat:@"%@?%@", _dataServletURL, params];
    NSURLRequest *dbRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:queryURL]
                                             cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                         timeoutInterval:60.0];
    
    return [[DatabaseConnection alloc] initWithRequest:dbRequest delegate:delegate ofType:type];
}


- (void) getEventCountForQuery:(Query *)query
{
    
}


#pragma mark -
#pragma mark Connection delegation

/**
 *  Called when the connection has begun to be responded to by the URL.
 *  May be called multiple times in the event of a redirect, etc.
 */
- (void)connection:(DatabaseConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"Type of query: %d", connection.type);
    if (connection.type != DBConnectionTypeLogin)
    {
        NSString *type;
        if (connection.type == DBConnectionTypeLocation)  type = @"LOCATION";
        if (connection.type == DBConnectionTypeRelation)  type = @"RELATION";
        if (connection.type == DBConnectionTypeMeta)  type = @"META";
        if (connection.type == DBConnectionTypeEvent)       type = @"EVENT";
        if (connection.type == DBConnectionTypeEventCount) type = @"EVENT_COUNT";
        NSLog(@"ERROR: Connection of type '%@' handled by DatabaseHandler. Expected 'LOGIN'", type);
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
    NSString *loginResponse = [[NSString alloc] initWithData:_response encoding:NSASCIIStringEncoding];
    
    if ([loginResponse isEqualToString:@"Welcome!"])
    {
        [_loginDelegate loginToDatabaseSucceeded];
    }
    else
    {
        [_loginDelegate loginToDatabaseFailedWithError:loginResponse];
    }
}

/**
 *  Called when the connection fails.
 */
- (void)connection:(DatabaseConnection *)connection didFailWithError:(NSError *)error
{
    [_loginDelegate loginToDatabaseFailedWithError:[NSString stringWithFormat:@"%@ (%@)", 
                                                    [error localizedDescription], 
                                                    [[error userInfo] objectForKey:NSURLErrorFailingURLErrorKey]]];
    NSLog(@"Login connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}


@end
