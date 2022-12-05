# vCore tools for deploy all-in-one cluster

## Prerequests

### Packages:
1. **jq** : Command-line JSON processor
2. **curl** : A utility for getting files from remote servers (FTP, HTTP, and others)

```
dnf -y install curl jq
```

## Uninstall Managment

1. Uninstall managment packages:

    ```
    dnf -y remove tionix-tvc-broker tionix-tvc-control
    ```

2. Remove some dirs:

    ```
    rm -rf /opt/tvc/broker
    rm -rf /opt/tvc/control
    rm -rf /opt/tvc/ignite
    ```

3. Replay scripts for Stage 2

    ```
    ./deploy-2.sh
    ```

## vCore API

Access to API description: http://HOST_IP:8082/apidoc/index.html






