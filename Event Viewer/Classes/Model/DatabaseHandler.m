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
#import "JSONKit.h"

@interface DatabaseHandler ()

- (void)loginWithUsername:(NSString *)user password:(NSString *)pass;

@end


@implementation DatabaseHandler
{
    JSONDecoder *_jsonHandler;   // JSON decoder to handle the results of queries
    NSString *_servletURL;       // URL of the servlet, or 'get.php' script
    
    NSMutableData *_response;    // The response of the current login query
}

@synthesize loginDelegate = _loginDelegate;


#pragma mark -
#pragma mark Initialization

- (id)initWithURL:(NSString *)url username:(NSString *)user password:(NSString *)pass delegate:(id<LoginDelegate>)delegate
{
    if ((self = [super init]))
    { 
        _loginDelegate = delegate;
        _servletURL = url;
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
    
    DatabaseConnection *loginConnection=[[DatabaseConnection alloc] initWithRequest:loginRequest delegate:self];
    [loginConnection setType:LOGIN];
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
- (void) queryWithParameters:(NSString *)params fromDelegate:(id)delegate
{

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
        [_loginDelegate loginToDatabaseFailed];
        NSLog(@"Failed login response: %@", loginResponse);
    }
}

/**
 *  Called when the connection fails.
 */
- (void)connection:(DatabaseConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}


@end
