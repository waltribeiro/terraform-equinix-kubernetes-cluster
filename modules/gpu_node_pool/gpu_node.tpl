#!/bin/bash

export HOME=/root

function nvidia_configure() {
 sudo pkill -SIGHUP dockerd && \
 distribution=$(. /etc/os-release;echo $ID$VERSION_ID) ; \
 curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - ; \
 curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list ; \
 sudo apt-get update && sudo apt-get install -y nvidia-docker2 nvidia-cuda-toolkit ; \
 sudo systemctl restart docker
}

function install_docker() {
 apt-get update; \
 apt-get install -y docker.io
}

function enable_docker() {
 systemctl enable docker ; \
 systemctl restart docker
}

function ceph_pre_check {
  apt install -y lvm2 ; \
  modprobe rbd
}

function install_kube_tools() {
 swapoff -a  && \
 apt-get update && apt-get install -y apt-transport-https
 curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
 echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
 apt-get update
 apt-get install -y kubelet=${kube_version} kubeadm=${kube_version} kubectl=${kube_version}
 echo "Waiting 180s to attempt to join cluster..."
}

function join_cluster() {
	echo "Attempting to join cluster" && \
    kubeadm join "${primary_node_ip}:6443" --token "${kube_token}" --discovery-token-unsafe-skip-ca-verification
}

install_docker && \
nvidia_configure && \
enable_docker && \
if [ "${storage}" = "ceph" ]; then
  ceph_pre_check
fi ; \
install_kube_tools && \
sleep 180 && \
join_cluster
