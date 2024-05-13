---
title: "Sync first"
date: 2024-05-02T08:18:36+02:00
draft: true
---


Async programming in Python had a lot of attraction in the recent years. Python 3.4 
was released in 2014 and added the asyncio module ! This enabled a great way to write 
async code but came with a new syntax and most libraries that wanted to be compatible
had to undergo a big rewrite to enable this. You can check the great post [What color is your function](https://journal.stuffwithstuff.com/2015/02/01/what-color-is-your-function/)
to understand why. We're now ten years after the first asyncio release, and while
the ecosystem still feels a bit fragmented, most of the time you can find an async library
for your usecase (either librairies have adopted async/await or new librairies were born to fill the gap).

# 📚 Async/await TLDR 
In short, async/await is a very efficient way to run IO-bound code concurrently.
Note that concurrency means that your are able to overlap the execution of function on a single thread, 
which is different from parralelism where you can execute multiples things at the same time on different thread.

Async/await works by running an event loop, which is basically a big loop that will decide which function to run next.
When a function, let's call it function A, is picked by the event loop, it starts and run until it reach an `await`statement. This indicates that the function
will perform some IO and the control can be yielded back to the event loop. The event loop is able to run another function while waiting for function A IO to finish.
This form of concurrency is called cooperative multitasking, 

# FastAPI

# The good

# The bad

Every new endpoint you write can potentially block the event loop.
Every dependency you add: is there any code that is performing IO ? doing CPU tasks that could last for a few seconds

+ async/await all you tests

# The trade off

Would it be possible to have async/await without thie ? timeout if a function doesn't yeild execution for X ms/statements ?

local complexity vs global complexity

I prefer to refactor a succesful service (or a subset of endpoint) to async
than to switch to everything async by default



