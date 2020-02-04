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

I had just started learning C++ after five years of writing Python. I thought
I wrote pretty good code,[^1] and like all new programmers I enjoyed finding
clever solutions to problems. Unfortunately I was a bit too clever sometimes.

## The Problem

At one point I had to handle setting some state based on two variables, each
variable could take one of a few discrete values. Form simplicity we can think
of the variables are `destination` which can take values `{north, east, south,
west}` and `travel_mode` which can be `{airplane, car, bike}`. All twelve
combinations required doing different processing, so at some point I wrote
something like:

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

This code made me upset: it wasn't clever, it was boring. I had recently learned
about a cool way to rewrite `if/else` statements in C++, the `switch`
statement, and I was itching to use it.

## Making It Worse

But a `switch` statement needs integral values, so I had to map each
variable's states to numbers. Easy enough, but I quickly ran into a problem: I
had to switch based on both values, so I had to combine the integers in some
manner. Then I remembered a "useful" math fact: the [product of unique primes
is itself unique][fta]. A horrible plan came together, it looked like this:

[fta]: https://en.wikipedia.org/wiki/Fundamental_theorem_of_arithmetic

```cpp
int NORTH = 2;
int EAST = 3;
int SOUTH = 5;
int WEST = 7:

int BIKE = 11;
int CAR = 13;
int PLANE = 17;

switch (destination * travel_mode) {
  case NORTH * BIKE: do_north_bike_stuff(); break;
  case EAST * BIKE: do_east_bike_stuff(); break;
  ...
  case WEST * PLANE: do_west_plane_stuff(); break;
}
```

This is **way** too clever; needing number theory to understand
control flow should be a *huge* warning sign. With ten years more experience,
I actually prefer the verbose but understandable `if/else` method.

## A Better Way

---

[^1]: **Narrator**: He didn't.
