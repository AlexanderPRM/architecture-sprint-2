#!/bin/bash
docker compose exec -it mongo-config-server mongosh --port 27017 <<EOF
rs.initiate({_id: "config_server", configsvr: true, version: 1, members: [ { _id: 0, host : 'mongo-config-server:27017' } ] })
EOF

docker compose exec -it mongo-shard-01 mongosh --port 27018 <<EOF
rs.initiate({_id: "shard-01", version: 1, members: [ { _id: 0, host : "mongo-shard-01-a:27018" }, { _id: 1, host : "mongo-shard-01-b:27018" }, { _id: 2, host : "mongo-shard-01-c:27018" }, ] })
EOF

docker compose exec -it mongo-shard-02 mongosh --port 27019 <<EOF
rs.initiate({_id: "shard-02", version: 1, members: [ { _id: 0, host : "mongo-shard-02-a:27019" }, { _id: 1, host : "mongo-shard-02-b:27019" }, { _id: 2, host : "mongo-shard-02-c:27019" }, ] })
EOF

docker compose exec -it mongos-router mongosh --port 27020 <<EOF

sh.addShard("shard-01/mongo-shard-01-a:27018")
sh.addShard("shard-01/mongo-shard-01-b:27018")
sh.addShard("shard-01/mongo-shard-01-c:27018")
sh.addShard("shard-02/mongo-shard-02-a:27019")
sh.addShard("shard-02/mongo-shard-02-b:27019")
sh.addShard("shard-02/mongo-shard-02-c:27019")

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )

use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
EOF