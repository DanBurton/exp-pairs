module ExpPairs.Tests.LinearForm where

import Data.Ratio
import Data.List
import ExpPairs.LinearForm

import Test.QuickCheck

testPlus a b c d e f = a+d==ad && b+e==be && c+f==cf where
	l1 = LinearForm a b c
	l2 = LinearForm d e f
	l3 = l1 + l2
	ad = evalLF (1, 0, 0) l3
	be = evalLF (0, 1, 0) l3
	cf = evalLF (0, 0, 1) l3

testMinus a b c d e f = a-d==ad && b-e==be && c-f==cf where
	l1 = LinearForm a b c
	l2 = LinearForm d e f
	l3 = l1 - l2
	ad = evalLF (1, 0, 0) l3
	be = evalLF (0, 1, 0) l3
	cf = evalLF (0, 0, 1) l3

testFromInteger a = evalLF (0, 0, 1) (fromInteger a) == a


testSmth depth (name, test) = do
	putStrLn name
	mapM_ (\_ -> quickCheck test) [1..1]

testSuite = do

	mapM_ (testSmth 1) [
		("linearform plus", testPlus),
		("linearform minus", testMinus)
		]