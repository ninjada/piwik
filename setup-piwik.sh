#!/bin/bash
(( $EUID )) && echo "Please run as root or sudo" && exit 1

PREFIX="$( cd "$( dirname "$0" )" && pwd )"
DATETIME="$(date +%Y%m%d-%H%M%S)"
APP_PATH="/home/ec2-user/www/piwik"
TMP_PATH="$PREFIX/../tmp-$DATETIME"
PIWIK_TMP_PATH="$TMP_PATH/piwik"
PIWIK_CONFIG="$APP_PATH/config/config.ini.php"
GEO_IP="$APP_PATH/misc/GeoIPCity.dat"
BKP_DIR="/home/ec2-user/backup"

# Default environment
ENVIRONMENT="prod"
if [ "$1" ];
then
    ENVIRONMENT="$1"
fi
echo "Using environment: $ENVIRONMENT"

# Checkout latest Piwik version
git clone https://github.com/piwik/piwik.git "$PIWIK_TMP_PATH"

if [ -f "$PIWIK_CONFIG" ];
then
    # ln -sfv "$WP_CONFIG" "$WP_TMP_PATH/wp-config.php"
    cp $GEO_IP $PIWIK_TMP_PATH/misc/;
    cp $PIWIK_CONFIG $PIWIK_TMP_PATH/config/;
    cp $PIWIK_CONFIG /home/ec2-user/backup/config.ini.php-$DATETIME;
    cp $GEO_IP $BKP_DIR/GeoIPCity.dat-$DATETIME;
    echo "maintenance_mode = 1" >> $PIWIK_CONFIG;
    echo "record_statistics = 0" >> $PIWIK_CONFIG;
else
    echo "Error. No config for $ENVIRONMENT environment: $PIWIK_CONFIG"
    exit 1
fi

if [ -d "$PIWIK_TMP_PATH" ];
then
    mv $APP_PATH $BKP_DIR/piwik-bkp/;
    mv $BKP_DIR/piwik-bkp/piwik $BKP_DIR/piwik-bkp/piwik-$DATETIME;
    cp -R $PIWIK_TMP_PATH /home/ec2-user/www/;
    chown -R nginx:nginx /home/ec2-user/www/;
else
    echo "PIWIK Not Found, WHERE DID YOU PUT IT???"
fi

echo "Restarting Web Stack";
sudo service nginx reload
sudo service php-fpm reload
sudo service varnish restart
echo "All Done -- don't forget to run any required DB upgrades!"
