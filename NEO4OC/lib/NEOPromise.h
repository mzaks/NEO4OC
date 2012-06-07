/*
 The MIT License (MIT)
 Copyright (c) 2012 Maxim Zaks (maxim.zaks@gmail.com)
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import <Foundation/Foundation.h>

@class NEOError;
enum PROMISE_STATUS{
    WAITING,
    DONE,
    ERROR
};
typedef enum PROMISE_STATUS PROMISE_STATUS;

@interface NEOPromise : NSObject

-(PROMISE_STATUS)status;
-(void)setValue:(id)aValue;

-(void)setError:(NEOError *)anError;
-(NEOError*)error;
- (BOOL)hasError;

-(id)wait;
-(void)waitWithHandler:(void (^)(id value, NEOError *error))callback;

+ (void)waitForPromises:(NEOPromise*)promise, ...;
@end