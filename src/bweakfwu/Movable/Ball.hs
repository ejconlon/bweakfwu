{-
- Copyright (C) 2013 Alexander Berntsen <alexander@plaimi.net>
-
- This file is part of bweakfwu
-
- bweakfwu is free software: you can redistribute it and/or modify
- it under the terms of the GNU General Public License as published by
- the Free Software Foundation, either version 3 of the License, or
- (at your option) any later version.
-
- bweakfwu is distributed in the hope that it will be useful,
- but WITHOUT ANY WARRANTY; without even the implied warranty of
- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
- GNU General Public License for more details.
-
- You should have received a copy of the GNU General Public License
- along with bwekfwu  If not, see <http://www.gnu.org/licenses/>.
-} module Movable.Ball where

import Control.Monad

import Graphics.Gloss
import Graphics.Gloss.Data.Vector

import Movable
import Movable.Paddle
import Rectangle
import Tangible
import Vector
import Visible
import Visible.Brick


data Ball = Ball Position Radius Color Velocity

instance Visible Ball where
  render (Ball p r c _) =
    Color c
    $ uncurry Translate p
    $ circleSolid r

instance Tangible Ball where
  centre (Ball p _ _ _)      = p
  left (Ball (x, _) r _ _)   = x - r
  right (Ball (x, _) r _ _)  = x + r
  top (Ball (_, y) r _ _)    = y + r
  bottom (Ball (_, y) r _ _) = y - r
  width (Ball _ r _  _)      = 2.0 * r
  height (Ball _ r _  _)     = 2.0 * r
  colour (Ball _ _ c _)      = c

instance Movable Ball where
  vel (Ball _ _ _ v)         = v

  move (Ball (x, y) c r v) t = Ball (x + fst v * t, y + snd v * t) c r v

collideBrick ::  Ball -> Brick -> Maybe (Normal, Velocity)
collideBrick b brick =
  msum [fmap (flip (,) 0) (f b brick) |
       f <- [collideEdges, collideCorners]]

collidePaddles ::  Ball -> Paddle -> Paddle -> Maybe (Normal, Velocity)
collidePaddles b p1 p2 =
  msum [fmap (flip (,) (vel p)) (f b p) |
       p <- [p1, p2],
       f <- [collideEdges, collideCorners]]

collideBall ::  Ball -> Ball -> Maybe Normal
collideBall b1 b2 = if collisionP then Just normal else Nothing
  where distanceVector = centre b1 ^-^ centre b2
        distance   = magV distanceVector
        b1Radius   = width b1/2
        b2Radius   = width b2/2
        collisionP = distance < (b1Radius + b2Radius)
        normal     = distanceVector ^/^ distance

collideEdges ::  Tangible a => Ball -> a -> Maybe Normal
collideEdges b p
  | snd (centre b) < top p &&
    snd (centre b) > bottom p &&
    right b > left p &&
    left b < right p = Just (signum (fst (centre p) - fst (centre b)) , 0.0)
  | fst (centre b) < right p &&
    fst (centre b) > left p &&
    top b > bottom p &&
    bottom b < top p = Just (0.0, signum (snd (centre p) - snd (centre b)))
  | otherwise        = Nothing

collideCorners ::  Tangible a => Ball -> a -> Maybe Normal
collideCorners b p = msum (map (collideCorner b) (corners p))

collideCorner ::  Ball -> Corner -> Maybe Normal
collideCorner b c =
  if distance < ballRadius
    then Just (distanceVector ^/^ distance)
    else Nothing
  where distanceVector = c ^-^ centre b
        distance       = magV distanceVector
        ballRadius     = width b/2
