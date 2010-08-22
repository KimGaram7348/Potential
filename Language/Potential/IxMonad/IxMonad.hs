{-# LANGUAGE
	NoImplicitPrelude,
	EmptyDataDecls,
	TypeFamilies,
	MultiParamTypeClasses,
	FlexibleInstances,
	FunctionalDependencies
	#-}
module Language.Potential.IxMonad.IxMonad
	( Composition(..)
	, IxFunctor(..), IxMonad(..), IxMonadTrans(..)
	, Unmodeled, Composable, Terminal
	, unmodeled, composable, terminal
	) where

import Prelude( String )

class Composition (fr :: *) (to :: *) where type Compose fr to :: *

data Unmodeled
unmodeled :: IxMonad m => m Unmodeled x x a -> m Unmodeled x x a
unmodeled m = m

data Composable
composable :: IxMonad m => m Composable x y a -> m Composable x y a
composable m = m

data Terminal
terminal :: IxMonad m => m Terminal x y a -> m Terminal x y a
terminal m = m

instance Composition Unmodeled Unmodeled where
  type Compose Unmodeled Unmodeled = Unmodeled
instance Composition Unmodeled Composable where
  type Compose Unmodeled Composable = Composable
instance Composition Unmodeled Terminal where
  type Compose Unmodeled Terminal = Terminal

instance Composition Composable Unmodeled where
  type Compose Composable Unmodeled = Composable
instance Composition Composable Composable where
  type Compose Composable Composable = Composable
instance Composition Composable Terminal where
  type Compose Composable Terminal = Terminal

instance Composition Terminal Unmodeled where
  type Compose Terminal Unmodeled = Terminal


class IxFunctor m where
  fmap :: (a -> b) -> m ct x y a -> m ct x y b

class IxFunctor m => IxMonad m where
  -- minimal interface
  (>>=)  :: Composition ct ct' =>
	    m ct x y a -> (a -> m ct' y z b) ->
	    m (Compose ct ct') x z b
  unsafeReturn :: a -> m ct x y a
  -- stuff for free
  (>>)   :: Composition ct ct' =>
	    m ct x y a -> m ct' y z b ->
	    m (Compose ct ct') x z b
  a >> b = a >>= (\_ -> b)
  return :: a -> m Unmodeled x x a
  return a = unsafeReturn a
  fail :: String -> m ct x x ()
  fail = fail

class IxMonadTrans t where
  lift :: IxMonad m => m ct x y a -> t m ct x y a

