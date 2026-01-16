#!/bin/bash
#
# Launch a Ray cluster inside Docker for vLLM inference on Jetson devices.
#
# Usage:
# 1. On head node:
#    bash run_jetson_cluster.sh [--detach|-d] \
#         mitakad/vllm:0.13.0-r36.4.tegra-aarch64-cp312-cu129-24.04 \
#         <head_node_ip> \
#         --head \
#         <network_interface> \
#         -e VLLM_HOST_IP=<head_node_ip> \
#         -e HF_TOKEN=<token>
#
# 2. On each worker node:
#    bash run_jetson_cluster.sh [--detach|-d] \
#         mitakad/vllm:0.13.0-r36.4.tegra-aarch64-cp312-cu129-24.04 \
#         <head_node_ip> \
#         --worker \
#         <network_interface> \
#         -e VLLM_HOST_IP=<worker_node_ip> \
#         -e HF_TOKEN=<token>
#
# 3. To stop a running container:
#    bash run_jetson_cluster.sh --stop
#
# Note: Use --detach or -d flag to run the container in detached mode (background).

# Parse command line arguments
STOP_MODE=false
DETACHED=false
NUM_CPUS=""
NUM_CPUS_SET=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --stop)
            STOP_MODE=true
            shift
            ;;
        --detach|-d)
            DETACHED=true
            shift
            ;;
        --num-cpus)
            NUM_CPUS="$2"
            NUM_CPUS_SET=true
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

# Handle stop mode
if [ "$STOP_MODE" = true ]; then
    CONTAINER_NAME="jetson-cluster-node"
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}\$"; then
        echo "Stopping and removing container: ${CONTAINER_NAME}"
        docker stop "${CONTAINER_NAME}" || echo "Container was already stopped"
        docker rm "${CONTAINER_NAME}" || echo "Failed to remove container"
        echo "Container stopped and removed successfully"
    else
        echo "No running container found with name: ${CONTAINER_NAME}"
    fi
    exit 0
fi

if [ $# -lt 5 ]; then
    echo "Usage: $0 [--detach|-d] [--num-cpus <num_cpus>] docker_image head_node_ip --head|--worker network_interface [additional_args...]"
    echo "       $0 --stop"
    exit 1
fi

DOCKER_IMAGE="$1"
HEAD_NODE_ADDRESS="$2"
NODE_TYPE="$3"
NETWORK_INTERFACE="$4"
shift 4

ADDITIONAL_ARGS=("$@")

echo "=========================================="
echo "DEBUG: Script Arguments"
echo "=========================================="
echo "DOCKER_IMAGE: ${DOCKER_IMAGE}"
echo "HEAD_NODE_ADDRESS: ${HEAD_NODE_ADDRESS}"
echo "NODE_TYPE: ${NODE_TYPE}"
echo "NETWORK_INTERFACE: ${NETWORK_INTERFACE}"
echo "ADDITIONAL_ARGS: ${ADDITIONAL_ARGS[@]}"
echo ""

if [ "${NODE_TYPE}" != "--head" ] && [ "${NODE_TYPE}" != "--worker" ]; then
    echo "Error: Node type must be --head or --worker"
    exit 1
fi

CONTAINER_NAME="jetson-cluster-node"

cleanup() {
    if [ "$DETACHED" = false ]; then
        docker stop "${CONTAINER_NAME}"
        docker rm "${CONTAINER_NAME}"
    fi
}
if [ "$DETACHED" = false ]; then
    trap cleanup EXIT
fi

echo "=========================================="
echo "DEBUG: Ray Configuration"
echo "=========================================="
echo "RAY_START_CMD: ${RAY_START_CMD}"
echo ""

# Parse VLLM_HOST_IP from additional args
VLLM_HOST_IP=""
for arg in "${ADDITIONAL_ARGS[@]}"; do
    if [[ $arg == "-e" ]]; then
        continue
    fi
    if [[ $arg == VLLM_HOST_IP=* ]]; then
        VLLM_HOST_IP="${arg#VLLM_HOST_IP=}"
        break
    fi
done

echo "=========================================="
echo "DEBUG: Parsed Variables"
echo "=========================================="
echo "VLLM_HOST_IP: ${VLLM_HOST_IP}"
echo ""

# Build Ray IP environment variables if VLLM_HOST_IP is set
RAY_IP_VARS=()
if [ -n "${VLLM_HOST_IP}" ]; then
    RAY_IP_VARS=(
        -e "RAY_NODE_IP_ADDRESS=${VLLM_HOST_IP}"
        -e "RAY_OVERRIDE_NODE_IP_ADDRESS=${VLLM_HOST_IP}"
    )
    # Build Ray start command using VLLM_HOST_IP explicitly for node IP address
    RAY_START_CMD="ray start -v --block --num-gpus 1"
    if [ "$NUM_CPUS_SET" = true ]; then
        RAY_START_CMD+=" --num-cpus=${NUM_CPUS}"
    fi
    if [ "${NODE_TYPE}" == "--head" ]; then
        RAY_START_CMD+=" --head --port=6379 --node-ip-address ${VLLM_HOST_IP} --num-gpus 1"
    else
        RAY_START_CMD+=" --address ${HEAD_NODE_ADDRESS}:6379 --node-ip-address ${VLLM_HOST_IP} --num-gpus 1"
    fi

else
    # Build Ray start command without explicit node IP address
    RAY_START_CMD="ray start -v --block --num-gpus 1"
    if [ "$NUM_CPUS_SET" = true ]; then
        RAY_START_CMD+=" --num-cpus=${NUM_CPUS}"
    fi
    if [ "${NODE_TYPE}" == "--head" ]; then
        RAY_START_CMD+=" --head --port=6379 --num-gpus 1"
    else
        RAY_START_CMD+=" --address=${HEAD_NODE_ADDRESS}:6379 --num-gpus 1"
    fi

fi

echo "=========================================="
echo "DEBUG: Ray IP Variables"
echo "=========================================="
echo "RAY_IP_VARS: ${RAY_IP_VARS[@]}"
echo ""

# Get jetson-containers data path
JETSON_DATA_PATH="$(jetson-containers data)"

echo "=========================================="
echo "DEBUG: Paths"
echo "=========================================="
echo "JETSON_DATA_PATH: ${JETSON_DATA_PATH}"
echo ""

echo "=========================================="
echo "DEBUG: Full Docker Command"
echo "=========================================="
echo "docker run \\"
if [ "$DETACHED" = true ]; then
    echo "    --detach \\"
fi
echo "    --runtime nvidia \\"
echo "    --entrypoint /bin/bash \\"
echo "    --network host \\"
echo "    --name \"${CONTAINER_NAME}\" \\"
echo "    --shm-size 8g \\"
echo "    --privileged \\"
echo "    --ipc=host \\"
echo "    -v /dev/shm:/dev/shm \\"
echo "    -v \"${JETSON_DATA_PATH}\":/data \\"
echo "    -e NVIDIA_DRIVER_CAPABILITIES=all \\"
echo "    -e UCX_NET_DEVICES=${NETWORK_INTERFACE} \\"
echo "    -e NCCL_SOCKET_IFNAME=${NETWORK_INTERFACE} \\"
echo "    -e GLOO_SOCKET_IFNAME=${NETWORK_INTERFACE} \\"
echo "    -e TP_SOCKET_IFNAME=${NETWORK_INTERFACE} \\"
echo "    -e TIKTOKEN_ENCODINGS_BASE=/data/encodings \\"
for var in "${RAY_IP_VARS[@]}"; do
    echo "    ${var} \\"
done
for arg in "${ADDITIONAL_ARGS[@]}"; do
    echo "    ${arg} \\"
done
echo "    \"${DOCKER_IMAGE}\" -c \"${RAY_START_CMD}\""
echo ""

echo "=========================================="
echo "DEBUG: Ray Start Command"
echo "=========================================="
echo "ray start \\"
for var in "${RAY_IP_VARS[@]}"; do
    echo "    ${var} \\"
done
if [ "$NUM_CPUS_SET" = true ]; then
    echo "    --num-cpus=${NUM_CPUS} \\"
fi
echo "    -v \\"
echo "    --block \\"
echo "    --num-gpus 1 \\"
if [ "${NODE_TYPE}" == "--head" ]; then
    echo "    --head \\"
    echo "    --port=6379 \\"
    if [ -n "${VLLM_HOST_IP}" ]; then
        echo "    --node-ip-address ${VLLM_HOST_IP} \\"
    fi
else
    echo "    --address ${HEAD_NODE_ADDRESS}:6379 \\"
    if [ -n "${VLLM_HOST_IP}" ]; then
        echo "    --node-ip-address ${VLLM_HOST_IP} \\"
    fi
fi
echo ""

echo "=========================================="
echo "Press Enter to execute, Ctrl+C to cancel"
echo "=========================================="
read

# Launch container with Jetson-specific configurations
docker run \
    ${DETACHED:+"--detach"} \
    --runtime nvidia \
    --entrypoint /bin/bash \
    --network host \
    --name "${CONTAINER_NAME}" \
    --shm-size 8g \
    --privileged \
    --ipc=host \
    -v /dev/shm:/dev/shm \
    -v "$(jetson-containers data)":/data \
    -e NVIDIA_DRIVER_CAPABILITIES=all \
    -e UCX_NET_DEVICES=${NETWORK_INTERFACE} \
    -e NCCL_SOCKET_IFNAME=${NETWORK_INTERFACE} \
    -e GLOO_SOCKET_IFNAME=${NETWORK_INTERFACE} \
    -e TP_SOCKET_IFNAME=${NETWORK_INTERFACE} \
    -e TIKTOKEN_ENCODINGS_BASE=/data/encodings \
    "${RAY_IP_VARS[@]}" \
    "${ADDITIONAL_ARGS[@]}" \
    "${DOCKER_IMAGE}" -c "${RAY_START_CMD}"
