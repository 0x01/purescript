-----------------------------------------------------------------------------
--
-- Module      :  Language.PureScript.Sugar
-- Copyright   :  (c) Phil Freeman 2013
-- License     :  MIT
--
-- Maintainer  :  Phil Freeman <paf31@cantab.net>
-- Stability   :  experimental
-- Portability :
--
-- |
-- Desugaring passes
--
-----------------------------------------------------------------------------

module Language.PureScript.Sugar (desugar, module S) where

import Control.Monad

import Language.PureScript.Declarations
import Language.PureScript.Errors

import Language.PureScript.Sugar.Operators as S
import Language.PureScript.Sugar.DoNotation as S
import Language.PureScript.Sugar.CaseDeclarations as S
import Language.PureScript.Sugar.TypeDeclarations as S
import Language.PureScript.Sugar.BindingGroups as S
import Language.PureScript.Sugar.TypeClasses as S
import Language.PureScript.Sugar.Names as S

import Control.Category ((>>>))

-- |
-- The desugaring pipeline proceeds as follows:
--
--  * Introduce type synonyms for type class dictionaries
--
--  * Rebracket user-defined binary operators
--
--  * Desugar do-notation using the @Prelude.Monad@ type class
--
--  * Desugar top-level case declarations into explicit case expressions
--
--  * Desugar type declarations into value declarations with explicit type annotations
--
--  * Group mutually recursive value and data declarations into binding groups.
--
--  * Qualify any unqualified names and types
--
desugar :: [Module] -> Either ErrorStack [Module]
desugar = map removeSignedLiterals
          >>> mapM desugarDoModule
          >=> desugarCasesModule
          >=> desugarTypeDeclarationsModule
          >=> desugarImports
          >=> rebracket
          >=> desugarTypeClasses
          >=> createBindingGroupsModule
