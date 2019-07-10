module BackendApp.Routes where

import BackendApp.Types (BackendMonad)
import Data.Symbol (SProxy(..))
import Effect.Aff (Aff)
import Foreign (Foreign, unsafeToForeign)
import Prelude (class Show, Unit, bind, pure, show, unit, ($))

helloWorldHandler :: BackendMonad Foreign
helloWorldHandler = do
    pure $ unsafeToForeign "Hello World"
