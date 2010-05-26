{-# LANGUAGE
	NoMonomorphismRestriction,
	NoImplicitPrelude
	#-}
module Potential.Flow
	( primJmp, primCondJmp, primCall, primRet
	, sjmp, scall, ret
	) where

import Potential.Core
import Potential.Assembly
import Potential.Stack
import Potential.Pointer

-- Pass in the type of the function we're jumping to.  We take on its
-- post-conditions.
primJmp :: (PState Instr c Terminal x y y' ())
	-> PState Instr c Terminal x y y' ()
primJmp _ = terminal $ mixedReturn ()

primCondJmp :: (PState Instr c Terminal x y y ())
	    -> PState Instr c Composable x x y ()
primCondJmp _ = composable $ mixedReturn ()

-- Pass in the function we're calling.  Note that it ret's to post-condition y,
-- so we must also leave the call instruction in that post-condition.  Note also
-- that it assumes condition x, so we must be in condition x just prior to the
-- call.
primCall :: (PState Instr c Terminal x y y ())
	 -> PState Instr c Composable x y y' ()
primCall _ = composable $ mixedReturn ()

-- Pass in the type of the return function on the stack.  We'll assure that
-- the function which invokes ret leaves the machine in the proper state for
-- the ret to be safe.
primRet :: (PState Instr c Terminal x y y ())
	-> PState Instr c Terminal x x y' ()
primRet _ = terminal $ return ()


-- we do a forget to avoid an infinite type error
-- any way to get around this?
{-
jmp dst = instr ( Jmp (arg dst) )
	>>> pGet >>>= \ms ->
	primJmp (fromPtr64 $ get ms dst) $ primForget dst ms >>>= \retms ->
	pPut retms
-}

sjmp fn =
     do assertFunction fn
	instr ( SJmp fn )
	primJmp (body fn)

{-
call dst = instr ( Call (arg dst) )
	>>> pGet >>>= \ms ->
	let stack  = get ms rsp
	in primPush (undefined) stack >>>= \stack' ->
	let ms' = set ms rsp stack'
	in primCall (fromPtr64 $ get ms dst) $ primForget dst ms' >>>= \retms ->
	pPut retms
-}

scall fn =
     do assertFunction fn
	instr ( SCall fn )
	stack <- get rsp
	stack' <- primPush (undefined) stack
	set rsp stack'
	primCall (body fn)

ret =
     do instr ( Ret )
	stack <- get rsp
	(a', stack') <- primPop stack
	set rsp stack'
	primRet (fromPtr64 a')


