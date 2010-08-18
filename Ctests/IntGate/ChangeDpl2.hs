module Ctests.IntGate.ChangeDpl2 where

{-
compile --outdir=Ctests/IntGate --outfile=changeDpl2.S Ctests.IntGate.ChangeDpl2
-}

import Potential
import Potential.Arch.Amd64.Machine.IntGate

_changeDpl2 = defun "_changeDpl2" $
     do isMemSubRegion $ isMemRegion $ isCode
	comment "rdi is new dpl, rsi is *intDesc"

	push rax

	comment "get the first partial of the intDesc"
	proj_InterruptGate_0 rsi rax

	comment "set its dpl"
	push rbx
	inj_InterruptGate_0_dpl rdi rax rbx
	pop rbx

	comment "inject the updated partial into the intDesc"
	inj_InterruptGate_0 rax rsi

	pop rax
	ret

getDpl2 = defun "_getDpl2" $
     do isMemRegion $ isCode
	comment "rdi is *intDesc"
	comment "return the dpl into rax"
	proj_InterruptGate_0 rdi rax
	proj_InterruptGate_0_dpl rax rbx
	ret

