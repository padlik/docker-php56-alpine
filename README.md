# PHP 5.6 for Alpine Linux

Image provides Apache, PHP 5.6 with MySQL client libraries and ready to be used with SugarCRM installations. 

## Running image

```sh
$ docker run -d --name sugar \ 
    -e DB_USER=root -e DB_PASS=pass \
    -p 80:80 --link mysql:mysql --link elastic:elastic \ 
    -v $(pwd)/sugar.d:/sugar.d absolutapps/php56-alpine
```

- `DB_USER` should have admin privileges 
Each sugar ZIP bundle under `/sugar.d` folder will be unzipped and silently installed into /var/www/localhost/htdocs/sugar/<Bundle_Name> 

## Possible options

### Licensing
`SUGAR_LICENSE` - String. Valid license key for appropriate SugarCRM version 

### Database options
- `MYSQL_HOST` - default: **mysql** 
- `MYSQL_PORT` - default: **3306**
- `DB_USER` default: 
- `DB_PASS` default: 


### Elasticsearch related parameters
Sugar requires [Elasticsearch][2] to be available. 
- `ELASTIC_HOST` default: **elastic**
- `ELASTIC_PORT` default: **9200**

[2]:https://hub.docker.com/_/elasticsearch/
