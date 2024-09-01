#!/bin/bash
winpty docker compose exec -it mongo-config-server mongosh --port 27017 <<EOF
rs.initiate({_id: "rs-config-server", configsvr: true, version: 1, members: [ { _id: 0, host : 'mongo-config-server:27017' } ] })
EOF

docker compose exec -it mongo-shard-01 mongosh --port 27018 <<EOF
rs.initiate(
    {
      _id : "shard-01",
      members: [
        { _id : 0, host : "mongo-shard-01:27018" }
      ]
    }
);
EOF

docker compose exec -it mongo-shard-02 mongosh --port 27019 <<EOF
rs.initiate(
    {
      _id : "shard-02",
      members: [
        { _id : 1, host : "mongo-shard-02:27019" }
      ]
    }
  );
EOF

docker compose exec -it mongos-router mongosh --port 27020 <<EOF

sh.addShard( "shard-01/shard-01:27018");
sh.addShard( "shard-02/shard-02:27019");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )

use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
EOF