const WebSocket = require('ws');


var _createWebSocketServer = function(opts){
    return new WebSocket.Server(opts);
}

var _attachServerEventListener = function(wss, event, fn){
    return wss.on(event,fn);
}

var _attachSocketEventListener = function(ws, event, fn){
    return ws.on(event,fn);
}

var _send = function(ws, message){
        ws.send(message);
}


exports._send = _send;
exports._createWebSocketServer = _createWebSocketServer;
exports._attachServerEventListener = _attachServerEventListener;
exports._attachSocketEventListener = _attachSocketEventListener;