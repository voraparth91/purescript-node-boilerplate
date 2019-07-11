module Main where

import BackendApp.Routes (helloWorldHandler)
import BackendApp.Types (GlobalState, BackendMonad)
import BackendApp.WebSockets (startServerWS)
import Control.Monad.Except (runExceptT)
import Control.Monad.Reader (runReaderT)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..), fromMaybe)
import Database.Redis (connect, defaultConfig)
import Database.Redis as Redis
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Aff.Class (liftAff)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Effect.Ref (new, Ref, read)
import Foreign (Foreign, unsafeToForeign)
import Node.Express.App (App, listenHttp, get)
import Node.Express.Handler (Handler)
import Node.Express.Request (getRouteParam)
import Node.Express.Response (send)
import Node.HTTP (Server)
import Prelude (Unit, bind, discard, pure, show, unit, ($), (<>))
import Utils (sToBS)

-- myhandler :: Ref GlobalState -> Handler
-- myhandler globalST = do
--     reqData <- getRouteParam "reqdata"
--     s <- liftEffect $ read globalST
--     _ <- liftAff $ (Redis.set s.redisConn (sToBS "key") (sToBS $ fromMaybe "{}" reqData) Nothing Nothing)
--     resp <- liftAff $ (Redis.get s.redisConn (sToBS "key"))
--     send $ fromMaybe (sToBS "Nothing Received") resp


-------------------------------------------------------------------------------
-- EXPRESS ROUTES SETUP
-------------------------------------------------------------------------------
app :: GlobalState -> App
app globalST = do
    -- get "/:reqdata" (myhandler globalST)
    get "/hello" $ (backendMonadToHandlerM helloWorldHandler globalST)


-------------------------------------------------------------------------------
-- APP SETUP
-------------------------------------------------------------------------------
main :: Effect Unit
main = do
    -- _ <- startWS
    launchAff_ initApp

initApp :: Aff Server
initApp = do
    _ <- startServerWS
    conn        <- connect defaultConfig
    globalST    <- pure $ { redisConn : conn}
    liftEffect $ listenHttp (app globalST) 8080 \_ ->
        log $ "Listening on " <> show 8080

backendMonadToHandlerM :: forall a. BackendMonad a -> GlobalState -> Handler
backendMonadToHandlerM fn globalST = do
    res <- liftAff $ runExceptT $ runReaderT (fn) (globalST)
    case res of
        Right dat -> send dat -- Send 200 here
        Left err -> send $ show err -- Send 500 here