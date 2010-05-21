{-# LANGUAGE
	EmptyDataDecls,
	NoImplicitPrelude,
	MultiParamTypeClasses,
	FlexibleInstances,
	TypeFamilies,
	TemplateHaskell #-}
module Potential.Machine.Flags where

import Prelude ( fromInteger, undefined, ($) )

import Potential.BuildDataStructures
import Potential.MachineState
import Potential.Primitives
import Potential.Size
import Potential.PMonad
import Potential.Assembly

import Potential.Machine.FlagsStruct

-- example:
-- :info FlagsRegister
defineStruct flags

data CS a

incCmp :: a -> (CS a)
incCmp _ = undefined

data CF a
data PF a
data AF a
data ZF a
data SF a
data OF a

applyCmp ::
     c -> FlagsRegister cf pf af zf sf tf if' df of' iopl rf ac vif vip id
       -> FlagsRegister (CF c) (PF c) (AF c) (ZF c) (SF c) tf if' df (OF c)
			iopl rf ac vif vip id
applyCmp _ _ = undefined

assertZF :: a -> ZF a -> ()
assertZF _ _ = ()


data PrivLevelUser   = PrivLevelUser
data PrivLevelKernel = PrivLevelKernel
defineDataSize ''PrivLevelUser   2
defineDataSize ''PrivLevelKernel 2

assertPrivLevelKernel =
     do fl <- get rflags
	assertSameType (proj_iopl fl) PrivLevelKernel

cmp r1 r2 =
     do instr $ Cmp (arg r1) (arg r2)
	-- verify we've got integers in these registers
	dr1 <- get r1
	dr2 <- get r2
	assertInt64 dr1
	assertInt64 dr2
	-- increment the machine state's cmp
	c <- getCmp
	let c' = incCmp c
	setCmp c'
	-- update the flags register to reflect this
	f <- get rflags
	let f' =  applyCmp c' f
	set rflags f'
	return c'

sje fn c =
     do instr $ SJe fn
	fl <- get rflags
	let zf = proj_zf fl
	    _  = assertZF c zf
	primJmp (body fn)

