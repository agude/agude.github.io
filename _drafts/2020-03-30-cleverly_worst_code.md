---
layout: post
title: "My Terribly Clever(ly&nbsp;Terrible) Code"
description: >
  When I was young and naive I tried to write very clever code. Here is one of
  the worst examples.
image: /files/worst-code/montreal_light_head_and_power_consolidated_linesmen_1928.jpg
image_alt: >
  A black and white photo of three linesmen repairing a tangle of overhead wires.
categories: coding
---

{% capture file_dir %}/files/worst-code/{% endcapture %}

{% include lead_image.html %}

I started learning C++ after having written Python for five years, so I
thought I was pretty good at writing code and thinking through problems.[^1]
Like all new programs I enjoyed finding clever solutions to problems;
sometimes too clever. This is the story of one of those times.

## The Problem

I had to handle setting some state based on two variables. Each variable could
take one of a few discrete values. For simplicity, think of the variables and
possible values:

| Variable Name | Possible Values                  |
|:--------------|---------------------------------:|
| `direction`   | `north`, `east`, `south`, `west` |
| `travel_mode` | `bike`, `car`, `airplane`        |

All twelve combinations required doing something slightly different, so the
first code I wrote looked something like this:

```cpp
if (direction == "north" && travel_mode == "bike") {
  do_north_bike_stuff();
}
else if (direction == "north" && travel_mode == "car") { 
  do_north_car_stuff();
}
else if ( ... ) { 
  ... // etc.
}
```

This code wasn't clever; it was boring and repetative so I looked for a way to
rewrite it! I had recently learned about a cool way to replace [`if/else`][if]
in C++: the [`switch`][switch] statement. I had to use it!

[if]: https://en.cppreference.com/w/cpp/language/if
[switch]: https://en.cppreference.com/w/cpp/language/switch

## Making It Worse

But a `switch` statement needs integral values, so I had to map each state to
numbers. Easy enough, but I quickly ran into a problem: I had to switch based
on both values, so I had to combine the integers in some manner. Then I
remembered a "useful" math fact: the [product of unique primes is itself
unique][fta].[^2] A horrible plan came together, it looked like this:

[fta]: https://en.wikipedia.org/wiki/Fundamental_theorem_of_arithmetic

```cpp
int NORTH = 2;
int EAST = 3;
int SOUTH = 5;
int WEST = 7:

int BIKE = 11;
int CAR = 13;
int PLANE = 17;

switch(direction * travel_mode) {
  case NORTH * BIKE:  do_north_bike_stuff(); break;
  case EAST  * BIKE:  do_east_bike_stuff(); break;
  ... // etc.
  case WEST  * PLANE: do_west_plane_stuff(); break;
}
```

My code was actually even worse; if you are morbidly curious I [archived it
here][code]. I did not assign nice readable variables like `NORTH` but just
used the numbers, so it looked like `case 2 * 11: do_north_bike_stuff()`.

[code]: /blog/cleverly-worst-code/the-code-itself/

This code is **way** too clever; needing number theory to understand
control flow is a _huge_ warning sign. With ten years more experience, I
actually prefer the verbose but understandable `if/else` method.

## A Better Way

I think a hybrid method is actually the way to go, using [`enum`][enum][^3]
and a few helper functions:

[enum]: https://en.cppreference.com/w/cpp/language/enum

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
    case EAST: ...; break;
    ... // etc.
  }
}
```

This has a few nice advantages:

- It delegates the complexity of handling the direction to each travel mode.
This is logical because it's likely the way a car handles East and West are
very similar, and very different from how a plane would.
- By using `enum` the compilier can check that we handle every case. If we
forget `case BIKE` or `case EAST`, the compilier can warn us.

In the end, readable is better than clever, even if you have a bunch more
lines to read!

---

[^1]: _Narrator_: He didn't.
[^2]: _Narrator_: It was not useful.
[^3]: See [_Python Patterns: Enum_][enum_post], which covers use-cases for `enum` in Python. It works essentially the same in C++.

[enum_post]: {% post_url 2019-01-22-python_patterns_enum %}
