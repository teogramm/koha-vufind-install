#!/bin/bash

#if no koha instance name was provided, then set it as "default"
export KOHA_INSTANCE=${KOHA_INSTANCE:-default}

export KOHA_INTRANET_PORT=8081
export KOHA_OPAC_PORT=8080
export MEMCACHED_SERVERS=${MEMCACHED_SERVERS:-localhost:11211}
export MYSQL_SERVER=${MYSQL_SERVER:-db}
export MYSQL_PASSWORD=${MYSQL_PASSWORD:-$(pwgen -s 15 1)}
export ZEBRA_MARC_FORMAT=${ZEBRA_MARC_FORMAT:-marc21}
export KOHA_PLACK_NAME=${KOHA_PLACK_NAME:-koha}
export KOHA_ES_NAME=${KOHA_ES_NAME:-es}


envsubst < ./templates/koha-sites.conf > /etc/koha/koha-sites.conf

# Create entry with admin username, password and myqsl server for this instance
echo -n "${KOHA_INSTANCE}:koha_${KOHA_INSTANCE}:${MYSQL_PASSWORD}:koha_${KOHA_INSTANCE}:${MYSQL_SERVER}" > /etc/koha/passwd

source /usr/share/koha/bin/koha-functions.sh

# TODO: Check if required environment variables are set.
# TODO: Check connection to mysql database

if [ "${USE_BACKEND}" = "1" ] || [ "${USE_BACKEND}" = "true" ]
then

    # Configure the elasticsearch server
    ES_PARAMS=""
    if [[ "${ELASTICSEARCH_HOST}" != "" ]]
    then
        ES_PARAMS="--elasticsearch-server ${ELASTICSEARCH_HOST}"
    fi

    if ! is_instance ${KOHA_INSTANCE} || [ ! -f "/etc/koha/sites/${KOHA_INSTANCE}/koha_conf.xml" ]
    then
        echo "Executing koha-create for instance ${KOHA_INSTANCE}"
        koha-create ${ES_PARAMS} --use-db ${KOHA_INSTANCE} | true
    else
        echo "Creating directories structure"
        koha-create-dirs ${KOHA_INSTANCE}
    fi

    # Add starman process to supervisor config
    envsubst < ./templates/supervisor/plack.conf > /etc/supervisor/conf.d/plack.conf

    # Configure search daemon
    if [ "${USE_ELASTICSEARCH}" != "true" ]
    then
        # Start zebra services with supervisord
        envsubst < ./templates/supervisor/zebra.conf > /etc/supervisor/conf.d/zebra.conf
    else
        koha-elasticsearch --rebuild -p $(grep -c ^processor /proc/cpuinfo) ${KOHA_INSTANCE} &
    fi

    for i in $(koha-translate -l)
    do
        if [ "${KOHA_LANGS}" = "" ] || ! echo "${KOHA_LANGS}"|grep -q -w $i
        then
            echo "Removing language $i"
            koha-translate -r $i
        else
            echo "Checking language $i"
            koha-translate -c $i
        fi
    done

    if [ "${KOHA_LANGS}" != "" ]
    then
        echo "Installing languages"
        LANGS=$(koha-translate -l)
        for i in $KOHA_LANGS
        do
            if ! echo "${LANGS}"|grep -q -w $i
            then
                echo "Installing language $i"
                koha-translate -i $i
            else
                echo "Language $i already present"
            fi
        done
    fi
fi

if [ "$USE_SIP" = "1" ] || [ "$USE_SIP" = "true" ]
then

    echo "Configuring SIPServer"
    SIP_CONF_ACCOUNTS=''
    for ac in $SIP_ACCOUNTS
    do
        SIP_PWD='SIP_${ac}_PWD'
        SIP_DLTR='SIP_${ac}_DLTR'
        SIP_ERR='SIP_${ac}_ERR'
        SIP_LIB='SIP_${ac}_LIB'
        SIP_CONF_ACCOUNTS=$(cat << EOF
        ${SIP_CONF_ACCOUNTS}
        <login  id=\"${ac}\" password="${!SIP_PWD}"
                delimiter="${!SIP_DLTR:-|}" error-detect="${!SIP_ERR:-enabled}" 
                institution="${!SIP_LIB}"
        />
EOF
)
    done

    SIP_CONF_LIBS=''
    for lib in $SIP_LIBS
    do
        SIP_IMPL='SIP_${lib}_IMPL'
        SIP_PARAMS='SIP_${lib}_PARAMS'
        SIP_CI='SIP_${lib}_CI'
        SIP_RNW='SIP_${lib}_RNW'
        SIP_CO='SIP_${lib}_CO'
        SIP_SU='SIP_${lib}_SU'
        SIP_OL='SIP_${lib}_OL'
        SIP_TO='SIP_${lib}_TO'
        SIP_RET='SIP_${lib}_RET'
        SIP_CONF_LIBS=$(cat << EOF
        ${SIP_CONF_LIBS}
        <institution id="${lib}" implementation="${!SIP_IMPL:-ILS}" parms="${!SIP_PARAMS}">
         <policy checkin="${!SIP_CI:-true}" renewal="${!SIP_RNW:-true}" checkout="${!SIP_CO:-true}"
                 status_update="${!SIP_SU:-false}" offline="${!SIP_OL:-false}"
                 timeout="${!SIP_TO:-100}"
                 retries="${!SIP_RET:-5}" />
        </institution>
EOF
)
    done

    envsubst < ./templates/SIPconfig.xml > /etc/koha/sites/${KOHA_INSTANCE}/SIPconfig.xml
    envsubst < ./templates/supervisor/sip.conf > /etc/supervisor/conf.d/sip.conf
fi

envsubst < ./templates/supervisor/supervisord.conf > /etc/supervisor/supervisord.conf

if [ "${USE_APACHE2}" = "1" ] || [ "${USE_APACHE2}" = "true" ]
then
    koha-plack --enable ${KOHA_INSTANCE}
    envsubst < ./templates/supervisor/apache2.conf > /etc/supervisor/conf.d/apache2.conf

    a2enmod proxy
fi

if [ "${USE_CRON}" = "1" ] || [ "${USE_CRON}" = "true" ]
then
    envsubst < ./templates/supervisor/cron.conf > /etc/supervisor/conf.d/cron.conf
fi

if [ "${USE_Z3950}" = "1" ] || [ "${USE_Z3950}" = "true" ]
then
    koha-z3950-responder --enable $KOHA_INSTANCE
    envsubst < ./templates/supervisor/z3950.conf > /etc/supervisor/conf.d/z3950.conf
fi

if [ "${MEMCACHED_SERVERS}" == "localhost:11211" ]
then
    cp ./templates/supervisor/memcached.conf /etc/supervisor/conf.d/
fi

# Prevent Plack from throwing permission errors
touch /var/log/koha/${KOHA_INSTANCE}/opac-error.log /var/log/koha/${KOHA_INSTANCE}/intranet-error.log
chown -R ${KOHA_INSTANCE}-koha:${KOHA_INSTANCE}-koha /var/log/koha/${KOHA_INSTANCE}/

# Enable backround jobs worker
envsubst < ./templates/supervisor/worker.conf > /etc/supervisor/conf.d/worker.conf

service apache2 stop
koha-indexer --stop ${KOHA_INSTANCE}
koha-zebra --stop ${KOHA_INSTANCE}
koha-worker --stop ${KOHA_INSTANCE}

supervisord -c /etc/supervisor/supervisord.conf
