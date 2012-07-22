/*
    The MIT License (MIT)
    Copyright (c) 2012 Maxim Zaks (maxim.zaks@gmail.com)

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import <Foundation/Foundation.h>
#import "NEONode.h"
#import "NEORelationship.h"
#import "NEOIndex.h"   


NSString *idOfURI(NSString *uri);

@class NEOError;
@class NEORequestBuilder;


@interface NEOGraphDatabase : NSObject

@property(strong) NEORequestBuilder * requestBuilder;

- (id)initWithURL:(NSURL *)aURL;

- (void)getInfo:(void (^)(NSDictionary *info, NEOError *error))callback;

- (NEONodePromise *)getNodeById:(NSString *)nodeId;
- (NEONodePromise *)createNodeWithData:(NSDictionary*)theDataOrNil;
- (void)queryCypher:(NSString *)cypher withParameters:(NSDictionary *)paramsOrNil andTypedResultHandler:(void (^)(NSArray *result, NEOError *error))callback;

- (NEORelationshipPromise *)getRelationshipById:(NSString *)relationshipId;

- (NEONodeIndexPromise*)createNodeIndexWithName:(NSString*)name andConfig:(NSDictionary*)configOrNil;
- (NEORelationshipIndexPromise *)createRelationshipIndexWithName:(NSString *)name andConfig:(NSDictionary *)configOrNil;

- (NEONodeIndexPromise*)getNodeIndexWithName:(NSString*)name;
- (NEORelationshipIndexPromise*)getRelationshipIndexWithName:(NSString*)name;
- (void)getAllNodeIndexesWithHandler:(void (^)(NSArray *indexes, NEOError* error))callback;
- (void)getAllRelationshipIndexesWithHandler:(void (^)(NSArray *indexes, NEOError* error))callback;


@end