---
title: "Ports and Adapters"
date: 2022-02-06T10:41:33+01:00
draft: true
---

One of the most interresting outcome of implementing Clean Architecture is in my opinion the Dependency Inversion principle.
Which is to put it shortly, to treat your database as an external system and encapsulate communication to it through a
interface. 


The Port and Adapter pattern is at the root of this and we'll show a quick example on how to do it in moden python and
with duck typing.

