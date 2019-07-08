module Utils where

import Prelude
import Data.ByteString (ByteString)
import Data.ByteString as ByteString

sToBS :: String -> ByteString
sToBS = ByteString.toUTF8
