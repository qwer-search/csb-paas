# 合格的mjj专用白嫖项目
白嫖使人快乐，独乐乐不如众乐乐。如果您有任何问题，请随时提出Issues。
---

Documentation: [English version](https://github.com/mjjonone/mjj/blob/main/README_EN.md) | 中文版

---

推荐使用固定隧道。

---

已打包成的镜像名为`mjjonone/mjj:amd64`，变量设置如下：容器的`PORT`变量可设置为3000、7860等，具体根据容器平台的要求进行设置，一般可以将`PORT`设置为3000。

---
```diff
!有些平台会检测关键词（比如render,huggingface)，可以使用打包好的Dockerfile文件解决，建议都Fork仓库再部署，防止封号。in red
!! 无法用github仓库部署的平台（比如huggingface），复制下面Dockerfile文件的内容，然后新建Dockerfile文件，要求内容一样
!!!   请先Fork下面的仓库，再部署你自己Fork的仓库。
```
Dockerfile文件仓库 [项目地址链接](https://github.com/mjjonone/mjj-docker)
---

镜像支持x64和arm64架构，支持通过项目网址`/list`查看节点信息和`/sub`节点订阅地址。容器平台可能会睡眠，请更新订阅试试

---

游戏托管平台需要上传的文件要赋予权限777，除了`server.jar`，它的权限要设置为444。

---

一些游戏托管平台：[https://github.com/Myuui/Free-Minecraft-Hosts.git](https://github.com/Myuui/Free-Minecraft-Hosts.git)

---

docker以及类似平台：

- [https://app.patr.cloud/deployment](https://app.patr.cloud/deployment)
- [https://huggingface.co/](https://huggingface.co/)
- [https://www.render.com](https://www.render.com)
- [https://www.back4app.com/](https://www.back4app.com/)
- [https://codesandbox.io/](https://codesandbox.io/)
- [https://glitch.com/](https://glitch.com/)
- [https://replit.com/](https://replit.com/)
- [https://fly.io/](https://fly.io/)

---

在node.js环境中，上传`index.js`、`package.json`和`start.sh`文件，同时支持通过网址`/list`查看节点信息和`/sub`节点订阅地址。

---

Minecraft相关的服务器：
1. Vanilla Bedrock或Minecraft Bedrock，启动文件为`bedrock_server`。
2. Paper Minecraft Java，启动文件为`server.jar`。

---

1-1：在上传之前，将原来的`bedrock_server`重命名为`bedrock_server1`，然后上传`start.sh`脚本并将其重命名为`bedrock_server`。

2-1：在上传之前，将原来的`server.jar`重命名为`server1.jar`，然后上传`server.jar`和`start.sh`。

---

在`start.sh`文件中填写变量信息。

---

自动输出vless节点信息，并保存在`list.txt`文件中。

---

变量说明：

- `NEZHA_SERVER`：Nezha地址（如果没有可不填）。
- `NEZHA_PORT`：Nezha端口（如果没有可不填）。
- `NEZHA_KEY`：Nezha密匙（如果没有可不填）。
- `NEZHA_TLS`：默认为TLS，如果不需要TLS，请将变量设置为''。
- `ARGO_DOMAIN`：隧道固定域名（如果没有可不填）。
- `ARGO_AUTH`：隧道的token或者json（如果没有可不填）。
- `WSPATH`：默认值为`argo`。
- `UUID`：默认值为`de04add9-5c68-8bab-950c-08cd5320df18`。
- `ARGO_AUTH`：隧道的值，请参考f佬的说明。
- 变量的填写方法也可以参考f佬的说明。

说明链接：[https://github.com/fscarmen2/Argo-X-Container-PaaS/blob/main/README.md](https://github.com/fscarmen2/Argo-X-Container-PaaS/blob/main/README.md)
