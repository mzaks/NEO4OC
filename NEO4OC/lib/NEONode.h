/*
 The MIT License (MIT)
 Copyright (c) 2012 Maxim Zaks (maxim.zaks@gmail.com)
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import <Foundation/Foundation.h>
#import "NEOPromise.h"


@class NEOGraphDatabase;
@class NEOError;
@class NEORelationshipPromise;

@protocol NEONode <NSObject>
@optional
- (NSString *)nodeURI;
- (NSString *)nodeId;

- (NSDictionary *)data;
- (void)fetchData:(void(^)(NSDictionary* data, NEOError* error))callback;
- (void)setData:(NSDictionary*)newDataOrEmpty withResultHandler:(void (^)(NEOError *error))callback;

- (void)deleteWithResultHandler:(void (^)(NEOError *error))callback;

- (NEORelationshipPromise*)createRelationshipToNode:(id<NEONode>)endNode ofType:(NSString*)theType andData:(NSDictionary*)theDataOrNil;
- (void)getAllRelationshipsOfTypes:(NSArray*)typesOrNil withResultHandler:(void(^)(NSArray * relationships, NEOError * error))callback;
- (void)getOutgoingRelationshipsOfTypes:(NSArray*)typesOrNil withResultHandler:(void(^)(NSArray * relationships, NEOError * error))callback;
- (void)getIncomingRelationshipsOfTypes:(NSArray*)typesOrNil withResultHandler:(void(^)(NSArray * relationships, NEOError * error))callback;
@end

@interface NEONode : NSObject <NEONode>
- (id)initWithGraph:(__weak NEOGraphDatabase *)database data:(NSDictionary *)theDataOrNil andURI:(NSString *)theNodeId;
@end

@interface NEONodePromise : NEOPromise <NEONode>
-(void)waitForNodeWithHandler:(void (^)(id<NEONode> value, NEOError *error))callback;
@end
