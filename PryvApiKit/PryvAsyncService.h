//
//  PYAsyncService.h
//  PryvApiKit
//
//  Created by Nenad Jelic on 4/15/13.
//  Copyright (c) 2013 Pryv. All rights reserved.
//

typedef void(^PAAsyncServiceSuccessBlock)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON);
typedef void(^PAAsyncServiceFailureBlock)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON);


#import <Foundation/Foundation.h>

@interface PryvAsyncService : NSObject <NSURLConnectionDelegate>
{
    NSURLConnection *_connection;
    NSURLRequest *_request;
    NSHTTPURLResponse *_response;
    NSMutableData *_responseData;
    
    BOOL _running;
    PAAsyncServiceSuccessBlock _onSuccess;
    PAAsyncServiceFailureBlock _onFailure;

}

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSHTTPURLResponse *response;

@property (nonatomic, retain) NSMutableData *responseData;

+ (void)JSONRequestServiceWithRequest:(NSURLRequest *)request
                            success:(PAAsyncServiceSuccessBlock)success
                            failure:(PAAsyncServiceFailureBlock)failure;

- (id)initWithRequest:(NSURLRequest *)request;

- (void)stop;

@end
