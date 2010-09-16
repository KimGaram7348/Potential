{-
  Copyright 2010 Timothy Carstens    carstens@math.utah.edu

  This file is part of the Potential Standard Library.

    The Potential Standard Library is free software: you can redistribute it
    and/or modify it under the terms of the GNU Lesser General Public License as
    published by the Free Software Foundation, version 3 of the License.

    The Potential Standard Library is distributed in the hope that it will be
    useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with the Potential Standard Library.  If not, see
    <http://www.gnu.org/licenses/>.
-}
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
	UndecidableInstances,
	ExistentialQuantification,
	TypeOperators
	#-}
module Language.Potential.Pointer
	( Ptr64, newPtr64, fromPtr64
	, assertPtrType
	, getStruct
	, MemRegion, isMemRegion, isMemSubRegion
	, withMemoryRegion, nestMemoryRegion
	) where

import Prelude( ($), Maybe(..) )

import Language.Potential.Size
import Language.Potential.Core
import Language.Potential.Assembly
import Language.Potential.DataStructure.AbstractSyntax
import Language.Potential.DataStructure.MetaData

import Language.Potential.IxMonad.Region
import Language.Potential.IxMonad.Reader
import Language.Potential.IxMonad.Writer

data Memory -- used to tag a region as a Memory region
type MemRegion r m = Region Memory r m
type MemSubRegionWitness r s = SubRegionWitness Memory r s

isMemRegion :: IxMonad m => m Unmodeled x x () -> MemRegion r m Unmodeled x x ()
isMemRegion _ = return ()

isMemSubRegion :: (IxMonadRegion m, RegionType m ~ Memory)
			=> m Unmodeled x x ()
			-> IxReaderT (MemSubRegionWitness r (RegionLabel m))
					m Unmodeled x x ()
isMemSubRegion _ = return ()

instance IxCode m => IxCode (MemRegion r m) where
  type Constraints (MemRegion r m) = Constraints m

instance (IxCode m, IxMonadRegion m, RegionType m ~ Memory, RegionLabel m ~ s)
  => IxCode (IxReaderT (MemSubRegionWitness r s) m) where
    type Constraints (IxReaderT (MemSubRegionWitness r s) m) = Constraints m

instance ASMable m => ASMable (MemRegion r m) where
  asm constraints s mr = asm constraints s (withRegion' memRegionMgr mr)

instance (ASMable m, IxMonadRegion m, RegionType m ~ Memory, RegionLabel m ~ s)
  => ASMable (IxReaderT (MemSubRegionWitness r s) m) where
    asm constraints s mr = asm constraints s (runIxReaderT mr undefined)

-- A pointer, bound to region r
data Ptr64 r t = Ptr64 t
instance HasSZ (Ptr64 r t) where type SZ (Ptr64 r t) = D6 :* D4

getPtrData :: Ptr64 r t -> t
getPtrData _ = undefined

fromPtr64 ptr = return $ getPtrData ptr


-- Allocate a pointer in the current region
newPtr64' :: IxMonadRegion m => t -> m Composable x x (Ptr64 (RegionLabel m) t)
newPtr64' t = unsafeReturn $ Ptr64 t

newPtr64 t dst =
     do instr Alloc
	ptr <- newPtr64' t
	set dst ptr

-- Pointer operations for dealing with sub and sup regions
newPtr64InSupRegion :: IxMonadReader (MemSubRegionWitness r s) m =>
			t -> m Composable x x (Ptr64 r t)
newPtr64InSupRegion t = unsafeReturn $ Ptr64 t

belongsInSupRegion :: IxMonadReader (MemSubRegionWitness r s) m =>
			Ptr64 r t -> m Unmodeled x x ()
belongsInSupRegion _ = return ()

belongsInSubRegion :: IxMonadReader (MemSubRegionWitness r s) m =>
			Ptr64 s t -> m Unmodeled x x ()
belongsInSubRegion _ = return ()

belongsHere :: (IxMonadRegion m, RegionType m ~ Memory)
		=> Ptr64 (RegionLabel m) t ->  m Unmodeled x x ()
belongsHere _ = return ()

-- |Uses a type-assertion function to validate that the given pointer does
-- in fact contain the right type
assertPtrType :: (IxMonadRegion m, RegionType m ~ Memory)
			=> (t -> t) -> Ptr64 (RegionLabel m) t
			-> m Unmodeled x x ()
assertPtrType f t = return ()

-- |Takes the given field from 'src' and puts it into 'dst', assuming the field
-- is small enough to fit into the destination register.
getStruct src f dst index constr tmp =
     do -- get the types
	structPtr <- get src
	belongsHere structPtr
	struct <- fromPtr64 structPtr
	-- instruction generation
	let access = deepAccess struct f
	comment "getStruct:"
	comment $ show access
	forget index
	forget constr
	forget tmp
	instr $ Mov (arg src) (arg index)
	instr $ MovC 0 (arg constr)
	generateAccess access index constr tmp
	-- type-level
	let fieldContents = projField struct f
	sizeBoundedBy64Bits fieldContents
	set dst fieldContents
	comment "end getStruct"

{- TODO:
  When accessing the final field in the list, do the bit-offset thing
  Also, make sure we don't do crazy stuff with bit-offset (like accessing a
  sub-field of someone who isn't byte-aligned)
  Also, deal with the situation where a constructor doesn't have a given field
-}
generateAccess [] index constr tmp = return ()
generateAccess (a@OneConstr{}:as) index constr tmp =
     do comment $ "field `" ++ accessor_name a ++ "'"
	instr $ AddC (fromIntegral $ bytesIn $ access_params a) (arg index)
	generateAccess as index constr tmp
generateAccess (a@WithConstr{}:b@ManyConstr{}:as) index constr tmp =
     do let (ca@OneConstr{}) = constr_access a
	comment $ "field `" ++ accessor_name a ++ "' via `" ++
			accessor_name ca ++ "'"
	-- get the constructor into constr
	comment $ "loading constructor `" ++ accessor_name ca ++ "'"
	instr $ Ld (Deref2 (fromIntegral $ bytesIn $ access_params ca)
			   (arg index))
		   (arg constr)
	instr $ MovC (maskIsolate $ access_params ca) (arg tmp)
	instr $ And (arg tmp) (arg constr)
	instr $ ShR (bitsIn $ access_params ca) (arg constr)
	-- now that we know which constructor we're using, we can add to our
	-- field
	comment $ "now our field `" ++ accessor_name a ++ "'"
	instr $ AddC (fromIntegral $ bytesIn $ access_params $ accessor a)
		     (arg index)
	-- now list the constructor-dependent strategies
	comment $ "field `" ++ accessor_name b ++ "'"
	allDone <- mkLabel
	generateStrategies (strategies b) allDone
	label allDone
	-- done!
	generateAccess as index constr tmp
  where generateStrategies [] allDone = return ()
	generateStrategies ((c, mfa):ss) allDone =
	 case mfa of
	   Just fa ->
	     do snext <- mkLabel
		comment $ "constructor `" ++ constr_name c ++
			  "' has a field named `" ++ accessor_name b ++ "'"
		instr $ CmpC (rep_by c) (arg constr)
		ljne snext
		instr $ AddC (fromIntegral $ bytesIn fa) (arg index)
		ljmp allDone
		label snext
		generateStrategies ss allDone
	   Nothing ->
	     do comment $ "constructor `" ++ constr_name c ++
			  "' does not have a field named `" ++
			  accessor_name b ++ "'"
		instr $ CmpC (rep_by c) (arg constr)
		-- sje whatever the escape routine is
		generateStrategies ss allDone

-- For projecting from Ptr64 r Type to Type_Offset
-- Types are encoded by the proj function
primPtrProj proj offset src dst =
     do instr $ Ld (Deref2 offset (arg src)) (arg dst)
	ptr <- get src
	belongsHere ptr
	dat <- fromPtr64 ptr
	set dst (proj dat)

primPtrInj inj offset partialSrc structSrc =
     do instr TxOwnership
	instr $ Sto (arg partialSrc) (Deref2 offset (arg structSrc))
	partial    <- get partialSrc
	structPtr  <- get structSrc
	forget structSrc
	belongsInSubRegion structPtr
	struct     <- fromPtr64 structPtr
	structPtr' <- newPtr64InSupRegion (inj partial struct)
	belongsInSupRegion structPtr'
	set structSrc structPtr'

-- For projecting from a partial to a field
primFieldProj field_label src tmp =
     do forget tmp
	partial <- get src
	forget src
	-- TODO
	{-
	instr $ MovC (isolateMask partial field_label) (arg tmp)
	instr $ And (arg tmp) (arg src)
	instr $ ShR (bitOffset partial field_label) (arg src)
	-}
	let field = projField partial field_label
	set src field

-- For injecting from a field into a partial
primFieldInj inj field_label src dst tmp =
     do constraints <- getConstraints
	forget tmp
	partial <- get dst
	-- TODO
	{-
	instr $ ShL (bitOffset partial field_label) (arg src)
	instr $ MovC (forgetMask partial field_label) (arg tmp)
	instr $ And (arg tmp) (arg dst)
	instr $ Or (arg src) (arg dst)
	-- this last right shift restores src to its original contents
	instr $ ShR (bitOffset partial field_label) (arg src)
	-}
	field <- get src
	set dst $ inj constraints field partial

-- Projects from an array pointer to a cell pointer
primArrayProj proj offset src dst =
     do instr $ Lea (Deref2 offset (arg src)) (arg dst)
	arrayPtr <- get src
	belongsHere arrayPtr
	array <- fromPtr64 arrayPtr
	let cell = proj array
	cellPtr <- newPtr64' cell
	belongsHere cellPtr
	set dst cellPtr
	return ()

primArrayInj inj offset src dst =
     do instr TxOwnership
	instr $ Sto (arg src) (Deref2 offset (arg dst))
	partial  <- get src
	arrayPtr <- get dst
	forget dst
	belongsInSubRegion arrayPtr
	array <- fromPtr64 arrayPtr
	arrayPtr' <- newPtr64InSupRegion (inj partial array)
	belongsInSupRegion arrayPtr'
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
		 => (forall s . IxReaderT (MemSubRegionWitness r s)
					  (MemRegion s m) ct x y a)
		 -> MemRegion r m ct x y a
nestMemoryRegion r = nestRegion r

