/*
 The MIT License (MIT)
 Copyright (c) 2012 Maxim Zaks (maxim.zaks@gmail.com)
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import <Foundation/Foundation.h>
#import "NEORelationship.h"
#import "NEOIndex.h"

@interface NEORequestBuilder : NSObject

-(id)initWithBaseURL:(NSURL *)url;
-(void)setTimeoutInSeconds:(NSTimeInterval)interval;


-(NSURLRequest *)requestForGetInfo;
-(NSURLRequest *)requestForGetNodeById:(NSString *)nodeId;
-(NSURLRequest *)requestForGetDataForNodeById:(NSString *)nodeId;
-(NSURLRequest *)requestForGetRelationshipById:(NSString *)relationshipId;
-(NSURLRequest *)requestForGetDataForRelationshipById:(NSString *)relId;
-(NSURLRequest *)requestForGetRelationships:(RELATIONSHIP_DIRECTION)direction forNodeId:(NSString *)nodeId andTypes:(NSArray *)typesOrNil;

-(NSURLRequest *)requestForCreateNodeWithData:(NSDictionary *)dataOrNil;
-(NSURLRequest *)requestForCreateRelationshipFromNodeId:(NSString *)nodeId withData:(NSDictionary *)dataOrNil;

-(NSURLRequest *)requestForDeleteNodeById:(NSString *)nodeId;
-(NSURLRequest *)requestForDeleteRelationshipById:(NSString *)relationshipId;

-(NSURLRequest *)requestForQueryWithCypher:(NSString *)cypher andParameters:(NSDictionary *)paramsOrNil;

-(NSURLRequest *)requestForSetData:(NSDictionary*)newData forNodeById:(NSString*)nodeId;
-(NSURLRequest *)requestForSetData:(NSDictionary*)newData forRelationshipById:(NSString*)nodeId;

-(NSURLRequest *)requestForCreateIndexWithType:(IndexType)type name:(NSString*)name andConfig:(NSDictionary*)configOrNil;
-(NSURLRequest *)requestForDeleteIndexWithType:(IndexType)type name:(NSString*)name;
-(NSURLRequest *)requestForGetIndexWithType:(IndexType)type name:(NSString*)name;
-(NSURLRequest *)requestForGetAllIndexesOfType:(IndexType)type;

-(NSURLRequest *)requestForAddByURI:(NSString *)nodeURI indexType:(IndexType)type name:(NSString *)indexName key:(NSString *)key andValue:(NSString *)value;
-(NSURLRequest *)requestForRemoveById:(NSString *)nodeId indexType:(IndexType)type name:(NSString *)indexName key:(NSString *)keyOrNil andValue:(NSString *)valueOrNil;
-(NSURLRequest *)requestForFindByExactMatchForIndexType:(IndexType)type name:(NSString *)indexName key:(NSString *)key andValue:(NSString *)value;

-(NSURLRequest *)requestForExecuteBatchOperations:(NSArray*)operations;

@end