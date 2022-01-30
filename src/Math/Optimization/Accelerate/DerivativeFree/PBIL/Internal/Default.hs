{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeFamilies #-}

module Math.Optimization.Accelerate.DerivativeFree.PBIL.Internal.Default
  ( PBILI.State(..)
  , PBILI.fromAccState
  , PBILI.initialProbabilities
  , initialStepGen
  , PBILI.initialMutateGen
  , adjustProbabilities
  , mutate
  , isConverged
  , PBILI.finalize
  ) where

import qualified Data.Array.Accelerate         as A
import qualified Data.Array.Accelerate.System.Random.SFC
                                               as SFC
import           Data.Maybe                     ( fromJust )
import qualified Math.Optimization.Accelerate.DerivativeFree.PBIL.Internal
                                               as PBILI
import           Math.Optimization.Accelerate.DerivativeFree.PBIL.Probability.Internal
                                                ( Probability(..) )

initialStepGen
  :: Int -- ^ number of bits in each sample
  -> IO (A.Acc SFC.Gen)
initialStepGen = PBILI.initialStepGen 20

-- | Adjust probabilities towards the best bits
-- in a set of samples.
adjustProbabilities
  :: ( A.Unlift A.Exp (Probability (A.Exp a))
     , A.FromIntegral A.Word8 a
     , A.Num a
     , SFC.Uniform a
     , Fractional a
     , Ord a
     , A.Ord b
     )
  => A.Acc (A.Vector (Probability a))
  -> A.Acc (A.Matrix Bool) -- ^ Rows of samples
  -> A.Acc (A.Vector b) -- ^ Objective values corresponding to samples
  -> A.Acc (A.Vector (Probability a))
adjustProbabilities = fromJust $ PBILI.adjustProbabilities 0.1

-- | Randomly adjust probabilities.
mutate
  :: (A.Num a, A.Ord a, Fractional a, Ord a, SFC.Uniform a)
  => Int -- ^ number of bits in each sample
  -> A.Acc (A.Vector (Probability a))
  -> A.Acc SFC.Gen -- ^ same length as probabilities
  -> (A.Acc (A.Vector (Probability a)), A.Acc SFC.Gen)
mutate n = fromJust $ PBILI.mutate (f n) 0.05 where
  f x | x < 1     = 1
      | otherwise = 1 / fromIntegral x

-- | Have probabilities converged?
isConverged
  :: ( A.Unlift A.Exp (Probability (A.Exp a))
     , A.Num a
     , A.Ord a
     , Fractional a
     , Ord a
     )
  => A.Acc (A.Vector (Probability a))
  -> A.Acc (A.Scalar Bool)
isConverged = fromJust $ PBILI.isConverged 0.75