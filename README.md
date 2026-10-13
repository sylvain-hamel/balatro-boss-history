# Boss History

A Balatro mod that shows the boss blinds you've faced in the current run.

Press **O** at any time during a run (blind select, shop or mid-round). A
panel lists each boss fight, ante by ante:

| Column | Meaning |
|---|---|
| Ante | The ante the boss was fought in |
| Boss | The boss's chip and name |
| Effect | What the boss does, as on the blind select screen |
| Score / Target | What you scored vs. what was needed |
| Hands | Hands used in that fight |
| Result | Beaten, Beaten (disabled) if Chicot/Luchador turned it off, or Lost |

An **Up next** row shows the current ante's boss with its effect and target.
Press **O** again, Esc or Back to close.

## How it works

The game only counts how often each boss was picked in a run, not when or how
the fight went. Boss History logs each boss fight when the round ends and saves
the log with the run, so it survives quitting and continuing.

Fights from before the mod was installed can't be recovered: for a run already
in progress, earlier bosses are listed as "also seen earlier this run" without
ante or score. Rerolled bosses (Director's Cut) can also show up there.

## Requirements

- [Lovely](https://github.com/ethangreen-dev/lovely-injector)
- [Steamodded](https://github.com/Steamodded/smods)

## Install

Clone or download this repo into your Balatro mods folder
(`%APPDATA%\Balatro\Mods` on Windows):

```
git clone https://github.com/sylvain-hamel/balatro-boss-history "%APPDATA%\Balatro\Mods\balatro-boss-history"
```

## Configuration

The key is set at the top of `main.lua` (`BH.TOGGLE_KEY`).

See also [Score Breakdown](https://github.com/sylvain-hamel/balatro-score-breakdown)
and [Disable Joker](https://github.com/sylvain-hamel/balatro-disable-joker).
