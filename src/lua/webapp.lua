#!/usr/local/bin/tarantool

-- Server
server = require('http.server').new('localhost', 8080)

-- Handlers
postHandler = function(request) 
	local body = request:json()
	
	local key = body.key
	local value = body.value
	
	if not key or not value then 
		request:render(400) -- Body isn't correct
	
		return
	end
	
	if box.space.kv:count(key) == 0 then
		local item = box.space.kv:insert({ key, value })
		
		request:render({ json = item })
		
		return
	else
		request:render(409) -- Space contains key
	end
end

putHandler = function(request) 
	local body = request:json()
	
	local key = request:stash('key')
	local value = body.value
	
	if not box.space.kv:count(key) == 0 then
		request:render(404) -- Key not found
		
		return
	end
	
	if not value then
		local item = box.space.kv:update(key, { value })
		
		request:render({ json = item })
		
		return
	else
		request:render(400) -- Body isn't correct 
	end	
end

getHandler = function(request) 
	local key = request:stash('key')
	
	local item = box.space.kv:select(key)
	
	if not item then
		request:render(404) -- Key not found
	else
		request:render({ json = item })
	end
end

deleteHandler = function(request) 
	local key = tonumber(request:stash('key'))
	
	local item = box.space.kv:select(key)
	
	if not item then
		request:render(404) -- Key not found
	else
		local deleteItem = box.space.kv:delete{ item }
	
		request:render({ json = deleteItem })
	end
end

withKeyHandler = function(request)
	local method = request.method
	
	if method == 'GET' then
		return getHandler(request)
	end
	
	if method == 'PUT' then
		return putHandler(request)
	end
	
	if method == 'DELETE' then
		return deleteHandler(request)
	end
end

-- Handlers
httpd:route({ path = '/kv' }, postHandler)
httpd:route({ path = '/kv/:key' }, withKeyHandler)

-- Start
httpd:start()
