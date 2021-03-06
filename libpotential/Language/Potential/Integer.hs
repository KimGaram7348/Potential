{-
  Copyright 2010 Timothy Carstens    carstens@math.utah.edu

  This file is part of the Potential Standard Library.

    The Potential Standard Library is free software: you can redistribute it
    and/or modify it under the terms of the GNU Lesser General Public License as
    published by the Free Software Foundation, version 3 of the License.

    The Potential Compiler is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
-}
{-# LANGUAGE
	TypeFamilies,
	NoImplicitPrelude
	#-}
module Language.Potential.Integer
	( Int64, assertInt64, add, sub, mul, loadInt ) where

import Prelude( ($) )

import Language.Potential.Size
import Language.Potential.Core

data Int64 = Int64
instance HasSZ Int64 where type SZ Int64 = T64

assertInt64 :: Int64 -> Code c Unmodeled x x ()
assertInt64 _ = unmodeled $ return ()

add r1 r2 =
     do a <- get r1
	b <- get r2
	assertInt64 a
	assertInt64 b
	instr $ Add (arg r1) (arg r2)

sub r1 r2 =
     do a <- get r1
	b <- get r2
	assertInt64 a
	assertInt64 b
	instr $ Sub (arg r1) (arg r2)

mul r1 r2 =
     do a <- get r1
	b <- get r2
	assertInt64 a
	assertInt64 b
	instr $ Mul (arg r1) (arg r2)

loadInt a r =
     do set r Int64
	instr $ MovC a (arg r)

