{-|
Module      : Math.ExpPairs.Process
Description : Processes of van der Corput
Copyright   : (c) Andrew Lelechenko, 2014-2015
License     : GPL-3
Maintainer  : andrew.lelechenko@gmail.com
Stability   : experimental
Portability : TemplateHaskell

Provides types for sequences of /A/- and /B/-processes of van der Corput. A good account on this topic can be found in /Graham S. W.,  Kolesnik G. A./ Van Der Corput's Method of Exponential Sums, Cambridge University Press, 1991, especially Ch. 5.
-}
{-# LANGUAGE DeriveGeneric #-}
module Math.ExpPairs.Process
	( Process ()
	, Path (Path)
	, aPath
	, baPath
	, evalPath
	, lengthPath
	) where

import GHC.Generics             (Generic)
import Generics.Deriving.Monoid (Monoid, mempty, memptydefault, mappend, mappenddefault)


import Math.ExpPairs.ProcessMatrix
import Math.ExpPairs.PrettyProcess

-- | Holds a list of 'Process' and a matrix of projective
-- transformation, which they define. It also provides a fancy 'Show'
-- instance. E. g.,
--
-- > show (mconcat $ replicate 10 aPath) == "A^10"
--
data Path = Path !ProcessMatrix ![Process]
	deriving (Eq, Generic)

instance Monoid Path where
	mempty  = memptydefault
	mappend = mappenddefault

instance Show Path where
	show (Path _ l) = show (prettifyM l) -- ++ "\n" ++ Mx.prettyMatrix m

instance Read Path where
	readsPrec _ zs = [reads' zs] where
		reads' ('A':xs) = (aPath `mappend` path, ys) where
			(path, ys) = reads' xs
		reads' ('B':'A':xs) = (baPath `mappend` path, ys) where
			(path, ys) = reads' xs
		reads' ('B':xs) = (baPath, xs)
		reads' xs = (mempty, xs)

instance Ord Path where
	(Path _ q1) <= (Path _ q2) = cmp q1 q2 where
		cmp (A:p1) (A:p2) = cmp p1 p2
		cmp (BA:p1) (BA:p2) = cmp p2 p1
		cmp (A:_) (BA:_) = True
		cmp (BA:_) (A:_) = False
		cmp [] _ = True
		cmp _ [] = False

-- | Path consisting of a single process 'A'.
aPath :: Path
aPath  = Path aMatrix [ A]

-- | Path consisting of a single process 'BA'.
baPath :: Path
baPath = Path baMatrix [BA]

-- |Apply a projective transformation, defined by 'Path',
-- to a given point in two-dimensional projective space.
evalPath :: (Num t) => Path -> (t, t, t) -> (t, t, t)
evalPath (Path m _) = evalMatrix m

-- | Count processes in the 'Path'. Note that 'BA' counts
-- for one process, not two.
lengthPath :: Path -> Int
lengthPath (Path _ xs) = length xs
