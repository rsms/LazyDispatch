// Copyright (c) 2012 Rasmus Andersson. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the accompanying README file.
#import "LazyDispatch.h"

@implementation LazyDispatch {
  dispatch_queue_t _queue;
}

+ (__weak LazyDispatch*)schedBackground {
  static dispatch_once_t onceToken;
  static LazyDispatch* obj;
  dispatch_once(&onceToken, ^{
    obj = [self sched:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
  });
  return obj;
}

+ (__weak LazyDispatch*)schedMain {
  static dispatch_once_t onceToken;
  static LazyDispatch* obj;
  dispatch_once(&onceToken, ^{
    obj = [self sched:dispatch_get_main_queue()];
  });
  return obj;
}

+ (LazyDispatch*)sched:(dispatch_queue_t)queue {
  LazyDispatch* task = [self new];
  task->_queue = queue;
  return task;
}

- (void)setBlock:(DBlockWithQueue)block {
  dispatch_queue_t parentQueue = dispatch_get_current_queue();
  dispatch_async(_queue, ^{ block(parentQueue); });
}

- (DBlockWithQueue)block {
  return nil;
}

@end

#define kLeewayNanosec 1000000 /* 1ms */

static DTimer __DTimerCreate(DQueue queue, dispatch_time_t start, int64_t interval, DBlockWithTimerAndQueue block) {
  dispatch_queue_t parentQueue = dispatch_get_current_queue();
  dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
  if (interval <= 0) {
    dispatch_source_set_event_handler(timer, ^{
      block(timer, parentQueue);
      DTimerStop(timer);
    });
  } else {
    dispatch_source_set_event_handler(timer, ^{ block(timer, parentQueue); });
  }
  dispatch_source_set_timer(timer, start, interval, kLeewayNanosec);
  dispatch_set_context(timer, (__bridge void*)timer);
  return timer;
}

inline static int64_t _NSTimeIntervalToInt64NanoSeconds(NSTimeInterval t) {
  return (int64_t)(t * 1000000000.0);
}

DTimer _DTimerCreate(DQueue queue, NSTimeInterval delay, NSTimeInterval interval, DBlockWithTimerAndQueue block) {
  dispatch_time_t _start = dispatch_time(0, _NSTimeIntervalToInt64NanoSeconds(delay));
  int64_t _interval = _NSTimeIntervalToInt64NanoSeconds(interval);
  return __DTimerCreate(queue, _start, _interval, block);
}

DTimer DTimerSetInterval(DTimer timer, NSTimeInterval interval) {
  int64_t _interval = _NSTimeIntervalToInt64NanoSeconds(interval);
  dispatch_source_set_timer(timer, dispatch_time(0, _interval), _interval, kLeewayNanosec);
  return timer;
}
