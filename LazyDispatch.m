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
