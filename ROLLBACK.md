## Why???
This update is for the final project in my Workstation and Server class, where we had to make something pertaining to networking. I'm not gonna write a paper, or do some boring Windows server crap; so I said naively: "Yeah, rollback should be easy enough to implement! I can do it in, like, a week; just like I made this fighting game in three days!" 

How foolish I was.


## What is Rollback
*(NB: this explanation may not be entirely correct)*

First, let's talk about netcode. Essentially, in fighting games, there are two different types of netcode (multiplayer infrastructure): *delay-based* and *rollback.* 

### Delay-Based Netcode
**Delay-based netcode** delays game execution until both sides recieve each others' inputs. This can make a fighting game feel sluggish (especially at higher pings)! This is especially poor (and why a lot of fighting game players *hate* delay-based netcode) because your inputs are delayed (*and* imprecise!).

### Rollback Netcode
**Rollback netcode** is a relatively recent development in fighting game online netcode (if you consider the '10s to be recent). Rollback makes inputs relatively *client-authoritative*; basically, we *don't* wait for the opponent's new inputs to be reaching us. Instead, we will predict what the opponent will do by assuming that their inputs will remain the same until we're told otherwise. If there's an issue, we'll roll back (see?) the state to match with the opponent.

## Implementing Rollback
### Initial Idea
My original idea was to gravitate towards [godot_ggpo](https://github.com/FlutterTal/godot_ggpo) (because I knew about GGPO before; GGPO is a rollback library by the people who came up with it), but that didn't get updated in a long time (and you have to use a custom editor!), so that idea was nixed. Then I found [godot-rollback-netcode](https://gitlab.com/snopek-games/godot-rollback-netcode), a Godot addon, which also conveniently had a tutorial series.

### Lobby System (`MultiplayerUI`)
I wanted to start getting my feet wet in Godot's multiplayer systems by making a basic text chat system (which ended up being a lobby system). Eventually, this work ended up frontloading a lot of the synchronization and game loading code in `ui/MultiplayerUI.gd` (so the file is a little bloated).

Basically, the lobby flows as follows:
1. The user chooses whether to host or to join a host (act as client).
2. The user enters their username.
3. *(Either users may send BM in chat at this point.)*
4. Both users start the ready-up sequence.
5. Once both users are ready, a synchronized countdown starts.
6. Game logic is stopped as the `Arena` is loaded.
7. Once it is known that both players are loaded, the game can start, and game logic resumes.

I ended up rewriting a few things as far as how the player data was loaded later in the development of the `MultiplayerUI` to use a custom class named `PlayerInfo` so that I could use each player's usernames during gameplay. That shot me in the foot about 2\~3 hours of work (because objects do not play nice over remote procedure calls!).

I made a big issue here by working so much on the lobby system, which took about a week of my work. But hey, at least it's pretty robust right? Right?

### Implementation
Turns out when you use a well-documented addon with tutorials, a lot of things can go quite smoothly. However, some rewrites had to happen.

#### Non-Rollback-Related Changes
The biggest change was that the local player should be controlling their fighter, not their opponent's; so, a rewrite happened to that code to define a "controller" of each `Entity` (the character being controlled) as opposed to the player number (which used to be synonymous with the controller, as P1 keys would control P1, and same for P2). This change happened both in `Entity` and in `ComboController` (which creates combos from inputs).

Some new setters and getters were added for gameplay-related classes (since there was a *lot* that needed to be passed around now).
I also added a text box to show some data so that I could visually inspect some bugs.

#### Rollback-Related Changes
Most of the work that went into it was: "Ok, let's shove all our input into `_get_local_input()`, push all of our necessary state into `_load` and `_save_state()`, then move all of our `_process()` work into `_network_process()`." Of course, there were many, many small bugs that arose from just doing this. You can't just move all the code over and expect it to work.

I started porting over the `Entity` and then the `PlayerEntity`. At this point, I needed to also port over the `ComboController`, then finally `Hitbox`es were last. Doing it one at a time and gingerly stepping around to see what broke definitely took some extra time out of my work.

The addon also adds in some extra rollback-aware nodes (one for the `AnimationPlayer`, which plays animations, and another for the `Timer`, which is a timer), so it wasn't a *big* hassle moving those over (except for the fact that the timer uses ticks instead of seconds).

Currently, I'm not sure if the `AnimationTree` (which is what I use for dynamically switching the animations for attacks and holding a little bit of state) really plays nice in rollback, but I didn't port that over to handle rollback (which would probably be a good idea). However, porting that over would probably also require porting the 20-some-odd resources that the `AnimationTree` uses for nodes over to rollback, and that wasn't really in scope (nor did I have the time for it).

So now that we have state implemented in rollback and inputs being sent, what now?

## Pitfalls
Yeah, turns out it's not all sunshine and roses. We're *technically* using rollback, but we're not performing best practices.

We're not supposed to use function calls in  animations as it might duplicate or simply miss function calls due to a rollback (or fast-forward). Attack animations use this for spawning hitboxes.

Technically, we're not doing any prediction, which leads to state mismatches. Currently, the worst offenders are jumping and hitstun. 
- **Jumping:** I don't really know, but rollback requires you to be deterministic (same output given same input), and I'm not sure if the physics collision system is really deterministic. Not sure how really to fix this.
- **Hitstun:** If the spawning of a hitbox happens a frame or two different than your peer, can cause state mismatches for every tick that the player is in hitstun. This leads to a disconnect when you perform the fireball (because the hitstun is so long).

Therefore, I think I need to create a more robust prediction system so fewer state mismatches happen; however, I don't have time for that right now.

Additionally, there was this really cool and awesome bug that happened when I added rollback frames for testing (testing robustness), which made it so that when state was changed, it would immediately rollback. For example, a player might take damage. This changes the health variable in one tick. The next tick, since the opponent may not have gotten the health change yet, the health value rolls back, so no health is lost. Same happens for stun (and it used to happen for blocking inputs while performing an animation).

## Later Work
I could work on this later, because this is definitely not a very robust system. There's a lot that could be worked on as far as UX is concerned as well (like rematching), but I genuinely don't have time for it for this project.