http {
    proxy_hide_header X-Powered-By;

    include       mime.types;
    default_type  application/octet-stream;

    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';

    #access_log  logs/access.log  main;

    sendfile        on;
    sendfile_max_chunk 512k;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  75;

    keepalive_requests 100000;  #total number of requests allowed over a keepalive connection, e.g: 20
    
    # disables keepalive connections for a particular set of browsers.
    #keepalive_disabled msie6 safari;   #unknown directive
    
    types_hash_max_size 4096;   #2048
    
    # For Security Reason
    server_tokens off;

    # improved response time, improve network speed with keep-alive mode
    tcp_nodelay on;
    # for requests served with sendfile
    tcp_nopush on;
    
    output_buffers 3 512k;  # only allow nginx 1.5MB of memory buffer for files.

    server_names_hash_bucket_size 128;  # fix for very long server names
    # server_name_in_redirect off;
    types_hash_bucket_size 64;

    ###
    ### Buffers , timeout, compression
    ###
    # If request is larger than specified size, then NGINX sends back the HTTP 413(Request Entity too large) error
    # Controlling Buffer Overflow Attacks
    client_max_body_size 15m;   #maximum limit
    client_body_timeout 60;
    client_header_timeout 60;
    
    # 8k buffer for 32-bit systems , 16k buffer for 64-bit systems.
    client_body_buffer_size  16k;
    client_header_buffer_size 1m;
    
    # If the request URI exceeds the size of a single buffer, NGINX sends back the HTTP 414(Request URI Too Long)
    large_client_header_buffers 4 8k; #allowed url length for a nginx request, increase to avoid 400 bad request
    
    # helpful for debugging purposes. It is not recommended for production deployments.
    client_body_in_file_only off;   #clean
    
    # it optimizes I/O while reading the $request_body variable
    client_body_in_single_buffer on;
    
    # store temporary files for the request body,will generate paths, such as temp_files/1/05/0000003051
    #client_body_temp_pathtemp_files 1 2;   #unknown
    
    
    # timeout for transmitting data to the client
    # if client stop responding, free up memory -- default 60
    send_timeout 60;
    
    # allow the server to close connection on non responding client, this will free up memory
    reset_timedout_connection on;


    ##
    # Gzip/compression Settings
    ##
    # reduce the data that needs to be sent over network
    gzip on;
    #gzip_static always; # will skip the client check and will serve the request with a .gz file    
    #gzip_disable "MSIE [1-6].(?!.*SV1)";   #"msie6";
    #gzip_vary on;
    #gzip_proxied expired no-cache no-store private auth;    #any;
    #gzip_comp_level 2;  # should from 1 to 3
    #gzip_min_length 10240;  # 512
    #gzip_buffers 16 8k;
    #gzip_http_version 1.1;
    #gzip_types text/css text/javascript text/xml text/plain text/x-component 
    #application/javascript application/x-javascript application/json 
    #application/xml  application/rss+xml font/truetype application/x-font-ttf 
    #font/opentype application/vnd.ms-fontobject image/svg+xml;

    fastcgi_buffers 256 4k;

    # define an easy to reference name that can be used in fastgi_pass
    upstream heroku-fcgi {
        #server 127.0.0.1:4999 max_fails=3 fail_timeout=3s;
        server unix:/tmp/heroku.fcgi.<?=getenv('PORT')?:'8080'?>.sock max_fails=3 fail_timeout=3s;
        keepalive 16;
    }
    
    server {
        # Set expires max on static file types
        location ~* ^.+\.(css|js|jpg|jpeg|gif|png|ico|gz|svg|svgz|ttf|otf|woff|eot|mp4|ogg|ogv|webm)$ {
            access_log off;
            log_not_found off;

            # Some basic cache-control for static files to be sent to the browser
            expires max;
            add_header Pragma public;
            add_header Cache-Control "public, must-revalidate, proxy-revalidate";
        }

        # define an easy to reference name that can be used in try_files
        location @heroku-fcgi {
            rewrite ^(.*)\?*$ /index.php?_route_=$1 last;

            fastcgi_keep_conn on;
            include fastcgi_params;
            
            fastcgi_split_path_info ^(.+\.php)(/.*)$;
            fastcgi_index index.php;
            fastcgi_intercept_errors off;   # fast execution
            fastcgi_ignore_client_abort off;
            fastcgi_connect_timeout 60;
            fastcgi_send_timeout 300;

            # FastCGI Buffers
            fastcgi_buffer_size 128k;
            fastcgi_buffers 256 16k;    #4 256k
            fastcgi_busy_buffers_size 256k;
            fastcgi_temp_file_write_size 256k;
            fastcgi_read_timeout 300;
            reset_timedout_connection on;
            
            fastcgi_pass_request_headers on;
            fastcgi_pass_request_body on;

            fastcgi_param  QUERY_STRING     $query_string;
            fastcgi_param  REQUEST_METHOD   $request_method;
            fastcgi_param  CONTENT_TYPE     $content_type;
            fastcgi_param  CONTENT_LENGTH   $content_length;

            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_param  SCRIPT_NAME $fastcgi_script_name;
            # try_files resets $fastcgi_path_info, see http://trac.nginx.org/nginx/ticket/321, so we use the if instead
            #fastcgi_param PATH_INFO $fastcgi_path_info if_not_empty;
            
            if (!-f $document_root$fastcgi_script_name) {
                # check if the script exists
                # otherwise, /foo.jpg/bar.php would get passed to FPM, which wouldn't run it as it's not in the list of allowed extensions, but this check is a good idea anyway, just in case
                return 404;
            }
            
            fastcgi_pass heroku-fcgi;
        }
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
        
        # TODO: use X-Forwarded-Host? http://comments.gmane.org/gmane.comp.web.nginx.english/2170
        server_name localhost;
        listen <?=getenv('PORT')?:'8080'?>;
        # FIXME: breaks redirects with foreman
        port_in_redirect off;
        
        root "<?=getenv('DOCUMENT_ROOT')?:getenv('HEROKU_APP_DIR')?:getcwd()?>";
        
        charset utf-8;
        error_log stderr;
        access_log /tmp/heroku.nginx_access.<?=getenv('PORT')?:'8080'?>.log;
        
        # Prevent directory listing
        autoindex off;
        error_page 404 /index.php;

        include "<?=getenv('HEROKU_PHP_NGINX_CONFIG_INCLUDE')?>";


        # restrict access to hidden files, just in case
        location ~ /\. {
            deny all;
        }
        # Deny .htaccess file access
        location ~ /\.ht {
            deny all;
        }
        location = /robots.txt  { access_log off; log_not_found off; }
        location ~ ~$           { access_log off; log_not_found off; deny all; }
        location /archive {
          rewrite ^/archive/(.*)/(.*)/?$ /index.php?rt=blog/archive&m=$1&y=$2 break;
        }
        location /feed {
          rewrite ^/feed/?$ /index.php?rt=blog/feed break;
        }
        location ~ \.tpl {
          deny all;
        }

        
        # default handling of .php
        location ~ \.(hh|php)$ {
            try_files @heroku-fcgi @heroku-fcgi;
            #try_files $uri $uri/ $uri.php @vinacart_rules;
        }
    }
}