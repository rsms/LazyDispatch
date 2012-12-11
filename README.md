# Lazy dispatcher

A very thin API + concepts on top of libdispatch (aka Grand Central Dispatch) for Cocoa Objective-C code.

I'm a lazy person and so it hurts me when I have to write so much to do such common things as to schedule various blocks of code in various dispatch queues. This little thing lets me write less code with the added bonus of making the result more readable.

### Example

First, using vanilla libdispatch:

```objc
dispatch_queue_t parentQueue = dispatch_get_current_queue();
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
  NSLog(@"Block #1 on queue '%s' (parentQueue: '%s')",
        dispatch_queue_get_label(dispatch_get_current_queue()),
        dispatch_queue_get_label(parentQueue));
  
  dispatch_queue_t parentQueue2 = dispatch_get_current_queue();
  dispatch_async(dispatch_get_main_queue(), ^{
    NSLog(@"Block #2 on queue '%s'",
          dispatch_queue_get_label(dispatch_get_current_queue()));
    
    dispatch_async(parentQueue2, ^{
      NSLog(@"Block #3 on queue '%s'",
            dispatch_queue_get_label(dispatch_get_current_queue()));
      exit(0);
    });
  });
});
```

Now, with LazyDispatch:

```objc
sched_background ^(DQueue parentQueue){
  NSLog(@"Block #1 on queue '%s' (parentQueue: '%s')",
        DQueueID(__queue), DQueueID(parentQueue));

  sched_main ^(DQueue parentQueue){
    NSLog(@"Block #2 on queue '%s'", DQueueID(__queue));

    sched(parentQueue) ^{
      NSLog(@"Block #3 on queue '%s'", DQueueID(__queue));
    };
  };
};
```

    Block #1 on queue 'com.apple.root.default-priority' (parentQueue: 'com.apple.main-thread')
    Block #2 on queue 'com.apple.main-thread'
    Block #3 on queue 'com.apple.root.default-priority'

See. Way simpler yet same performance as no actual overhead is added. We just rephrased things to be a little more readable.

*Wow! I can haz so much fun nows!*

There are also timers. We love them timers, don't we?!

```objc
sched_delay(1, ^{
  NSLog(@"Delayed block executed after one second");
});
```

Just like e.g. JavaScript, timers can be cancelled:

```objc
DTimer timer = sched_interval(13.37, ^{
  NSLog(@"Delayed block sez hi");
});
//...
DTimerStop(timer);
```

## API

### Types

- `DQueue` — A dispatch queue (alias for `dispatch_queue_t`)
- `DBlock` — A block (alias for `dispatch_block_t`)
- `DTimer` — A timer (alias for `dispatch_source_t`)

### Special variables

- `__queue` → `DQueue` — The current queue
- `__main_queue` → `DQueue` — The main queue

### Keyword expressions

#### `sched_background ^([DQueue parentQueue]) → block`

Schedules a block in the background queue. The block can optionally accept an
argument which will be the queue from which `sched_background` was called.
The result of the expression is the block itself.

Useful for invoking callbacks and returning control to the same queue, e.g:

```objc
- (void)doSomethingFunkyWithCallback:(DBlock)callback {
  sched_background ^(DQueue parentQueue){
    // work work work ...
    sched(parentQueue) callback;
  };
}
```

#### `sched_main ^([DQueue parentQueue]) → block`

Schedules a block in the main queue. The block can optionally accept an argument
which will be the queue from which `sched_main` was called. The result of the
expression is the block itself.

#### `sched(DQueue queue) ^([DQueue parentQueue]) → block`

Schedules a block in a `queue`. The block can optionally accept an argument
which will be the queue from which `sched` was called. The result of the
expression is the block itself.

### Functions

#### `const char* DQueueID(DQueue queue)`

Access the human-readable identifier of `queue` (its "label")

#### `DTimer sched_delay(NSTimeInterval delay, ^([DTimer[, DQueue]]))`

Schedule a block in the current queue to execute after `delay` seconds. You can call `DTimerStop` on the `DTimer` object (returned from this function) to cancel a timer before it has triggered.

Example:

```objc
// Schedule a block to be run after a delay of one second
sched_delay(1, ^{
  NSLog(@"Delayed block triggered");
});
```

#### `DTimer sched_interval(NSTimeInterval interval, ^([DTimer[, DQueue]]))`

Schedule a block in the current queue to be executed every `interval` seconds. You are responsible for calling `DTimerStop(timer)` when the timer is no longer needed.

Example:

```objc
// Schedule a block to be run every 1.1 seconds
sched_interval(1.1, ^{
  NSLog(@"Perpetual block triggered");
});
```

#### `DTimer sched_timer(DQueue queue, NSTimeInterval delay, NSTimeInterval interval, ^([DTimer[, DQueue]]))`

Schedule a timer on `queue` which starts after `delay` seconds and repeats with `interval`.

If `interval` has a positive value, the timer repeats every `interval` seconds. In this case you are responsible for stopping the timer by calling `DTimerStop(timer)`. If `interval` is zero or negative, the timer is triggered once and then automatically stopped.

Example:

```objc
// Start a timer on `fooQueue` after 1.5 seconds, triggering in 3.5 second intervals
sched_timer(fooQueue, 1.5, 3.5, ^(DTimer timer){
  NSLog(@"Timer %@ triggered on foo queue", timer);
});
```

#### `DTimer DTimerCreate(DQueue queue, NSTimeInterval delay, NSTimeInterval interval, ^([DTimer[, DQueue]]))`

Like `sched_timer` but only creates a timer (does not schedule it). You need to call `DTimerResume` in order to schedule the timer.

Example:

```objc
DTimer timer = DTimerCreate(fooQueue, 1.5, 3.5, ^(DTimer timer){
  NSLog(@"Timer %@ triggered on foo queue", timer);
});
// ...
DTimerResume(timer);
```

#### `DTimer DTimerResume(DTimer timer)`

Schedule a timer that is not yet scheduled (has been paused by `DTimerPause` or just created by `DTimerCreate`.)

Each call to `DTimerResume` must balance a call to `DTimerPause`, or there will be violent memory violations that will crash all the things. This is a property of libdispatch, trading tolerance of use for efficiency. Note that the timers returned from `sched_delay`, `sched_interval` and `sched_timer` are already resumed.

#### `DTimer DTimerPause(DTimer timer)`

Unschedule a timer that has been scheduled. When pausing a timer and later resuming it, the trigger time does *not* adjust for the time which during the timer was paused.

#### `DTimer DTimerSetInterval(DTimer timer, NSTimeInterval interval)`

Modify and reset the interval of a timer.

Calling this function has no effect if the timer source has already been canceled.

Example:

```objc
// Execute a block five times with 1 second interval, then change the interval to
// execute the block with 2 seconds interval.
__block int triggerCount = 0;
sched_interval(1.0, ^(DTimer timer){
  NSLog(@"Perpetual block triggered");
  if (++triggerCount == 5) {
    DTimerSetInterval(timer, 2.0);
  }
});
```

#### `void DTimerStop(DTimer timer)`

Cancellation prevents any further invocation of the handler block for the specified timer, but does not interrupt a handler block that is already executing.


# MIT License

Copyright (c) 2012 Rasmus Andersson <http://rsms.me/>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
