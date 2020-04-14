---
title: X Is Simply A Monoid In The Category Of Y-functor Part 1
date: 2020-04-02T23:25:00Z
author: Eben Till
---

_(N.B, the following are understandings resulting from reading the wonderful paper 'Notions of Computation as Monoids', the following Haskell extensions are needed: GADTs, TypeOperators, DerivingFunctor)_

If you've ever witnessed someone ask what a monad is, you've undoubtedly watched them be hit with a pithy, unoriginal "a monad is the monoid in the category of endofunctors" by some smart arse.

The person who asked is confused, you're giving up halfway into your twelve page running metaphor on why monads are burritos and you just know the person who derailed the question is wearing a shit eating grin. _What does it even mean?_
First things, first. What is a monoid?

_"In abstract algebra, a branch of mathematics, a monoid is an algebraic structure with a single associative binary operation and an identity element."_

More nerd words, we're getting nowhere. How about instead:

_"Take some type of value, define a function that takes two values of this type and returns one of the same type. Also, there's going to need to be a value that doesn't really do anything"_

Better. In fact, there's two monoids we've been exposed to all of our lives: not only do integers form a monoid with both addition as the binary operation and `0` as the identity, they again form a monoid with multiplication with `1` acting as the identity.
Strings form a monoid with concatanation and an empty string etc. In fact, leveraging the `Maybe` monad we get monoids for any type for free... but we're getting ahead of ourselves.

Armed with the above, there's a few rules to follow to make a lawful monoid:

* Associativity. Our binary operation, must always produce the same result no matter the precedence. E.g 1 * (2 * 3) ≡ (1 * 2) * 3

* our identity works on the left: 1 * 2 ≡ 2

* our identity works on the right: 2 * 1 ≡ 2

So what are we to do about this enigmatic endofunctor? Let's dampen expectations, _all_ functors in Haskell are endofunctors. An endofunctor maps a category to itself, in Haskell everything exists within the category of `Set`.

Hmmm, but what is a functor? A functor maps morphisms. Or less succinctly, given a value in some box, a function expecting a plain value not in a box, we'll get a new, boxed value of the function applied to the value.

Lists form functors, so let's think of the list as the box. If we have a list of numbers and we apply a function to this box, we get a new box of numbers.
In Haskell, `fmap` is the function to show a functor mapping

``fmap (+1) [1,2,3] ≡ [2,3,4]``

Just like monoids, we have laws to follow:

* Identity must be preserved, the functor is of inconsequence. For the integers we have zero as an identity, for functions there is an identity function (`id`) and it'll just return any value passed, i.e ``f(x) = x``
  so, `fmap id ≡ id`

* Function mappings compose `(fmap f) ∘ (fmap g) ≡ fmap (f ∘ g)`

In generalising monoids from our classical understanding on concrete types to over functors, our product changes.
The product of functors is composition, i.e `Functor f, Functor g => f (g)`. Declaring a type operator makes this a little more familiar:
`type (f :*: g) a = f (g a)`

Now, we also need an identity:

`data Identity a = Identity a deriving (Functor, Show)`

Armed with a product and identity, let's create a new monoid class avoiding any previous definitions.

```haskell
class Functor m => Monoid' m where
  unit :: Identity a -> m a
  tensor :: (m :*: m) a -> m a
```

A generalised algebraic datatype to wrap existing monads:


```haskell
data Monad' m a where
  M' :: Monad m => m a -> Monad' m a
```

With this, a function to unwrap the algebraic datatype:

```haskell
unM' :: Monad m => Monad' m a -> m a
unM' (M' a) = a
```

Thus, with a definition of a functor, wrapping any existing monad inside of our new, monad-adjacent instance gives rise to a monoid.

```haskell
instance (Monad m, Functor m) => Functor (Monad' m) where
  fmap f (M' x) = M' (fmap f x)
```

```haskell
instance (Monad m, Functor m) => Monoid' (Monad' m) where
  unit (Identity x) = M' $ return x
  tensor (M' x) = M' $ (unM' =<< x)
```

You should be able to see that the unit is nothing more than the `return`.

The tensor I have lazily, and with great malice aforethought, buried the lead...
The tensor of monads would be `join`, but an application of `UnM'` is required over the result - the pattern of the composition `fmap . join` is precisely the bind of a monad.
