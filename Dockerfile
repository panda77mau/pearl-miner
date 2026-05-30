FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04

RUN apt-get update && apt-get install -y curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN curl -L -o miner.tar.gz https://pearl.alphapool.tech/downloads/alpha-V1.7.4.20260527.tar.gz && \
    tar -xf miner.tar.gz && \
    chmod +x ./alpha/alpha && \
    rm miner.tar.gz

ENV PEARL_ADDRESS=""
ENV PEARL_POOL_HOST="us2.alphapool.tech"
ENV PEARL_POOL_PORT="5566"
ENV PEARL_BACKEND=""
ENV PEARL_DIFFICULTY="1048576"

CMD ["sh", "-c", "if [ -n \"$PEARL_BACKEND\" ]; then BACKEND_ARG=\"--force-backend $PEARL_BACKEND\"; else BACKEND_ARG=\"\"; fi; ./alpha/alpha --pool stratum+tcp://${PEARL_POOL_HOST}:${PEARL_POOL_PORT} --address ${PEARL_ADDRESS} --worker salad_${SALAD_ORGANIZATION_NAME}_${SALAD_CONTAINER_GROUP_NAME}_$(echo ${SALAD_MACHINE_ID:-x} | cut -c1-6) --password \"x;d=${PEARL_DIFFICULTY}\" $BACKEND_ARG"]
