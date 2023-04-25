 ## What is This?
### Introduction
This is my final project for my Formal Languages and Finite Automata class, for which we were required to either a) write a paper or b) code something using what we learned in class. Since this course briefly covered Regex, I decided to make a small fighting game in Godot Engine ver. 3.4.2. 

I would like to say that this is the culmination of a month of hard work, but this is the culmination of about a week and a half of work and two full days of very hard game jamming amidst schoolwork.

This is game is not balanced at all. All the artwork was also done by me. You can find binaries on the [releases page](https://github.com/PistolRcks/flfa-project/releases).

### Structure
#### The `ComboController`
The first thing to get done was pretty much the one thing that meets the requirement for this assignment, which was the [`ComboController`](util/ComboController.gd). It handles translating keyboard/controller inputs into [numpad notation](http://www.dustloop.com/wiki/index.php/Notation), which is then run through a Regex to determine whether or not a combo was performed (yes I know that it's technically a motion input/command input, and "combo" is too general of a term, but I named it combo so that's how I will refer to it).

When a combo ends up being processed by the `ComboController`, it is then sent to the [`Entity`](entity/Entity.gd)---which is a playable ([`PlayerEntity`](entity/PlayerEntity.gd)) or nonplayable character---to have some state checks be run and then (if the `Entity`'s state is correct) play the animation corresponding with that combo.

#### `Entity` States
In a sense, the `Entity`'s main states (`stand`, `air`, `crouch`, `hitstun`, `blockstun`) do make a DFA-like structure (especially since they're represented in Godot's StateMachine animation node, which acts like a DFA). Although, Godot's StateMachine does allow you to teleport (which is kind of cheating, but whatever).

In short:
* The `stand` state is the starting state of the `Entity`; most combos will be performed from this state. Blocking in the `stand` state defends against `HIGH` and `MID` attacks, but not `LOW`s.
* The `crouch` state is performed by pressing down during the `stand` state. Blocking in the `crouch` state defends against `MID` and `LOW` attacks, but not `HIGH`s. Releasing down returns to the `stand` state.
* The `air` state is performed by jumping by pressing up. You cannot block in the `air` state. Landing on the ground returns to the `stand` state. (Currently this actually doesn't do anything other than making you lose your block privileges.)
* The `Entity` enters `hitstun` by being hit by an attack and not blocking, and remains there until the stun timer runs out. 
* The `Entity` enters `blockstun` by being hits by an attack while blocking, and remains there until the stun timer runs out. This amount of time is usually shorter than `hitstun`.

#### The `Combo`
[`Combo`](util/Combo.gd)s are read by the `ComboController` to check if a combo is performed. They also hold hitbox metadata. In a sense, they are just tuples which hold data. They also hold the compiled Regex query to check if it is performed. See its constructor (the `_init()` function) for more info.

#### The Basic Character
To show off the `ComboController`, a basic character (aptly named "[Punchy Guy](entity/fighters/punchy_guy/PunchyGuy.gd)") was made. His moves, quite frankly, are unbalanced as far as hitboxes and hitstun are concerned. Just... don't think about it that much. His `Combo`s serve as good examples of how the `Combo` class (and hitbox metadata) are constructed.

### Event-based Design Philosophy
A lot of the code is based around the idea of event-based design: the `ComboController` fires a signal when a combo is performed; the hurtbox emits a signal when an enemy hitbox enters it; etc. This design allows most of the code to remain separate and forgo baked-in relationships.

### What Else???
I'm not sure what other places might be of interest, but all mentioned classes are linked to their source code. I understand if you might not understand GDScript, but it is similar to Python, and most of the code is commented. There should not be too much issue as far as understanding the code is concerned, other than Godot Engine-specific things (for which you can look up the documentation).
