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
    dnf -y remove vcore-broker vcore-control
    ```
Old names (pre 1.3.0): tionix-tvc-broker tionix-tvc-control

2. Remove some dirs:

    ```
    rm -rf /opt/vcore/broker
    rm -rf /opt/vcore/control
    rm -rf /opt/vcore/ignite
    ```
Old path (pre 1.3.0): /opt/tvc

3. Replay scripts for Stage 2

    ```
    ./deploy-2.sh
    ```

## vCore API

Access to API description: http://HOST_IP:8082/apidoc/index.html







