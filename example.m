#import <Foundation/Foundation.h>
#import "LazyDispatch.h"

int main(int argc, const char * argv[]) {
  @autoreleasepool {

    // Schedule a block to run in the normal-priority background queue
    sched_background ^(DQueue parentQueue){
      NSLog(@"Block #1 on queue '%s' (parentQueue: '%s')",
            DQueueID(__queue), DQueueID(parentQueue));

      sched_main ^(DQueue parentQueue){
        NSLog(@"Block #2 on queue '%s'", DQueueID(__queue));

        sched(parentQueue) ^{
          NSLog(@"Block #3 on queue '%s'", DQueueID(__queue));
          exit(0);
        };
      };
    };
    
    // Run the main runloop so to avoid this example program exiting
    [[NSRunLoop mainRunLoop] run];
  }
  return 0;
}

