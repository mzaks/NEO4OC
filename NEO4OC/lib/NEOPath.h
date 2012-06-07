/*
 The MIT License (MIT)
 Copyright (c) 2012 Maxim Zaks (maxim.zaks@gmail.com)
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import <Foundation/Foundation.h>
#import "NEOGraphDatabase.h"


@interface NEOPath : NSObject

-(id)initWithGraph:(__weak NEOGraphDatabase *)database startId:(NSString*)start endId:(NSString*)end length:(NSUInteger)pathLength nodes:(NSArray*)nodes relationships:(NSArray*)relationships;
-(NEONodePromise*)startNode;
-(NEONodePromise*)endNode;
-(NSUInteger)length;
-(void)iterateThroughNodes:(void(^)(id<NEONode> data, NEOError* error, BOOL *stop))iteratee;
-(void)iterateThroughRelationships:(void(^)(id<NEORelationship> data, NEOError* error, BOOL *stop))iteratee;
@end
