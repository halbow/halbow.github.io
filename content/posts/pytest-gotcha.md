---
title: "Pytest Gotcha"
date: 2022-01-19T17:43:08+01:00
draft: false
---

[Pytest](https://docs.pytest.org/en/6.2.x/) is a great library and has become my default choice for any testing I have to do in Python.
It's really easy to start with it, just create some function starting with `test_` containing  some assert inside a file and run pytest on this file.
Pytest will auto-discover the test function and run it, providing a detailed explanation in case of failure !

However, there's one small pitfall I noticed several times during code review, which is the following usage:

```
def complex_function(state, arg):
    if arg < 1:
        raise ValueError()
    else:
        state["new_entry"] = 42


def test_complex_function_failure():
    state = {}
    with pytest.raises(ValueError):
        complex_function(state, 0)
        assert state == {}
```
Basically what we are trying to do here is to test that some function is correctly raising a ValueError when we pass an invalid parameter 
and we want to ensure that the state is not changed. Now let's consider that we do a mistake during a refactoring and the code ends up looking something like that:
```
def incorrect_function(state, arg):
    state["new_entry"] = 42
    if arg < 1:
        raise ValueError()
    
    
def test_complex_function_failure():
    state = {}
    with pytest.raises(ValueError):
        incorrect_function(state, 0)
        assert state == {}
```
So now in our newly refactored function, even when the passed value is incorrect we have a side effect and we modify the state.
Thankfully, we will catch it with our unit-test suite right ... ?
*Not really !* The test will pass happily despite the state being modified ! So what is happening here ?

This is actually [documented](https://docs.pytest.org/en/6.2.x/reference.html?highlight=raises#pytest-raises) but can be easily missed:
the assert is actually never evaluated as it is inside the `pytest.raises` context manager but after the line raising the exception.
The fix is quite easy and is to move the assert out of scope of the context manager:
```
def incorrect_function(state, arg):
    state["new_entry"] = 42
    if arg < 1:
        raise ValueError()


def test_complex_function_failure():
    state = {}
    with pytest.raises(ValueError):
        incorrect_function(state, 0)
    assert state == {}
```
# But why ? 🕵️
To understand a bit more what is happening, we have to understand how context managers are working.
If we look at `pytest.raise` [source code](https://github.com/pytest-dev/pytest/blob/828fde1156ba87e3f2d3850ffc64a3f4d9455ebd/src/_pytest/python_api.py#L934),
we see that is quite a classic implementatin of a context manager with a class defining both `__enter__` and `__exit__` methods.
Context manager's `__exit__` method have a quite interresting [behavior](https://docs.python.org/3/library/stdtypes.html#contextmanager.__exit__):
if the return value is True (or truthy), it will supress any exception raised. And it's exactly how the `pytest.raises` method
is implemented, it will check that there's an exception and that it's the correct type (which we can verify the the `exc_type` argument) and will fail the test otherwise.

## Syntactic sugar

The last bit of information we need to have a complete picture is that context manager's implementation in Python is a syntactic sugar of a try/except block.
I highly recommend this [article](https://snarky.ca/unravelling-the-with-statement/) by Brett Cannon (and the whole serie about Python's syntactic sugar) to understand Python's statement more deeply !

Now Let's take back the example from the beginning containing the gotcha and simplify it a bit:
```
with pytest.raises(ValueError):
    raise ValueError()
    assert False
```
And if we unwrap the context manager' syntactic sugar, it becomes quite clear that the assert is dead code and will never be reached !
```

context_manager = pytest.raises(ValueError)
pytest_raise_enter = context_manager.__enter__
pytest_raise_exit = context_manager.__exit__

# We don't really use the ExceptionInfo returned by pytest
_ = pytest_raise_enter()

try:
    raise ValueError
    assert False  # Our assert is dead code !
except:
    if not pytest_raise_exit(*sys.exc_info()):
        raise
else:
    pytest_raise_exit(None, None, None)
```

## That's a wrap 🌯

And that's it for today ! And just to be clear, I absolutely recommend pytest as a test library, it's great 🚀

I hope you learned something !
