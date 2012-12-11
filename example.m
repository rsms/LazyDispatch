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
          //exit(0);
        };
      };
    };

    // Schedule a block to be run after a delay of one second
    sched_delay(1, ^{
      NSLog(@"Delayed block triggered");
    });

    // Schedule a block to be run every 1.1 seconds
    sched_interval(1.1, ^{
      NSLog(@"Perpetual block triggered");
    });

    // Custom timer that starts after 1.5 seconds and is then triggered two more
    // times with 3.5 seconds interval
    __block int trigger_count = 0;
    sched_timer(__queue, 1.5, 3.5, ^(DTimer timer){
      NSLog(@"Custom timer triggered");
      if (++trigger_count == 3) {
        DTimerStop(timer);
        NSLog(@"Custom timer stopped");
      }
    });
    
    // Run the main runloop so to avoid this example program exiting
    [[NSRunLoop mainRunLoop] run];
  }
  return 0;
}

