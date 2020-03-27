---
layout: post
title: "My Most Terribly Clever(ly&nbsp;Terrible) Code"
description: >
  When I was young and naive I tried to write very clever code. Here is the
  worst example.
image: /files/patterns/biologia_centrali_americana_coronella_annulata.jpg
image_alt: >
  A drawing of a red, black, and yellow milk snake from Biologia Centrali
  Americana.
categories: coding
---

{% include lead_image.html %}

I started learning C++ after five years of writing Python. I thought I wrote
pretty good code,[^1] and like all new programmers I enjoyed finding clever
solutions to problems. Unfortunately I was a bit too clever sometimes.

## The Problem

For one problem I had to handle setting some state based on two variables,
each variable could take one of a few discrete values. For simplicity we can
think of the variables as `destination` which can take values `{north, east,
south, west}` and `travel_mode` which can be `{airplane, car, bike}`. All
twelve combinations required doing different processing, so at some point I
wrote something like:

```cpp
if (destination == "north" && travel_mode == "bike") {
  do_north_bike_stuff();
}
else if (destination == "north" && travel_mode == "car") { 
  do_north_car_stuff();
}
else if ( ... ) { 
  ...
} ...
```

This code wasn't clever; it was boring and repetative! But I had recently
learned about a cool way to rewrite `if/else` in C++: the `switch` statement.
I was itching to use it.

## Making It Worse

But a `switch` statement needs integral values, so I had to map each
variable's states to numbers. Easy enough, but I quickly ran into a problem: I
had to switch based on both values, so I had to combine the integers in some
manner. Then I remembered a "useful" math fact: the [product of unique primes
is itself unique][fta].[^2] A horrible plan came together, it looked like this:

[fta]: https://en.wikipedia.org/wiki/Fundamental_theorem_of_arithmetic

```cpp
int NORTH = 2;
int EAST = 3;
int SOUTH = 5;
int WEST = 7:

int BIKE = 11;
int CAR = 13;
int PLANE = 17;

switch(destination * travel_mode) {
  case NORTH * BIKE:  do_north_bike_stuff(); break;
  case EAST  * BIKE:  do_east_bike_stuff(); break;
  ...
  case WEST  * PLANE: do_west_plane_stuff(); break;
}
```

My code was actually even worse. I did not assign nice readable variables like
`NORTH` but just used the numbers, so it looked like `case 2 * 11:
do_north_bike_stuff()`.

This code is **way** too clever; needing number theory to understand
control flow should be a _huge_ warning sign. With ten years more experience,
I actually prefer the verbose but understandable `if/else` method.

## A Better Way

I think a hybrid method is actually the way to go, using `enum` and a few
helper functions:

```cpp
enum TravelMode { BIKE, CAR, PLANE };
enum Direction { NORTH, EAST, SOUTH, WEST };

switch(travel_mode) {
  case BIKE:  do_bike_stuff(direction); break;
  case CAR:   do_car_stuff(direction); break;
  case PLANE: do_plane_stuff(direction); break;
}

void do_bike_stuff(Direction dir) {
  switch(dir) {
    case NORTH: ...; break;
    case EAST: ...
    ...
  }
}
```

This has a few nice advantages:

- It delegates the complexity of handling the direction to each travel mode.
This is logical because it's likely the way a car handles East and West are
very similar, and very different from how a plane would.
- By using `enum` the compilier can check that we handle every case. If we
forget `case BIKE` or `case EAST`, the compilier can warn us.

---

[^1]: _Narrator_: He didn't.
[^2]: _Narrator_: It was not useful.
