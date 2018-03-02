---
title: Functors For Nothing, Monads For Free
date: 2018-02-28T20:52:00Z
author: Eben Till
---

To the delight of functional programmers and the umbrage of everyone else, Monads
have crept their way into Real World™ programming.

Being a perspicacious programmer you've noticed that from ``Promises`` in JavaScript ES6 to the ``Maybe``-esque null-coalescing operator introduced in C# 6, the once feared M-word is not only extant but here to stay.

So, having ham-fisted a monad or two in a project and taken a cursory look at the ``mtl`` library you've got a chip on your shoulder. Once again you're ahead of the curve, you fear no interview questions! You can now say in a droll voice and with an air of authority at dinner parties "of course, a monad is simply a monoid in the category of endofunctors". The opposite sex swoons.

But there've been whispers, rumours. There's a new kid on the block: ``Free Monads``. Tide, time and computer science stop for no man, the unusually far-sighted 12<sup>th</sup> century adage goes.

There's a number of good blog posts out there but personally, I find them prolix and unclear in their connection to traditional monads for the uninitiated. Allow me to give a cursory overview of implementing a free monad from scratch to applying it - though in keeping it simple and bridging understanding we'll have to gloss over the algebraic syntax tree properties that make free monads special for now.

<hr class="section-break">

First, what is a free monad? In short, a free monad is a way of taking any data structure that forms a functor, and getting a monad for no extra effort. Nothing. _Free_. Through just defining a functor instance you've now got do-notation and a monad transformer!

The title of this post alludes to the ``Maybe`` data type; for the purposes of illustrating exactly how we can create a monad from just a functor, I'm instead going to use an isomorphism of ``Maybe``. Where ``Maybe`` is defined:
```haskell
data Maybe a = Just a | Nothing
```

We will define a new F-Algebra, though a facsimile. Thus allowing us to start with nothing predefined for us:

```haskell
data StatusF = Success a | Failure 
```

Now we have a data structure that models two states, augmenting a pure value with whether there was success, and with it the valid value, or failure which will instead have an absence of a value.

As we know, a data structure alone does not a monad, applicative or functor make. So we need a functor instance for this:

```haskell
instance Functor StatusF where
  fmap f (Success x) = Success (f x)
  fmap _ Failure = Failure
```

Et voilà! Let's define a convenient type synonym, equipping ``StatusF`` with ``Free`` from ``Control.Monad.Free``:

``type Status a = Free StatusF a``

And we've got ourselves a free monad. We can use do-notation to model computations with a context of failure - and we did it all ourselves.

Let's define a couple of helper functions to save typing

```haskell
success :: a -> Status a
success = liftF . Success

failure :: Status a
failure = liftF Failure
```

We've taken the pure constructors we defined in the data type and composed them with ``liftF`` from ``Control.Monad.Free`` - taking the results into the realm of free monad.

So let's see it in action. With nothing defined other than a functor instance, no behind the curtains trickery, we've got a monad complete with do notation. For a contrived example, let's show a safe version of the ``head`` function that won't blow up when passed an empty list:

```haskell
safeHead :: [a] -> Status a
safeHead xs = do
    x <- myTail xs
    return x
  where myTail (x:xs) = success x
        myTail []     = failure 
```

With ``FoldFree id`` and providing a traditional monad implementation for ``StatusF`` we can prove the two implementations isomorphic. I leave this, of course, as an exercise to the reader.

<hr class="section-break">

A single layer monad however is limited in application. What if we wanted to extend `State`, `Reader` or, the forbidden fruit, ``IO`` with our newfangled monad?

Fortunately for us, the ``Free`` monad is hiding more than it lets on: it's already using transformer, composed with ``Identity`` as its base. Let's ditch ``Control.Monad.Free`` and instead use the following imports:

```haskell
import Control.Monad.Trans.Free
import Control.Monad.Trans (lift)
```

Our previously defined ``Status`` monad is constrained to having ``Identity`` as its base, so we'll have to define a new type that will let us choose an underlying monad to add our effect to:

```haskell
type StatusT m a = FreeT StatusF m a
```

Those helper functions we defined earlier, we simply change the types and we've got functions that can lift into our transformer! 

```haskell
success :: Monad m => a -> StatusT m a
failure :: Monad m = StatusT m a 
```

And so we enter contrived example number two: workplace password security is at an all time low. If having a password length greater than five isn't going to stop hackers, nothing will says management. Ok so we've got a requirement that can pass or fail, let's write a function for it:

```haskell
validation :: Monad m => String -> StatusT m String
validation password
  | (length password) > 5 = success password
  | otherwise = failure
```

We've now got a function that will work for any monad passed into it. As we're getting user input we're interested in ``IO``:

```haskell
validateInput :: StatusT IO String
validateInput = do
  input <- lift getLine
  validation input
```

Notice the ``lift`` from the ``Control.Monad.Trans`` package, it's not a typo. We need to lift from a _regular_ monad to a free transformer so ``liftF`` is no good for us here.

So far so good. But how do we get results out of it? At the start I hand waved away the structure of ``Free`` - but now we've got to face it. ``Free``'s strength comes from building up a structure as works its magic. The lisp veterans among you will know how powerful this is. However, as we're trying to imitate the [forgetful](https://en.wikipedia.org/wiki/Forgetful_functor) nature of a monad we're going to have to interpret this tree. 

``Free`` can be thought of as a tree structure: the eponymous ``Free`` constructor creates its branches, and ``Pure`` is its leaves.

So, with our vague understanding we know we're going to have to check our two ``Free`` elements and the ``Pure`` leaf

```haskell
runStatusIO :: StatusT IO String -> IO ()
runStatusIO f = do
  x <- runFreeT f
  case x of
    Pure r -> print r
    Free (Success x) -> runStatusIO x
    Free (Failure) -> print "Not good enough!"
```

So what're we doing here? It takes a free monad transformer as an input and runs ``runFreeT`` on it and binds it to x. ``runFreeT`` is a function that evaluates the first layer of structure, in essence it steps through it one at a time.

After evaluating the output we're going to want to do one of three things:

1. If it's a ``Pure`` value we know we're at the bottom of the structure and can stop recursing here and print the value.

2. A ``Success`` means we're headed in the right direction, we need to dig deeper to get to our value. The structure thus far is put right back into the function again.

3. ``Failure`` is a short circuit, we can stop here and admonish users as neccessary.

And we've done it! ``Free`` is nothing to fear. To be clear, the above doesn't
do anything you couldn't do with ``Monad``. The real power of ``Free`` I plan to show at a later date, working with the built up structure we can accomplish different ways of interpreting an algebraic syntax tree - whether skipping branches or evaluating it under different contexts.
