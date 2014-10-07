#!/bin/sh

DIR=$(dirname $(readlink -f $0))

echo  Cleanup
for i in shakespeare_data elasticsearch
do
    docker rm -f  $i 2>&1 >/dev/null
done



echo Starting elasticsearch
# Start elasticsearch

# bringing it up writing to this directory....
docker run -d -p 9200:9200 -p 9300:9300  -v $DIR/data:/data --name elasticsearch dockerfile/elasticsearch 

echo Sleeping to let elasticsearch come up
sleep 30

echo Create the index
# from Kibana in 10 minutes -- 
# http://www.elasticsearch.org/guide/en/kibana/current/using-kibana-for-the-first-time.html

curl -XPUT http://localhost:9200/shakespeare -d '
{
 "mappings" : {
  "_default_" : {
   "properties" : {
    "speaker" : {"type": "string", "index" : "not_analyzed" },
    "play_name" : {"type": "string", "index" : "not_analyzed" },
    "line_id" : { "type" : "integer" },
    "speech_number" : { "type" : "integer" }
   }
  }
 }
}
';

echo Load the data

curl -o /tmp/shakespeare.json http://www.elasticsearch.org/guide/en/kibana/current/snippets/shakespeare.json

curl -XPUT localhost:9200/_bulk --data-binary @/tmp/shakespeare.json

echo Sleeping to let things stabilize

curl http://localhost:9200/_nodes/stats/indicies

docker stop elasticsearch

echo Building data container
docker build -t aetherical/shakespeare-data ${DIR}/.

echo In order to make it '"work"', link the containers like this:
echo  docker run  -d -i -t --name shakespeare_data aetherical/shakespeare-data
echo  docker run -d --volumes-from=shakespeare_data -p 9200:9200 -p 9300:9300 --name elasticsearch dockerfile/elasticsearch 

