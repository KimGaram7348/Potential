{-# LANGUAGE
	ScopedTypeVariables,
	NoImplicitPrelude,
	NoMonomorphismRestriction,
	TypeFamilies,
	EmptyDataDecls,
	Rank2Types,
	MultiParamTypeClasses,
	TypeSynonymInstances,
	FlexibleContexts,
	FlexibleInstances,
	UndecidableInstances
	#-}
module Potential.Pointer
	( Ptr64, newPtr64, fromPtr64
	, primPtrProj, primPtrInj
	, primFieldProj, primFieldInj
	, primArrayProj, primArrayInj
	, MemRegion, MemSubRegion
	, withMemoryRegion, nestMemoryRegion
	) where

import Prelude( ($) )

import Potential.Size
import Potential.Core
import Potential.Assembly
import Potential.Printing -- temporary, used in a TODO

import Potential.IxMonad.Region
import Potential.IxMonad.Writer

data Memory -- used to tag a region as a Memory region
type MemRegion r m = Region Memory r m
type MemSubRegion r s = SubRegion Memory r s

instance IxCode m => IxCode (MemRegion r m) where
  type Constraints (MemRegion r m) = Constraints m

instance ASMable m => ASMable (MemRegion r m) where
  asm constraints mr = asm constraints (withRegion' memRegionMgr mr)

-- A pointer, bound to region r
data Ptr64 r t = Ptr64 t
instance HasSZ (Ptr64 r t) where type SZ (Ptr64 r t) = T64

getPtrData :: Ptr64 r t -> t
getPtrData _ = undefined

fromPtr64 ptr = return $ getPtrData ptr


-- Allocate a pointer in the current region
newPtr64' :: IxMonad m => t -> MemRegion r m Composable x x (Ptr64 r t)
newPtr64' t = unsafeReturn $ Ptr64 t

newPtr64 t dst =
     do instr Alloc
	ptr <- newPtr64' t
	set dst ptr

-- Pointer operations for dealing with sub and sup regions
newPtr64InSupRegion :: IxMonad m =>
			MemSubRegion r s -> t
			-> MemRegion s m Composable x x (Ptr64 r t)
newPtr64InSupRegion _ t = unsafeReturn $ Ptr64 t

belongsInSubRegion :: IxMonad m =>
			MemSubRegion r s -> Ptr64 s t
			-> MemRegion s m Unmodeled x x ()
belongsInSubRegion _ _ = return ()

belongsInSupRegion :: IxMonad m =>
			MemSubRegion r s -> Ptr64 r t
			-> MemRegion s m Unmodeled x x ()
belongsInSupRegion _ _ = return ()

belongsHere :: IxMonad m => Ptr64 r t -> MemRegion r m Unmodeled x x ()
belongsHere _ = return ()

-- For projecting from Ptr64 r Type to Type_Offset
-- Types are encoded by the proj function
primPtrProj proj offset src dst =
     do instr $ Ld (Deref2 offset (arg src)) (arg dst)
	ptr <- get src
	belongsHere ptr
	dat <- fromPtr64 ptr
	set dst (proj dat)

primPtrInj inj offset partialSrc structSrc sr =
     do instr TxOwnership
	instr $ Sto (arg partialSrc) (Deref2 offset (arg structSrc))
	partial    <- get partialSrc
	structPtr  <- get structSrc
	forget structSrc
	belongsInSubRegion sr structPtr
	struct     <- fromPtr64 structPtr
	structPtr' <- newPtr64InSupRegion sr (inj partial struct)
	belongsInSupRegion sr structPtr'
	set structSrc structPtr'

-- For projecting from a partial to a field
primFieldProj proj isolate_mask bit_offset src =
     do instr $ And isolate_mask (arg src)
	instr $ ShR bit_offset (arg src)
	t <- get src
	let t' = proj t
	forget src
	set src t'

-- For injecting from a field into a partial
primFieldInj inj forget_mask bit_offset src dst =
     do constraints <- getConstraints
	instr $ ShL bit_offset (arg src)
	instr $ And forget_mask (arg dst)
	instr $ Or (arg src) (arg dst)
	-- this last right shift restores src to its original contents
	instr $ ShR bit_offset (arg src)
	f <- get src
	p <- get dst
	set dst $ inj constraints f p

-- Projects from an array pointer to a cell pointer
primArrayProj proj offset src dst =
     do comment $ "lea from " ++ show (arg src) ++ "+" ++ show offset ++
		  " to " ++ show (arg dst)
	-- TODO: do a real instr with the right offset
	arrayPtr <- get src
	belongsHere arrayPtr
	array <- fromPtr64 arrayPtr
	return ()
	let cell = proj array
	cellPtr <- newPtr64' cell
	belongsHere cellPtr
	set dst cellPtr
	return ()

primArrayInj inj offset src dst sr =
     do instr TxOwnership
	comment $ "inj from " ++ show (arg src) ++ " to " ++ show (arg dst) ++
		  "+" ++ show offset
	-- TODO: a real instr with the right offset
	partial  <- get src
	arrayPtr <- get dst
	forget dst
	belongsInSubRegion sr arrayPtr
	array <- fromPtr64 arrayPtr
	arrayPtr' <- newPtr64InSupRegion sr (inj partial array)
	belongsInSupRegion sr arrayPtr'
	set dst arrayPtr'

-- the Memory region manager
memRegionMgr :: (IxMonadWriter [Instr] m) => RegionMgr m
memRegionMgr =
      RegionMgr { enter    = instr NewRegion
		, close    = instr KillRegion
		, goUp     = instr GoUpRegion
		, comeDown = instr ComeDownRegion
		}

-- Execute code within a memory region
withMemoryRegion :: ( IxMonadWriter [Instr] m
		    , Composition ct Unmodeled, Compose ct Unmodeled ~ ct
		    , Composition Unmodeled ct, Compose Unmodeled ct ~ ct )
		 => (forall r . MemRegion r m ct x y a) -> m ct x y a
withMemoryRegion r = withRegion memRegionMgr r


-- Nest a memory region
nestMemoryRegion :: ( IxMonad m
		    , Composition Unmodeled ct, Compose Unmodeled ct ~ ct
		    , Composition ct Unmodeled, Compose ct Unmodeled ~ ct)
		 => (forall s . MemSubRegion r s -> MemRegion s m ct x y a)
		 -> MemRegion r m ct x y a
nestMemoryRegion r = nestRegion r

