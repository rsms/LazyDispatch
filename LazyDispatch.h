#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>

typedef dispatch_queue_t  DQueue;
typedef dispatch_block_t  DBlock;

#define __queue          dispatch_get_current_queue()
#define __main_queue     dispatch_get_main_queue()

#define sched_background         [LazyDispatch schedBackground].block = (DBlockWithQueue)
#define sched_main               [LazyDispatch schedMain].block = (DBlockWithQueue)
#define sched(queue)             [LazyDispatch sched:(queue)].block = (DBlockWithQueue)

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

typedef dispatch_source_t DTimer;

#define sched_timer(queue, delay, interval, block) \
  DTimerResume(DTimerCreate((queue), (delay), (interval), (block)))
#define sched_delay(delay, block)        sched_timer(__queue, (delay), 0, (block))
#define sched_interval(interval, block)  sched_timer(__queue, (interval), (interval), (block))

#define DTimerCreate(queue, delay, interval, block) \
  _DTimerCreate((queue), (delay), (interval), (DBlockWithTimerAndQueue)(block))

typedef void(^DBlockWithTimerAndQueue)(DTimer timer, dispatch_queue_t parentQueue);
#ifdef __cplusplus
extern "C" {
#endif
DTimer _DTimerCreate(DQueue queue, NSTimeInterval delay, NSTimeInterval interval, DBlockWithTimerAndQueue block);
DTimer DTimerSetInterval(DTimer timer, NSTimeInterval interval);
#ifdef __cplusplus
}
#endif
inline static DTimer DTimerPause(DTimer timer) { dispatch_suspend(timer); return timer; }
inline static DTimer DTimerResume(DTimer timer) { dispatch_resume(timer); return timer; }
inline static void DTimerStop(DTimer timer) { dispatch_source_cancel(timer); }
