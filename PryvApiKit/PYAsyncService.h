//
//  PYAsyncService.h
//  PryvApiKit
//
//  Created by Nenad Jelic on 4/15/13.
//  Copyright (c) 2013 Pryv. All rights reserved.
//

typedef void(^PYAsyncServiceSuccessBlock)(NSURLRequest *req, NSHTTPURLResponse *resp, id JSON);
typedef void(^PYAsyncServiceFailureBlock)(NSURLRequest *req, NSHTTPURLResponse *resp, NSError *error, id JSON);

typedef enum {
	PYRequestResultTypeJSON = 1,
	PYRequestResultTypeRAW
} PYRequestResultType;

#import <Foundation/Foundation.h>

@interface PYAsyncService : NSObject
{
    NSURLConnection *_connection;
    NSURLRequest *_request;
    NSHTTPURLResponse *_response;
    NSMutableData *_responseData;
    PYRequestResultType _requestResultType;
    
    BOOL _running;
    PYAsyncServiceSuccessBlock _onSuccess;
    PYAsyncServiceFailureBlock _onFailure;

}

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSHTTPURLResponse *response;

@property (nonatomic, retain) NSMutableData *responseData;

+ (void)JSONRequestServiceWithRequest:(NSURLRequest *)request
                            success:(PYAsyncServiceSuccessBlock)success
                            failure:(PYAsyncServiceFailureBlock)failure;

+ (void)RAWRequestServiceWithRequest:(NSURLRequest *)request
                              success:(PYAsyncServiceSuccessBlock)success
                              failure:(PYAsyncServiceFailureBlock)failure;


- (id)initWithRequest:(NSURLRequest *)request;

- (void)stop;

@end
