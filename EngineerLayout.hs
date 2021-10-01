{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FunctionalDependencies #-}

{-# LANGUAGE TupleSections #-}
module EngineerLayout (Engineer(Engineer), WindowFn(..)) where

import XMonad hiding (state)
import XMonad.StackSet
import qualified Data.List as List
import Data.Bifunctor(second)

class (Read b, Show b) => WindowFn fn b | fn -> b where
  windowFunction :: fn -> Window -> X b
data Engineer fn b l a = Engineer
  { specifyWindow :: fn
  , matchers :: [[(b, RationalRect)]]
  , defaultLayout :: l a
  } deriving (Show,Read)

instance (WindowFn fn b, Show b, Ord b, Show fn, Read b, LayoutClass l Window) => LayoutClass (Engineer fn b l) Window where
  description _ = "Engineer"
  runLayout (Workspace i (Engineer fn matchMap fallBackLayout) ms ) baseRect =
    maybe defLayout engineerLayout ms
    where
      -- wrap l inside Engineer 
      wrapLayout = fmap (second (fmap (Engineer fn matchMap)))
      defLayout = wrapLayout $ runLayout (Workspace i fallBackLayout ms) baseRect
      engineerLayout s =
        layoutMatch >>= maybe defLayout
        (return . (,layoutState) . zip ws . map scaleRect)
        where
            ws = integrate s
            scaleRect = scaleRationalRect baseRect
            progTypes = mapM (windowFunction fn) ws
            layoutState = Just (Engineer fn matchMap fallBackLayout)
            layoutMatch = pickLayout <$> progTypes
            pickLayout programs =
              match >>= Just . orderMatch programs
                where
                  match = List.find ((== List.sort programs ) . List.sort . map fst) matchMap
            orderMatch (progType:xs) (matchTuple@(matcherType,matcherPositions):ys) =
              if progType == matcherType
              then matcherPositions:orderMatch xs ys
              -- shuffle matcher to look for rest. if match code is correct, is finite
              else orderMatch (progType:xs) (ys ++ [matchTuple])
            orderMatch _ [] = []
            orderMatch [] y = map snd y
