/*
 The MIT License (MIT)
 Copyright (c) 2012 Maxim Zaks (maxim.zaks@gmail.com)
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import <Foundation/Foundation.h>
#import "NEOPromise.h"
#import "NEONode.h"

@class NEOError;

enum DIRECTION{
    ALL,
    IN,
    OUT
};
typedef enum DIRECTION RELATIONSHIP_DIRECTION;

@protocol NEORelationship <NSObject>
@optional
- (NSString *) relationshipURI;
- (NSString *) relationshipId;

- (NSDictionary *) data;
- (void)fetchData:(void(^)(NSDictionary* data, NEOError* error))callback;
- (void)setData:(NSDictionary*)newDataOrEmpty withResultHandler:(void (^)(NEOError *))callback;

- (NSString *) type;

- (NSString *) startNodeId;
- (NEONodePromise *) startNode;

- (NSString *) endNodeId;
- (NEONodePromise *) endNode;

- (void)deleteWithResultHandler:(void (^)(NEOError *))callback;
@end

@class NEOGraphDatabase;
@interface NEORelationship : NSObject <NEORelationship>
- (id)initWithGraph:(__weak NEOGraphDatabase *)database data:(NSDictionary *)theData type:(NSString*)theType start:(NSString*)startId end:(NSString*)endId andURI:(NSString *)theRelationshipURI;
@end

@interface NEORelationshipPromise : NEOPromise <NEORelationship>
-(void)waitForRelationshipWithHandler:(void (^)(id<NEORelationship> value, NEOError *error))callback;
@end