---
title: X Is Simply A Monoid In The Category Of Y-functor Part 2
date: 2020-04-10T23:43:00Z
author: Eben Till
---

Monads as monoids in the category of endofunctors are passé. They're Banksy. They're mid-2000's The Killers. Interesting and exciting when we first discovered them, now trite and only to be enjoyed ironically.

Applicative as monoids in the category of endofunctors _though_. These are Flying Lotus. They are Finnegan's Wake. They are the Fluxus movement. They are all things you say you understand but deep down, we know it's a trendy facade.

First, a flying tour of an applicative functor. As the name implies, extend these upon a functor. If we map a function of greater than one arguements over a functor, we get a partially applied function inside the functor:
```haskell
  fmap (+) (Just 2) = Just (2+)
```

We've got no easy way to _apply_ this, and none that work for all cases. Enter applicatives.
The `<*>` operator lets us apply a functor function on the left over a functor value, e.g:
```haskell
  (fmap (+) (Just 2)) <*> Just 3 == Just 5
```

Applicatives form what is known as a _strong lax monoidal functor_. Don't pout, look on the bright side - we know what _half_ of those words mean.
Let's start with the easy part; all applicatives in Haskell are strong. The strength is defined by a natural transformation of _stA,B:A⊗F B→F(A⊗B)_
, in Haskell that is:
```haskell
st :: (a, f b) -> f (a, b) 
st (a, fb) = fmap ((,) a) fb
```

A _lax monoidal functor_ is a functor between two categories that preserves the monoid each form together with a natural transformation:
```haskell
eta :: Applicative f => (f a -> f b) -> f a -> f b
unit :: f ()
```

We're putting together all the puzzle pieces to create a monoid in the category of endofunctors, but there will need to be a different kind of tensor - 
Monads compose, for Applicatives we'll need to use what is known as the Day convolution.
Contrary to _Notions of Computation as Monoids_, I've curried the function and had to make the existential quantification explicit:

```haskell
data Day f g a = forall b c. Day (f b) (g c) (b -> c -> a)
```

It can be thought of as such: a box `f` of `b`'s, a box `g` of `c`'s, with a function that takes `b` and `c` and returns some `a`.

With the existential quantifications, we can't derive functor with GHC but it's trivial enough.
```haskell
instance (Functor f, Functor g) => Functor (Day f g) where
  fmap f (Day x y g) = Day x y $ \b c -> f (g b c)
```

Our identity remains the same but, as mentioned previously, the tensor has now changed.
Our new tensor is thus:

```haskell
class Functor m => Monoid' m where
  unit :: a -> m a
  tensor :: Day m m a -> m a

instance Applicative f => Monoid' (App f) where
  unit (Identity x) = F $ pure x
  tensor (Day fb gc bca) = F (fmap bca (unF fb) <*> unF gc)
```

The tensor is nothing more than a generalisation of `liftA2`, lifting binary functions over applicatives.
