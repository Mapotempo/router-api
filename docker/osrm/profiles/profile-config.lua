local postgres = require('luasql.postgres').postgres()
sql_conn = assert(postgres:connect('postgresql://osrm:osrm@db/osrm'))

local redis = require('redis')
redis_conn = assert(redis.connect('redis-cache', 6379))

