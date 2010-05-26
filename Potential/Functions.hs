{-# LANGUAGE
	TypeFamilies,
	TemplateHaskell,
	Rank2Types,
	FlexibleContexts #-}
module Potential.Functions
	( asCode , renderFn , asm
	, getType , getTypeOf
	) where

import Control.Monad.Writer
import Language.Haskell.TH

import Potential.Core hiding (return, (>>), (>>=), fail)
import Potential.Printing

pos = do loc <- location
	 let filename = loc_filename loc
	     fileline = fst $ loc_start loc
	 p <- [| (filename, fileline) :: (String, Int) |]
	 return p

asCode :: String
       -> PState Instr c Terminal assumes returns returns ()
       -> Function c assumes returns
asCode fnname c =
     Fn { fnname    = fnname
	, body      = c
	}

renderFn c =
     do { let asmcode = asm ( body c )
	; putStrLn $ fnname c ++ ":"
	-- ; putStrLn $
	--	"    // defined at " ++ filename c ++ ":" ++ show (fileline c)
	; mapM_ (\l -> putStrLn $ "    " ++ show l) asmcode
	}

asm pstate = let (_, _, asmcode) = runPState pstate ConstraintsOff undefined
             in asmcode


getType :: Function ConstraintsOn
		    (MS rax rbx rcx rdx rsi rdi rbp rsp rflags
			rip r08 r09 r10 r11 r12 r13 r14 r15
			(Allocator hn hs cs) cmp)
		    (MS rax' rbx' rcx' rdx' rsi' rdi' rbp' rsp' rflags'
			rip' r08' r09' r10' r11' r12' r13' r14' r15'
			(Allocator hn' hs' cs') cmp')
	-> Function ConstraintsOn
		    (MS rax rbx rcx rdx rsi rdi rbp rsp rflags
			rip r08 r09 r10 r11 r12 r13 r14 r15
			(Allocator hn hs cs) cmp)
		    (MS rax' rbx' rcx' rdx' rsi' rdi' rbp' rsp' rflags'
			rip' r08' r09' r10' r11' r12' r13' r14' r15'
			(Allocator hn' hs' cs') cmp')
getType = id

getTypeOf
    :: src
    -> Function ConstraintsOn
		(MS rax' rbx' rcx' rdx' rsi' rdi' rbp' rsp' rflags'
		    rip' r08' r09' r10' r11' r12' r13' r14' r15' alloc' cmp)
		(MS rax rbx rcx rdx rsi rdi rbp rsp rflags
		    rip r08 r09 r10 r11 r12 r13 r14 r15 alloc cmp)
    -> Get src rax rbx rcx rdx rsi rdi rbp rsp rflags
	       rip r08 r09 r10 r11 r12 r13 r14 r15 alloc cmp
getTypeOf src fn = undefined

