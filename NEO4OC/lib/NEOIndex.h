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
#import "NEORelationship.h"

typedef enum IndexType {
    nodeIndex,
    relationshipIndex
}IndexType;

@protocol NEOIndex

@optional
- (NSString*)indexName;
- (void)deleteWithResultHandler:(void (^)(NEOError *error))callback;
@end

@protocol NEONodeIndex <NEOIndex>
@optional
- (void)addNode:(id<NEONode>)node forKey:(NSString*)key andValue:(NSString*)value withResultHandler:(void (^)(NEOError *error))callback;
- (void)removeNode:(id<NEONode>)node forKey:(NSString*)keyOrNil andValue:(NSString*)valueOrNil withResultHandler:(void (^)(NEOError *error))callback;
- (void)findNodesByExactMatchForKey:(NSString*)key andValue:(NSString*)value withResultHandler:(void (^)(NSArray *result, NEOError *error))callback;
@end

@protocol NEORelationshipIndex <NEOIndex>
@optional
- (void)addRelationship:(id<NEORelationship>)relationship forKey:(NSString*)key andValue:(NSString*)value withResultHandler:(void (^)(NEOError *error))callback;
- (void)removeRelationship:(id<NEORelationship>)relationship forKey:(NSString*)keyOrNil andValue:(NSString*)valueOrNil withResultHandler:(void (^)(NEOError *error))callback;
- (void)findRelationshipsByExactMatchForKey:(NSString*)key andValue:(NSString*)value withResultHandler:(void (^)(NSArray *result, NEOError *error))callback;
@end

@class NEOGraphDatabase;
@interface NEOIndex : NSObject <NEONodeIndex, NEORelationshipIndex>

-(id)initWithGraph:(__weak NEOGraphDatabase *)database type:(IndexType)type andName:(NSString*)name;

@end

@interface NEONodeIndexPromise : NEOPromise <NEONodeIndex>
-(void)waitForIndexWithHandler:(void (^)(id<NEONodeIndex> value, NEOError *error))callback;
@end

@interface NEORelationshipIndexPromise : NEOPromise <NEORelationshipIndex>
-(void)waitForIndexWithHandler:(void (^)(id<NEORelationshipIndex> value, NEOError *error))callback;
@end
