//
//  Promise.m
//
//  Created by Michael Schoonmaker on 3/29/13.
//  Copyright (c) 2013 Michael Schoonmaker. All rights reserved.
//

#import "Promise.h"

enum PromiseState {
    Pending,
    Fulfilled,
    Rejected
};

@interface PromiseChild : NSObject

@property (strong, nonatomic) Promise *promise;
@property (strong, nonatomic) PromiseBlock fulfilled;
@property (strong, nonatomic) PromiseBlock rejected;

@end

@implementation PromiseChild

@synthesize promise=_promise;
@synthesize fulfilled=_fulfilled;
@synthesize rejected=_rejected;

@end

@interface Promise() {
    enum PromiseState state;
    id value;
    NSError *reason;

    NSMutableArray *children;
}

- (void)notify:(PromiseChild *)child;

@end

@implementation Promise

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
    Promise *promise = [[Promise alloc] init];
    [promise fulfillWithValue:aValue];
    return promise;
}

+ (instancetype)rejected:(NSError *)anError {
    Promise *promise = [[Promise alloc] init];
    [promise rejectWithReason:anError];
    return promise;
}

- (BOOL)fulfillWithValue:(id)aValue {
    if (state != Pending) {
        return NO;
    }

    if ([aValue isKindOfClass:[Promise class]]) {
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

    for (PromiseChild *child in children) {
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

    for (PromiseChild *child in children) {
        [self notify:child];
    }

    return YES;
}

- (instancetype)then:(PromiseBlock)fulfillment fail:(PromiseBlock)rejection {
    PromiseChild *child = [[PromiseChild alloc] init];

    child.promise = [[Promise alloc] init];
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

- (instancetype)then:(PromiseBlock)fulfillment {
    return [self then:fulfillment fail:nil];
}

- (instancetype)fail:(PromiseBlock)rejection {
    return [self then:nil fail:rejection];
}

- (void)notify:(PromiseChild *)child {
    PromiseBlock block;
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
    return [NSError errorWithDomain:@"Promise"
        code:0L
        userInfo:[NSDictionary dictionaryWithObject:aString forKey:NSLocalizedDescriptionKey]
    ];
}

@end
