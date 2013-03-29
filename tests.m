#import "Promise.h"

void runTests() {
    NSLog(@"Started. Ctrl-C to stop.");

    Promise *a = [Promise empty];
    Promise *b = [a then:^id(id value, NSError **error) {
        NSLog(@"A then: %@", value);

        return [NSNumber numberWithInt:23];
    }];
    Promise *c = [b then:^id(id value, NSError **error) {
        NSLog(@"B then: %@", value);

        return *error = [Promise reasonWithString:@"Test Failure"];
    }];
    Promise *d = [c then:^id(id value, NSError **error) {
        NSLog(@"C then: %@", value);

        return nil;
    } fail:^id(id value, NSError **error) {
        NSLog(@"C fail: %@", value);

        Promise *t = [Promise empty];

        dispatch_async(dispatch_get_main_queue(), ^{
            [t fulfillWithValue:@"Back from darkness!"];
        });

        return t;
    }];
    Promise *e = [d then:^id(id value, NSError **error) {
        NSLog(@"D then: %@", value);

        return nil;
    }];

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
