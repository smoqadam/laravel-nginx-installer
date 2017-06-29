#!/usr/bin/env bash


Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
NC='\033[0m' # No Color

install_composer(){
    php="which php"
    $php composer-setup.php --install-dir=/usr/local/bin/composer --filename=composer
    $php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    rm -f composer-setup.php
}


install_virtualhost(){
   path=$1
   domain=$2
   nginx_conf="""
    server {
            listen 80 ;
            listen [::]:80 ;
    
            root $path/public;
            index index.php index.html index.htm index.nginx-debian.html;
    
            server_name $domain www.$domain;
    
            location / {
                    try_files \$uri \$uri/ =404;
            }
    
	    location ~ \.php$ {
    		fastcgi_pass unix:/var/run/php/php7.1-fpm.sock;
    		fastcgi_index   index.php;
    		fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    		include         fastcgi_params;
    	    }
    }
    """
     ## add virtual host to nginx
     echo "$nginx_conf" > /etc/nginx/sites-available/$domain
     ln -s /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
     echo "127.0.0.1	$domain" >> /etc/hosts
     service nginx restart
}


install_laravel(){
    laravel_version=$1
    path=$2
    composer create-project laravel/laravel $path "$laravel_version"
    sudo -s chmod 777 -R $path/storage
}


usage(){
    usage="""
${Green}Usage:${NC}
    command [options] [arguments]
	
${Green}Options:${NC}
    -v, --laravel-version  	install specific laravel version. default is 5.1
    -w, --with-virtualhost 	add virtual host to nginx or not
    -d, --domain 		virtual host domain name
    -r, --root 			root directory to install laravel
    -h, --help			display this help message
${Green}Example:${NC}
    ${Cyan}./nginx-laravel-installer.sh -w -d blog.local -v 5.4${NC}
"""
    echo -e "$usage"
}

domain="blog.local"
laravel_version=5.1
root=$(pwd)
with_virtualhost=false

while [ "$1" != "" ]; do
	case $1 in
		-v | --laravel-version ) shift
					 laravel_version=$1
					 ;;
		-w | --with-virtualhost ) 
					  with_virtualhost=true
					  ;;
		-d | --doamin		) shift
					  domain=$1
					  ;;
		-r | --root		) shift
					  root=$1
					  ;;

		-h | --help		)
					  usage					 
					  exit
					  ;;

		* )			  usage
					  exit
					  ;;
	esac
	shift
done

# Set full path 
path=$root/$domain

echo "Installing Laravel $laravel_version"
echo "***********************************"

install_laravel $laravel_version $path

if [ $with_virtualhost = true ];then
    echo "Installing Nginx Virtual Host" 
    echo "*****************************"
    install_virtualhost $path $domain
fi

sudo chown -R $USER:www-data $path

echo "*****************************"
echo -e "${Yello}Done. Now open http://$domain/${NC}"

