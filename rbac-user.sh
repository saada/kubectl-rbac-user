#!/usr/bin/env bash

# Usage:
#   kubectl rbac_user create <serviceaccount-name> [<clusterrole:view> <serviceaccount-namespace:default> <rolebinding-namespace:false>]
#   kubectl rbac_user delete <serviceaccount-name> [<serviceaccount-namespace:default> <rolebinding-namespace:false>]

# Requires:
# - kubectl
# - jq
set -eo pipefail

function usage() {
  echo "USAGE"
  echo "-----"
  echo "kubectl rbac-user [create|delete|list] [ARGS]"
  echo ""
  echo "kubectl rbac-user -h | --help               : Usage of this command line";
  echo ""
  echo "kubectl rbac-user list [-n <namespace>]     : list users";
  echo ""
  echo "kubectl rbac-user create <serviceaccount-name> [<clusterrole:view> <serviceaccount-namespace:default> <rolebinding-namespace:false>] : create new serviceaccount with rolebinding (default to clusterrolebinding)";
  echo "kubectl rbac-user create joe # cluster wide access"
  echo "kubectl rbac-user create joe view # cluster wide access"
  echo "kubectl rbac-user create joe myClusterRole myNamespace # create user in specific namespace"
  echo "kubectl rbac-user create joe myClusterRole myNamespace restrictedNamespace # restrict access to specified namespace"
  echo "";
  echo "kubectl rbac-user delete <serviceaccount-name> [<serviceaccount-namespace:default> <rolebinding-namespace:false>] : delete serviceaccount and clusterrolebinding";
  echo "kubectl rbac-user delete joe"
  echo "kubectl rbac-user delete joe default"
  echo "kubectl rbac-user delete joe default restrictedNamespace"
}

function listUsers() {
  kubectl get sa "$@"
}

function createUser() {
  if [ -z "$1" ]; then echo "ERROR: Missing user"; usage; exit 1; else username="$1"; fi
  if [ -z "$2" ]; then role='view'; else role="$2"; fi
  if [ -z "$3" ]; then namespace='default'; else namespace="$3"; fi
  if [ -z "$4" ]; then rolebinding_namespace='false'; else rolebinding_namespace="$4"; fi
  kubectl create serviceaccount "$username" -n $namespace
  # assume it's a cluster-wide user
  if [ "$rolebinding_namespace" = "false" ]
  then
    kubectl create clusterrolebinding "$role:$username" \
      --clusterrole="$role" \
      --serviceaccount="$namespace:$username"
  else
    kubectl create rolebinding "$namespace:$role:$username" \
      --clusterrole="$role" \
      --serviceaccount="$namespace:$username" \
      --namespace="$rolebinding_namespace"
  fi
}

function deleteUser() {
  if [ -z "$1" ]; then echo "ERROR: Missing user"; usage; exit 1; else username="$1"; fi
  if [ -z "$2" ]; then namespace='default'; else namespace="$2"; fi
  if [ -z "$3" ]; then rolebinding_namespace='default'; else rolebinding_namespace="$3"; fi
  kubectl delete serviceaccount "$username" -n $namespace
  kubectl get rolebindings -n "$rolebinding_namespace" -o json | jq -r ".items[] | select(.subjects // [] | .[] | [.kind,.namespace,.name] == [\"ServiceAccount\",\"${namespace}\",\"${username}\"]) | .metadata.name" | xargs kubectl delete rolebindings -n "$rolebinding_namespace"
  kubectl get clusterrolebindings -o json | jq -r ".items[] | select(.subjects // [] | .[] | [.kind,.namespace,.name] == [\"ServiceAccount\",\"${namespace}\",\"${username}\"]) | .metadata.name" | xargs kubectl delete clusterrolebindings
}

if [ -z "$1" ]; then usage && exit; fi
while [ -n "$1" ]; do
  case "$1" in
    get)            shift; listUsers "$@";   exit;;
    create)         shift; createUser "$@"; exit;;
    delete)         shift; deleteUser "$@"; exit;;
    -h|--help)      usage;              exit;; # quit and show usage
    * ) echo "$1 not recognized";       exit 1;; # if no match, add it to the positional args
  esac
done