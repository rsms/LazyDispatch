# Lazy dispatcher

A very thin API + concepts on top of libdispatch (aka Grand Central Dispatch) for Cocoa Objective-C code.

I'm a lazy person and so it hurts me when I have to write so much to do such common things as to schedule various blocks of code in various dispatch queues. This little thing lets me write less code with the added bonus of making the result more readable.

### Example

```m
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

Output:

    Block #1 on queue 'com.apple.root.default-priority' (parentQueue: 'com.apple.main-thread')
    Block #2 on queue 'com.apple.main-thread'
    Block #3 on queue 'com.apple.root.default-priority'

Wow! I can haz so much fun nows!

## API

### Types

- `DQueue` — alias for `dispatch_queue_t`
- `DBlock` — alias for `dispatch_block_t`

### Special variables

- `__queue` → `DQueue` — The current queue
- `__main_queue` → `DQueue` — The main queue

### Keyword expressions

#### sched_background block([DQueue parentQueue]) → block

Schedules `block` in the background queue. The block can optionally accept an
argument which will be the queue from which `sched_background` was called.
The result of the expression is the block itself.

Useful for invoking callbacks and returning control to the same queue, e.g:

```m
- (void)doSomethingFunkyWithCallback:(DBlock)callback {
  sched_background ^(DQueue parentQueue){
    // work work work ...
    sched(parentQueue) callback;
  };
}
```

#### sched_main block([DQueue parentQueue]) → block

Schedules `block` in the main queue. The block can optionally accept an argument
which will be the queue from which `sched_main` was called. The result of the
expression is the block itself.

#### sched(DQueue queue) block([DQueue parentQueue]) → block

Schedules `block` in a `queue`. The block can optionally accept an argument
which will be the queue from which `sched` was called. The result of the
expression is the block itself.

### Functions

#### `const char* DQueueID(DQueue queue)`

Access the human-readable identifier of `queue` (its "label")


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
