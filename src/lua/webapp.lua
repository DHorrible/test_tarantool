#!/usr/bin/env tarantool

local http_server = require('http.server')
local log = require('log')

local httpd = http_server.new(
	'localhost', 8080, 
	{
		log_errors = true,
	})
	
-- Handlers
local postHandler = function(request) 
	log:info('POST is starting')
	
	local body = request:json()
	
	local key = body.key
	local value = body.value
	
	if key == nil or value == nil then 
		request:{ error = 400 } -- Body isn't correct
		log:error('POST has error 400')
	
		return
	end
	
	if box.space.kv:count(key) == 0 then
		local item = box.space.kv:insert({ key = key, value = value })
		
		request:render{ json = item }	-- Successfull
		log:info('POST successfull')
		
		return
	else
		request:render{ error = 409 } -- Space contains key
		log:error('POST has error 409')
	end
end

local putHandler = function(request) 
	log:info('PUT is starting')

	local body = request:json()
	
	local key = request:stash('key')
	local value = body.value
	
	if not box.space.kv:count(key) == 0 then
		request:render{ error = 404 } -- Key not found
		log:error('PUT has error 404')
		
		return
	end
	
	if value == nil then
		local item = box.space.kv:update(key, { value })
		
		request:render{ json = item }	-- Successfull
		log:info('PUT successfull')
		
		return
	else
		request:render{ error = 400 } -- Body isn't correct 
		log:error('PUT has error 400')
	end	
end

local getHandler = function(request)
	log:info('GET is starting') 
	
	local key = request:stash('key')
	
	local item = box.space.kv:select(key)
	
	if #item == 0 then
		request:render{ error = 404 } -- Key not found
		log:error('GET has error 404')
	else
		request:render{ json = item } -- Successfull
		log:info('GET successfull')
	end
end

local deleteHandler = function(request)
	log:info('DELETE is starting') 
	
	local key = request:stash('key')
	
	local item = box.space.kv:select(key)
	
	if #item == 0 then
		request:render{ error = 404 } -- Key not found
		log:error('DELETE has error 404')
	else
		local deleteItem = box.space.kv:delete{ item }
	
		request:render{ json = deleteItem } -- Successfull
		log:info('DELETE successfull')
	end
end

local withKeyHandler = function(request)
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

httpd:route({ path = '/kv' }, postHandler)
httpd:route({ path = '/kv/:key' }, withKeyHandler)

httpd:start()

