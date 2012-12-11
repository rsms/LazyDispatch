#import <Foundation/Foundation.h>

typedef dispatch_queue_t DQueue;
typedef dispatch_block_t DBlock;

#define __queue          dispatch_get_current_queue()
#define __main_queue     dispatch_get_main_queue()

#define sched_background [LazyDispatch schedBackground].block = (DBlockWithQueue)
#define sched_main       [LazyDispatch schedMain].block = (DBlockWithQueue)
#define sched(queue)     [LazyDispatch sched:(queue)].block = (DBlockWithQueue)

inline static const char* DQueueID(DQueue q) {
  return dispatch_queue_get_label(q);
}

typedef void(^DBlockWithQueue)(dispatch_queue_t parentQueue);
@interface LazyDispatch : NSObject
@property (copy) DBlockWithQueue block;
+ (__weak LazyDispatch*)schedBackground;
+ (__weak LazyDispatch*)schedMain;
+ (LazyDispatch*)sched:(dispatch_queue_t)queue;
@end
