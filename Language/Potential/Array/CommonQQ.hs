{-# LANGUAGE TemplateHaskell #-}
module Language.Potential.Array.CommonQQ
	( parseArrayExp
	, parseArrayPat
	) where

import Prelude
import Data.Generics.Aliases (extQ)
import qualified Language.Haskell.TH as TH
import Language.Haskell.TH.Quote (dataToExpQ, dataToPatQ)

import Language.Potential.Array.AbstractSyntax
import Language.Potential.Array.CodeGenerator

antiE :: UserArray -> Maybe TH.ExpQ
antiE us = Just [| us |] -- Just $ reifyArray us

parseArrayExp parser s =
     do loc <- TH.location
	let fname = TH.loc_filename loc
	    (line, col) = TH.loc_start loc
	parsed <- parser fname line col s
	dataToExpQ (const Nothing `extQ` antiE) parsed

parseArrayPat parser s =
     do loc <- TH.location
	let fname = TH.loc_filename loc
	    (line, col) = TH.loc_start loc
	parsed <- parser fname line col s
	dataToPatQ (const Nothing) parsed



