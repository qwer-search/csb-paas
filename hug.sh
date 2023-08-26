#!/usr/bin/env bash
NEZHA_SERVER=${NEZHA_SERVER:-''}
NEZHA_PORT=${NEZHA_PORT:-''}
NEZHA_KEY=${NEZHA_KEY:-''}
NEZHA_TLS=${NEZHA_TLS:-'--tls'}
ARGO_DOMAIN=${ARGO_DOMAIN:-''}
ARGO_AUTH=${ARGO_AUTH:-''}
WSPATH=${WSPATH:-'argo'}
UUID=${UUID:-'de04add9-5c68-8bab-950c-08cd5320df18'}

set_download_url() {
  local program_name="$1"
  local default_url="$2"
  local x64_url="$3"

  if [ "$(uname -m)" = "x86_64" ] || [ "$(uname -m)" = "amd64" ] || [ "$(uname -m)" = "x64" ]; then
    download_url="$x64_url"
  else
    download_url="$default_url"
  fi
}

download_program() {
  local program_name="$1"
  local default_url="$2"
  local x64_url="$3"

  set_download_url "$program_name" "$default_url" "$x64_url"

  if [ ! -f "$program_name" ]; then
    if [ -n "$download_url" ]; then
      echo "Downloading $program_name..."
      curl -sSL "$download_url" -o "$program_name"
      dd if=/dev/urandom bs=1024 count=1024 | base64 >> "$program_name"
      echo "Downloaded $program_name"
    else
      echo "Skipping download for $program_name"
    fi
  else
    dd if=/dev/urandom bs=1024 count=1024 | base64 >> "$program_name"
    echo "$program_name already exists, skipping download"
  fi
}


download_program "nm" "https://github.com/fscarmen2/X-for-Botshard-ARM/raw/main/nezha-agent" "https://github.com/fscarmen2/X-for-Stozu/raw/main/nezha-agent"
sleep 6

download_program "web" "https://github.com/fscarmen2/X-for-Botshard-ARM/raw/main/web.js" "https://github.com/fscarmen2/X-for-Stozu/raw/main/web.js"
sleep 6

download_program "cc" "https://github.com/cloudflare/cloudflared/releases/download/2023.8.0/cloudflared-linux-arm64" "https://github.com/cloudflare/cloudflared/releases/download/2023.8.0/cloudflared-linux-amd64"
sleep 6

cleanup_files() {
  rm -rf argo.log list.txt sub.txt encode.txt
}

argo_type() {
  if [[ -z $ARGO_AUTH || -z $ARGO_DOMAIN ]]; then
    echo "ARGO_AUTH 或 ARGO_DOMAIN 为空,使用Quick Tunnels"
    return
  fi

  if [[ $ARGO_AUTH =~ TunnelSecret ]]; then
    echo $ARGO_AUTH > tunnel.json
    cat > tunnel.yml << EOF
tunnel: $(cut -d\" -f12 <<< $ARGO_AUTH)
credentials-file: ./tunnel.json
protocol: http2

ingress:
  - hostname: $ARGO_DOMAIN
    service: http://localhost:8080
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF
  else
    echo "ARGO_AUTH 不匹配 TunnelSecret"
  fi
}


run() {
  if [ -e nm ]; then
  
    if [ -n "$NEZHA_SERVER" ] && [ -n "$NEZHA_PORT" ] && [ -n "$NEZHA_KEY" ]; then
    nohup ./nm -s ${NEZHA_SERVER}:${NEZHA_PORT} -p ${NEZHA_KEY} ${NEZHA_TLS} >/dev/null 2>&1 &
    keep1="nohup ./nm -s ${NEZHA_SERVER}:${NEZHA_PORT} -p ${NEZHA_KEY} ${NEZHA_TLS} >/dev/null 2>&1 &"
    fi
  fi

  if [ -e web ]; then

    nohup ./web -c ./config.json >/dev/null 2>&1 &
    keep2="nohup ./web -c ./config.json >/dev/null 2>&1 &"
  fi

  if [ -e cc ]; then

if [[ $ARGO_AUTH =~ ^[A-Z0-9a-z=]{120,250}$ ]]; then
  args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 --logfile argo.log --loglevel info run --token ${ARGO_AUTH}"
elif [[ $ARGO_AUTH =~ TunnelSecret ]]; then
  args="tunnel --edge-ip-version auto --config tunnel.yml run"
else
  args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 --logfile argo.log --loglevel info --url http://localhost:8080"
fi
nohup ./cc $args >/dev/null 2>&1 &
keep3="nohup ./cc $args >/dev/null 2>&1 &"
  fi
} 

generate_config() {
  cat > config.json << EOF
{
    "log":{
        "access":"/dev/null",
        "error":"/dev/null",
        "loglevel":"none"
    },
    "inbounds":[
        {
            "port":8080,
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "flow":"xtls-rprx-vision"
                    }
                ],
                "decryption":"none",
                "fallbacks":[
                    {
                        "dest":3001
                    },
                    {
                        "path":"/${WSPATH}-vless",
                        "dest":3002
                    },
                    {
                        "path":"/${WSPATH}-vmess",
                        "dest":3003
                    },
                    {
                        "path":"/${WSPATH}-trojan",
                        "dest":3004
                    },
                    {
                        "path":"/${WSPATH}-shadowsocks",
                        "dest":3005
                    }
                ]
            },
            "streamSettings":{
                "network":"tcp"
            }
        },
        {
            "port":3001,
            "listen":"127.0.0.1",
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}"
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "security":"none"
            }
        },
        {
            "port":3002,
            "listen":"127.0.0.1",
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "level":0
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "security":"none",
                "wsSettings":{
                    "path":"/${WSPATH}-vless"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls",
                    "quic"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":3003,
            "listen":"127.0.0.1",
            "protocol":"vmess",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "alterId":0
                    }
                ]
            },
            "streamSettings":{
                "network":"ws",
                "wsSettings":{
                    "path":"/${WSPATH}-vmess"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls",
                    "quic"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":3004,
            "listen":"127.0.0.1",
            "protocol":"trojan",
            "settings":{
                "clients":[
                    {
                        "password":"${UUID}"
                    }
                ]
            },
            "streamSettings":{
                "network":"ws",
                "security":"none",
                "wsSettings":{
                    "path":"/${WSPATH}-trojan"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls",
                    "quic"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":3005,
            "listen":"127.0.0.1",
            "protocol":"shadowsocks",
            "settings":{
                "clients":[
                    {
                        "method":"chacha20-ietf-poly1305",
                        "password":"${UUID}"
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "wsSettings":{
                    "path":"/${WSPATH}-shadowsocks"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls",
                    "quic"
                ],
                "metadataOnly":false
            }
        }
    ],
    "dns":{
        "servers":[
            "https+local://8.8.8.8/dns-query"
        ]
    },
    "outbounds":[
        {
            "protocol":"freedom"
        },
        {
            "tag":"WARP",
            "protocol":"wireguard",
            "settings":{
                "secretKey":"YFYOAdbw1bKTHlNNi+aEjBM3BO7unuFC5rOkMRAz9XY=",
                "address":[
                    "172.16.0.2/32",
                    "2606:4700:110:8a36:df92:102a:9602:fa18/128"
                ],
                "peers":[
                    {
                        "publicKey":"bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
                        "allowedIPs":[
                            "0.0.0.0/0",
                            "::/0"
                        ],
                        "endpoint":"162.159.193.10:2408"
                    }
                ],
                "reserved":[78, 135, 76],
                "mtu":1280
            }
        }
    ],
    "routing":{
        "domainStrategy":"AsIs",
        "rules":[
            {
                "type":"field",
                "domain":[
                    "domain:openai.com",
                    "domain:ai.com"
                ],
                "outboundTag":"WARP"
            }
        ]
    }
}
EOF
}

cleanup_files
sleep 2
generate_config
sleep 3
argo_type
sleep 3
run
sleep 15

function get_argo_domain() {
  if [[ -n $ARGO_AUTH ]]; then
    echo "$ARGO_DOMAIN"
  else
    cat argo.log | grep trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}'
  fi
}

isp=$(curl -s https://speed.cloudflare.com/meta | awk -F\" '{print $26"-"$18"-"$30}' | sed -e 's/ /_/g')
sleep 3

generate_links() {
  argo=$(get_argo_domain)
  sleep 1

  VMESS="{ \"v\": \"2\", \"ps\": \"${isp}-vm\", \"add\": \"icook.hk\", \"port\": \"443\", \"id\": \"${UUID}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"${argo}\", \"path\": \"/${WSPATH}-vmess?ed=2048\", \"tls\": \"tls\", \"sni\": \"${argo}\", \"alpn\": \"\" }"

  cat > list.txt <<EOF
*******************************************
icook.hk 可替换为CF优选IP,端口 443 可改为 2053 2083 2087 2096 8443
----------------------------
V2-rayN:
----------------------------
vless://${UUID}@icook.hk:443?encryption=none&security=tls&sni=${argo}&type=ws&host=${argo}&path=%2F${WSPATH}-vless?ed=2048#${isp}-Vl
----------------------------
vmess://$(echo "$VMESS" | base64 -w0)
----------------------------
trojan://${UUID}@icook.hk:443?security=tls&sni=${argo}&type=ws&host=${argo}&path=%2F${WSPATH}-trojan?ed=2048#${isp}-Tr
----------------------------
ss://$(echo "chacha20-ietf-poly1305:${UUID}@icook.hk:443" | base64 -w0)@icook.hk:443#${isp}-SS
由于该软件导出的链接不全，请自行处理如下: 传输协议: WS ， 伪装域名: ${argo} ，路径: /${WSPATH}-shadowsocks?ed=2048 ， 传输层安全: tls ， sni: ${argo}
*******************************************
Shadowrocket:
----------------------------
vless://${UUID}@icook.hk:443?encryption=none&security=tls&type=ws&host=${argo}&path=/${WSPATH}-vless?ed=2048&sni=${argo}#${isp}-Vl
----------------------------
vmess://$(echo "none:${UUID}@icook.hk:443" | base64 -w0)?remarks=${isp}-Vm&obfsParam=${argo}&path=/${WSPATH}-vmess?ed=2048&obfs=websocket&tls=1&peer=${argo}&alterId=0
----------------------------
trojan://${UUID}@icook.hk:443?peer=${argo}&plugin=obfs-local;obfs=websocket;obfs-host=${argo};obfs-uri=/${WSPATH}-trojan?ed=2048#${isp}-Tr
----------------------------
ss://$(echo "chacha20-ietf-poly1305:${UUID}@icook.hk:443" | base64 -w0)?obfs=wss&obfsParam=${argo}&path=/${WSPATH}-shadowsocks?ed=2048#${isp}-Ss
*******************************************
Clash:
----------------------------
- {name: ${isp}-Vless, type: vless, server: icook.hk, port: 443, uuid: ${UUID}, tls: true, servername: ${argo}, skip-cert-verify: false, network: ws, ws-opts: {path: /${WSPATH}-vless?ed=2048, headers: { Host: ${argo}}}, udp: true}
----------------------------
- {name: ${isp}-Vmess, type: vmess, server: icook.hk, port: 443, uuid: ${UUID}, alterId: 0, cipher: none, tls: true, skip-cert-verify: true, network: ws, ws-opts: {path: /${WSPATH}-vmess?ed=2048, headers: {Host: ${argo}}}, udp: true}
----------------------------
- {name: ${isp}-Trojan, type: trojan, server: icook.hk, port: 443, password: ${UUID}, udp: true, tls: true, sni: ${argo}, skip-cert-verify: false, network: ws, ws-opts: { path: /${WSPATH}-trojan?ed=2048, headers: { Host: ${argo} } } }
----------------------------
- {name: ${isp}-Shadowsocks, type: ss, server: icook.hk, port: 443, cipher: chacha20-ietf-poly1305, password: ${UUID}, plugin: v2ray-plugin, plugin-opts: { mode: websocket, host: ${argo}, path: /${WSPATH}-shadowsocks?ed=2048, tls: true, skip-cert-verify: false, mux: false } }
*******************************************
EOF

  cat > encode.txt <<EOF
vless://${UUID}@icook.hk:443?encryption=none&security=tls&sni=${argo}&type=ws&host=${argo}&path=%2F${WSPATH}-vless?ed=2048#${isp}-Vl
vmess://$(echo "$VMESS" | base64 -w0)
trojan://${UUID}@icook.hk:443?security=tls&sni=${argo}&type=ws&host=${argo}&path=%2F${WSPATH}-trojan?ed=2048#${isp}-Tr
EOF

base64 -w0 encode.txt > sub.txt 

  cat list.txt
  echo -e "\n节点信息已保存在 list.txt"
}

generate_links


if [ -n "$STARTUP" ]; then
  if [[ "$STARTUP" == *"java"* ]]; then
    java -Xms128M -XX:MaxRAMPercentage=95.0 -Dterminal.jline=false -Dterminal.ansi=true -jar server1.jar
  elif [[ "$STARTUP" == *"bedrock_server"* ]]; then
    ./bedrock_server1
  fi
fi

function start_nm_program() {
if [ -n "$keep1" ]; then
  if [ -z "$pid" ]; then
    echo "程序'$program'未运行，正在启动..."
    eval "$command"
  else
    echo "程序'$program'正在运行，PID: $pid"
  fi
else
  echo "程序'$program'不需要启动，无需执行任何命令"
fi
}

function start_web_program() {
  if [ -z "$pid" ]; then
    echo "程序'$program'未运行，正在启动..."
    eval "$command"
  else
    echo "程序'$program'正在运行，PID: $pid"
  fi
}

function start_cc_program() {
  if [ -z "$pid" ]; then
    echo "程序'$program'未运行，正在启动..."
    cleanup_files
    sleep 2
    eval "$command"
    sleep 5
    generate_links
    sleep 3
  else
    echo "程序'$program'正在运行，PID: $pid"
  fi
}

function start_program() {
  local program=$1
  local command=$2

  pid=$(pidof "$program")

  if [ "$program" = "nm" ]; then
    start_nm_program
  elif [ "$program" = "web" ]; then
    start_web_program
  elif [ "$program" = "cc" ]; then
    start_cc_program
  fi
}

programs=("nm" "web" "cc")
commands=("$keep1" "$keep2" "$keep3")

while true; do
  for ((i=0; i<${#programs[@]}; i++)); do
    program=${programs[i]}
    command=${commands[i]}

    start_program "$program" "$command"
  done
  sleep 180
done
