---
title: "Upgrade Your Test Skills"
date: 2023-01-30T17:56:19+01:00
draft: true
---

When you have a bit of code and you want to implement some tests for it you have quite a few options.
Beside choosing the type of test you'de like to do, you also have a few different technique/solution to implement them.
In this post I will keep things fairly siple and assume this defintion of tests:
- Unit test: tests that are not doing any kind of IO
- Integration test: tests that are doing IO/interacting with external stuf/code
- 
When implementing tests for your code/application, you have quite a few different way
Testing is


Let's take a simple example and see how we can test it:
```
import httpx

def get_list_of_stuff():
    url = "https://example.com"
    data = httpx.get(url).text
    data = data.replace("domain", "text")
    data = data.replace("Domain", "Text")
    with open("result.txt", 'w') as f:
        print(data, file=f)
```

# Patching

Patching will dynamically replace an object with another. You can use it to modify/replace part of your code that you don't want to test.


# Test Double

## Mock

## Spy

## Fake

## Stubs




## Second post ?

I have personnal preference of avoiding patch and favorising implementing fake as I think that they have quite a few advantages.
It's true taht it require a bit more work upfront but I have the feeling it pays back as it for

But this is rather a subjective feeling and I wondered if we can objectively measure any difference/improvements.
So let's try a (very scientific 😁) little experiment here and let's try to implement the different kind of tests of a sample project
and see how easy it is to implement, maintain, etc.

I'd like to try on a simple twitter-like application with two different kind of application/architecture. A more simple/CRUD like Django app
and a FastAPI one using a bit of clean clean architecture principle. Then implement a sample tests using the different kind of tests we discussed previously 
and compare the effort, loc, etc. Next I'd like to implement a few changes/updates to the codebase and see how it reflects to the tests code.
Will some be easier to test/adapt ? Let's find out🕵️





