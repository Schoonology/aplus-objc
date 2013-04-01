// # SGPromise.h
//
// Copyright (C) 2013 Michael Schoonmaker (michael.r.schoonmaker@gmail.com)
//
// This project is free software released under the MIT/X11 license:
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>

typedef id (^ SGPromiseBlock)(id aValue, NSError **outError);

@interface SGPromise : NSObject

+ (instancetype)empty;
+ (instancetype)fulfilled:(id)aValue;
+ (instancetype)rejected:(NSError *)anError;

- (BOOL)fulfillWithValue:(id)aValue;
- (BOOL)rejectWithReason:(NSError *)anError;

- (instancetype)then:(SGPromiseBlock)fulfillment fail:(SGPromiseBlock)rejection;
- (instancetype)then:(SGPromiseBlock)fulfillment;
- (instancetype)fail:(SGPromiseBlock)rejection;

+ (NSError *)reasonWithString:(NSString *)aString;

+ (instancetype)map:(NSArray *)items usingBlock:(SGPromiseBlock)block;

@end
