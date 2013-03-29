// # SGPromise.m
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

#import "SGPromise.h"

enum SGPromiseState {
    Pending,
    Fulfilled,
    Rejected
};

@interface SGPromiseChild : NSObject

@property (strong, nonatomic) SGPromise *promise;
@property (strong, nonatomic) SGPromiseBlock fulfilled;
@property (strong, nonatomic) SGPromiseBlock rejected;

@end

@implementation SGPromiseChild

@synthesize promise=_promise;
@synthesize fulfilled=_fulfilled;
@synthesize rejected=_rejected;

@end

@interface SGPromise() {
    enum SGPromiseState state;
    id value;
    NSError *reason;

    NSMutableArray *children;
}

- (void)notify:(SGPromiseChild *)child;

@end

@implementation SGPromise

- (instancetype)init {
    self = [super init];

    if (self) {
        state = Pending;
        children = [NSMutableArray arrayWithCapacity:0];
    }

    return self;
}

+ (instancetype)empty {
    return [[self alloc] init];
}

+ (instancetype)fulfilled:(id)aValue {
    SGPromise *promise = [[SGPromise alloc] init];
    [promise fulfillWithValue:aValue];
    return promise;
}

+ (instancetype)rejected:(NSError *)anError {
    SGPromise *promise = [[SGPromise alloc] init];
    [promise rejectWithReason:anError];
    return promise;
}

- (BOOL)fulfillWithValue:(id)aValue {
    if (state != Pending) {
        return NO;
    }

    if (aValue && [aValue isKindOfClass:[SGPromise class]]) {
        [aValue then:^id(id aValue, NSError **outError) {
                [self fulfillWithValue:aValue];
                return nil;
            }
            fail:^id(NSError *anError, NSError **outError) {
                [self rejectWithReason:anError];
                return nil;
            }];
        return YES;
    }

    state = Fulfilled;
    value = aValue;

    for (SGPromiseChild *child in children) {
        [self notify:child];
    }

    return YES;
}

- (BOOL)rejectWithReason:(NSError *)anError {
    if (state != Pending) {
        return NO;
    }

    state = Rejected;
    reason = anError;

    for (SGPromiseChild *child in children) {
        [self notify:child];
    }

    return YES;
}

- (instancetype)then:(SGPromiseBlock)fulfillment fail:(SGPromiseBlock)rejection {
    SGPromiseChild *child = [[SGPromiseChild alloc] init];

    child.promise = [[SGPromise alloc] init];
    child.fulfilled = fulfillment;
    child.rejected = rejection;

    if (state == Pending) {
        [children addObject:child];
        return child.promise;
    }

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self notify:child];
    });

    return child.promise;
}

- (instancetype)then:(SGPromiseBlock)fulfillment {
    return [self then:fulfillment fail:nil];
}

- (instancetype)fail:(SGPromiseBlock)rejection {
    return [self then:nil fail:rejection];
}

- (void)notify:(SGPromiseChild *)child {
    SGPromiseBlock block;
    id arg;

    switch (state) {
        case Fulfilled:
            block = child.fulfilled;
            arg = value;

            if (!block) {
                [child.promise fulfillWithValue:arg];
                return;
            }

            break;
        case Rejected:
            block = child.rejected;
            arg = reason;

            if (!block) {
                [child.promise rejectWithReason:arg];
                return;
            }

            break;
        default:
            return;
    }

    NSError *error = nil;
    id result = block(arg, &error);

    if (error) {
        [child.promise rejectWithReason:error];
    } else {
        [child.promise fulfillWithValue:result];
    }
}

+ (NSError *)reasonWithString:(NSString *)aString {
    return [NSError errorWithDomain:@"SGPromise"
        code:0L
        userInfo:[NSDictionary dictionaryWithObject:aString forKey:NSLocalizedDescriptionKey]
    ];
}

@end
