FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04

RUN apt-get update && apt-get install -y curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN curl -L -o miner.tar.gz https://pearl.alphapool.tech/downloads/alpha-V1.7.4.20260527.tar.gz && \
    tar -xf miner.tar.gz && \
    chmod +x ./alpha/alpha && \
    rm miner.tar.gz

# Tạo startup script
RUN cat > /app/start.sh << 'SCRIPT'
#!/bin/sh
set -e

# Auto-detect GPU và set difficulty phù hợp
GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits 2>/dev/null | head -1)
echo "Detected GPU: $GPU_NAME"

# Nếu PEARL_DIFFICULTY chưa được set thủ công thì auto-detect
if [ -z "$PEARL_DIFFICULTY" ]; then
  case "$GPU_NAME" in
    *"RTX 5090"*|*"H100"*|*"H200"*|*"B100"*|*"B200"*)
      PEARL_DIFFICULTY=1048576 ;;
    *"RTX 4090"*|*"RTX 5080"*)
      PEARL_DIFFICULTY=524288 ;;
    *"RTX 4070"*|*"RTX 4080"*|*"RTX 3080"*|*"RTX 3090"*|*"RTX 5070"*|*"RTX 5060"*)
      PEARL_DIFFICULTY=262144 ;;
    *"A100"*|*"RTX 3060 Ti"*|*"RTX 3070"*|*"RTX 4060"*)
      PEARL_DIFFICULTY=131072 ;;
    *"RTX 2070"*|*"RTX 2080"*|*"RTX 3060"*)
      PEARL_DIFFICULTY=16384 ;;
    *"V100"*|*"CMP 100"*|*"CMP 210"*)
      PEARL_DIFFICULTY=4096 ;;
    *)
      PEARL_DIFFICULTY=262144 ;;  # safe default
  esac
  echo "Auto-selected difficulty: $PEARL_DIFFICULTY"
else
  echo "Manual difficulty: $PEARL_DIFFICULTY"
fi

# Build worker name
WORKER_SUFFIX=$(echo "${SALAD_MACHINE_ID:-$(hostname)}" | cut -c1-6)
WORKER_NAME="salad_${SALAD_ORGANIZATION_NAME}_${SALAD_CONTAINER_GROUP_NAME}_${WORKER_SUFFIX}"

# Build backend arg (chỉ thêm nếu PEARL_BACKEND được set)
BACKEND_ARG=""
if [ -n "$PEARL_BACKEND" ]; then
  BACKEND_ARG="--force-backend $PEARL_BACKEND"
fi

# Run miner
exec ./alpha/alpha \
  --pool stratum+tcp://${PEARL_POOL_HOST}:${PEARL_POOL_PORT} \
  --address ${PEARL_ADDRESS} \
  --worker ${WORKER_NAME} \
  --password "x;d=${PEARL_DIFFICULTY}" \
  ${BACKEND_ARG}
SCRIPT

RUN chmod +x /app/start.sh

ENV PEARL_ADDRESS=""
ENV PEARL_POOL_HOST="us2.alphapool.tech"
ENV PEARL_POOL_PORT="5566"
ENV PEARL_BACKEND=""
ENV PEARL_DIFFICULTY=""

CMD ["/app/start.sh"]
