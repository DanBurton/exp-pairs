{-|
Module      : Math.ExpPairs.PrettyProcess
Description : Compact representation of process sequences
Copyright   : (c) Andrew Lelechenko, 2015
License     : GPL-3
Maintainer  : andrew.lelechenko@gmail.com
Stability   : experimental
Portability : TemplateHaskell

Transforms sequences of 'Process' into most compact (by the means of typesetting) representation using brackets and powers.
E. g., AAAABABABA -> A^4(BA)^3.

This module uses memoization extensively.
-}
{-# LANGUAGE LambdaCase      #-}
{-# LANGUAGE TemplateHaskell #-}
{-# OPTIONS_GHC -fno-warn-type-defaults #-}
module Math.ExpPairs.PrettyProcess
  ( prettify,
    uglify,
    PrettyProcess) where

import Data.List                (minimumBy)
import Data.Ord                 (comparing)
import Data.Function.Memoize    (memoize, deriveMemoizable)
import Text.PrettyPrint.Leijen

import Math.ExpPairs.ProcessMatrix

-- | Compact representation of the sequence of 'Process'.
data PrettyProcess
  = Simply [Process]
  | Repeat PrettyProcess Int
  | Sequence PrettyProcess PrettyProcess
  deriving (Show)

data PrettyProcessWithWidth = PPWL { ppwlProcess :: PrettyProcess, ppwlWidth :: Int }

deriveMemoizable ''PrettyProcess

instance Pretty PrettyProcess where
  pretty = \case
    Simply xs    -> hsep (map (text . show) xs)
    Repeat _  0  -> empty
    Repeat xs 1  -> pretty xs
    Repeat (Simply [A]) n -> text (show A) <> char '^' <> int n
    Repeat xs n  -> parens (pretty xs) <> char '^' <> int n
    Sequence a b -> pretty a <+> pretty b

-- | Width of the bracket.
bracketWidth :: Int
bracketWidth = 4

-- | Width of the subscript-sized character (e. g., power).
subscriptWidth :: Int
subscriptWidth = 4

-- | Width of the processes in typeset
processWidth :: Process -> Int
processWidth  A = 10
processWidth BA = 20

-- | Compute the width of the 'PrettyProcess' according to 'bracketWidth', 'subscriptWidth' and 'printedWidth''.
printedWidth :: PrettyProcess -> Int
printedWidth = \case
  Simply xs             -> sum (map processWidth xs)
  Repeat _ 0            -> 0
  Repeat xs 1           -> printedWidth xs
  Repeat (Simply [A]) _ -> processWidth A + subscriptWidth
  Repeat xs _           -> printedWidth xs + bracketWidth * 2 + subscriptWidth
  Sequence a b          -> printedWidth a + printedWidth b

-- | Convert 'PrettyProcess' to 'PrettyProcessWithWidth'.
annotateWithWidth :: PrettyProcess -> PrettyProcessWithWidth
annotateWithWidth p = PPWL p (printedWidth p)

-- | Return non-trivial divisors of an argument.
divisors :: Int -> [Int]
divisors n = ds1 ++ reverse ds2 where
  (ds1, ds2) = unzip [ (a, n `div` a) | a <- [1 .. sqrtint n], n `mod` a == 0 ]
  sqrtint = round . sqrt . fromIntegral

-- | Try to represent list as a replication of list.
asRepeat :: [Process] -> ([Process], Int)
asRepeat [] = ([], 0)
asRepeat xs = pair where
  l = length xs
  candidates = [ (take d xs, l `div` d) | d <- divisors l ]
  pair = head $ filter (\(ys, n) -> concat (replicate n ys) == xs) candidates

-- | Find the most compact representation of the sequence of processes.
prettify :: [Process] -> PrettyProcess
prettify = ppwlProcess . prettifyP

-- | Find the most compact representation of the sequence of processes, keeping track of widthess.
prettifyP :: [Process] -> PrettyProcessWithWidth
prettifyP = memoize prettify' where

prettify' :: [Process] -> PrettyProcessWithWidth
prettify' = \case
  []   -> annotateWithWidth (Simply [])
  [A]  -> annotateWithWidth (Simply [A])
  [BA] -> annotateWithWidth (Simply [BA])
  xs   -> minimumBy (comparing ppwlWidth) yss where
    xs'' = case asRepeat xs of
      (_, 1)   -> annotateWithWidth (Simply xs)
      (xs', n) -> annotateWithWidth (Repeat (prettify xs') n)

    yss = xs'' : map f bcs

    bcs = takeWhile (not . null . snd) $ iterate bcf ([head xs], tail xs)

    bcf (_, [])    = undefined
    bcf (zs, y:ys) = (zs++[y], ys)

    f (bs, cs) = PPWL (Sequence bsP csP) (bsW + csW) where
      PPWL bsP bsW = prettifyP bs
      PPWL csP csW = prettifyP cs

-- | Unfold back 'PrettyProcess' into the sequence of 'Process'.
uglify :: PrettyProcess -> [Process]
uglify = \case
  Simply xs      -> xs
  Repeat xs n    -> concat . replicate n . uglify $ xs
  Sequence xs ys -> uglify xs ++ uglify ys
