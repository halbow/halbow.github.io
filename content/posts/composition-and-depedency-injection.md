---
title: "Composition and Depedency Injection"
date: 2023-11-06T19:55:21+01:00
draft: false
---

Back at Europython this year, I attended this very good [talk](https://www.youtube.com/watch?v=2qpW1-7TnzA) on composition by [Hynek Schlawack](https://hynek.me),
which clicked on many level with how I code nowadays. I was never a huge fan of oriented object programming and inheritance in particular. I really
recommend to watch the talk if you feel the same ! But I recently learned that when trying to apply composition together with dependency injection, things can become a bit more complex 😶

# 💼 The case

The usecase we had looked very similar to the example in the talk, a simplified verison would look like this:

```
class OutputConvertr(abc.ABC):
    @abc.abstractmethod
    def convert_file(self, working_dir: Path, file: str):
       raise NotImplementedError

    def convert_output(self, working_dir: Path):
        for file in os.listdir(working_dir):
            self.convert_file(working_dir, file)

class XmlConverter(OutputConverter):
    def convert_file(self, working_dir: Path, file: str):
        ... # any logic to convert a incomming file to XML

class CsvConverter(OutputConverter):
    def convert_file(self, working_dir: Path, file: str):
        ... # any logic to convert a incomming file to CSV
```


When seeing this example in code review, it really felt like we could apply almost exactly the same principle and re-write this like:

```
class FileConvertor(Protocol):
    def convert_file(self, working_dir: Path, file: str):
        ...

class XmlConverter:
    def convert_file(self, working_dir: Path, file: str):
        ... # any logic to convert a incomming file to XML

class CsvConverter:
    def convert_file(self, working_dir: Path, file: str):
        ... # any logic to convert a incomming file to CSV

class OutputConverter:
    def __init__(self, converter: FileConverter):
        self.converter = converter

    def convert_output(self, working_dir: Path):
        for file in os.listdir(working_dir):
            self.converter.convert_file(working_dir, file)

```
And it indeed feels much easier to reason about (at least IMHO) and there's a clear separation of concern for each class, 
FileConverter only needs to handle conversion of one file, and the OutputConvertor is agnostic to which type of conversion is done.
I was ready to add a suggestion to improve the code in this way when I realized that in our case, it would lead to some extra complexity ...

# 💉 Dependency Injection

We use dependency injection heavily in our codebase and most of our core logic looks like this (nothing out of ordinary if you are familiar with Clean Architecture and its principle):

```
class SomeUsecase:
    @inject
    def __init__(self, some_service: SomeService):
        self.some_service = some_service
    
    def execute(self, *args, **kwargs):
        pass

```
And in this case, the the design with inheritance makes it easier to have different usecase with different converter
as the dependency injection knows which class to inject directly:
``` 
class SomeUsecase:
    @inject
    def __init__(self, converter: XmlConverter):
        self.converter
    
     def execute(self, *args, **kwargs):
        ...
        self.converter.convert_output(working_dir)
        ...
    
class AnotherUsecase:
    @inject
    def __init__(self, converter: CsvConverter):
        self.converter                  

     def execute(self, *args, **kwargs):
        ...
        self.converter.convert_output(working_dir)
        ...

```
But playing with composition is a bit trickier to have as the `OutputConverter` class
cannot be instanciated easily by the Dependency Injector framework (we use [injector](https://github.com/python-injector/injector))
as it doesn't know which `FileConveter` to use and even if it did,
it would need to bind multiple implementation of the same interface for each converter

```
from injector import inject

class SomeUsecase:
    @inject
   # Not as obvious on how specify the type here
    def __init__(self, converter: OutputConverter):  
        self.converter

     def execute(self, *args, **kwargs):
        ...
        self.converter.convert_output(working_dir)
        ...
```
The main workaround I found to tackle this is to make the `Converter` class generic:

(We can use the [new syntax for generic](https://peps.python.org/pep-0695/) introduced in Python 3.2 😎)
```
class OutputConverter[T: FileConvertor]:
    def __init__(self, converter: T):
        self.converter = converter

    def convert_output(self, working_dir: Path):
        for file in os.listdir(working_dir):
            self.converter.convert_file(working_dir, file)
```


And ideally we could use it in our usecase like this:

```
class SomeUsecase:
    @inject
    def __init__(self, converter: OutputConverter[XmlConverter]):  
        self.converter

     def execute(self, *args, **kwargs):
        ...
        self.converter.convert_output(working_dir)
        ...
```

Unfortunately it's not something supported yet with the injector library (see [here](https://github.com/python-injector/injector/issues/175)) and
the only way I foudn to make ti work require quite a bit more code: we have to implement explicitely a class for each `Converter` type and we have 
to manually add it to the injector's binder (again for each converter type):
```
class XmlOutputConverter(OutputConverter[XmlConverter]):
   pass

binder.bind(XmlOutputConverter, OutputConverter(XmlConverter()))

class SomeUsecase:
    @inject
    def __init__(self, converter: XmlOutputConverter):
        self.converter

     def execute(self, *args, **kwargs):
        ...
        self.converter.convert_output(working_dir)
        ...
```

While this works, it starts to feel a bit more complicated than the solution using inheritance so we ended up
keeping the inheritance deisgn, maybe we'll refactor if generics ends up being supported in Injector !

And that's all, see you next time 😊

