---
title: Mental Calories Framework
description: A framework for quantifying the cognitive burden of each screen in a user flow, treating mental effort as a measurable design constraint and optimizing for low-calorie paths to value.
tags: [concepts, product, ux, design, onboarding, conversion, decision-design, psychology]
---

Every screen in your product asks something of the user. Not just time — mental effort. The decision to read, parse, evaluate, and act. The Mental Calories Framework treats that effort as a design constraint the same way a nutritionist treats caloric intake: something to be counted, managed, and reduced everywhere it isn't earning its keep.

The core idea is simple. If a screen requires more than 100 mental calories — more cognitive work than a user in a distracted, low-attention state can reasonably complete — it's too much. The goal is to get users to the moment of value before their attention budget runs out.

## What mental calories measure

A "mental calorie" isn't a formal unit — it's a thinking tool. The question is: how much cognitive work does this screen impose on the user?

High-calorie elements include:

- **Large option sets.** Presenting 400+ portfolios requires the user to evaluate, compare, and decide from a set they likely don't have the context to navigate. Showing four pre-curated options requires them only to recognize which one fits. The difference in cognitive cost is enormous.
- **Missing context.** When a user doesn't have the information needed to make a decision confidently, they either guess and feel anxious, or stall and abandon. Screens that ask users to make consequential choices without the right scaffolding carry high calories.
- **Unfiltered lists.** A brokerage selector showing every supported institution imposes a scanning cost — the user has to search through noise to find the one thing relevant to them. Detecting which brokerage app they already have installed and showing only that option collapses a high-calorie screen to near zero.
- **Abstract or unfamiliar choices.** If the user doesn't have a mental model for the thing they're being asked to choose, they have to build one before they can act. That's expensive. Defaulting where possible, or presenting choices in terms the user already uses, eliminates this cost.

Low-calorie elements work in the opposite direction: they make the right choice obvious, pre-answer questions the user would have had to form, and minimize the gap between arriving at a screen and completing it.

## The 100-calorie heuristic

The threshold of 100 mental calories is a useful working limit, not a precise formula. It captures the insight that there's a budget — and that budget is lower than most product teams assume.

Users don't arrive at a product in ideal conditions. They're distracted, multitasking, briefly curious. The question isn't whether the onboarding makes sense to someone who's fully focused and motivated — it usually does. The question is whether it works for someone who's glancing at their phone while something else is demanding their attention.

Designing to the distracted-state user is a form of stress-testing. If the flow can't survive someone checking it out on a commute, between meetings, or with background noise competing for their focus, it's too demanding for the real conditions under which most users encounter it for the first time.

## The distracted-state test

A practical implementation of this principle is timing yourself through your own onboarding while simulating distraction. Pick up your phone with something else open. Walk through the flow as a new user would encounter it. Measure how long it takes to reach the product's core value.

The target is under two minutes to the magic moment — the point where the product has delivered something tangible and useful. Flows that take five or ten minutes assume an attention budget users aren't providing.

If any step causes you to pause and think — not about whether to proceed, but about what you're even being asked to decide — that's a high-calorie screen. It needs to be simplified, split, or sequenced later in the flow.

## Earned friction: when high calories are correct

The Mental Calories Framework is not an argument for zero friction. It's an argument for *placed* friction — designing so that cognitive load appears at the moments where it creates value rather than draining it.

The clearest example is the transition from free to paid. An investment amount screen asking for a $500 minimum is genuinely high-calorie — it requires the user to commit real money, which produces real anxiety. But if this screen appears *after* the user has experienced value, the anxiety is working differently. The user is already engaged. The emotional investment makes them more willing to commit attention and resources, not less.

The pattern: low calories on routing and selection screens. High calories, strategically, at commitment moments — after the magic moment has landed and the user is primed to want more.

Similarly, a screen asking users to connect a financial account carries legitimate anxiety. That anxiety is appropriate — it's a signal that something real is happening. The design response isn't to eliminate the anxiety but to manage it: adding social proof, displaying security signals, using language that acknowledges the moment without apologizing for it. The calories stay high because they're doing productive work.

## Calories and screen sequencing

The Mental Calories Framework implies a specific ordering principle: low-calorie decisions come first, high-calorie decisions come after value is established.

This is the structural version of [[concepts/behavioral-onboarding-sequencing|Behavioral Onboarding Sequencing]] — making sure that commitment friction doesn't appear before the user has a reason to commit. A user who hasn't experienced the product's core value yet doesn't have enough context to make high-stakes decisions confidently. Moving those decisions to after the magic moment doesn't make them less necessary; it makes the user better positioned to answer them.

The sequencing principle also reduces false exits — moments where users abandon not because they don't want the product but because they hit a high-calorie screen before they were ready for it.

## Relationship to option curation

One of the highest-leverage applications of the Mental Calories Framework is option curation — reducing the number of choices presented on any selection screen.

The effect of presenting many options versus few is well documented. When users face large option sets, they're more likely to delay, second-guess, or abandon. The cognitive cost of comparison-shopping is high. Curating to a small set — typically four or fewer options for selection screens — converts a high-calorie decision into a low-calorie one.

Crucially, curation is not the same as restriction. The full option set remains available. What changes is the default path: instead of presenting everything and asking the user to navigate it, the product does that navigation work in advance and presents only what's most likely to be right. Users who want to go deeper can; most won't need to.

This is the core technique behind [[concepts/cognitive-load-optimization|Cognitive Load Optimization]]: exercise product intelligence on behalf of the user so they don't have to.

## Running a mental calories audit

Applying the framework to an existing flow is an audit process:

1. **Walk every screen.** List each step from the moment a user arrives to the moment they first experience core value.
2. **Assign a relative calorie count.** For each screen, estimate the cognitive effort required: how many options, how much reading, how much decision-making, how much context is needed to proceed.
3. **Identify the high-calorie screens.** Which steps are most demanding? Where do users pause, abandon, or ask for help?
4. **Classify each screen.** Is this a routing screen (where high calories are wasted) or a commitment screen (where high calories might be earned)? The answer determines whether the goal is to reduce, move, or design around the friction.
5. **Test and measure.** [[concepts/data-driven-friction-audit|Data-Driven Friction Audit]] operationalizes this step: A/B test changes to high-calorie screens, measure conversion impact, and retain only the elements that earn their calorie cost.

The output is a ranked list of friction points and a clear prioritization of where simplification has the highest expected return.

## Relationship to adjacent patterns

The Mental Calories Framework is a measurement lens. It doesn't tell you how to reduce friction — it tells you where friction exists and how to think about whether it belongs there.

[[concepts/cognitive-load-optimization|Cognitive Load Optimization]] is the parent discipline: the systematic reduction of decision friction across a product experience. The Mental Calories Framework provides the vocabulary for quantifying that friction.

[[concepts/binary-choice-architecture|Binary Choice Architecture]] is one of the primary techniques for reducing calories on decision screens — converting multi-option selections to binary yes/no flows wherever the product logic allows.

[[concepts/behavioral-onboarding-sequencing|Behavioral Onboarding Sequencing]] operationalizes the sequencing insight — placing high-calorie commitment screens after the magic moment rather than before it.

[[concepts/data-driven-friction-audit|Data-Driven Friction Audit]] is the experimental method for validating which elements are carrying unnecessary caloric load and can be safely removed.

[[concepts/magic-moment-engineering|Magic Moment Engineering]] is the destination: the point the user is trying to reach before their attention budget expires. Reducing mental calories everywhere else is in service of getting them there.

## Related

- [[concepts/cognitive-load-optimization|Cognitive Load Optimization]] — the parent framework; treating cognitive effort as a first-class design constraint across the full product experience
- [[concepts/binary-choice-architecture|Binary Choice Architecture]] — primary technique for reducing calories on decision screens; yes/no flows as the lowest-calorie decision structure
- [[concepts/behavioral-onboarding-sequencing|Behavioral Onboarding Sequencing]] — sequencing high-calorie commitment screens after the magic moment rather than before it
- [[concepts/data-driven-friction-audit|Data-Driven Friction Audit]] — experimental method for identifying which screen elements carry unnecessary cognitive cost
- [[concepts/magic-moment-engineering|Magic Moment Engineering]] — the destination that low-calorie onboarding paths are designed to reach; the first experience of core product value
- [[concepts/qualification-screening-paradox|Qualification Screening Paradox]] — adjacent pattern where screening friction can motivate qualified users, illustrating that not all calories are equal
