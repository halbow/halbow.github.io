---
title: "Syscall in Python"
date: 2024-01-09T19:04:32+01:00
draft: false
---



## What is a Syscall ? 🔎

Syscall are the main way for program to communicate with the Operating System. Program
usually run in userspace and are limited in the action they can do. For safety reason many low level
actions are handled by the kernel. As soon as you want to do something meaningful (print something to stdout, 
read something from a hard drive, send something on the network, etc) you have to make a syscall to communicat
with the kernel to do it.

## How to do a syscall in Python ? 🖊️

As for [everything in python](https://xkcd.com/353/), you can use the standard library for most usecase.
Let's say you want to use the [open syscall](https://man7.org/linux/man-pages/man2/open.2.html) to open a file,
you can do it via the `os` module:

```python
import os

fd = os.open(path="abc.txt", flags=os.O_WRONLY, mode=0o755)
```

The argument of the [os.open](https://docs.python.org/3/library/os.html#os.open) function match the 
documentation for the syscall, with the little help of a few variable like like `O_WRONLY` to avoid using plain integers
for flag. So the os module offers a nice interface for syscallls (more or less unified between Windows and Linux) 
but what can we do if we want to perform a syscall that doesn't have an interface in the `os` module ?

Lets look at how the `os.open` function is implemented to find out !


## We need to go deeper ⛏

If we try to take a look at the source code of `os.open` with Pycharm, it will show us a `posix.py` file but 
it's actually just a stub file that Pycharm create and uses for its IDE capabilities, no luck here.

```python
def open(*args, **kwargs): # real signature unknown
    """
    Open a file for low level IO.  Returns a file descriptor (integer).
    
    If dir_fd is not None, it should be a file descriptor open to a directory,
      and path should be relative; path will then be relative to that directory.
    dir_fd may not be implemented on your platform.
      If it is unavailable, using it will raise a NotImplementedError.
    """
    pass
```

The real implementation of `os.open` is a bit harder to find as it's actually implemented in C
as part of the python laguage. We can find the implemetation in [this file](https://github.com/python/cpython/blob/fda901a1ff94ea6cc338b74928acdbc5ee165ed7/Modules/posixmodule.c#L10552)
and as you can see, the function contains both low level integration with syscalls and handle logic different for different operating system.

## The usecase: Atomic file Renaming ☢️

But then is it possible to perform an arbitrary syscalls in Python ?

That's the the problem I encountered when trying to use `os.rename`
(which use the `rename` syscall under the hood) to ensure only one process is able to write a file/folder in a consistent way.
The idea is pretty simple, we basically write the file/folder in a temporary location, and then rename it to the destination file/folder
when we finished writing. 

                 +---------+               +---------+
                 | tmp.txt | ===rename===> | dest.txt |
                 +---------+               +---------+

As this code was running in the context of a background job (with eventual retry) I also wanted to make sure only
one process would succeed (in case where we end up with the same task executing twice in parallel) and thus
the rename operation has to be exclusive, meaning it will fail if destination file/folder is alreay existing.
This ensure that any process interruption will not leave with a file half written or a folder containing half of the file.

The problem is that this rename operation was not behaving how I expected: when using the [rename syscall](https://man7.org/linux/man-pages/man2/rename.2.html) 
(which is what happend when using [os.rename](https://docs.python.org/3/library/os.html#os.rename) in Python), it has different behavior when using it with file of folder:
+ With files, if destindation is present, it will overwrite the result (in an atomic way).
+ With folder, if destination is an empty folder, it will overwrite the result
+ With folder, if destination is a non-empty folder, it will raises a OSError !

In our case we want only one operation to succeed, so it will work correctly with folder but
it's not possible to to have an atomic rename for files using the `os.rename` which is exclusive, meaning it will not overwrite
the destination if it exists !

## The hero: renameat2 🦸

Fortunately, there's a solution that landed in the Linux kernel 3.15: the `renameat2` syscall&nbsp;!

Shortly, `renameat2` is a newer version of `rename` that accepts a flag
to overwrite or not the destination ! So it is possible to rename a file only if the destination
doesn't exists, which is exactly what we want ! The only problem is that it's no available anywhere in the Python standard library ...

Thankfully there's an easy way to make syscall in Python: the [ctypes](https://docs.python.org/3/library/ctypes.html)
library, which allows to call C functions in DLLS and shared libraries.

This means that with the `ctypes` module, we can easily call a function in the C standard library (libc) and get the result !
And libc has function wrapper for most syscalls, including the `renameat2` system call !
After a bit of googling to find documentation around flags, we can call like this:

```python
import ctypes
from os import strerror, fsencode

# load the shared librarie libc
libc = ctypes.CDLL("libc.so.6", use_errno=True)

# FLAF used for renameat2 syscall
RENAME_FLAG = 0
NOREPLACE_FLAG = 1
EXCHANGE_FLAG = 2

# This indicates the relative file descriptor if 
# src_path is relative but we use absolute path for simplicity here
_AT_FDCWD = -100

def rename(src_path: str, dst_path: str, flag: int):
    err = libc.renameat2(
        _AT_FDCWD,
        fsencode(src_path),
        _AT_FDCWD,
        fsencode(dst_path),
        linux_flag,
    )


```
But what if the syscall we want ot make is not available in libc ?

We can still make a syscall using the `syscall` function in libc and pass the syscall number !
Be aware syscall's number can change depending on your CPU architecture, here 
I hardcoded the number corresponding to my computer CPU arch but you probably don't want to try this without being 100% sure of which syscall you make !

```python
import os
import ctypes

libc = ctypes.CDLL("libc.so.6", use_errno=True)

get_pid_syscall_nbr_x86_64 = 39 

pid = libc.syscall(get_pid_syscall_nbr)

print(pid)
print(os.getpid())
```

## Why isn't this in standard lib ? 🧐

The `os.rename` function in the standard library could in theory be adapted to have the 
flag but according ot this [thread](https://discuss.python.org/t/extending-os-rename-to-support-file-swapping-and-whiteout/22257)
the main reason this is not included seems to be the cross-platform nature of Python, mainly it's not easy to add this
flag in a backward compatible way and have a clean interface for both windows and unix.


And that's it ! 🌯
Hope you learned something !



