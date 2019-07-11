module BackendApp.WebSockets where

import Prelude

import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Uncurried (EffectFn1, EffectFn2, EffectFn3, mkEffectFn1, runEffectFn1, runEffectFn2, runEffectFn3)

type WebSocketServerOptions = { port:: Int}
data WebSocketServerEvents = CONNECTION String
data WebSocketEvents = MESSAGE

foreign import data WebSocketServer :: Type
foreign import data WebSocket :: Type

foreign import _send :: EffectFn2 WebSocket String Unit
foreign import _createWebSocketServer :: EffectFn1 WebSocketServerOptions WebSocketServer
foreign import _attachServerEventListener:: 
    EffectFn3 WebSocketServer String (EffectFn1 WebSocket Unit) WebSocketServer
foreign import _attachSocketEventListener:: 
    EffectFn3 WebSocket String (EffectFn1 String Unit) WebSocket

startServerWS :: Aff Unit
startServerWS = do
    wss <- liftEffect $ runEffectFn1 _createWebSocketServer { port: 8082}
    _ <- liftEffect $ runEffectFn3 _attachServerEventListener wss ("connection") (mkEffectFn1 onConnection)
    pure unit

onConnection:: WebSocket -> Effect Unit
onConnection ws = do
    _ <- runEffectFn2 _send ws "Welcome!"
    _ <- runEffectFn3 _attachSocketEventListener ws ("message") (mkEffectFn1 (onMessage ws))
    pure unit

onMessage:: WebSocket -> String -> Effect Unit
onMessage ws msg = do
    _ <- runEffectFn2 _send ws "Message Received"
    pure unit