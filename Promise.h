//
//  Promise.h
//
//  Created by Michael Schoonmaker on 3/29/13.
//  Copyright (c) 2013 Michael Schoonmaker. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef id (^ PromiseBlock)(id aValue, NSError **outError);

@interface Promise : NSObject

+ (instancetype)empty;
+ (instancetype)fulfilled:(id)aValue;
+ (instancetype)rejected:(NSError *)anError;

- (BOOL)fulfillWithValue:(id)aValue;
- (BOOL)rejectWithReason:(NSError *)anError;

- (instancetype)then:(PromiseBlock)fulfillment fail:(PromiseBlock)rejection;
- (instancetype)then:(PromiseBlock)fulfillment;
- (instancetype)fail:(PromiseBlock)rejection;

+ (NSError *)reasonWithString:(NSString *)aString;

@end
