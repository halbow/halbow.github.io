---
title: "Is 100% coverage worth it ?"
date: 2024-06-14T08:10:43+02:00
draft: false
---

#  🧵The debate

The debate over targetting 100% code coverage has long divided software engineers.
Some believe it's worth the time to test everything while others argue that aiming
80% or 90% is sufficient. Achieving such high coverage is clearly a significant amount of work, especially
on a legacy/non-trivial codebase. I recently had to start a new project from scratch and asked myself the question:
should I bother to aim for 100% coverage or should I settle for an arbitrary threshold like 90% ?

But before answering the question let's discuss about coverage 🤓

# 📖 100% coverage is not the holy grail of testing

First, let's clarify that when a library or a application claims 100% code coverage, 
it typically means 100% line or statement coverage. This means the tests execute every line/statements in the codebase.
The difference between a line and a statement is usually minimal, consider this example:

```python
def some_function(flag):
    do_something();print("Finished")
```

Statement coverage recognizes that two statements, not just one line, are executed ! This distinction
can slightly affects the coverage percentage, though it's rare in Python due to the infrequent use of semicolons 😁 ! 

## ⚠️ Limitations of (statement) coverage

While 100% statement coverage sounds great, it has limitations. Consider this example:

```python
def weird_div(flag=True):
    a = 0
    if flag:
       a += 1
    return 1 / a
```

Running `coverage` on this snippet will pass with 100% statement coverage if called with `weird_div()`. But if you run the test with
`weird_div(False)`, not only you will not reach 100% coverage but the test will fail as well 😅 !
With [coverage](https://coverage.readthedocs.io/en/7.5.0/) you can enable branch coverage to make sure your tests run over the main branches/paths of your code.
This will catch simple usecases like this where the code jumps conditionnaly over a few lines of code.


While 100% branch coverage can indicate that you have a good coverage, if doesn't mean the code is bug free and 
unfortunately as soon as you start to have some more complex usecase, even branch coverage will not save you.
You can find a bunch of example of the limitations of branch coverage [here](https://nedbatchelder.com/blog/200710/flaws_in_coverage_measurement.html).

# 💯 Why you should aim for 100% coverage report

One common argument against 100% coverage is that it might not be the best use of an engineer's time,
potentially leading to the creation of unnecessary tests. Engineers might want to intentionally skip testing certain functions if they think it's not worth it.
The issue with this approach is that you cannot tell easily if this was a deliberate choice or an oversight.
Six months later, it’s unlikely anyone will remember the reasoning behind these decisions.

The main reason I still like to keep 100% branch coverage in my project (and enforce it in the CI) is not really for 
the existing codebase but for all the future code that will be written. When you settle for an arbitrary threshold 
like 80%, while this is a pretty good metric for the existing codebase, this means that you only require the new
code to be tested at 80%. A new merge request adding 100 statements that only tests 80 of it would be likely to pass this.

The best approach, in my opinion, is to aim for a 100% coverage **report**. This doesn't mean testing every single line of code, 
but rather ensuring the overall report stay at 100% by explicitely ignoring the lines, functions, or file you choose to exclude from coverage.

This approach forces you to consider which parts of the code should be tested, makes the decision to ignore code explicit by documenting it in the code
and it ensures that you won't accept future code that is only 80% tested because of an arbitrary limit.

Another benfit is that it can help you remove useless code. If you write some code that you don't need yet,
you will see it in the coverage report and most of the time when asking myslef if I should test it or not, I ended
up removing the code altogether. Less code is always good 😁



