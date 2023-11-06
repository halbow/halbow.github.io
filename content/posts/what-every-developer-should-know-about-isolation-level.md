---
title: "What Every Developer Should Know About Database Isolation Level"
date: 2023-08-26T12:28:39+02:00
draft: true
---

The goal of this blog post is to explain in the different islation level with simple programmatic example.
From my experience, most junior developers are not very familiar with this concept and just use the isolation level set by default form the database they use.
While this is fine most of the time this can reserve some surprise as different database might use different default isolation level which reuslt in different
behvior out of the box.

# Transaction 101



```
CREATE TABLE jobs(
   id INT AUTO_INCREMENT,
   status VARCHAR(100),
   start_date DATETIME,
   end_date DATETIME,
   PRIMARY KEY(id)
);
```



# I in ACID 🧪 

I stand for Isolation in the famous ACID acronym used to describe database property.
The four level of transcation isolation are 
* Read un-commited
* Read comitted
* Repeatable read
* Serializable
