//
//  DatabaseHandler.m
//  Event Viewer
//
//  Created by Home on 1/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ServletHandler.h"
#import "JSONKit.h"

@interface ServletHandler ()

- (BOOL)loginWithUsername:(NSString *)user password:(NSString *)pass;

@end


@implementation ServletHandler
{
    JSONDecoder *jsonHandler;   // JSON decoder to handle the results of queries
    NSString *servletURL;       // URL of the servlet, or 'get.php' script
}


#pragma mark -
#pragma mark Initialization

- (id)initWithURL:(NSString *)url username:(NSString *)user password:(NSString *)pass
{
    if ((self = [super init]))
    { 
        servletURL = url;
        if ([self loginWithUsername:user password:pass])
        {
            NSLog(@"Sucessfully logged in!");
        }
        else
        {
            NSLog(@"Login failed for user '%@'", user);
        }
    }
    
    return self;
}


- (BOOL)loginWithUsername:(NSString *)user password:(NSString *)pass
{
    NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.apple.com/"]
                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                          timeoutInterval:60.0];
    // create the connection with the request
    // and start loading the data
    NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    if (theConnection) {
        // Create the NSMutableData to hold the received data.
        // receivedData is an instance variable declared elsewhere.
        receivedData = [[NSMutableData data] retain];
    } else {
        // Inform the user that the connection failed.
    }
    
    NSString *queryURL = [NSString stringWithFormat:@"%@?method=login&user=%@&pass=%@", servletURL, user, pass];
    NSURL *urlToSend = [[NSURL alloc] initWithString:queryURL];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:urlToSend   
                                                cachePolicy:NSURLRequestReturnCacheDataElseLoad                                                               
                                            timeoutInterval:30];
    NSData *urlData;
    NSURLResponse *response;
    NSError *error;
    urlData = [NSURLConnection sendSynchronousRequest:urlRequest  
                                    returningResponse:&response 
                                                error:&error];
    
    return YES;
}


#pragma mark -
#pragma mark Querying

/**
 *  Querys the curent get.php script with the parameters specified.
 *  Parameters must be specified as they appear after the '?' at the end of the address
 *  of the current script.
 *
 *  Returns a dictionary representing the parsed 
 */
- (NSDictionary *) queryWithParameters:(NSString *)params
{
//    NSLog(@"Querying with parameters: \"%@\"", params);
//    
//    NSString *queryURL = [NSString stringWithFormat:@"%@?%@", servletURL, params];
//    NSURL *urlToSend = [[NSURL alloc] initWithString:queryURL];
//    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:urlToSend   
//                                                cachePolicy:NSURLRequestReturnCacheDataElseLoad                                                               
//                                            timeoutInterval:30];
//    NSData *urlData;
//    NSURLResponse *response;
//    NSError *error;
//    urlData = [NSURLConnection sendSynchronousRequest:urlRequest  
//                                    returningResponse:&response 
//                                                error:&error];
//    //encode into NSDictionary
//    NSString *json_string=[[[NSString alloc]initWithData:urlData encoding:NSUTF8StringEncoding]autorelease];
//    
//    //remove any error messsages and output to console
//    NSCharacterSet *cset = [NSCharacterSet characterSetWithCharactersInString:@"["];    //the start of the JSON
//    NSRange range = [json_string rangeOfCharacterFromSet:cset];
//    if (range.location != NSNotFound && range.location > 0 && range.location < [json_string length]) 
//    {
//        NSString *errorString = [json_string substringToIndex:range.location];    
//        NSLog(@"ERROR in query with parameters \"%@\": %@", params, errorString);
//        
//        json_string = [json_string substringFromIndex:range.location];
//        NSLog(@"Returned: %@", json_string);
//    }
//    else if (range.location != NSNotFound)
//    {
//        NSLog(@"Sucessfully queried with parameters \"%@\"", params);
//        json_string = [json_string substringFromIndex:range.location];
//    }
//    
//    NSDictionary *jsonDict = [json_string yajl_JSON];        
//    
//    [urlToSend release], urlToSend = nil;
//    
//    return jsonDict;
}

- (void) getEventCountForCurrentQuery
{
    
}


#pragma mark -
#pragma mark Connection delegation

/**
 *  Called when the connection has begun to be responded to by the URL
 */
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    
}

/**
 *  Called periodically when the connection recieves data
 */
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    
}

/**
 *  Called when the connection has completed its request
 */
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{

}

/**
 *  Called when the connection fails
 */
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    
}


@end
