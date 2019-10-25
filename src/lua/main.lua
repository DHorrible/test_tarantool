#!/usr/bin/tarantool

box.cfg
{
	listen = 3301,
	logger = '/home/psipilov/Desktop/tarantool/test_tarantool/tarantool.log'
}

box.schema.user.passwd('admin', 'admin')

box.once(
	'kv_space', 
	function()
		space = box.schema.space.create('kv')
		space:create_index(
			'primary', 
			{
				type = 'hash',
				parts = 
				{
					1, 'str'
				}
			})
	end)

