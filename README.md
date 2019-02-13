# kubectl-rbac-user

## Motivation

* Managing users with rbac can be complicated and has a steep learning curve
* Hunting down all bindings to a user on deletion of the user can be a tedious manual process

## Installation

### Dependencies

* jq
* bash

### With [krew](https://github.com/GoogleContainerTools/krew) (recommended)

```sh
kubectl krew install rbac-user
kubectl rbac-user
```

### Without krew

* Copy `rbac-user.sh` to a file called `kubectl-rbac_user`
* Run `chmod +x kubectl-rbac_user`
* Add the path to directory in your $PATH. eg `export PATH="/path/to/dir:$PATH"`
* Test `kubectl rbac_user`

## Features

* Create and delete users
* Automatically delete related ClusterRoleBinding and RoleBinding objects
* Works well with [view-serviceaccount-kubeconfig](https://github.com/superbrothers/kubectl-view-serviceaccount-kubeconfig-plugin/) plugin

## Usage

```sh
kubectl rbac-user [create|delete|list] [ARGS]

kubectl rbac-user -h | --help               : Usage of this command line

kubectl rbac-user list [-n <namespace>]     : list users

kubectl rbac-user create <serviceaccount-name> [<clusterrole:view> <serviceaccount-namespace:default> <rolebinding-namespace:false>] : create new serviceaccount with rolebinding (default to clusterrolebinding)
kubectl rbac-user create joe # cluster wide access
kubectl rbac-user create joe view # cluster wide access
kubectl rbac-user create joe myClusterRole myNamespace # create user in specific namespace
kubectl rbac-user create joe myClusterRole myNamespace restrictedNamespace # restrict access to specified namespace

kubectl rbac-user delete <serviceaccount-name> [<serviceaccount-namespace:default> <rolebinding-namespace:false>] : delete serviceaccount and clusterrolebinding
kubectl rbac-user delete joe
kubectl rbac-user delete joe default
kubectl rbac-user delete joe default restrictedNamespace
```
