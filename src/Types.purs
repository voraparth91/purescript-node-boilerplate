module BackendApp.Types where

import Control.Monad.Except (ExceptT(..))
import Control.Monad.Reader (ReaderT(..))
import Data.Interval.Duration.Iso (Error)
import Database.Redis (Connection)
import Effect.Aff (Aff)

type GlobalState = { redisConn :: Connection }

type BackendMonad a = (ReaderT GlobalState (ExceptT Error Aff)) a