# Lazy dispatcher

A very thin API + concepts on top of libdispatch (aka Grand Central Dispatch).

### Example

    // Schedule a block to run in the normal priority background queue
    sched_background ^(DQueue parentQueue){
      NSLog(@"Block #1 on queue '%s' (parentQueue: '%s')",
            DQueueID(__queue), DQueueID(parentQueue));
      sched_main ^{
        NSLog(@"Block #2 on queue '%s'", DQueueID(__queue));
      };
      sched(parentQueue) ^{
        NSLog(@"Block #3 on queue '%s'", DQueueID(__queue));
      };
      // ^ is equivalent to this:
      dispatch_async(parentQueue, ^{
        NSLog(@"Block #4 on queue '%s'", DQueueID(__queue));
      });
    };

Output:

    Block #1 on queue 'com.apple.root.default-priority' (parentQueue:
      'com.apple.main-thread')
    Block #2 on queue 'com.apple.main-thread'
    Block #3 on queue 'com.apple.main-thread'
    Block #4 on queue 'com.apple.main-thread'

## API

### Types (typedef's)

- `DQueue` -- alias for dispatch_queue_t
- `DBlock` -- alias for dispatch_block_t

### Special variables

- `__queue` -- The current queue (a `DQueue`.)
- `__main_queue` -- The main queue (a `DQueue`.)

### Keyword expressions

#### sched_background block([DQueue parentQueue]) -> block

Schedules `block` in the background queue. The block can optionally accept an
argument which will be the queue from which `sched_background` was called.
The result of the expression is the block itself.

Useful for invoking callbacks and returning control to the same queue, e.g:

    - (void)doSomethingFunkyWithCallback:(DBlock)callback {
      sched_background ^(DQueue parentQueue){
        // work work work ...
        sched(parentQueue) callback;
      };
    }

#### sched_main block([DQueue parentQueue]) -> block

Schedules `block` in the main queue. The block can optionally accept an argument
which will be the queue from which `sched_main` was called. The result of the
expression is the block itself.

#### sched(DQueue queue) block([DQueue parentQueue]) -> block

Schedules `block` in a `queue`. The block can optionally accept an argument
which will be the queue from which `sched` was called. The result of the
expression is the block itself.

### Functions

#### `const char* DQueueID(DQueue queue)`

Access the human-readable identifier of `queue` (its "label")
