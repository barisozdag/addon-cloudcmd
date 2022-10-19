#!/command/with-contenv bashio

declare cloudcmd_port=8000
declare cloudcmd_protocol=http
# Generate upstream configuration
bashio::var.json \
    port "^${cloudcmd_port}" \
    | tempio \
        -template /etc/nginx/templates/upstream.gtpl \
        -out /etc/nginx/includes/upstream.conf

# Generate Ingress configuration
bashio::var.json \
    interface "$(bashio::addon.ip_address)" \
    port "^$(bashio::addon.ingress_port)" \
    protocol "${cloudcmd_protocol}" \
    | tempio \
        -template /etc/nginx/templates/ingress.gtpl \
        -out /etc/nginx/servers/ingress.conf

# Generate direct access configuration, if enabled.
if bashio::var.has_value "$(bashio::addon.port 80)"; then
    bashio::config.require.ssl
    bashio::var.json \
        certfile "$(bashio::config 'certfile')" \
        keyfile "$(bashio::config 'keyfile')" \
        leave_front_door_open "^$(bashio::config 'leave_front_door_open')" \
        port "^$(bashio::addon.port 80)" \
        protocol "${cloudcmd_protocol}" \
        ssl "^$(bashio::config 'ssl')" \
        | tempio \
            -template /etc/nginx/templates/direct.gtpl \
            -out /etc/nginx/servers/direct.conf
fi
