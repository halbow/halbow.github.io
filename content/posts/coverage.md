---
title: "100% coverage or not"
date: 2024-05-01T08:10:43+02:00
draft: false
---

#  🧵The debate

Whether targeting 100% coverage is worth it or not has been a long discussion in Software Engineering.
For some people it's very well worth the time to test everything while some other argue that it's
not worthwile to invest that much time and that some 80% or 90% is good enough. While it's clearly
a significant amount of work to reach this kind of threshold on a legacy/non-trivial codebase, I recently
had to start a new project from scratch and asked myself the question: should I bother to aim for 100%
coverage or should I settle for an arbitrary threshold like 90% ? But before answering the question let's
discuss about coverage 🤓

# 📖 100% coverage is not the holy grail of testing

First thing we have to clarify is that most of the time, when a library or a application
claims to have 100% code coverage, they mean 100% line/statement coverage. What this means is that
the tests ran over all the line/statements in the codebase. The difference between a line and a statement 
is quite minimal, only in some case, this can make the computation of the percentage vary a bit, consider this example:

```python
def some_function(flag):
    do_something();print("Finished")
```

With statement coverage it will correctly notice that the tests run over (or didn't)
two statements and not only one line ! This has probably more impact in other language 
as in Python this pretty rare to arraneg code this way (and to use semi colon 😁)


## ⚠️ Limitations of (statement) coverage

While 100% statement coverage is nice, there's a few cases where it can have suprising result:

```python
def weird_div(flag=True):
    a = 0
    if flag:
       a += 1
    return 1 / a
```

This snippet will pass with 100% statement coverage if called with `weird_div()` but will fail if you call `weird_div(False)` !
With [coverage](https://coverage.readthedocs.io/en/7.5.0/) you can enable branch coverage to make sure your tests run over the main branches/paths of your code.
This will catch simple usecases like this where the code jumps conditionnaly over a few lines of code.


While 100% branch coverage is clearly indicates that you have a good coverage of the code, this doesn't mean
that the code is not buggy and unfortunately as soon as you start to have some more complex usecase, coverage will
not save you. You can find a bunch of example of the limitations of branch coverage [here](https://nedbatchelder.com/blog/200710/flaws_in_coverage_measurement.html).


# 💯 Why you should aim for 100% coverage report

The main reason I like to keep 100% branch coverage in my project (and enforce it in the CI) is not really for 
the existing codebase but for all the future code that will be written. When you settle for an arbitrary threshold 
like 80%, while this is a pretty good metric for the existing codebase, this means that you only require the new
code to be tested at 80%. A new merge request adding 100 statements that only tests 80 of it would be likely to pass this.

One could argue that 100% coverage is still un-neccessary work because maybe the engineer decided that it wasn't worth it 
to test these 2 functions and that with 100% coverage the engineer would spend time writing test just for the coverage to pass.
The problem with this is that you don't really know if it's a conscious choice or an oversight from the engineers when doing the review.
And if you do, you certainly won't in 6 months.

IMO the best of both world is 100% coverage **report**. This doesn't mean you have to test all the lines of code but that
you report needs to stay at 100%. With a big incentive to ignore all the lines/files/functions you don't
want to test. This means you don't have to spend the time writting useless tests to reach the coverage but you are forced
to think about it. And this make the choice not to test some function/part of the code explicit.



