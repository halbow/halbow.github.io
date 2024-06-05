---
title: "Why I still write Synchronous APIs"
date: 2024-05-02T08:18:36+02:00
draft: true
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

In the context of FastAPI, you can choose whether your endpoint are async or not by simply
defining either an `async def`or a regular `def` for you endpoint:

```python
@app.get("/")
async def root():
    return {"message": "Hello World"}

# Or

@app.get("/")
def root():
    return {"message": "Hello World"}
```

Async function will run within the event loop while sync function will run in a threadpool (thanks to asyncio support of run_in_thread)

When choosing async functions in FASTPI, you are effectively using cooperative multitasking. While this means
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


This also mean that every dependency you add in your code is also a liability.
 Even if the library is not supposed to do IO,
if there's somewhere down the code a call to `time.sleep` or if it's reading/loading some values from a file, you'll be doing
synchronous IO blocking the event loop. You can argue that these are bad practice and should be fixed in the library, and you're probably right !
But the bottom line is that you don't really know if the library is doing any of that without going through the code itslef.
And this breaks the "functional abstraction" that you normally get when calling a function.

```python
@app.get("/")
async def root():
    # 
    some_library.some_method()
    return {"message": "Hello World"}
```


FastAPi does provide the `fastapi.concurrency.run_in_threadpool` method which can helps in this situation (but it doesn't seem to be documented [yet](https://github.com/tiangolo/fastapi/issues/1066)

# Testing

The two m ain
Blocking the event loop is not something you easily catch in unit/integration tests as you are usually not running
a large number of request.

No easy way to shift left and detect this earlier than in production oer in perofrmance test
+ you need to async all your tests

# Conclusion: The Trade off

IMO async/await trade local complexity for global complexity. It's easier to read/write async function but
the system as a whole become much more complex. In most case, I prefer to start a project in "sync mode" with FastAPI
to avoid premature optimization. This make sense especially when you value velocity of development over performance.
This is true in most B2B usecases where the number of client of your applications is not that big and the value relies 
more in the feature and specialization. And I can always improve performance for some endpoint later down the road if needed.

# Conclusion

I wonder if it would be possible to have some kind of async/await concurrency without the limitation of cooperative multitasking.
Whether it could be to statically detect functions blocking the event loop or having a timeout if the function runs for longer than some time bbut I don't see
any way of doing this
 ? timeout if a function doesn't yeild execution for X ms/statements ?


The concurrency model of Golang seems to be a good tradeoff, goroutine are very light thread managed by the golang runtime.
Goroutine are cheap 
whcih is some way is quite close to spawnign a threadpool and throwing async funciton to run there ?



