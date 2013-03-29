#import "SGPromise.h"

void runTests() {
    NSLog(@"Started. Ctrl-C to stop.");

    SGPromise *a = [SGPromise fulfilled:[NSNumber numberWithInt:42]];
    SGPromise *b = [a then:^id(id value, NSError **error) {
        NSLog(@"A then: %@", value);

        return [NSNumber numberWithInt:23];
    }];
    SGPromise *c = [b then:^id(id value, NSError **error) {
        NSLog(@"B then: %@", value);

        return *error = [SGPromise reasonWithString:@"Test Failure"];
    }];
    SGPromise *d = [c then:^id(id value, NSError **error) {
        NSLog(@"C then: %@", value);

        return nil;
    } fail:^id(id value, NSError **error) {
        NSLog(@"C fail: %@", value);

        SGPromise *t = [SGPromise empty];

        dispatch_async(dispatch_get_main_queue(), ^{
            [t fulfillWithValue:@"Back from darkness!"];
        });

        return t;
    }];
    SGPromise *e = [d then:^id(id value, NSError **error) {
        NSLog(@"D then: %@", value);

        return [SGPromise rejected:[SGPromise reasonWithString:@"E Error"]];
    }];
    SGPromise *f = [e then:nil fail:^id(id value, NSError **error) {
        NSLog(@"E fail: %@", value);

        return *error = [SGPromise reasonWithString:@"F Error"];
    }];
    SGPromise *g = [f then:nil fail:nil];
    SGPromise *h = [g then:nil fail:^id(id value, NSError **error) {
        NSLog(@"G fail: %@", value);

        return nil;
    }];
    assert(f != g && g != h);

    dispatch_async(dispatch_get_main_queue(), ^{
        [a fulfillWithValue:[NSNumber numberWithInt:42]];
    });
}

void handleSignal(int signo) {
    if (signo == SIGINT) {
        exit(0);
    }
}

int main(int argc, char *argv[])
{
    @autoreleasepool {
        signal(SIGINT, handleSignal);
        runTests();
        dispatch_main();
    }
}
