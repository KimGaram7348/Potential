{-# LANGUAGE FlexibleContexts #-}
module PC.Compiler where

import Control.Monad.Reader
import GHC
import GHC.Paths (libdir) 		-- this is a Cabal thing
import DynFlags (defaultDynFlags)	-- this is a -package ghc thing

import Digraph (flattenSCCs)

import Outputable

import PC.Config

compile :: MonadIO m => Config -> m ()
compile cfg = runReaderT compile' cfg

on_source :: MonadReader Config m => (Int -> Int -> FilePath -> m ()) -> m ()
on_source f =
     do cfg <- ask
	sequence_ $ zipWith (f $ length $ source cfg) [1 .. ] (source cfg)

compile' :: MonadIO m => ReaderT Config m ()
compile' =
     do on_source compileFile

compileFile :: MonadIO m => Int -> Int -> FilePath -> ReaderT Config m ()
compileFile total n targetFile =
     do liftIO $ putStrLn $
		"[" ++ show n ++ " of " ++ show total ++ "] Compiling " ++
		show targetFile ++ "..."
	res <- liftIO $ defaultErrorHandler defaultDynFlags $
			  runGhc (Just libdir) (doCompileFile targetFile)
	liftIO $ putStrLn $ showSDoc (ppr res)

doCompileFile targetFile =
     do dflags <- getSessionDynFlags
	setSessionDynFlags (dflags{ ctxtStkDepth = 160
				  , objectDir = Just "temp"
				  , hiDir = Just "temp" })
	target <- guessTarget targetFile Nothing
	setTargets [target]
	-- Dependency analysis
	-- TODO: make sure client code isn't cheating by importing forbidden
	-- fruit.
	modGraph <- do mg <- depanal [] False
		       return $ flattenSCCs $
				topSortModuleGraph False mg Nothing
	let targetMod  = last modGraph
	    targetName = ms_mod_name targetMod
	-- Load the code
	load LoadAllTargets
	-- Figure out the top level definitions for the target
	maybeTargetModInfo  <- getModuleInfo (ms_mod targetMod)
	let targetTopLevel = case maybeTargetModInfo of
				Nothing -> Nothing
				Just targetModInfo -> Just $ modInfoExports targetModInfo
	return (targetName, targetTopLevel)
