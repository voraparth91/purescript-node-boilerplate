var _getTime = function(){
	return function(){
		return new Date().getTime();		
	}
}

exports.getTime = _getTime;