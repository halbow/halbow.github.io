---
title: "Why I still write Synchronous APIs"
date: 2024-05-02T08:18:36+02:00
draft: false
---


Async programming in Python had a lot of attraction in the recent years. Python 3.4 
was released in 2014 and added the asyncio module. This enabled a great way to write 
async code but came with a new syntax and most libraries that wanted to be compatible
had to undergo a big rewrite to enable this (you can check the great post [What color is your function](https://journal.stuffwithstuff.com/2015/02/01/what-color-is-your-function/)
to understand why). We're now ten years after the first asyncio release, and while
the ecosystem still feels a bit fragmented, most of the time you can find an async library
for your usecase (either librairies have adopted async/await or new librairies were born to fill the gap).

However when building a new API, most of the time I don't go for async by default !

# 📚 Async/await TLDR 
Async/await is a very efficient way to run IO-bound code concurrently.
Note that concurrency means that your are able to overlap the execution of functions on a single thread, 
which is different from parralelism where you can execute multiples things at the same time on different threads.

Async/await works by running an event loop, which is basically a task scheduler (understand: a big loop) that will decide which task to run next.
When a task is picked by the event loop, it starts and run until it reach an `await`statement. This indicates that the task
will perform some IO and the control can be yielded back to the event loop. The event loop is able to run another task while waiting for the first task's IO to finish.
You can take a look  at [this post](https://jacobpadilla.com/articles/recreating-asyncio) to understand more how the event loop works by creating 
 a dummy event loop based on generators !

This form of concurrency is called cooperative multitasking, meaning each task/functions needs to cooperate
and yield back execution to the scheduler (event loop) for it to work well.

Note that in both async and thread concurrency, if your tasks are CPU bounded, you'll be limited
by the GIL (but this might change in python 3.13, see [here](https://docs.python.org/3.13/whatsnew/3.13.html#free-threaded-cpython))

# ⚡️ FastAPI

In the context of FastAPI, you can choose whether your endpoint are async or not, and FastAPI will automatically
execute the async function on the event loop and the sync one in a threadpool ! To define the endpoint, simply use `async def`or a regular `def`:

```python
@app.get("/")
async def root():
    return {"message": "Hello World"}

# Or

@app.get("/")
def root():
    return {"message": "Hello World"}
```

# 🚦 Blocking the event loop

When choosing async functions in FastAPI, you are effectively using cooperative multitasking. While this means
you can handle IO very effectively and scale to ten/hundred of request per second on a server, the downside is that every task needs to cooperate to
achieve this level of concurrency. Practically, every new endpoint you write can block the event loop if you're not careful.

This can happen for several reason, for example if you do synchronous IO:

```python
@app.get("/")
async def root():
    # This will block the whole app for the time fo the request
    res = requests.get('https://example.com/some_url')
    return {"result": res}
```

Or if your code call `time.sleep` 

```python
@app.get("/")
async def root():
    # Easy to spot here but might be much more difficult in a large codebase
    time.sleep(3) 
    return {"message": "Hello World"}
```

But also if you have some CPU-bound function that might run for a few seconds:

```python
@app.post("/")
async def compute_user_history(user_ids: int):
    res = {}
    # The whole loop will block the event loop 
    # as we only store the result after the loop
    for user_id in users_id;
        res[results] = compute_user_history()
    await store(results)
    return 
```

And some innoncent looking code like a regex can also be CPU intensive:

```python
@app.get("/")
async def extract_info():
    # A long regex that can potentieally block the event loop
    res = re.findall(some_complex_regex, large_text)
    return {"results": res}
```

This also mean that every dependency you add in your code is also a liability. Even if the library is not supposed to do IO,
if there's somewhere down the code a call to `time.sleep` or if it's reading/loading some values from a file, you'll be doing
synchronous IO blocking the event loop. You can argue that these are bad practice and should be fixed in the library, and you're probably right !
But the bottom line is that you don't really know if the call is doing any of that without going through the code itslef.
And this breaks the "functional abstraction" that you normally get when calling a function.

```python
@app.get("/")
async def root():
    some_library.some_method()
    return {"message": "Hello World"}
```


FastAPi does provide the `fastapi.concurrency.run_in_threadpool` method which can helps in this situation (but it doesn't seem to be documented [yet](https://github.com/tiangolo/fastapi/issues/1066):

```python
@app.get("/")
async def root():
    run_in_threadpool(synchronous_code)
    return {"message": "Hello World"}
```


<!---
# Testing

Another
The two m ain
Blocking the event loop is not something you easily catch in unit/integration tests as you are usually not running
a large number of request.

No easy way to shift left and detect this earlier than in production oer in perofrmance test
+ you need to async all your tests

-->
# 🤝 The Trade off

IMO async/await trade local complexity for global complexity. It's easier to read/write async function but
the system as a whole become much more complex. In most case, I prefer to start a project in "sync mode" with FastAPI
to avoid premature optimization. This make sense especially when you value velocity of development over performance.
This is often the case when doing Business-to-Business apps where the number of client of your applications is lower and the value relies 
more in the feature and specialization. And I can always improve performance for some endpoint later down the road if needed.
This seems to be algined with the opinion with of FastAPI's creator according to [this discussion](https://github.com/tiangolo/fastapi/discussions/3099#discussioncomment-5179960)

I wonder if it would be possible to have some kind of async/await concurrency without the limitation of cooperative multitasking.
Whether it could be to statically detect functions blocking the event loop or having a timeout if the function runs for longer than some time but I don't see
how this could be done.

The concurrency model of Golang seems to be a pretty good trade-off, goroutines are very light thread managed by the golang runtime.
Goroutines are cheap to create and context switch is managed by the go runtime which automatically switch when the code blocks on system calls (which means any IO).

In some way it looks quite similar to spawning a threadpool and throwing async function to run there,
if you don't take into account the CPU limitation due to the GIL and the fact the OS will manage teh context switching instead of the runtime.


And that's it, see ya 👋




