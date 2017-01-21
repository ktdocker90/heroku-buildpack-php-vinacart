# rewrites our query strings properly for vinacart
location @vinacart_rules {
    rewrite ^(.*)\?*$ /index.php?_route_=$1 last;
    
    #if ($http_cookie ~* "HTTP_IS_RETINA"){
    # rewrite ^/(.*)\.(gif|jpg|png)$ /$1@2x.$2;
    #}
    #if (!-e $request_filename){
    # rewrite ^/(.*)@2x\.(gif|jpg|png)$ /$1.$2;
    #}
    #if (!-e $request_filename){
    # rewrite ^/(.*)\?*$ /index.php?_route_=$1 last;
    #}
}

location / {
    index  index.php index.html index.htm;
    try_files $uri $uri/ $uri.php @vinacart_rules;
}

# for people with app root as doc root, restrict access to a few things
location ~ ^/(composer\.|Procfile$|<?=getenv('COMPOSER_VENDOR_DIR')?>/|<?=getenv('COMPOSER_BIN_DIR')?>/) {
    deny all;
}
